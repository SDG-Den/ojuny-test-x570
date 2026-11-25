#!/usr/bin/env bash

clear

flakepath="$OJUNY_REPO_PATH"

sudo echo "rebuilding configuration $(hostname) using path $flakepath"
git -C $flakepath pull

if which nom; then
    sudo nixos-rebuild switch --flake $flakepath#$(hostname) |& nom
else
    sudo nixos-rebuild switch --flake $flakepath#$(hostname)
fi

if mmsg get cursorpos; then
    dms kill
    mmsg dispatch spawn_shell,dms run
fi
