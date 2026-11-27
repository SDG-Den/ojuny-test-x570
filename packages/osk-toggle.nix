{ pkgs }:
pkgs.writeShellApplication {
  name = "ojuny-osk-toggle";
  runtimeInputs = [
    pkgs.libnotify
    pkgs.systemd
  ];
  text = builtins.readFile ../scripts/ojuny-osk-toggle.sh;
}
