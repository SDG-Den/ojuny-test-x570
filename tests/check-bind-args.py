#!/usr/bin/env python3
"""Reject bind args that were rewritten as quoted lists or expressions.

A keybind args field is either a plain string or a Nix list. Encoding a list
or an expression as a quoted string still parses, but the generated mango
config then runs the literal text instead of the command.
"""

import argparse
import pathlib
import re
import sys

EXPRESSION_PREFIXES = ("config.", "desktop.", "ojuny.", "inputs.", "lib.")
ARGS_PATTERN = re.compile(r'\bargs\s*=\s*"((?:[^"\\]|\\.)*)"\s*;')
CLICK_PATTERN = re.compile(r"\bydotool\s+click\s+(0x[0-9A-Fa-f]+)")


def check(root):
    errors = []
    for path in sorted((pathlib.Path(root) / "modules").rglob("*.nix")):
        for number, line in enumerate(path.read_text().splitlines(), 1):
            match = ARGS_PATTERN.search(line)
            if match is not None:
                value = match.group(1).strip()
                if value.startswith("["):
                    errors.append(
                        "{}:{}: args is a quoted list: {}".format(path, number, value)
                    )
                elif value.startswith(EXPRESSION_PREFIXES):
                    errors.append(
                        "{}:{}: args is a quoted expression: {}".format(path, number, value)
                    )
            click = CLICK_PATTERN.search(line)
            if click is not None:
                button = int(click.group(1), 16)
                if button & 0xC0 not in (0x40, 0x80, 0xC0):
                    errors.append(
                        "{}:{}: ydotool click {} has no press/release mask; use 0xC0, 0xC1 or 0xC2".format(
                            path, number, click.group(1)
                        )
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
