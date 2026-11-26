round 2 (theoretically implemented, must be tested):


development patch projects menu does not work correctly for agent, obsidian or terminal. it ends up in home. both terminal and vscodium end up inside the devshell which is good, both open zsh which is correct. obsidian will also open previously-opened windows, which we do not want. 

update: terminal fixed, agent still completely fails to open, obsidian vault seems to not work properly either, it never detects the vault. 



nix-settings-gui: opening the GUI when local repo is synced and git auto-sync is on reports "the local branch has diverged from upstream (ahead 0, behind 0)" when it is not actually ahead or behind or diverged. > still happens

ojuny CLI: ojuny raw-settings lacks a way to list available pages, and for example "secureboot" does not open the secureboot page because it only filters on Secure Boot. > still lacks a way to list available pages, just running ojuny raw-settings only shows usage. also, when running an unknown page, it'll list everything but that's not a proper solution, and this list looks very messy because it's not properly spaced.

raven: office installer exits with error 255, trying to select the full error in raven for copying causes a full system freeze. `ojuny crashes` does not show a crash, but a hard reset was required to fix it. this is replicable.

nix-settings-gui: wallpaper previews are missing, and auto-themed shouldn't be its own separate option, since the bundled wallpapers are auto-themed. > still missing and auto-themed is still a separate option


card layout: network throughput entirely absent from dashboard. > still missing

nix-settings-gui: cards with a "tone" do not have other options past "primary", except weather which has a blank open text field. > still happens, not fixed. 


   

acessibility: on-screen keyboard does not work using the mouse, as when the mouse is over it, it focuses the keyboard and does not pass through the information to your application. this same issue was not the case using WVKBD when tested in the past. > now keybind is fully broken

nix-settings-gui: splash screen tips need to be quoted, but are not automatically quoted, which is confusing to the user. on save, it changes the input string to being individual words. > this now adds a quote or a \" every time the page is saved to all entries, the quotes need to be added to the underlaying nix module, not displayed, and not double-added.

GTK applications like nix-settings-gui: selecting text in the application immediately deselects it. > still a problem


ojuny-login-splash: launch-on-rebuild doesnt end automatically because it gets started *before* the user presses any button to close the window, while the DMS reload it's supposed to cover happens *after* > doesn't happen at all now

rebuilding via nix-settings-gui should be switched to using an ojuny CLI item, we should add some build-related items to the ojuny script. > not configured on test device, but individual commands work, replacing manually (settings gui settings are not managed by nix) works.



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




round 3:

overflow layout does not work at all.

nix-settings-gui resets scroll on flake inputs page for every update check it does, so you cannot scroll down to see it progress while it is going. 

nix-shell-gui: no feedback when it is pulling/compiling something, so pressing launch can look like it did nothing even though it is actually starting the shell in the background.

flatpak applications (flatseal and thunderbird) take very long to load.

nix-settings-gui flake inputs: "scan commits" does nothing, commit hash pin is a free text field. 

building ojuny-iso takes a really long time even on a ryzen 7 5700G with 32GB RAM because it seems to be limited to only 2 cores when it hits building wlr-utils (single build running) 

steam settings in ojuny: steam is not themed by default when installed, it should be with a toggle to turn it off

quake terminal is positioned centered on the screen, rather than near the top. it is also behind the bar instead of above. 

btop does not show some GPU's (eg nvidia 3060)

middle-click has some weird interactions with games (warframe: middle-click is intercepted and character moves camera to pointing directly downwards) this may be because straight middle-click does maximize. this should be changed to only happening if the focused window is not already fullscreen, and it should be a transparent bind. to add to this, we could change what this does since super+f is already the same bind. maybe we can have it do different things depending on layout? we can add a settings option set for that, with the default being to maximize, while default for tiling modes is zoom (makes the target the master)


there should be a keybind that the user can use to either toggle off/on the focused display, or while holding shift, toggle off/on all displays. 

USB automount does not occur if the device was already plugged in at boot. it has to be re-plugged to automount.

rm command (rmtrash) doesn't work for root, which could cause other issues. when run as root, the rm shim we have should default to regular rm. only users and userspace applications/scripts should be automatically subjected to rmtrash. 


sway needs to also receive the monitor configuration so multi-monitor setups have the right layout for the greeter.






