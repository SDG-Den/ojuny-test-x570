#!/usr/bin/env python3
"""Compare pre-included patch modules with the registry on shape only.

Option values and descriptions are deliberately ignored. Only module keys,
menu headers and assigned option paths are compared.
"""

import argparse
import pathlib
import re
import sys

MODULE_RE = re.compile(r"flake\.modules\.([A-Za-z]+)\.([A-Za-z0-9_-]+)\s*=")
ASSIGN_RE = re.compile(r"^\s*([A-Za-z0-9_.-]+)\s*=")
MENU_RE = re.compile(r"@menu\b")


def shape(text):
    modules = {(kind, name) for kind, name in MODULE_RE.findall(text)}
    menus = set()
    options = set()
    lines = text.splitlines()
    for index, line in enumerate(lines):
        if MENU_RE.search(line):
            for follow in lines[index + 1 : index + 12]:
                if "displayname" in follow:
                    value = follow.split("displayname", 1)[1]
                    value = value.split("=", 1)[-1].strip().strip('"; ')
                    if value:
                        menus.add(value)
                    break
                if "*/" in follow:
                    break
        if "@option" in line:
            for follow in lines[index + 1 : index + 8]:
                stripped = follow.strip()
                if not stripped or stripped.startswith("#") or stripped.startswith("/*"):
                    continue
                match = ASSIGN_RE.match(follow)
                if match:
                    options.add(match.group(1))
                break
    return modules, menus, options


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--registry", required=True)
    args = parser.parse_args()

    root = pathlib.Path(args.root) / "modules/patches"
    registry = pathlib.Path(args.registry) / "modules/patches"
    errors = []
    for local in sorted(root.glob("patch-*.nix")):
        remote = registry / local.name
        if not remote.is_file():
            errors.append(f"{local.name}: missing from the registry")
            continue
        local_shape = shape(local.read_text())
        remote_shape = shape(remote.read_text())
        labels = ("module keys", "menu headers", "option paths")
        for label, local_set, remote_set in zip(labels, local_shape, remote_shape):
            if local_set != remote_set:
                missing = sorted(remote_set - local_set)
                extra = sorted(local_set - remote_set)
                errors.append(
                    f"{local.name}: {label} differ; missing {missing}, extra {extra}"
                )
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
