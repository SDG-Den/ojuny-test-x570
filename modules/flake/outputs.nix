{ inputs, self, ... }:
{
  flake = {
    # Only the source checks live here. A system build in hydraJobs would
    # force import-from-derivation during `nix flake check`; the fixture
    # build runs in scripts/check-baseline.sh instead.
    hydraJobs = self.checks;

    nixosModules.default = inputs.ojuny-desktop.nixosModules.default;
    homeManagerModules.default = inputs.ojuny-desktop.homeManagerModules.default;

    deploy.nodes = builtins.mapAttrs (name: configuration: {
      hostname = name;
      sshUser = "root";
      profiles.system = {
        user = "root";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos configuration;
      };
    }) (builtins.removeAttrs self.nixosConfigurations [ "fixture" ]);
  };
}
