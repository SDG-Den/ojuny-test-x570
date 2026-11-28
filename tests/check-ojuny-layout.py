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


SYSMON_METRICS = [
    ("cpu", ["usage", "temp", "clock"]),
    ("memory", ["used", "swap"]),
    ("disk:nvme0n1", ["space", "read", "write"]),
    ("net", ["down", "up"]),
    ("gpu:0000:01:00.0", ["usage", "temp", "vram", "power"]),
]


def check_sysmon(cards, errors):
    match = re.search(r"\n {6}sysmon = \{(?P<body>.*?)\n {6}\};", cards, re.S)
    if not match:
        errors.append("04-dashboard.nix: dashCards.sysmon is missing")
        return
    sysmon = match.group("body")
    config = re.search(r"\n {8}config = \{(?P<body>.*?)\n {8}\};", sysmon, re.S)
    if not config:
        errors.append("04-dashboard.nix: dashCards.sysmon.config is missing")
        return
    body = config.group("body")
    for needle in [
        'layout = "bars";',
        "showHeader = false;",
        'barOrientation = "horizontal";',
        "barNames = true;",
        'barStyle = "tiles";',
    ]:
        require(body, needle, "04-dashboard.nix sysmon.config", errors)

    metrics = re.search(r"metrics = \[(?P<body>.*?)\n {10}\];", body, re.S)
    if not metrics:
        errors.append("04-dashboard.nix: sysmon.config.metrics is missing")
        return
    metrics_body = metrics.group("body")
    if "@option" in metrics_body:
        errors.append("04-dashboard.nix: @option inside sysmon.config.metrics")
    found = re.findall(
        r'device = "([^"]+)";\s*graph = (?:true|false);\s*on = (?:true|false);\s*'
        r'vals = \[ ([^\]]*) \];',
        metrics_body,
    )
    expected = [(device, " ".join(f'"{value}"' for value in vals)) for device, vals in SYSMON_METRICS]
    if found != expected:
        errors.append(
            "04-dashboard.nix: sysmon.config.metrics is "
            f"{found}, expected {expected}"
        )
    for device, vals in found:
        kind = device.split(":", 1)[0]
        allowed = {
            "cpu": ["usage", "temp", "clock"],
            "memory": ["used", "swap"],
            "gpu": ["usage", "temp", "vram", "power"],
            "disk": ["space", "read", "write"],
            "net": ["down", "up"],
        }.get(kind, [])
        for value in re.findall(r'"([^"]+)"', vals):
            if value not in allowed:
                errors.append(
                    f"04-dashboard.nix: {device} has unsupported value {value}"
                )


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
    require(
        dashboard,
        "dashOptions.overview.panelRows = 7",
        "04-dashboard.nix",
        errors,
    )

    cards = re.search(r"dashCards = \{(?P<body>.*?)\n    \};", dashboard, re.S)
    if not cards:
        errors.append("04-dashboard.nix: dashCards is missing")
    else:
        if "network = {" in cards.group("body"):
            errors.append("04-dashboard.nix dashCards: the removed network card is still present")
        check_sysmon(cards.group("body"), errors)

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
