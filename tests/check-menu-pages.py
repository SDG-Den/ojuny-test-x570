#!/usr/bin/env python3
"""Fail when a settings page is not named in the page spec.

docs/02-settings-menu.md is the authoritative page list, and a file with an
@menu header is a settings page. Naming the file there keeps the spec and the
menus from drifting apart. Patch pages are installed from the registry and are
described as a group instead of one file at a time.
"""

import argparse
import pathlib
import re
import sys

MENU_RE = re.compile(r"@menu\b")
EXCLUDED_DIRS = {"patches"}


def pages(root):
    modules = root / "modules"
    for path in sorted(modules.rglob("*.nix")):
        if EXCLUDED_DIRS & set(path.relative_to(modules).parts):
            continue
        if MENU_RE.search(path.read_text(encoding="utf-8")):
            yield path


def check(root):
    root = pathlib.Path(root)
    spec = (root / "docs" / "02-settings-menu.md").read_text(encoding="utf-8")
    errors = []
    for path in pages(root):
        if path.name not in spec:
            errors.append(
                "{}: settings page is not named in docs/02-settings-menu.md".format(
                    path.relative_to(root)
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
    print("menu-page gate: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
