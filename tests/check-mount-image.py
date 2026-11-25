#!/usr/bin/env python3
"""Check the mount-image script contract and the image fixtures it must handle."""

import pathlib
import re
import subprocess
import sys
import tempfile

REQUIRED = [
    "udevadm settle",
    "lsblk -ln -o FSTYPE",
    "--options ro",
    "trap cleanup EXIT",
    "udisksctl loop-delete",
    "gnome-disk-image-mounter --read-only",
]


def run(command, **kwargs):
    subprocess.run(command, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, **kwargs)


def main():
    root = pathlib.Path(sys.argv[1])
    script = (root / "scripts" / "ojuny-mount-image.sh").read_text()

    missing = [item for item in REQUIRED if item not in script]
    if missing:
        sys.exit("ojuny-mount-image.sh is missing: " + ", ".join(missing))

    with tempfile.TemporaryDirectory() as directory:
        work = pathlib.Path(directory)
        content = work / "content"
        content.mkdir()
        (content / "hello.txt").write_text("hello\n")

        plain = work / "plain.iso"
        run(["xorriso", "-as", "mkisofs", "-o", str(plain), str(content)])
        if plain.stat().st_size == 0:
            sys.exit("the plain ISO fixture is empty")

        hybrid = work / "hybrid.img"
        with hybrid.open("wb") as handle:
            handle.truncate(16 * 1024 * 1024)
        run(
            ["sfdisk", str(hybrid)],
            input="label: dos\n2048,8192,83,*\n",
            text=True,
        )
        run(["mke2fs", "-q", "-F", "-b", "1024", "-E", "offset=1048576", str(hybrid), "4096"])

        table = subprocess.run(
            ["sfdisk", "-d", str(hybrid)],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
        if not re.search(r"start=\s*2048\b", table):
            sys.exit("the partition fixture has no partition at sector 2048")

        kind = subprocess.run(
            ["file", "-b", str(plain)],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
        if "ISO 9660" not in kind:
            sys.exit("the plain fixture is not an ISO 9660 image")

    print("mount-image: contract and plain/hybrid fixtures verified")


if __name__ == "__main__":
    main()
