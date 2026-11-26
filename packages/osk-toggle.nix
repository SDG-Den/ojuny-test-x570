{ pkgs }:
pkgs.writeShellApplication {
  name = "ojuny-osk-toggle";
  runtimeInputs = [ pkgs.systemd ];
  text = builtins.readFile ../scripts/ojuny-osk-toggle.sh;
}
