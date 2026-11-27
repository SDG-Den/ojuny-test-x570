#!/usr/bin/env bash
set -euo pipefail

theme_source="${1:?theme source path is required}"
theme_name="${2:?theme name is required}"
home="${HOME:?HOME is required}"

steam_root="${home}/.steam/steam"
theme_dir="${steam_root}/millennium/themes/${theme_name}"
config_dir="${home}/.config/millennium"
config_file="${config_dir}/config.json"

mkdir -p "$(dirname "$theme_dir")" "$config_dir"
ln -sfnT "$theme_source" "$theme_dir"

if [ ! -f "$config_file" ]; then
  printf '{"themes":{"activeTheme":"%s"}}\n' "$theme_name" >"$config_file"
fi
