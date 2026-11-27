needs testing: 



nix-settings-gui: opening the GUI when local repo is synced and git auto-sync is on reports "the local branch has diverged from upstream (ahead 0, behind 0)" when it is not actually ahead or behind or diverged. > still happens > still happens x2

raven: office installer exits with error 255, trying to select the full error in raven for copying causes a full system freeze. `ojuny crashes` does not show a crash, but a hard reset was required to fix it. this is replicable. > still a problem. 


nix-settings-gui: wallpaper previews are missing, and auto-themed shouldn't be its own separate option, since the bundled wallpapers are auto-themed. > still missing and auto-themed is still a separate option > still the case


acessibility: on-screen keyboard does not work using the mouse, as when the mouse is over it, it focuses the keyboard and does not pass through the information to your application. this same issue was not the case using WVKBD when tested in the past. > now keybind is fully broken, nothing happens. > still broken entirely. cannot type on it. 


ojuny-login-splash: launch-on-rebuild doesnt end automatically because it gets started *before* the user presses any button to close the window, while the DMS reload it's supposed to cover happens *after* > doesn't happen at all now, and the splash no longer quits once DMS is loaded. > still doesn't happen at all.

nix-settings-gui resets scroll on flake inputs page for every update check it does, so you cannot scroll down to see it progress while it is going. > still happens

flatpak applications (flatseal and thunderbird) take very long to load. > still the case. 10 seconds for thunderbird. 

nix-settings-gui flake inputs: "scan commits" does nothing, commit hash pin is a free text field. > works, but not useful, should show a date stamp as well.


steam settings in ojuny: steam is not themed by default when installed, it should be with a toggle to turn it off > uses millenium now, which is good, but theme is not applied by default. > millenium settings are no longer accessible, but millenium is still used.

quake terminal is positioned centered on the screen, rather than near the top. it is also behind the bar instead of above. > works on initial spawn, but re-triggers reset it once you trigger it on a different monitor once.



there should be a keybind that the user can use to either toggle off/on the focused display, or while holding shift, toggle off/on all displays. > works with super+o, but super+shift+o overlaps with OCR by default.

USB automount does not occur if the device was already plugged in at boot. it has to be re-plugged to automount. > still the case




ojuny-manual lists theme selection and keybinds, neither of which are correct for the w3m version. > unchanged. using it via tty is impossible, needs to not directly use the generated HTML, we need to have it package the MD directly, and make the viewer actually have good controls. 



copy-pasting from vscodium to a terminal is not possible, the data shows up on the clipboard but cannot be pasted into a terminal. > still the case

OSK - auto show/hide only works with vscodium, not with firefox, ghostty or libreoffice writer, manual show/hide with the keybind does not work, tray icon does not work, cannot actually use the OSK > still mostly broken.

auto-rotate is missing from the menu. > still the case. 




round 5:

obsidian vault names need to receive auto-quoting treatment.

nix settings gui: new sysmon card item needs its settings menu popout thingie to be *Significantly* larger, it is currently about 2.5 text lines tall so it's really hard to actually read what's on ther, these items need to automatically size to fit their content in general.

raven: the error log window on crash can expand past screen bounds instead of becoming scrollable. trying to use the office deployment tool from microsoft causes raven to never even launch now. 



round 6:

when clicking on the terminal when it is rebuilding from NSG, it acts like a constant stream of text is being typed. ^[[26~ on repeat. this happens as long as the window is focused. it also lists "dependency graph" multiple times. this may either be to do with how the window is spawned, or NOM cache discovery bugging out. > seems to be something causing ~ to be held down, pressing ` again stops it. clicking in ghostty restarts it. 

sometimes, it becomes impossible to select text in opencode using the mouse.

