#!/usr/bin/env bash
set -euo pipefail

tray="$1"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cat >"$work/toggle" <<'SH'
#!/usr/bin/env bash
: >"$OJUNY_OSK_MARKER"
SH
chmod +x "$work/toggle"
export OJUNY_OSK_MARKER="$work/activated"
export OJUNY_OSK_TOGGLE="$work/toggle"

cat >"$work/watcher.py" <<'PY'
import sys

from gi.repository import GLib
from pydbus import SessionBus


class Watcher:
    """
    <node>
      <interface name="org.kde.StatusNotifierWatcher">
        <method name="RegisterStatusNotifierItem">
          <arg name="service" type="s" direction="in"/>
        </method>
        <property name="RegisteredStatusNotifierItems" type="as" access="read"/>
      </interface>
    </node>
    """

    def __init__(self, log):
        self.log = log
        self.items = []

    def RegisterStatusNotifierItem(self, service):
        self.items.append(service)
        with open(self.log, "a", encoding="utf-8") as handle:
            handle.write(service + "\n")

    @property
    def RegisteredStatusNotifierItems(self):
        return self.items


bus = SessionBus()
bus.publish(
    "org.kde.StatusNotifierWatcher",
    ("/StatusNotifierWatcher", Watcher(sys.argv[1])),
)
GLib.MainLoop().run()
PY

python3 "$work/watcher.py" "$work/registered" &
watcher=$!
sleep 0.5

timeout 5 python3 "$tray" &
tray_pid=$!
for _ in $(seq 1 40); do
  [ -s "$work/registered" ] && break
  sleep 0.1
done

service="$(head -n 1 "$work/registered")"
python3 - "$service" <<'PY'
import sys

from pydbus import SessionBus

bus = SessionBus()
item = bus.get(sys.argv[1], "/StatusNotifierItem")
item.Activate(0, 0)
PY
for _ in $(seq 1 20); do
  [ -f "$OJUNY_OSK_MARKER" ] && break
  sleep 0.1
done
[ -f "$OJUNY_OSK_MARKER" ] || fail "the tray Activate did not run the toggle"

kill "$tray_pid" 2>/dev/null || true
kill "$watcher" 2>/dev/null || true
wait "$tray_pid" 2>/dev/null || true
wait "$watcher" 2>/dev/null || true

[ -s "$work/registered" ] || fail "the tray did not register with the watcher"
grep -q "org.kde.StatusNotifierItem" "$work/registered" ||
  fail "the tray registered the wrong service name"

printf 'ok: the OSK tray registers a StatusNotifierItem and activates the toggle\n'
