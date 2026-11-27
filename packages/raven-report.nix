{ pkgs }:
pkgs.writeShellApplication {
  name = "ojuny-raven-report";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.wl-clipboard
    pkgs.yad
  ];
  text = builtins.readFile ../scripts/ojuny-raven-report.sh;
}
