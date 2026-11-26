{ inputs, ... }:
{
  perSystem = { config, pkgs, ... }: {
    checks.flake-simple =
      pkgs.runCommand "check-flake-simple"
        {
          nativeBuildInputs = [
            pkgs.bash
            pkgs.gnugrep
          ];
        }
        ''
          bash ${../../tests/check-flake-simple.sh} ${../../flake.nix}
          touch $out
        '';

    checks.flake-structure =
      let
        source = pkgs.lib.cleanSource ../..;
      in
      pkgs.runCommand "check-flake-structure"
        {
          nativeBuildInputs = [ pkgs.python3 ];
        }
        ''
          python3 ${source}/tests/check-flake-structure.py
          touch $out
        '';

    checks.fixed-paths =
      let
        source = pkgs.lib.cleanSource ../..;
      in
      pkgs.runCommand "check-fixed-paths"
        {
          nativeBuildInputs = [ pkgs.python3 ];
        }
        ''
          python3 ${source}/tests/check-fixed-paths.py
          touch $out
        '';

    checks.runtime-deps =
      let
        source = pkgs.lib.cleanSource ../..;
      in
      pkgs.runCommand "check-runtime-deps"
        {
          nativeBuildInputs = [ pkgs.python3 ];
        }
        ''
          python3 ${source}/tests/check-runtime-deps.py
          touch $out
        '';

    checks.bind-args =
      let
        source = pkgs.lib.cleanSource ../..;
      in
      pkgs.runCommand "check-bind-args"
        {
          nativeBuildInputs = [ pkgs.python3 ];
        }
        ''
          python3 ${source}/tests/check-bind-args.py --root ${source}
          touch $out
        '';

    checks.settings-options =
      let
        source = pkgs.lib.cleanSource ../..;
      in
      pkgs.runCommand "check-settings-options"
        {
          nativeBuildInputs = [ pkgs.python3 ];
        }
        ''
          python3 ${source}/tests/check-settings-options.py --root ${source}
          touch $out
        '';

    checks.ojuny-layout =
      let
        source = pkgs.lib.cleanSource ../..;
      in
      pkgs.runCommand "check-ojuny-layout"
        {
          nativeBuildInputs = [ pkgs.python3 ];
        }
        ''
          python3 ${
            builtins.path {
              path = ../../tests/check-ojuny-layout.py;
              name = "check-ojuny-layout.py";
            }
          } --root ${source}
          touch $out
        '';

    checks.ojuny-apps =
      let
        source = pkgs.lib.cleanSource ../..;
      in
      pkgs.runCommand "check-ojuny-apps"
        {
          nativeBuildInputs = [ pkgs.python3 ];
        }
        ''
          python3 ${
            builtins.path {
              path = ../../tests/check-ojuny-apps.py;
              name = "check-ojuny-apps.py";
            }
          } --root ${source}
          touch $out
        '';

    checks.patch-shape =
      let
        source = pkgs.lib.cleanSource ../..;
      in
      pkgs.runCommand "check-patch-shape"
        {
          nativeBuildInputs = [ pkgs.python3 ];
        }
        ''
          python3 ${
            builtins.path {
              path = ../../tests/check-patch-shape.py;
              name = "check-patch-shape.py";
            }
          } --root ${source} --registry ${inputs.ojuny-patches}
          touch $out
        '';

    checks.module-tree-current =
      let
        source = pkgs.lib.cleanSource ../..;
      in
      pkgs.runCommand "check-module-tree"
        {
          nativeBuildInputs = [ pkgs.diffutils ];
        }
        ''
          cp -r ${source} work
          chmod -R u+w work
          cd work
          sh scripts/gen-module-tree.sh
          diff -u ${source}/docs/module-tree.md docs/module-tree.md
          touch $out
        '';

    checks.default = pkgs.runCommand "check-default" { } ''
      ${pkgs.lib.concatMapStringsSep "\n" (name: "echo ${config.checks.${name}} >/dev/null") (
        builtins.attrNames (builtins.removeAttrs config.checks [ "default" ])
      )}
      touch $out
    '';
  };
}
