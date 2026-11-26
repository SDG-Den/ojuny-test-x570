{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      source = pkgs.lib.cleanSource ../../..;

      oskToggleTest = pkgs.writeShellScriptBin "test-ojuny-osk-toggle" (
        builtins.readFile ../../../scripts/ojuny-osk-toggle.sh
      );
    in
    {
      checks.hardware-profile =
        pkgs.runCommand "check-hardware-profile"
          {
            nativeBuildInputs = [ pkgs.python3 ];
          }
          ''
            python3 ${source}/tests/check-hardware-profile.py --root ${source}
            touch $out
          '';

      checks.graphics-defaults = import ../../../tests/check-graphics-defaults.nix {
        inherit pkgs;
        nixpkgs = inputs.nixpkgs;
      };

      checks.minimal-graphics =
        pkgs.runCommand "check-minimal-graphics"
          {
            nativeBuildInputs = [ pkgs.python3 ];
          }
          ''
            python3 ${source}/tests/check-minimal-graphics.py --root ${source}
            touch $out
          '';

      checks.bootorder =
        pkgs.runCommand "check-bootorder"
          {
            nativeBuildInputs = [
              pkgs.bash
              pkgs.coreutils
            ];
          }
          ''
            SCRIPT=${source}/modules/backend/01-system/bootorder.sh bash ${source}/tests/check-bootorder.sh
            touch $out
          '';

      checks.osk-toggle =
        pkgs.runCommand "check-osk-toggle"
          {
            nativeBuildInputs = [
              pkgs.bash
              pkgs.coreutils
              pkgs.gnugrep
            ];
          }
          ''
            bash ${
              builtins.path {
                path = ../../../tests/check-osk-toggle.sh;
                name = "check-osk-toggle.sh";
              }
            } ${oskToggleTest}/bin/test-ojuny-osk-toggle
            touch $out
          '';

      checks.derived-kernel =
        let
          lib = pkgs.lib;

          reportNames = [
            "report-laptop"
            "report-desktop"
            "report-amd-kvm"
            "report-virtio-vm"
            "report-sata-server"
          ];

          readReport =
            name: builtins.fromJSON (builtins.readFile (../../../tests/fixtures + "/${name}.json"));

          settings = {
            default = { };

            all-toggles = {
              ojuny.derivedKernel = {
                wifi = lib.mkForce true;
                usbNetworking = lib.mkForce true;
                webcam = lib.mkForce true;
                gamepad = lib.mkForce true;
                bluetooth = lib.mkForce true;
                printing = lib.mkForce true;
                luks = lib.mkForce true;
                networkFilesystems = lib.mkForce true;
                legacyHardware = lib.mkForce true;
                debugTracing = lib.mkForce true;
              };
              virtualisation.libvirtd.enable = lib.mkForce true;
              virtualisation.docker.enable = lib.mkForce true;
              boot.swraid.enable = lib.mkForce true;
              zramSwap.enable = lib.mkForce true;
              boot.zswap.enable = lib.mkForce true;
              services.printing.enable = lib.mkForce true;
              hardware.bluetooth.enable = lib.mkForce true;
              networking.wireless.enable = lib.mkForce true;
              services.nfs.server.enable = lib.mkForce true;
              services.samba.enable = lib.mkForce true;
              services.btrfs.autoScrub.enable = lib.mkForce true;
              environment.systemPackages = [ pkgs.bpftrace ];
            };

            services = {
              virtualisation.libvirtd.enable = lib.mkForce true;
              virtualisation.docker.enable = lib.mkForce true;
              services.printing.enable = lib.mkForce true;
              hardware.bluetooth.enable = lib.mkForce true;
              networking.wireless.enable = lib.mkForce true;
              services.nfs.server.enable = lib.mkForce true;
              services.samba.enable = lib.mkForce true;
              services.btrfs.autoScrub.enable = lib.mkForce true;
            };

            legacy = {
              ojuny.derivedKernel.legacyHardware = lib.mkForce true;
            };

            debug = {
              ojuny.derivedKernel.debugTracing = lib.mkForce true;
              environment.systemPackages = [ pkgs.bpftrace ];
            };
          };

          mkCase =
            reportName: settingName: setting:
            let
              fixture = self.nixosConfigurations.fixture.extendModules {
                modules = [
                  {
                    ojuny.kernel = inputs.nixpkgs.lib.mkOverride 49 "Derived Minimal (Experimental)";
                    hardware.facter.report = lib.mkForce (readReport reportName);
                  }
                  setting
                ];
              };
              cfg = fixture.config;
              payload = pkgs.writeText "derived-kernel-${reportName}-${settingName}.json" (
                builtins.toJSON {
                  coreSymbols = cfg.ojuny.derivedKernel.coreSymbols;
                  activeSymbols = cfg.ojuny.derivedKernel.activeSymbols;
                  moduleSymbols = cfg.ojuny.derivedKernel.moduleSymbols;
                  activeComponents = cfg.ojuny.derivedKernel.activeComponents;
                  reportDrivers = cfg.ojuny.derivedKernel.reportDrivers;
                  reportClasses = cfg.ojuny.derivedKernel.reportClasses;
                  moduleComponents = cfg.ojuny.derivedKernel.moduleComponents;
                  classComponents = cfg.ojuny.derivedKernel.classComponents;
                  initrdModules = cfg.boot.initrd.availableKernelModules ++ cfg.boot.initrd.kernelModules;
                  kernelModules = cfg.boot.kernelModules;
                }
              );
            in
            pkgs.runCommand "check-derived-kernel-${reportName}-${settingName}"
              {
                nativeBuildInputs = [ pkgs.python3 ];
              }
              ''
                python3 ${../../../tests/check-derived-kernel.py} \
                  --config ${cfg.boot.kernelPackages.kernel.configfile} \
                  --base-config ${pkgs.linux_7_3.configfile} \
                  --payload ${payload}
                touch $out
              '';

          cases = lib.concatMap (
            reportName:
            lib.mapAttrsToList (settingName: setting: mkCase reportName settingName setting) settings
          ) reportNames;
        in
        pkgs.runCommand "check-derived-kernel" { } ''
          ${lib.concatMapStringsSep "\n" (case: "echo ${case} >/dev/null") cases}
          touch $out
        '';
    };
}
