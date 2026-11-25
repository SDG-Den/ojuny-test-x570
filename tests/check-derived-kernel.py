#!/usr/bin/env python3
"""Check the Derived Minimal kernel configuration.

The generated .config must keep every core symbol, every symbol of an active
component, and a kernel symbol for every module that NixOS puts in the initrd
or loads in stage 2. A module mapped to null is out-of-tree and is skipped.
"""

import argparse
import json
import pathlib
import re
import sys


def read_config(path):
    config = {}
    for raw in pathlib.Path(path).read_text().splitlines():
        line = raw.strip()
        if line.startswith("CONFIG_") and "=" in line:
            name, value = line[len("CONFIG_") :].split("=", 1)
            config[name] = value
        elif line.startswith("# CONFIG_") and line.endswith(" is not set"):
            name = line[len("# CONFIG_") : -len(" is not set")]
            config[name] = "n"
    return config


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    parser.add_argument("--base-config", required=True)
    parser.add_argument("--payload", required=True)
    args = parser.parse_args()

    config = read_config(args.config)
    base = read_config(args.base_config)
    payload = json.loads(pathlib.Path(args.payload).read_text())

    errors = []

    for symbol in payload["coreSymbols"]:
        if symbol not in base:
            continue
        if config.get(symbol) not in ("y", "m"):
            errors.append(
                "core symbol {} is {}".format(symbol, config.get(symbol, "absent"))
            )

    for symbol in payload["activeSymbols"]:
        if symbol not in base:
            continue
        if config.get(symbol) not in ("y", "m"):
            errors.append(
                "active symbol {} is {}".format(symbol, config.get(symbol, "absent"))
            )

    active_components = set(payload.get("activeComponents", []))
    module_components = payload.get("moduleComponents", {})
    class_components = payload.get("classComponents", {})

    for driver in payload.get("reportDrivers", []):
        key = driver.replace("-", "_")
        for component in module_components.get(key, []) + module_components.get(driver, []):
            if component not in active_components:
                errors.append(
                    "report driver {} needs active component {}".format(driver, component)
                )

    for hardware_class in payload.get("reportClasses", []):
        for component in class_components.get(hardware_class, []):
            if component not in active_components:
                errors.append(
                    "report class {} needs active component {}".format(
                        hardware_class, component
                    )
                )

    mapping = payload["moduleSymbols"]
    modules = sorted(set(payload["initrdModules"]) | set(payload["kernelModules"]))
    for module in modules:
        if module in mapping and mapping[module] is None:
            continue
        symbol = mapping.get(module)
        if symbol is None:
            symbol = re.sub(r"[^A-Za-z0-9_]", "_", module).upper()
        if symbol not in base:
            continue
        if config.get(symbol) not in ("y", "m"):
            errors.append(
                "module {} needs {}, which is {}".format(
                    module, symbol, config.get(symbol, "absent")
                )
            )

    if errors:
        print(
            "active components: {}".format(", ".join(sorted(active_components))),
            file=sys.stderr,
        )
        for prefix in (
            "SERIO",
            "USB_OHCI",
            "VIRTIO",
            "NET_9P",
            "9P_",
            "VIRTUALIZATION",
            "KVM",
            "WLAN",
            "CFG80211",
            "MAC80211",
        ):
            matches = sorted(
                (name, value) for name, value in config.items() if name.startswith(prefix)
            )
            print("{}: {}".format(prefix, matches), file=sys.stderr)
        print("\n".join(errors), file=sys.stderr)
        return 1

    print(
        "derived kernel config ok: {} core symbols, {} active symbols, {} modules".format(
            len(payload["coreSymbols"]), len(payload["activeSymbols"]), len(modules)
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
