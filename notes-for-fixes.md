
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






