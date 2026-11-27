{ pkgs }:
pkgs.writeShellApplication {
  name = "ojuny-auto-rotate";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.iio-sensor-proxy
    pkgs.wlr-randr
  ];
  text = builtins.readFile ../scripts/ojuny-auto-rotate.sh;
}
