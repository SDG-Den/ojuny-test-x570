#!/usr/bin/env bash
set -euo pipefail

theme_source="${1:?theme source path is required}"
theme_name="${2:?theme name is required}"
stylix_css="${3:-}"
home="${HOME:?HOME is required}"

config_home="${XDG_CONFIG_HOME:-$home/.config}"
data_home="${XDG_DATA_HOME:-$home/.local/share}"

steam_root="$data_home/Steam"
if [ -d "$home/.steam/steam" ]; then
  steam_root="$home/.steam/steam"
fi
theme_dir="${steam_root}/millennium/themes/${theme_name}"
config_dir="${config_home}/millennium"
config_file="${config_dir}/config.json"

mkdir -p "${theme_dir%/*}" "$config_dir"
ln -sfnT "$theme_source" "$theme_dir"

if [ -f "$config_file" ] && jq -e . "$config_file" >/dev/null 2>&1; then
  current="$(jq -r '.themes.activeTheme // empty' "$config_file")"
  if [ -z "$current" ] || [ "$current" = "default" ]; then
    tmp="$(mktemp)"
    jq --arg theme "$theme_name" '.themes = ((.themes // {}) + {activeTheme: $theme})' "$config_file" >"$tmp"
    mv "$tmp" "$config_file"
  fi
else
  printf '{"themes":{"activeTheme":"%s"}}\n' "$theme_name" >"$config_file"
fi

if [ -n "$stylix_css" ] && [ -r "$stylix_css" ]; then
  install -d -m 0755 "$config_dir"
  install -m 0644 "$stylix_css" "$config_dir/quick.css"
fi
