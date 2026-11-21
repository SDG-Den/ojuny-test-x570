#!/usr/bin/env python3
import argparse
import pathlib
import sys

DEFAULT_ROOT = pathlib.Path(__file__).resolve().parents[1]

VISUAL_OPTIONS = [
    "ojuny.mango.flag.blur",
    "ojuny.mango.flag.blur_layer",
    "ojuny.mango.flag.blur_optimized",
    "ojuny.mango.flag.shadows",
    "ojuny.mango.flag.layer_shadows",
    "desktop.ojuny.mango.global.focused_opacity",
    "desktop.ojuny.mango.global.unfocused_opacity",
    "desktop.ojuny.dux.settings.blurEnabled",
    "desktop.ojuny.dux.settings.blurBorderEnabled",
    "desktop.ojuny.dux.settings.frameBlurEnabled",
    "desktop.ojuny.dux.settings.barElevationEnabled",
    "desktop.ojuny.dux.settings.m3ElevationEnabled",
    "desktop.ojuny.dux.settings.modalElevationEnabled",
    "desktop.ojuny.dux.settings.popoutElevationEnabled",
    "desktop.ojuny.dux.settings.notificationPopupShadowEnabled",
    "desktop.ojuny.dux.settings.floatingWindowTransparency",
    "desktop.ojuny.dux.settings.floatingWindowForegroundTransparency",
    "desktop.ojuny.dux.settings.foregroundLayerTransparency",
    "desktop.ojuny.dux.settings.popupTransparency",
    "ojuny.dux.customBar.transparency",
    "ojuny.dux.customBar.shadowIntensity",
    "desktop.ojuny.dux.dockConfigs.dock.transparency",
]

ANIMATION_OPTIONS = [
    "ojuny.mango.flag.animations",
    "ojuny.mango.flag.layer_animations",
    "ojuny.mango.flag.animation_fade_in",
    "ojuny.mango.flag.animation_fade_out",
    "desktop.ojuny.dux.settings.animationDuration",
    "desktop.ojuny.dux.settings.modalAnimationDuration",
    "desktop.ojuny.dux.settings.popoutAnimationDuration",
    "desktop.ojuny.dux.settings.notificationAnimationDuration",
    "desktop.ojuny.dux.settings.reduceMotion",
]

FORBIDDEN_IN_BOTH = ["border_radius", "gap_inner_horizontal", "gap_inner_vertical"]


def brace_block(text, marker):
    start = text.index(marker)
    brace = text.index("{", start)
    depth = 0
    for index in range(brace, len(text)):
        if text[index] == "{":
            depth += 1
        elif text[index] == "}":
            depth -= 1
            if depth == 0:
                return text[brace : index + 1]
    raise ValueError("unclosed block for %s" % marker)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=str(DEFAULT_ROOT))
    args = parser.parse_args()
    root = pathlib.Path(args.root).resolve()

    module_path = root / "modules/backend/02-core/05-compositor-backend.nix"
    page_path = root / "modules/07-system/04-graphics.nix"
    module = module_path.read_text()
    page = page_path.read_text()

    errors = []

    def check(condition, message):
        if not condition:
            errors.append(message)

    visual = brace_block(module, "lib.mkIf config.ojuny.disableVisualEffects")
    animations = brace_block(module, "lib.mkIf config.ojuny.disableAnimations")

    for name in VISUAL_OPTIONS:
        check(name in visual, "visual effects block is missing %s" % name)
    for name in ANIMATION_OPTIONS:
        check(name in animations, "animations block is missing %s" % name)

    check("blurEnabled" not in animations, "animations block must not touch blur")
    check(
        "animationDuration" not in visual,
        "visual effects block must not touch animation durations",
    )

    for name in FORBIDDEN_IN_BOTH:
        check(name not in visual, "visual effects block must not force %s" % name)
        check(name not in animations, "animations block must not force %s" % name)

    check(
        'label = "Disable Visual Effects"' in page,
        "graphics page is missing the Disable Visual Effects switch",
    )
    check(
        'label = "Disable Animations"' in page,
        "graphics page is missing the Disable Animations switch",
    )
    check(
        "ojuny-display-tweaks effects %%val%%" in page,
        "Disable Visual Effects is not wired to the live helper",
    )
    check(
        "ojuny-display-tweaks animations %%val%%" in page,
        "Disable Animations is not wired to the live helper",
    )

    if errors:
        for error in errors:
            print("check-minimal-graphics: %s" % error, file=sys.stderr)
        return 1

    print(
        "check-minimal-graphics: ok (%d visual, %d animation)"
        % (len(VISUAL_OPTIONS), len(ANIMATION_OPTIONS))
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
