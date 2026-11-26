{ inputs, ... }:
{
  perSystem = { pkgs, system, ... }: {
    packages = {
      prepare-repo = pkgs.writeShellApplication {
        name = "prepare-repo";
        runtimeInputs = [ pkgs.python3 ];
        text = ''
          export PYTHONPATH=${../../scripts}''${PYTHONPATH:+:$PYTHONPATH}
          exec python3 ${../../scripts/prepare-repo.py} "$@"
        '';
      };

      regenerate-hardware = pkgs.writeShellApplication {
        name = "regenerate-hardware";
        runtimeInputs = [
          pkgs.python3
          pkgs.nixos-install-tools
          pkgs.nixos-facter
          pkgs.util-linux
          pkgs.coreutils
          pkgs.gnused
          pkgs.gnugrep
        ];
        text = ''
          export PYTHONPATH=${../../scripts}''${PYTHONPATH:+:$PYTHONPATH}
          exec python3 ${../../scripts/regenerate-hardware.py} "$@"
        '';
      };

      ojuny-bootorder = pkgs.writeShellApplication {
        name = "ojuny-bootorder";
        runtimeInputs = with pkgs; [
          coreutils
          efibootmgr
          findutils
          gawk
          gnugrep
          gnused
          util-linux
        ];
        text = builtins.readFile ../../modules/backend/01-system/bootorder.sh;
      };

      ojuny-ukify = pkgs.writeShellApplication {
        name = "ukify";
        runtimeInputs = [
          (pkgs.python3.withPackages (ps: [
            ps.cryptography
            ps.pefile
          ]))
          pkgs.binutils
        ];
        text = ''
          exec python3 ${pkgs.systemd.src}/src/ukify/ukify.py "$@" \
            --stub ${pkgs.systemd}/lib/systemd/boot/efi/linuxx64.efi.stub
        '';
      };

      nix-settings-gui = inputs.nix-settings-gui.packages.${system}.default;
      ojuny-welcome = inputs.ojuny-welcome.packages.${system}.default;
      nix-regedit = inputs.nix-regedit.packages.${system}.default;
      nix-shell-gui = inputs.nix-shell-gui.packages.${system}.default;
      nix-cache-discovery = inputs.nix-cache-discovery.packages.${system}.default;
      nix-builder-discovery = inputs.nix-builder-discovery.packages.${system}.default;
      nix-cleaner = inputs.nix-cleaner.packages.${system}.default;
      simple-nix-update-gui = inputs.simple-nix-update-gui.packages.${system}.default;
      simple-nix-update-gui-daemon = inputs.simple-nix-update-gui.packages.${system}.daemon;
      mango = inputs.ojuny-desktop.inputs.mangowm.packages.${system}.mango;
      dux = inputs.ojuny-desktop.inputs.dux-shell.packages.${system}.default;
      dms-greeter = inputs.dux-greeter.packages.${system}.dms-greeter;
      raven = inputs.raven.packages.${system}.raven;
      ojuny-cli = inputs.ojuny-cli.packages.${system}.ojuny-cli;
      ojuny-patches-cli = inputs.ojuny-cli.packages.${system}.ojuny-patches-cli;
      ojuny-manual = inputs.ojuny-manual.packages.${system}.default;
    };
  };
}
