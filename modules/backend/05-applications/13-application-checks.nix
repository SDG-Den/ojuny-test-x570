{ ... }:
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
    in
    {
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
