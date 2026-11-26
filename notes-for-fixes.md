
development patch projects menu does not work correctly for agent, obsidian or terminal. it ends up in home. both terminal and vscodium end up inside the devshell which is good, both open zsh which is correct. obsidian will also open previously-opened windows, which we do not want. 








round 2:

nix-cleaner: view resets whenever an item is checked, making checking large amounts of items extremely tedious. 

nix-cleaner: clean failed because of a link in /tmp "outside permitted locations"

automatic disk mount does not work for all ISO's, nixos iso worked, mint iso did not. mint image 3.1gb, nixos iso tested was under 1gb

nix-settings-gui: opening the GUI when local repo is synced and git auto-sync is on reports "the local branch has diverged from upstream (ahead 0, behind 0)" when it is not actually ahead or behind or diverged. 

ojuny CLI: ojuny raw-settings lacks a way to list available pages, and for example "secureboot" does not open the secureboot page because it only filters on Secure Boot. 

dux control center: control center grid placement was off. likely because the row with the wifi, bluetooth, vpn, valent and disk modules overlaps the microphone slider, which causes the whole stack to be pushed down below that space automatically. the power and lock buttons are also beside eachother, almost like the grid is forced to be one width smaller than it should be, resulting in this behaviour. this may have come from a dux update.

raven: office installer exits with error 255, trying to select the full error in raven for copying causes a full system freeze. `ojuny crashes` does not show a crash, but a hard reset was required to fix it. this is replicable.

nix-regedit: type listing is too far to the right, so even type "key" only shows "ke..."

nix-settings-gui: wallpaper previews are missing, and auto-themed shouldn't be its own separate option, since the bundled wallpapers are auto-themed.

nix-settings-gui: hovering over a spinner once again automatically selects is, so scrolling past one means as soon as you reach it it'll start changing the value instead. 

nix-settings-gui: options under OSD and sounds don't have descriptions that show. 

card layout: network throughput entirely absent from dashboard. 

nix-settings-gui: cards with a "tone" do not have other options past "primary", except weather which has a blank open text field. 

craft apps: toggle for "all craft apps" in menu is misleading, claims it installs everything but doesn't install anything until the user toggles on specific items. this option should be hidden into the backend and enabled automatically if any individual craftapp is enabled. 

vesktop/steam: should both have an "autostart on boot" entry that adds an exec_once entry. 

screenshots: OCR QR code scanning uses super+shift+q, which is not good because it means with a little slip-up of not holding down shift enough, the user can accidentally close the window instead of scanning the QR code. it also does not seem to copy the payload. 

firefox/chromium: sponsorblock gets a "review options" page on first boot. 

accessibility: mouse mode clicks do not work. 

acessibility: on-screen keyboard does not work using the mouse, as when the mouse is over it, it focuses the keyboard and does not pass through the information to your application. this same issue was not the case using WVKBD when tested in the past. 

nix-settings-gui: changing the icons settings to tela makes the typography module unparseable. switching back to papirus fixes it. 

nix-settings-gui: splash screen tips need to be quoted, but are not automatically quoted, which is confusing to the user. on save, it changes the input string to being individual words. 

GTK applications like nix-settings-gui: selecting text in the application immediately deselects it. 

nix-settings-gui: the commit message save prompt should automatically select the text box, and pressing enter should send it.

ojuny-login-splash: launch-on-rebuild doesnt end automatically because it gets started *before* the user presses any button to close the window, while the DMS reload it's supposed to cover happens *after*

rebuilding via nix-settings-gui should be switched to using an ojuny CLI item, we should add some build-related items to the ojuny script. namely:

ojuny rebuild - equal to `echo "starting rebuild" && nixos-rebuild switch --flake (insert ojuny flake dir here) &| nom` with a bit of extra wiring to make the experience smoother

ojuny rebuild boot - like rebuild but with boot instead of switch

ojuny rebuild switch - equal to ojuny rebuild, effectively ojuny rebuild is a category with the default subcommand being switch

ojuny rebuild rollback - roll back to an older generation


patch-ojuny-agent: agent has no ability to search the web in assist mode, and refuses to do so in agentic mode.

report from the agent:

For your harness notes, the concrete things this exposed:
- Tool exposure vs. agent prompt disagree: websearch/webfetch are in the session's tool schema, but the ojuny-agent guide still says "no network." One of those needs to win.
- Mid-session agent switch doesn't re-bind: switching to ojuny-agent changed the ojuny-side config (ojuny-agent-cli status shows both agents), but the prompt and tools for the running session stayed as they were.
- No ojuny web command: ojuny commands --json has nothing for web/search/fetch, so there's no CLI-level probe to fall back on.
- ojuny-assist web search is a config gap, not a permission failure — worth checking its agent definition separately.


ojuny-manual: no way to start CLI version while in a graphical environment, should have a way to do that.

fastfetch - some items are missing icons: shell, terminal, terminal font, disk, board. SWAP is labeled zram, dotfiles entry should be replaced by:

local repo (path to local repository)
remote repo (path to remote repository)
ojuny base (the template type it was made from, in this case it would be just Ojuny, but for ojuny pro this would list Ojuny Pro)









