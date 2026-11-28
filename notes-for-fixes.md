round 8:
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

- after pressing save and rebuild when updating the patches, it showed a warning that work tree was clean. 
- NOM cache discovery + nix-cache-discovery - 127.0.0.1:5055 is shown when downloading from fallback cache, should show fallback cache URL (just like it shows local device when pulling from the local device)
- ojuny-login-splash now does not end at all for either rebuild nor boot. major regression, revert functionality to previous, simpler functionality: starts on login, mango has exec= line that runs --quit with a short delay conditional on DMS being available as checked by mmsg get all-layers. this guarantees that on mango reload, it will quit the splash x seconds later, while mango's initial load will be before DMS is active, so it will not trigger the splash kill. this is the exact method that was used initially, and they significantly more complex current system is a major regression and makes it impossible to troubleshoot.
- wvkbd no longer shows on-boot, but still has 0 actual functionality, making it effectively useless. 

