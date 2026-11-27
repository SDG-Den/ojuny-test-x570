#!/usr/bin/env python3
"""Minimal StatusNotifierItem tray for the on-screen keyboard."""

import os
import shutil
import subprocess
import sys
import time

from gi.repository import GLib
from pydbus import SessionBus
from pydbus.generic import signal

ITEM_PATH = "/StatusNotifierItem"
WATCHER_NAME = "org.kde.StatusNotifierWatcher"
WATCHER_PATH = "/StatusNotifierWatcher"


class StatusNotifierItem:
    """
    <node>
      <interface name="org.kde.StatusNotifierItem">
        <property name="Category" type="s" access="read"/>
        <property name="Id" type="s" access="read"/>
        <property name="Title" type="s" access="read"/>
        <property name="Status" type="s" access="read"/>
        <property name="IconName" type="s" access="read"/>
        <property name="IconPixmap" type="a(iiay)" access="read"/>
        <property name="Menu" type="o" access="read"/>
        <property name="ItemIsMenu" type="b" access="read"/>
        <property name="ToolTip" type="(sa(iiay)ss)" access="read"/>
        <method name="Activate">
          <arg name="x" type="i" direction="in"/>
          <arg name="y" type="i" direction="in"/>
        </method>
        <method name="SecondaryActivate">
          <arg name="x" type="i" direction="in"/>
          <arg name="y" type="i" direction="in"/>
        </method>
        <method name="ContextMenu">
          <arg name="x" type="i" direction="in"/>
          <arg name="y" type="i" direction="in"/>
        </method>
        <method name="Scroll">
          <arg name="delta" type="i" direction="in"/>
          <arg name="orientation" type="s" direction="in"/>
        </method>
        <signal name="NewIcon"/>
        <signal name="NewStatus">
          <arg name="status" type="s"/>
        </signal>
        <signal name="NewToolTip"/>
      </interface>
    </node>
    """

    Category = "ApplicationStatus"
    Id = "ojuny-osk"
    Title = "On-screen keyboard"
    Status = "Active"
    IconName = "input-keyboard-symbolic"
    IconPixmap = []
    Menu = "/NO_DBUSMENU"
    ItemIsMenu = False
    ToolTip = (
        "input-keyboard-symbolic",
        [],
        "On-screen keyboard",
        "Toggle keyboard",
    )

    NewIcon = signal()
    NewStatus = signal()
    NewToolTip = signal()

    def __init__(self, toggle):
        self.toggle = toggle

    def Activate(self, x, y):
        if shutil.which(self.toggle) is None:
            print(f"ojuny-osk-tray: toggle not found: {self.toggle}", file=sys.stderr)
            return
        subprocess.Popen(
            [self.toggle],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    def SecondaryActivate(self, x, y):
        self.Activate(x, y)

    def ContextMenu(self, x, y):
        self.Activate(x, y)

    def Scroll(self, delta, orientation):
        pass


def register(bus, name):
    for _ in range(30):
        try:
            watcher = bus.get(WATCHER_NAME, WATCHER_PATH)
            watcher.RegisterStatusNotifierItem(name)
            return
        except Exception:
            time.sleep(1)
    raise RuntimeError("StatusNotifierWatcher is not available")


def main():
    toggle = os.environ.get("OJUNY_OSK_TOGGLE", "ojuny-osk-toggle")
    bus = SessionBus()
    name = f"org.kde.StatusNotifierItem-{os.getpid()}-1"
    bus.publish(name, (ITEM_PATH, StatusNotifierItem(toggle)))
    register(bus, name)
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
