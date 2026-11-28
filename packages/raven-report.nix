{ pkgs }:
pkgs.writeShellApplication {
  name = "ojuny-raven-report";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.libnotify
    pkgs.wl-clipboard
    pkgs.yad
  ];
  text = builtins.readFile ../scripts/ojuny-raven-report.sh;
}
