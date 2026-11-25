/*
  @menu
  displayname = "Nix settings";
  icon = "package-x-generic-symbolic";
  order = 110;
  description = "Nix tooling, the settings GUIs, the LAN cache and remote builders";
  category = "02-Core";
*/

{ self, inputs, ... }: {

  flake.modules.nixos.system-nixsettings = { config, pkgs, ... }: {

    imports = [
      inputs.nix-shell-gui.nixosModules.default
      inputs.nix-regedit.nixosModules.default
      inputs.nix-cache-discovery.nixosModules.default
      inputs.nix-builder-discovery.nixosModules.default
      inputs.nix-cleaner.nixosModules.default
      inputs.nix-connect.nixosModules.default
    ];

    nixpkgs.overlays = [ inputs.nom-cache-discovery.overlays.default ];

    # @option widget = "switch"; label = "Allow unfree packages"; group = "Packages"; groupOrder = 10; order = 100; description = "Needed by Steam, NVIDIA drivers and other proprietary software.";
    nixpkgs.config.allowUnfree = true;

    # @option widget = "list"; label = "Trusted users"; group = "Access"; groupOrder = 20; order = 100; description = "Users allowed to use the Nix daemon and add substituters.";
    nix.settings.trusted-users = [ "@wheel" ];

    # @option widget = "list"; label = "Experimental features"; group = "Features"; groupOrder = 30; order = 100; description = "nix-command and flakes are required by this flake.";
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # @option widget = "switch"; label = "LAN cache"; group = "LAN cache"; groupOrder = 35; order = 10; description = "Share built store paths with other devices on the LAN and use their caches.";
    services.nix-cache-discovery.enable = false;

    # @option widget = "switch"; label = "Use only the LAN cache"; group = "LAN cache"; groupOrder = 35; order = 20; description = "Make the LAN cache the only substituter. It fetches missing paths from upstream caches for you, so the substituter list below is hidden and unused.";
    services.nix-cache-discovery.exclusive = false;

    # @option widget = "switch"; label = "Detect LAN automatically"; group = "LAN cache"; groupOrder = 35; order = 25; visibleWhen.path = "services.nix-cache-discovery.enable"; visibleWhen.equals = true; description = "Use the subnet this device is connected to. Fixed ranges below are ignored while enabled.";
    services.nix-cache-discovery.discovery.auto = true;

    # @option widget = "spin"; label = "LAN cache port"; group = "LAN cache"; groupOrder = 35; order = 30; min = 1; max = 65535; visibleWhen.path = "services.nix-cache-discovery.enable"; visibleWhen.equals = true; description = "Must match on every device that should share the cache.";
    services.nix-cache-discovery.port = 5055;

    # @option widget = "spin"; label = "LAN cache scan interval"; group = "LAN cache"; groupOrder = 35; order = 35; min = 10; max = 3600; unit = "s"; visibleWhen.path = "services.nix-cache-discovery.enable"; visibleWhen.equals = true; description = "Seconds between scans for other devices.";
    services.nix-cache-discovery.discovery.interval = 600;

    # @option widget = "list"; label = "LAN cache ranges"; group = "LAN cache"; groupOrder = 35; order = 40; itemLabel = "range"; addLabel = "Add range"; visibleWhen.path = "services.nix-cache-discovery.discovery.auto"; visibleWhen.equals = false; description = "Fixed ranges used when automatic detection is off.";
    services.nix-cache-discovery.discovery.ranges = [ "192.168.0.0/16" ];

    # @option widget = "switch"; label = "LAN remote builders"; group = "Remote builders"; groupOrder = 36; order = 10; description = "Discover and pair with other devices for remote builds. The first build opens an approval on both machines.";
    services.nix-builder-discovery.enable = false;

    # @option widget = "dropdown"; label = "Act as a builder for others"; group = "Remote builders"; groupOrder = 36; order = 20; choices = [ "ask" "allow" "deny" ]; visibleWhen.path = "services.nix-builder-discovery.enable"; visibleWhen.equals = true; description = "ask opens a prompt on this device, allow trusts new devices automatically, deny makes this device client only.";
    services.nix-builder-discovery.defaults.incoming = "ask";

    # @option widget = "dropdown"; label = "Use other devices as builders"; group = "Remote builders"; groupOrder = 36; order = 30; choices = [ "ask" "allow" "deny" ]; visibleWhen.path = "services.nix-builder-discovery.enable"; visibleWhen.equals = true; description = "ask opens a prompt, allow trusts new builders automatically, deny makes this device builder only.";
    services.nix-builder-discovery.defaults.outgoing = "ask";

    # @option widget = "switch"; label = "Detect LAN automatically"; group = "Remote builders"; groupOrder = 36; order = 40; visibleWhen.path = "services.nix-builder-discovery.enable"; visibleWhen.equals = true; description = "Use the subnet this device is connected to. Fixed ranges below are ignored while enabled.";
    services.nix-builder-discovery.discovery.auto = true;

    # @option widget = "list"; label = "Builder discovery ranges"; group = "Remote builders"; groupOrder = 36; order = 50; itemLabel = "range"; addLabel = "Add range"; visibleWhen.path = "services.nix-builder-discovery.discovery.auto"; visibleWhen.equals = false; description = "Fixed ranges used when automatic detection is off.";
    services.nix-builder-discovery.discovery.ranges = [ "192.168.0.0/16" ];

    # @option widget = "switch"; label = "Wait for a busy builder"; group = "Remote builders"; groupOrder = 36; order = 60; advanced = true; visibleWhen.path = "services.nix-builder-discovery.enable"; visibleWhen.equals = true; description = "Wait for a remote slot instead of building locally when every eligible builder is busy.";
    services.nix-builder-discovery.waitForBuilders = false;

    # @option widget = "spin"; label = "Concurrent remote job count"; group = "Remote builders"; groupOrder = 36; order = 70; advanced = true; min = 1; max = 16; visibleWhen.path = "services.nix-builder-discovery.enable"; visibleWhen.equals = true; description = "Jobs this device accepts when acting as a builder.";
    services.nix-builder-discovery.maxConnections = 1;

    # @option widget = "text"; label = "Builder cache URL"; group = "Remote builders"; groupOrder = 36; order = 80; advanced = true; visibleWhen.path = "services.nix-builder-discovery.enable"; visibleWhen.equals = true; description = "Optional LAN cache URL for inputs and outputs. Empty uses direct transfer.";
    services.nix-builder-discovery.cacheURL = "";

    # @option widget = "switch"; label = "Device management"; group = "Device management"; groupOrder = 37; order = 10; description = "Discover and manage NixOS devices on the LAN. Disabled by default.";
    services.nix-connect.enable = false;

    # @option widget = "switch"; label = "Device management GUI"; group = "Device management"; groupOrder = 37; order = 15; visibleWhen.path = "services.nix-connect.enable"; visibleWhen.equals = true; description = "Install the nix-connect GUI for pairing and managing devices.";
    services.nix-connect.gui.enable = true;

    # @option widget = "spin"; label = "Information port"; group = "Device management"; groupOrder = 37; order = 20; min = 1; max = 65535; visibleWhen.path = "services.nix-connect.enable"; visibleWhen.equals = true; description = "Public, signed device information port.";
    services.nix-connect.infoPort = 5060;

    # @option widget = "spin"; label = "Control port"; group = "Device management"; groupOrder = 37; order = 30; min = 1; max = 65535; visibleWhen.path = "services.nix-connect.enable"; visibleWhen.equals = true; description = "mTLS control port for paired devices.";
    services.nix-connect.controlPort = 5061;

    # @option widget = "switch"; label = "Open firewall"; group = "Device management"; groupOrder = 37; order = 40; visibleWhen.path = "services.nix-connect.enable"; visibleWhen.equals = true; description = "Open the information and control ports on the LAN.";
    services.nix-connect.openFirewall = true;

    # @option widget = "switch"; label = "Detect LAN automatically"; group = "Device management"; groupOrder = 37; order = 50; visibleWhen.path = "services.nix-connect.enable"; visibleWhen.equals = true; description = "Use the current subnet for discovery.";
    services.nix-connect.discovery.auto = true;

    # @option widget = "list"; label = "Discovery ranges"; group = "Device management"; groupOrder = 37; order = 60; itemLabel = "range"; addLabel = "Add range"; visibleWhen.path = "services.nix-connect.discovery.auto"; visibleWhen.equals = false; description = "Fixed ranges used when automatic detection is off.";
    services.nix-connect.discovery.ranges = [ "192.168.0.0/16" ];

    # @option widget = "spin"; label = "Discovery interval"; group = "Device management"; groupOrder = 37; order = 70; min = 10; max = 3600; unit = "s"; visibleWhen.path = "services.nix-connect.enable"; visibleWhen.equals = true; description = "Seconds between discovery scans.";
    services.nix-connect.discovery.interval = 600;

    # @option widget = "list"; label = "Substituters"; group = "Substituters"; groupOrder = 40; description = "Binary caches to pull prebuilt paths from. Hidden while the LAN cache is the only substituter."; order = 100; visibleWhen.path = "services.nix-cache-discovery.exclusive"; visibleWhen.equals = false;
    nix.settings.substituters = [ "https://cache.nixos.org/" ];

    # @option widget = "list"; label = "Fallback substituters"; group = "Substituters"; groupOrder = 40; description = "Upstream caches the LAN cache consults after the local store and LAN peers."; order = 100; visibleWhen.path = "services.nix-cache-discovery.exclusive"; visibleWhen.equals = true;
    services.nix-cache-discovery.fallbackSubstituters = [ "https://cache.nixos.org" ];

    # @option widget = "switch"; label = "Verify fallback signatures"; group = "Substituters"; groupOrder = 40; order = 150; advanced = true; visibleWhen.path = "services.nix-cache-discovery.exclusive"; visibleWhen.equals = true; description = "Verify narinfo signatures from the fallback substituters before proxying them.";
    services.nix-cache-discovery.verifyFallbackSignatures = true;

    # @option widget = "list"; label = "Trusted public keys"; group = "Substituters"; groupOrder = 40; description = "Signing keys for the substituters above, and for the upstream caches the LAN cache proxies."; order = 200;
    nix.settings.trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];

    # @option widget = "dropdown"; label = "Max build jobs"; group = "Build"; groupOrder = 50; choices = [ "auto" "1" "2" "4" "8" "16" "32" ]; description = "Number of parallel build processes, or auto to use every CPU core."; order = 100;
    nix.settings.max-jobs = "auto";

    # @option widget = "spin"; label = "Cores per job"; group = "Build"; groupOrder = 50; description = "Cores each build uses; 0 means all of them."; min = 0; max = 128; order = 200;
    nix.settings.cores = 0;

    # @option widget = "switch"; label = "Sandbox builds"; group = "Build"; groupOrder = 50; description = "Run builds in isolated namespaces."; order = 300;
    nix.settings.sandbox = true;

    # @option widget = "switch"; label = "Allow import from derivation"; group = "Build"; groupOrder = 50; description = "Lets derivations evaluate other derivations; needed by some flakes."; order = 400;
    nix.settings.allow-import-from-derivation = true;

    # @option widget = "spin"; label = "Connection timeout"; group = "Daemon"; groupOrder = 60; description = "Seconds before a download is abandoned."; min = 1; max = 600; unit = "s"; order = 100;
    nix.settings.connect-timeout = 30;

    # @option widget = "spin"; label = "Stalled download timeout"; group = "Daemon"; groupOrder = 60; description = "Seconds a download may stall before it is retried."; min = 1; max = 3600; unit = "s"; order = 200;
    nix.settings.stalled-download-timeout = 1200;

    # @option widget = "spin"; label = "Download attempts"; group = "Daemon"; groupOrder = 60; description = "How many times a failed download is retried."; min = 1; max = 100; order = 300;
    nix.settings.download-attempts = 30;

    # @option widget = "switch"; label = "Auto-optimise store"; group = "Store"; groupOrder = 70; order = 100; description = "Hard-link identical store paths to save disk space.";
    nix.settings.auto-optimise-store = true;

    # @option widget = "switch"; label = "Optimise store periodically"; group = "Store"; groupOrder = 70; order = 200;
    nix.optimise.automatic = true;

    # @option widget = "switch"; label = "Automatic garbage collection"; group = "Garbage collection"; groupOrder = 80; order = 100;
    nix.gc.automatic = true;

    # @option widget = "list"; label = "Garbage collection schedule"; group = "Garbage collection"; groupOrder = 80; order = 200; visibleWhen.path = "nix.gc.automatic"; visibleWhen.equals = true; description = "systemd calendar expressions, e.g. weekly.";
    nix.gc.dates = [ "weekly" ];

    # @option widget = "text"; label = "Garbage collection options"; group = "Garbage collection"; groupOrder = 80; order = 300; visibleWhen.path = "nix.gc.automatic"; visibleWhen.equals = true; description = "e.g. --delete-older-than 30d";
    nix.gc.options = "--delete-older-than 30d";

    # @option widget = "multiline"; label = "Extra nix.conf options"; group = "Advanced"; groupOrder = 95; order = 10; rows = 5; advanced = true; description = "Raw lines appended to /etc/nix/nix.conf.";
    nix.extraOptions = "";

    # @option widget = "switch"; label = "Install Nix Shell GUI"; group = "Tools"; groupOrder = 90; order = 100;
    services.nix-shell-gui.enable = true;

    # @option widget = "switch"; label = "Install Nix Regedit"; group = "Tools"; groupOrder = 90; order = 200;
    services.nix-regedit.enable = true;

    # @option widget = "switch"; label = "Install Nix Cleaner"; group = "Tools"; groupOrder = 90; order = 300;
    programs.nix-cleaner.enable = true;

    environment.systemPackages = with pkgs; [ nix-output-monitor ];

    # Every nix call from the GUIs and from the printed rebuild command carries
    # --extra-experimental-features "nix-command flakes"; nix.conf is never
    # written. nix-settings-gui and simple-nix-update-gui live on the Updates
    # page.

  };

}
