{ inputs, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    let
      generateUser = pkgs.writeShellApplication {
        name = "generate-user";
        runtimeInputs = [
          pkgs.mkpasswd
          pkgs.coreutils
          pkgs.python3
        ];
        text = builtins.readFile ../../scripts/generate-user.sh;
      };
    in
    {
      apps.prepare-repo = {
        type = "app";
        program = "${config.packages.prepare-repo}/bin/prepare-repo";
      };

      apps.regenerate-hardware = {
        type = "app";
        program = "${config.packages.regenerate-hardware}/bin/regenerate-hardware";
      };

      apps.ci = {
        type = "app";
        program = "${
          pkgs.writeShellApplication {
            name = "ci";
            runtimeInputs = [ pkgs.nix ];
            text = ''
              exec nix flake check "$@"
            '';
          }
        }/bin/ci";
      };

      apps.remote-setup = {
        type = "app";
        program = "${
          pkgs.writeShellApplication {
            name = "remote-setup";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.git
              pkgs.openssh
              pkgs.nix
              inputs.deploy-rs.packages.${system}.default
            ];
            text = ''
              export OJUNY_TEMPLATE_SOURCE="${inputs.self}"
              export OJUNY_DEPLOY_RS="${inputs.deploy-rs.packages.${system}.default}/bin/deploy"
              ${builtins.readFile ../../scripts/remote-setup.sh}
            '';
          }
        }/bin/remote-setup";
      };

      apps.prepare-remote-repository = {
        type = "app";
        program = "${
          pkgs.writeShellApplication {
            name = "prepare-remote-repository";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.git
              pkgs.gnused
              pkgs.mkpasswd
              pkgs.nix
              pkgs.python3
            ];
            text = ''
              export OJUNY_TEMPLATE_SOURCE="${inputs.self}"
              ${builtins.readFile ../../scripts/prepare-remote-repository.sh}
            '';
          }
        }/bin/prepare-remote-repository";
      };

      apps.remote-install = {
        type = "app";
        program = "${
          pkgs.writeShellApplication {
            name = "remote-install";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.git
              pkgs.gnused
              pkgs.nix
              pkgs.openssh
              inputs.disko.packages.${system}.disko
              inputs.nixos-anywhere.packages.${system}.default
            ];
            text = ''
              export OJUNY_TEMPLATE_SOURCE="${inputs.self}"
              export OJUNY_DISKO="${inputs.disko.packages.${system}.disko}/bin/disko"
              export OJUNY_NIXOS_ANYWHERE="${inputs.nixos-anywhere.packages.${system}.default}/bin/nixos-anywhere"
              ${builtins.readFile ../../scripts/remote-install.sh}
            '';
          }
        }/bin/remote-install";
      };

      apps.setup = {
        type = "app";
        program = "${
          pkgs.writeShellApplication {
            name = "setup";
            runtimeInputs = [
              pkgs.nixos-install-tools
              pkgs.nixos-option
              pkgs.nixos-rebuild
              pkgs.mkpasswd
              pkgs.nix
              pkgs.python3
              pkgs.git
              pkgs.coreutils
              pkgs.gnused
              pkgs.gnugrep
              (pkgs.writeShellApplication {
                name = "generate-hw";
                runtimeInputs = [
                  pkgs.nixos-install-tools
                  pkgs.nixos-facter
                  pkgs.python3
                  pkgs.coreutils
                  pkgs.gnused
                  pkgs.gnugrep
                  pkgs.util-linux
                ];
                text = builtins.readFile ../../scripts/generate-hw.sh;
              })
              generateUser
              (pkgs.writeShellApplication {
                name = "create-new-system";
                runtimeInputs = [
                  pkgs.gnused
                  pkgs.coreutils
                  pkgs.python3
                ];
                text = builtins.readFile ../../scripts/create-new-system.sh;
              })
            ];
            text = builtins.readFile ../../scripts/setup.sh;
          }
        }/bin/setup";
      };

      apps.handover = {
        type = "app";
        program = "${
          pkgs.writeShellApplication {
            name = "handover";
            runtimeInputs = [
              pkgs.nixos-rebuild
              pkgs.git
              pkgs.coreutils
              pkgs.gnused
              pkgs.gnugrep
              pkgs.python3
              generateUser
            ];
            text = builtins.readFile ../../scripts/handover.sh;
          }
        }/bin/handover";
      };

      apps.factory-reset = {
        type = "app";
        program = "${
          pkgs.writeShellApplication {
            name = "factory-reset";
            runtimeInputs = [
              pkgs.nixos-rebuild
              pkgs.git
              pkgs.rsync
              pkgs.coreutils
              pkgs.gnused
              pkgs.gnugrep
              pkgs.python3
            ];
            text = builtins.readFile ../../scripts/factory-reset.sh;
          }
        }/bin/factory-reset";
      };
    };
}
