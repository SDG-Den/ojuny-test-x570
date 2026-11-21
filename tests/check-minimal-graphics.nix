{ pkgs, base }:
let
  lib = pkgs.lib;

  eval = extra: (plain.extendModules { modules = [ extra ]; }).config;

  plain = base.extendModules {
    modules = [ { stylix.enable = lib.mkForce false; } ];
  };

  none = plain.config;
  effects = eval {
    ojuny.disableVisualEffects = lib.mkForce true;
  };
  animations = eval {
    ojuny.disableAnimations = lib.mkForce true;
  };
  both = eval {
    ojuny.disableVisualEffects = lib.mkForce true;
    ojuny.disableAnimations = lib.mkForce true;
  };

  results = [
    {
      name = "defaults keep blur and animations on";
      ok =
        none.ojuny.mango.flag.blur
        && none.ojuny.mango.flag.animations
        && none.desktop.ojuny.dux.settings.animationDuration == 350;
    }
    {
      name = "visual effects toggle disables mango blur and shadows";
      ok =
        !effects.ojuny.mango.flag.blur
        && !effects.ojuny.mango.flag.shadows
        && effects.desktop.ojuny.mango.global.focused_opacity == 1.0;
    }
    {
      name = "visual effects toggle disables DMS blur, elevation and transparency";
      ok =
        !effects.desktop.ojuny.dux.settings.blurEnabled
        && !effects.desktop.ojuny.dux.settings.frameBlurEnabled
        && !effects.desktop.ojuny.dux.settings.m3ElevationEnabled
        && effects.desktop.ojuny.dux.settings.popupTransparency == 1.0
        && effects.ojuny.dux.customBar.transparency == 1;
    }
    {
      name = "visual effects toggle leaves animations alone";
      ok =
        effects.ojuny.mango.flag.animations && effects.desktop.ojuny.dux.settings.animationDuration == 350;
    }
    {
      name = "animations toggle disables mango animations";
      ok =
        !animations.ojuny.mango.flag.animations
        && !animations.ojuny.mango.flag.animation_fade_in
        && !animations.ojuny.mango.flag.animation_fade_out;
    }
    {
      name = "animations toggle disables DMS durations and enables reduced motion";
      ok =
        animations.desktop.ojuny.dux.settings.animationDuration == 0
        && animations.desktop.ojuny.dux.settings.modalAnimationDuration == 0
        && animations.desktop.ojuny.dux.settings.reduceMotion;
    }
    {
      name = "animations toggle leaves visual effects alone";
      ok = animations.ojuny.mango.flag.blur && animations.desktop.ojuny.dux.settings.frameBlurEnabled;
    }
    {
      name = "both toggles force both groups";
      ok =
        !both.ojuny.mango.flag.blur
        && !both.ojuny.mango.flag.animations
        && both.desktop.ojuny.dux.settings.animationDuration == 0;
    }
    {
      name = "border radius and gaps stay unchanged";
      ok =
        none.desktop.ojuny.mango.global.border_radius == 12
        && both.desktop.ojuny.mango.global.border_radius == 12
        && none.desktop.ojuny.mango.global.gap_inner_horizontal == 4
        && both.desktop.ojuny.mango.global.gap_inner_horizontal == 4;
    }
  ];

  failed = builtins.filter (result: !result.ok) results;
in
if failed == [ ] then
  pkgs.runCommand "check-minimal-graphics" { } "touch $out"
else
  throw (
    "check-minimal-graphics failed:\n"
    + lib.concatStringsSep "\n" (map (result: "  ${result.name}") failed)
  )
