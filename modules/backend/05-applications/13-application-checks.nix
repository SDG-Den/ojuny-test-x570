{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      source = pkgs.lib.cleanSource ../../..;

      ravenReportTest = pkgs.writeShellApplication {
        name = "test-ojuny-raven-report";
        runtimeInputs = [ pkgs.coreutils ];
        text = builtins.readFile ../../../scripts/ojuny-raven-report.sh;
      };

      withKeyboard = self.nixosConfigurations.fixture.extendModules {
        modules = [ { ojuny.accessibility.onScreenKeyboard.enable = true; } ];
      };

      withoutKeyboard = self.nixosConfigurations.fixture.extendModules {
        modules = [ { ojuny.accessibility.onScreenKeyboard.enable = false; } ];
      };

      oskServices = pkgs.writeText "osk-services.json" (
        builtins.toJSON {
          keyboard = withKeyboard.config.systemd.user.services ? ojuny-osk;
          tray = withKeyboard.config.systemd.user.services ? ojuny-osk-tray;
          wantedBy = withKeyboard.config.systemd.user.services.ojuny-osk.wantedBy;
          partOf = withKeyboard.config.systemd.user.services.ojuny-osk.partOf;
          disabledKeyboard = withoutKeyboard.config.systemd.user.services ? ojuny-osk;
          disabledTray = withoutKeyboard.config.systemd.user.services ? ojuny-osk-tray;
        }
      );
    in
    {
      checks.osk-service =
        pkgs.runCommand "check-osk-service"
          {
            nativeBuildInputs = [ pkgs.jq ];
          }
          ''
            jq -e '
              .keyboard == true and
              .tray == true and
              .wantedBy == [ "mango-session.target" ] and
              .partOf == [ "mango-session.target" ] and
              .disabledKeyboard == false and
              .disabledTray == false
            ' ${oskServices} >/dev/null
            touch $out
          '';

      checks.qr-capture =
        pkgs.runCommand "check-qr-capture"
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
                path = ../../../tests/check-qr.sh;
                name = "check-qr.sh";
              }
            } ${source}
            touch $out
          '';

      checks.raven-report =
        pkgs.runCommand "check-raven-report"
          {
            nativeBuildInputs = [
              pkgs.bash
              pkgs.coreutils
              pkgs.diffutils
              pkgs.gnugrep
            ];
          }
          ''
            bash ${
              builtins.path {
                path = ../../../tests/check-raven-report.sh;
                name = "check-raven-report.sh";
              }
            } ${ravenReportTest}/bin/test-ojuny-raven-report ${source}/scripts/ojuny-raven-report.sh
            touch $out
          '';

      checks.mount-image =
        pkgs.runCommand "check-mount-image"
          {
            nativeBuildInputs = [
              pkgs.e2fsprogs
              pkgs.file
              pkgs.python3
              pkgs.util-linux
              pkgs.xorriso
            ];
          }
          ''
            python3 ${
              builtins.path {
                path = ../../../tests/check-mount-image.py;
                name = "check-mount-image.py";
              }
            } ${source}
            touch $out
          '';
    };
}
