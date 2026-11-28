round 8:

- wallpaper: works now, sort of. running `dms kill && mmsg dispatch spawn_shell,dms run` causes it to select *the wrong wallpaper*, selected: Default, showing: Retro.
- ojuny login splash: only shows for half a second on login, instantly ends now. does not end at all when triggered by rebuild. 
- WVKBD: still shows immediately on login. cannot type on it still even with DMS disabled.
- nsg: still "/home/den/repos/nix-flake: git puill refused by origin/.main: git pull --no-edit --ff-only: fatal: cannot fast-forward to multiple branches. (merge refs: refs/heads/man)"
- nsg: environment reload command still does not run at all.
- flatpak applications still take long to start. but this is per-app. thunderbird - 8 seconds, kitties - 5 seconds, memerist - 2 seconds, flatseal - 6 seconds, unity hub - 9 seconds. may be a general "flatpaks are slow because sandboxing" issue. 
- steam: millenium settings are back, but still not auto-themed by stylix.
- quake terminal: still moves to middle of screen once opened at least once on a different monitor. likely fix: having the bind run a script that first detects state, then toggles the scratchpad, then sets the position of the terminal on enable. 
- monitor toggle: super+o toggles one monitor, but cannot then toggle a second monitor. super+shift+o toggles one monitor at a time, and cannot toggle monitors back on until all 3 monitors are toggled off. also, this completely messes up positioning for all windows. maybe we need to change to the monitor sleep method. 
- automount still has not occured on boot
- ojuny manual: needs reverse layout on fzf (top-to-bottom instead of bottom-to-top), and all items get a bat error stating the file is not accessible. 
- copy paste from vscodium to terminal: still not functional
- auto-rotate toggle is still either missing from the nix-settings-gui menu or cannot be found with the word "rotate" in the search bar. 
- NSG: the card layout somehow started showing the old network monitor tile even though it no longer exists.

round 9:

