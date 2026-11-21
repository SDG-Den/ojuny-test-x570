{ pkgs, nixpkgs }:
let
  lib = nixpkgs.lib;

  graphicsBackend =
    (import ../modules/backend/01-system/04-graphics-backend.nix {
      self = { };
      inputs = { };
    }).flake.modules.nixos.system-graphics-backend;

  graphicsPage =
    (import ../modules/07-system/04-graphics.nix {
      self = { modules.nixos.system-graphics-backend = graphicsBackend; };
      inputs = { };
    }).flake.modules.nixos.system-graphics;

  hardwareStub =
    { lib, ... }:
    {
      options.ojuny.hardware.gpu = {
        managed = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        detected = lib.mkOption {
          type = lib.types.str;
          default = "unknown";
        };
        source = lib.mkOption {
          type = lib.types.str;
          default = "test";
        };
        legacyIntel = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        busIds = lib.mkOption {
          type = lib.types.attrs;
          default = {
            intel = "PCI:0:2:0";
            amd = "PCI:5:0:0";
            nvidia = "PCI:1:0:0";
            discrete = "PCI:5:0:0";
          };
        };
      };
      options.ojuny.hardware.detectedProfile = lib.mkOption {
        type = lib.types.str;
        default = "unmatched";
      };
    };

  system = pkgs.stdenv.hostPlatform.system;

  evalBackend = detected: profile: extra: (nixpkgs.lib.nixosSystem {
    modules = [
      { nixpkgs.hostPlatform = system; }
      graphicsBackend
      hardwareStub
      {
        config.ojuny.hardware.gpu.detected = detected;
        config.ojuny.hardware.detectedProfile = profile;
      }
    ] ++ extra;
  }).config;

  evalPage = extra: (nixpkgs.lib.nixosSystem {
    modules = [
      { nixpkgs.hostPlatform = system; }
      graphicsPage
      hardwareStub
      { config.ojuny.hardware.gpu.detected = "intel"; }
    ] ++ extra;
  }).config;

  names = packages: map (package: package.name) packages;
  hasParam = params: param: builtins.elem param params;
  contains = text: fragment: lib.hasInfix fragment text;

  intelDefault = evalBackend "intel" "unmatched" [ ];
  intelProfile = evalBackend "intel" "microsoft-surface-go" [
    { config.hardware.graphics.extraPackages = [ pkgs.intel-compute-runtime-legacy1 ]; }
  ];
  driversProfile = evalBackend "intel" "unmatched" [
    { config.services.xserver.videoDrivers = [ "profile-driver" ]; }
  ];
  amdModprobe = evalBackend "amd" "unmatched" [
    { config.ojuny.gpuAmd.siCik = true; }
    { config.boot.extraModprobeConfig = "options profile=1\n"; }
  ];
  nvidia = evalBackend "nvidia" "unmatched" [ ];
  hybridNvidia = evalBackend "hybrid-intel-nvidia" "unmatched" [ ];
  pageDefault = evalPage [ ];
  pageProfile = evalPage [
    {
      config.hardware.graphics.enable = false;
      config.hardware.enableRedistributableFirmware = false;
    }
  ];
  softwareNone = evalBackend "unknown" "unmatched" [ ];
  softwareLegacy = evalBackend "intel" "unmatched" [
    { config.ojuny.hardware.gpu.legacyIntel = true; }
  ];
  softwareLegacySwitch = evalBackend "intel" "unmatched" [
    { config.ojuny.gpuIntel.legacy = true; }
  ];
  hardwareIntel = evalBackend "intel" "unmatched" [ ];

  hardwareProfileModule = import ../modules/backend/01-system/10-hardware-profile.nix {
    self = { };
    inputs = { inherit nixpkgs; };
  };
  legacyReport = {
    smbios.system = {
      manufacturer = "LENOVO";
      product = "25372Q6";
    };
    hardware.graphics_card = [
      {
        vendor = {
          name = "Intel Corporation";
          hex = "8086";
        };
        device = { hex = "0046"; };
        sysfs_bus_id = "0000:00:02.0";
      }
    ];
  };
  broadwellReport = {
    smbios.system = {
      manufacturer = "LENOVO";
      product = "25372Q6";
    };
    hardware.graphics_card = [
      {
        vendor = {
          name = "Intel Corporation";
          hex = "8086";
        };
        device = { hex = "1616"; };
        sysfs_bus_id = "0000:00:02.0";
      }
    ];
  };
  legacyDetection = hardwareProfileModule.flake.lib.hardware-profile legacyReport;
  broadwellDetection = hardwareProfileModule.flake.lib.hardware-profile broadwellReport;

  envVar = config: name: config.environment.sessionVariables.${name} or null;
  softwareVars = [
    "LIBGL_ALWAYS_SOFTWARE"
    "GALLIUM_DRIVER"
    "MESA_LOADER_DRIVER_OVERRIDE"
    "GSK_RENDERER"
    "WEBKIT_DISABLE_COMPOSITING_MODE"
    "VK_DRIVER_FILES"
  ];
  hasSoftwareEnv = config: builtins.all (name: envVar config name != null) softwareVars;
  hasSoftGL = config:
    let
      vk = envVar config "VK_DRIVER_FILES";
    in
    envVar config "LIBGL_ALWAYS_SOFTWARE" == "1"
    && envVar config "QSG_RENDER_LOOP" == "basic"
    && vk != null
    && lib.hasSuffix "/lvp_icd.x86_64.json" vk;

  results = [
    {
      name = "profile extraPackages must replace the template Intel packages";
      ok = names intelProfile.hardware.graphics.extraPackages == [ pkgs.intel-compute-runtime-legacy1.name ];
    }
    {
      name = "template Intel packages must apply without a profile";
      ok = names intelDefault.hardware.graphics.extraPackages == [
        pkgs.intel-media-driver.name
        pkgs.vpl-gpu-rt.name
        pkgs.intel-compute-runtime.name
      ];
    }
    {
      name = "Intel GuC parameter must apply without a profile";
      ok = hasParam intelDefault.boot.kernelParams "i915.enable_guc=3";
    }
    {
      name = "Intel GuC parameter must be suppressed by a profile";
      ok = !hasParam intelProfile.boot.kernelParams "i915.enable_guc=3";
    }
    {
      name = "profile videoDrivers must replace the template drivers";
      ok = driversProfile.services.xserver.videoDrivers == [ "profile-driver" ];
    }
    {
      name = "template AMD modprobe options must merge with profile options";
      ok =
        contains amdModprobe.boot.extraModprobeConfig "options amdgpu si_support=1"
        && contains amdModprobe.boot.extraModprobeConfig "options profile=1";
    }
    {
      name = "NVIDIA defaults must apply without a profile";
      ok =
        lib.hasPrefix "nvidia-x11" nvidia.hardware.nvidia.package.name
        && nvidia.hardware.nvidia.open == false
        && nvidia.hardware.nvidia.modesetting.enable
        && hybridNvidia.hardware.nvidia.prime.offload.enable
        && hybridNvidia.hardware.nvidia.prime.nvidiaBusId == "PCI:1:0:0";
    }
    {
      name = "graphics and firmware defaults must apply without a profile";
      ok = pageDefault.hardware.graphics.enable && pageDefault.hardware.enableRedistributableFirmware;
    }
    {
      name = "profile graphics and firmware definitions must win";
      ok = !pageProfile.hardware.graphics.enable && !pageProfile.hardware.enableRedistributableFirmware;
    }
    {
      name = "software fallback must force Mesa, GTK, WebKit and Vulkan software rendering";
      ok = hasSoftwareEnv softwareNone && hasSoftGL softwareNone;
    }
    {
      name = "legacy Intel must use the software fallback";
      ok =
        hasSoftwareEnv softwareLegacy
        && hasSoftGL softwareLegacy
        && names softwareLegacy.hardware.graphics.extraPackages == [ pkgs.intel-vaapi-driver.name ]
        && envVar softwareLegacy "LIBVA_DRIVER_NAME" == "i965";
    }
    {
      name = "legacy switch must use the software fallback";
      ok = hasSoftwareEnv softwareLegacySwitch && hasSoftGL softwareLegacySwitch;
    }
    {
      name = "Ironlake PCI ID must select legacy Intel";
      ok = legacyDetection.gpu.legacyIntel;
    }
    {
      name = "Broadwell PCI ID must not select legacy Intel";
      ok = !broadwellDetection.gpu.legacyIntel;
    }
    {
      name = "non-legacy Intel must keep the threaded hardware path";
      ok =
        envVar hardwareIntel "LIBGL_ALWAYS_SOFTWARE" == null
        && envVar hardwareIntel "QSG_RENDER_LOOP" == "threaded";
    }
  ];

  failed = builtins.filter (result: !result.ok) results;
in
if failed == [ ] then
  pkgs.runCommand "check-graphics-defaults" { } "touch $out"
else
  throw (
    "check-graphics-defaults failed:\n"
    + lib.concatStringsSep "\n" (map (result: "  ${result.name}") failed)
  )
