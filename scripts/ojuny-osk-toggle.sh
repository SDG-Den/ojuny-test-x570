#!/usr/bin/env bash
set -euo pipefail

pid="$(systemctl --user show -p MainPID --value ojuny-osk.service 2>/dev/null || true)"
case "$pid" in
"" | 0) exec systemctl --user start ojuny-osk.service ;;
*) exec kill -s RTMIN "$pid" ;;
esac
