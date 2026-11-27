{ pkgs, oskToggle }:
let
  python = pkgs.python3.withPackages (packages: [ packages.pydbus ]);
in
pkgs.writeShellApplication {
  name = "ojuny-osk-tray";
  runtimeInputs = [ python ];
  text = ''
    export OJUNY_OSK_TOGGLE="${oskToggle}/bin/ojuny-osk-toggle"
    exec python3 ${../scripts/ojuny-osk-tray.py}
  '';
}
