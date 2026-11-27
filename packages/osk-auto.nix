{ pkgs, default }:
let
  defaultValue = if default then "1" else "0";

  status = pkgs.writeShellApplication {
    name = "ojuny-osk-auto-status";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnused
    ];
    text = ''
      current="$(systemctl --user show-environment 2>/dev/null | sed -n 's/^OJUNY_OSK_AUTO=//p' | head -n 1 || true)"
      [ -n "$current" ] || current="${defaultValue}"
      [ "$current" = "1" ]
    '';
  };

  toggle = pkgs.writeShellApplication {
    name = "ojuny-osk-auto-toggle";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnused
    ];
    text = ''
      current="$(systemctl --user show-environment 2>/dev/null | sed -n 's/^OJUNY_OSK_AUTO=//p' | head -n 1 || true)"
      [ -n "$current" ] || current="${defaultValue}"
      if [ "$current" = "1" ]; then
        next=0
      else
        next=1
      fi
      systemctl --user set-environment "OJUNY_OSK_AUTO=$next"
      systemctl --user restart ojuny-osk.service 2>/dev/null || true
    '';
  };
in
{
  inherit status toggle;
}
