{ pkgs }:
pkgs.writeShellApplication {
  name = "ojuny-clipboard-doctor";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.procps
    pkgs.wl-clipboard
    pkgs.xclip
  ];
  text = builtins.readFile ../scripts/ojuny-clipboard-doctor.sh;
}
