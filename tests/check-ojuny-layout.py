#!/usr/bin/env python3
"""Check the Ojuny-owned desktop layout configuration.

The control center layout is authored for eight columns. The generated Dux
settings must keep that width, the dashboard must enable a tab that hosts the
cards, and the island must leave enough time to click before hover opens it.
"""

import argparse
import pathlib
import re
import sys


def require(text, needle, path, errors):
    if needle not in text:
        errors.append(f"{path}: missing {needle}")


def check(root):
    root = pathlib.Path(root)
    errors = []
    control = (root / "modules/04-gui/05-controlcenter.nix").read_text()
    bar = (root / "modules/04-gui/01-bar.nix").read_text()
    dashboard = (root / "modules/04-gui/04-dashboard.nix").read_text()

    require(control, "gridColumns = 8", "05-controlcenter.nix", errors)
    require(control, "controlCenterColumns = 8", "05-controlcenter.nix", errors)
    require(bar, "islandHoverOpenDelay = 500", "01-bar.nix", errors)
    require(bar, "islandHoverCloseDelay = 300", "01-bar.nix", errors)
    require(dashboard, "dashTabs.overview.enabled = true", "04-dashboard.nix", errors)
    require(dashboard, 'network = {', "04-dashboard.nix", errors)

    for match in re.finditer(r"col = (\d+);\s*row = \d+;\s*w = (\d+);", control):
        col, width = (int(group) for group in match.groups())
        if col + width > 8:
            errors.append(
                "05-controlcenter.nix: widget at col {col} width {width} exceeds eight columns"
            )
    return errors


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    args = parser.parse_args()
    errors = check(args.root)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
