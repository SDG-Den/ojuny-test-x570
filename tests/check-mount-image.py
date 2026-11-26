#!/usr/bin/env python3
"""Check the mount-image script contract and the image fixtures it must handle."""

import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

REQUIRED = [
    "udevadm settle",
    "lsblk -ln -o FSTYPE",
    "loop-setup --read-only",
    "--options ro",
    "trap cleanup EXIT",
    "udisksctl loop-delete",
    "gnome-disk-image-mounter --read-only",
    "iso9660",
    "udf",
]


def run(command, **kwargs):
    subprocess.run(command, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, **kwargs)


def stub(path, body, bash):
    path.write_text(f"#!{bash}\n{body}\n")
    path.chmod(0o755)


def check_candidate_selection(work, script):
    text = script.read_text()
    start = text.index("fstype_of() {")
    end = text.index("candidates=()", start)
    bindir = work / "bin"
    bindir.mkdir()
    bash = shutil.which("bash")

    stub(
        bindir / "lsblk",
        """case "$*" in
*"-o FSTYPE /tmp/loop0") ;;
*"-o FSTYPE /tmp/loop0p1") printf 'iso9660\\n' ;;
*"-o FSTYPE /tmp/loop0p2") printf 'vfat\\n' ;;
*"-o NAME,FSTYPE /tmp/loop0") printf 'loop0\\nloop0p1 iso9660\\nloop0p2 vfat\\n' ;;
esac""",
        bash,
    )
    probe = work / "probe.sh"
    probe.write_text(
        "set -euo pipefail\n"
        "loop_device=/tmp/loop0\n"
        + text[start:end]
        + "\nread_candidates\n"
        + "printf 'P:%s\\n' \"${preferred[@]}\"\n"
        + "printf 'O:%s\\n' \"${others[@]}\"\n"
    )
    env = os.environ.copy()
    env["PATH"] = f"{bindir}:{env['PATH']}"
    result = subprocess.run(["bash", str(probe)], capture_output=True, text=True, env=env)
    if result.returncode != 0:
        sys.exit(f"candidate selection failed: {result.stdout}\n{result.stderr}")
    if "P:/dev/loop0p1" not in result.stdout:
        sys.exit(f"the ISO partition was not preferred: {result.stdout!r} {result.stderr!r}")
    if "O:/dev/loop0p2" not in result.stdout:
        sys.exit(f"the EFI partition was not kept as a fallback: {result.stdout!r}")


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

        check_candidate_selection(work, root / "scripts" / "ojuny-mount-image.sh")

    print("mount-image: contract, plain/hybrid fixtures and ISO partition selection verified")


if __name__ == "__main__":
    main()
