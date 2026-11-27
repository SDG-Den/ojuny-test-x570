{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      source = pkgs.lib.cleanSource ../../..;

      oskAuto = import ../../../packages/osk-auto.nix {
        inherit pkgs;
        default = true;
      };

      ravenReportTest = pkgs.writeShellApplication {
        name = "test-ojuny-raven-report";
        runtimeInputs = [ pkgs.coreutils ];
        text = builtins.readFile ../../../scripts/ojuny-raven-report.sh;
      };

      withKeyboard = self.nixosConfigurations.fixture.extendModules {
        modules = [ { ojuny.accessibility.onScreenKeyboard.enable = pkgs.lib.mkForce true; } ];
      };

      withoutKeyboard = self.nixosConfigurations.fixture.extendModules {
        modules = [ { ojuny.accessibility.onScreenKeyboard.enable = pkgs.lib.mkForce false; } ];
      };

      oskServices = pkgs.writeText "osk-services.json" (
        builtins.toJSON {
          keyboard = withKeyboard.config.systemd.user.services ? ojuny-osk;
          tray = withKeyboard.config.systemd.user.services ? ojuny-osk-tray;
          wantedBy = withKeyboard.config.systemd.user.services.ojuny-osk.wantedBy;
          partOf = withKeyboard.config.systemd.user.services.ojuny-osk.partOf;
          keyboardArgs =
            withKeyboard.config.desktop.ojuny.mango.binds.common.accessibilityKeyboard.args;
          runnerExecStart =
            withKeyboard.config.systemd.user.services.ojuny-osk.serviceConfig.ExecStart;
          trayExecStart =
            withKeyboard.config.systemd.user.services.ojuny-osk-tray.serviceConfig.ExecStart;
          traySource = builtins.readFile ../../../scripts/ojuny-osk-tray.py;
          menuAuto = withKeyboard.config.desktop.ojuny.dankMenu.menu ? "setup.accessibility.auto-popup";
          menuAutoChecked =
            withKeyboard.config.desktop.ojuny.dankMenu.menu."setup.accessibility.auto-popup".checked;
          menuAutoAction =
            withKeyboard.config.desktop.ojuny.dankMenu.menu."setup.accessibility.auto-popup".action;
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
              (.keyboardArgs | endswith("/bin/ojuny-osk-toggle")) and
              (.runnerExecStart | endswith("/bin/ojuny-osk-run")) and
              (.trayExecStart | endswith("/bin/ojuny-osk-tray")) and
              (.traySource | contains("org.kde.StatusNotifierItem")) and
              (.traySource | contains("RegisterStatusNotifierItem")) and
              .menuAuto == true and
              (.menuAutoChecked | endswith("/bin/ojuny-osk-auto-status")) and
              (.menuAutoAction | endswith("/bin/ojuny-osk-auto-toggle")) and
              .disabledKeyboard == false and
              .disabledTray == false
            ' ${oskServices} >/dev/null
            touch $out
          '';

      checks.osk-tray =
        pkgs.runCommand "check-osk-tray"
          {
            nativeBuildInputs = [
              pkgs.bash
              pkgs.coreutils
              pkgs.dbus
              pkgs.gnugrep
              (pkgs.python3.withPackages (packages: [ packages.pydbus ]))
            ];
          }
          ''
            dbus-run-session --config-file=${pkgs.dbus}/share/dbus-1/session.conf -- bash ${source}/tests/check-osk-tray.sh ${source}/scripts/ojuny-osk-tray.py
            touch $out
          '';

      checks.osk-auto =
        pkgs.runCommand "check-osk-auto"
          {
            nativeBuildInputs = [
              pkgs.bash
              pkgs.coreutils
              pkgs.gnugrep
            ];
          }
          ''
            bash ${source}/tests/check-osk-auto.sh ${oskAuto.status}/bin/ojuny-osk-auto-status ${oskAuto.toggle}/bin/ojuny-osk-auto-toggle
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
