needs testing: 



nix-settings-gui: opening the GUI when local repo is synced and git auto-sync is on reports "the local branch has diverged from upstream (ahead 0, behind 0)" when it is not actually ahead or behind or diverged. > still happens > still happens x2

raven: office installer exits with error 255, trying to select the full error in raven for copying causes a full system freeze. `ojuny crashes` does not show a crash, but a hard reset was required to fix it. this is replicable. > still a problem. 

error log:

Raven launch Time: 2026-11-27T00:10:42+01:00 Application: /home/den/Downloads/officedeploymenttool_20527-20150.exe Wrapper: /nix/store/9mkx4f1ygwyyl05mhmn6z9xkjxry7yd9-ojuny-raven/bin/ojuny-raven Raven command: /nix/store/36lwpwj4fx19715ap4qhd2ni5dc76ldl-raven-unstable/bin/raven --run-process --execution=native --timeout-ms=86400000 --desktop=wayland --directory=Z:\home\den\Downloads /home/den/Downloads/officedeploymenttool_20527-20150.exe -- Raven revision: bd450e51302a26f22f427910296681bdf38c0c01 Raven package: 0-unstable-2026-11-19 System: Architecture: x86_64 Kernel: Linux 7.3.6-cachyos x86_64 ID=ojuny ID_LIKE=nixos PRETTY_NAME="Ojuny 26.11 (Zokor)" VERSION_ID="26.11" CPU: AMD Ryzen 7 5700G with Radeon Graphics MemTotal:       32715424 kB MemAvailable:   21767072 kB GPU: 01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA106 [GeForce RTX 3060] [10de:2544] (rev a1) Compositor: wlroots Session: wayland Environment: DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus DESKTOP_SESSION=ojuny DISPLAY=:0 HOME=/home/den LANG=en_US.UTF-8 PATH=/nix/store/a50ml7za6h61m4mv4cdbvkl33c6sx5yn-coreutils-9.12/bin:/nix/store/x275j18p7dx6kv7vfj45saapbhbljia4-gnused-4.10/bin:/nix/store/5sgjjiqn90zmvlvlgadw7ss00nn3hpjb-gnugrep-3.12/bin:/nix/store/hr20hjaf8q0hhchv9rb3k9fzflbl8y3k-pciutils-3.15.0/bin:/nix/store/m50dfhnbbqpvj79i444kcdd2zsfwr4hk-bubblewrap-0.13.1/bin:/nix/store/2g6c6lh1dg082axhl0vhhcamx1ifm740-ffmpegthumbnailer-2.4.1/bin:/nix/store/nx16mjcv442bx13rn80az81a83aw2xvy-poppler-utils-26.11.0/bin:/nix/store/5b6ipwfrbs9jq38w02d6kz1pa3hl2hj5-mango-nightly/bin:/nix/store/5phiv8qd3vq60g8mjzmpm71zch4h0vpy-ojuny-config/bin:/nix/store/n4ll3pznfj6qdka7wc3gaap79kpdp2c3-dms/bin:/nix/store/cjv6p2g83pbzikkzlmc0lrk03y7mi6vi-wl-clipboard-2.3.0/bin:/nix/store/cqwgczixlja6dzn6msqq0lxsnk7j7gr9-wl-clip-persist-0.5.0/bin:/nix/store/8ja0dv5y5lbl4njd866wa2dfkq3v09ms-cliphist-0.7.0/bin:/nix/store/313mfbjivfd2jwjqshlnx658br9q5q1g-wlr-utils-1.11.1/bin:/nix/store/rrm55n7733yzhjk3l0lhckmxj7mbjln6-ydotool-1.0.4/bin:/nix/store/nh0wly5a1h79bfjgw46sly70ljdy1xkl-jq-1.8.2-bin/bin:/nix/store/i1kknqwyq354kmvacmmafk17b272b5s8-sqlite-3.54.0-bin/bin:/nix/store/s6acwnf1xb7zfgdbi1x9y1dc7jizcy1d-fzf-0.75.0/bin:/nix/store/ch08kx5samb5pj90334bi8xni48ljz7m-eza-0.23.5/bin:/nix/store/azrmzxmgjrmy6zsb7v1gvrq991r2n3h3-glib-2.90.0-bin/bin:/nix/store/19m5qzcwm8k68lpnv359x3m887crn7qd-networkmanager-1.58.1/bin:/nix/store/9l818ldvz56gdh0b7jbyhwan7jb40bv0-cava-1.0.0/bin:/nix/store/amnhck3is93a6hai64dvy6zckkpcm01n-khal-0.14.1/bin:/nix/store/db0clszc1dxk6mh8p8mbh2v9jd6m6n9w-matugen-4.2.0/bin:/nix/store/wc6ky2sqq8shrmaf14x7spbdpqi6ls9w-iproute2-7.2.0/bin:/nix/store/kfsark7xjl1g232vmghbjvd9kw1nwbl1-kdeconnect-kde-26.08.3/bin:/nix/store/9bbmxrzmii9mybf18bz4id67nkcg3gcx-ojuny-ghostty/bin:/nix/store/xamxmg28y7klvc1jkjvv2khv3aizfyyj-ojuny-snap/bin:/nix/store/1qrgpkdhsrb720k7wdqhrw83xy738m9q-vesktop-1.6.9/bin:/nix/store/rdwf6zqvwn7bzhgmqplyf4pfmlqj5av9-obsidian-1.15.1/bin:/nix/store/jp06ad1735p1fmf19298a93kw05qhh7s-ghostty-1.4.0/bin:/nix/store/lr6rlibz9mi24mag008wxng40ii0q2kb-firefox-160.0.1/bin:/nix/store/p4f56xydspy44ga833vxdqhlsp05is56-dgop-2.1.0/bin:/nix/store/wcfhk2zpl2y9pzwdf5yhds670xawjjkb-dsearch-2.1.0/bin:/nix/store/qwd8rh208dg57h4b54k3i1m6kwq8swkv-dankcalendar-2.1.0/bin:/nix/store/qxiafim05h47di68xa4mfhivjja2ak1n-ojuny-WinMenu/bin:/nix/store/zdiajy2afsdv6d1wkvcividnb6rmjsjx-dux-files-2.1.0/bin:/run/wrappers/bin:/nix/store/j4zx5kmilwjw0ys88npq2l4x9c8jnqkv-rm/bin:/home/den/.local/share/flatpak/exports/bin:/var/lib/flatpak/exports/bin:/home/den/.nix-profile/bin:/nix/profile/bin:/home/den/.local/state/nix/profile/bin:/etc/profiles/per-user/den/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin WAYLAND_DISPLAY=wayland-0 XDG_ACTIVATION_TOKEN=0ceb1eb0253f763cdb329c7af27ccedb XDG_CONFIG_DIRS=/etc/xdg:/home/den/.local/share/flatpak/exports/etc/xdg:/var/lib/flatpak/exports/etc/xdg:/home/den/.nix-profile/etc/xdg:/nix/profile/etc/xdg:/home/den/.local/state/nix/profile/etc/xdg:/etc/profiles/per-user/den/etc/xdg:/nix/var/nix/profiles/default/etc/xdg:/run/current-system/sw/etc/xdg XDG_CURRENT_DESKTOP=wlroots XDG_DATA_DIRS=/nix/store/pp5gazj0m54a5g9sbzayk6k0d7bv5v61-desktops/share:/home/den/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/home/den/.nix-profile/share:/nix/profile/share:/home/den/.local/state/nix/profile/share:/etc/profiles/per-user/den/share:/nix/var/nix/profiles/default/share:/run/current-system/sw/share XDG_RUNTIME_DIR=/run/user/1000 XDG_SEAT=seat0 XDG_SESSION_DESKTOP=wlroots XDG_SESSION_ID=3 XDG_SESSION_TYPE=wayland XDG_VTNR=1 Report this at https://github.com/mirkobrombin/raven/issues
--- output --- Native process exited with status 4294967295 Exit status: 255
--- sandbox refusals --- 2026-11-25 18:58:47	C:\Program Files\Notepad++\notepad++.exe	open	/home/den/.local/share/raven/default/drive_c/windows/Fonts/LiberationMono-Bold.ttf 2026-11-25 18:58:47	C:\Program Files\Notepad++\notepad++.exe	open

nix-settings-gui: wallpaper previews are missing, and auto-themed shouldn't be its own separate option, since the bundled wallpapers are auto-themed. > still missing and auto-themed is still a separate option > still the case


acessibility: on-screen keyboard does not work using the mouse, as when the mouse is over it, it focuses the keyboard and does not pass through the information to your application. this same issue was not the case using WVKBD when tested in the past. > now keybind is fully broken, nothing happens. > still broken entirely. cannot type on it. 


ojuny-login-splash: launch-on-rebuild doesnt end automatically because it gets started *before* the user presses any button to close the window, while the DMS reload it's supposed to cover happens *after* > doesn't happen at all now, and the splash no longer quits once DMS is loaded.

nix-settings-gui resets scroll on flake inputs page for every update check it does, so you cannot scroll down to see it progress while it is going. > still happens

flatpak applications (flatseal and thunderbird) take very long to load.

nix-settings-gui flake inputs: "scan commits" does nothing, commit hash pin is a free text field. > works, but not useful, should show a date stamp as well.

building ojuny-iso takes a really long time even on a ryzen 7 5700G with 32GB RAM because it seems to be limited to only 2 cores when it hits building wlr-utils (single build running) 

steam settings in ojuny: steam is not themed by default when installed, it should be with a toggle to turn it off

quake terminal is positioned centered on the screen, rather than near the top. it is also behind the bar instead of above. 

btop does not show some GPU's (eg nvidia 3060)

middle-click has some weird interactions with games (warframe: middle-click is intercepted and character moves camera to pointing directly downwards) this may be because straight middle-click does maximize. this should be changed to only happening if the focused window is not already fullscreen, and it should be a transparent bind. to add to this, we could change what this does since super+f is already the same bind. maybe we can have it do different things depending on layout? we can add a settings option set for that, with the default being to maximize, while default for tiling modes is zoom (makes the target the master)


there should be a keybind that the user can use to either toggle off/on the focused display, or while holding shift, toggle off/on all displays. 

USB automount does not occur if the device was already plugged in at boot. it has to be re-plugged to automount.

rm command (rmtrash) doesn't work for root, which could cause other issues. when run as root, the rm shim we have should default to regular rm. only users and userspace applications/scripts should be automatically subjected to rmtrash. 


sway needs to also receive the monitor configuration so multi-monitor setups have the right layout for the greeter.

ojuny rebuild does not pause at the end, so the terminal closes immediately once the command finishes for nix-settings-gui, this means you cannot see if it failed. 


ojuny-manual lists theme selection and keybinds, neither of which are correct for the w3m version. 


ojuny patches - list looks terrible because of poor spacing.

NSG - most icons are entirely missing when not on the default papirus theme. 

copy-pasting from vscodium to a terminal is not possible, the data shows up on the clipboard but cannot be pasted into a terminal.

OSK - auto show/hide only works with vscodium, not with firefox, ghostty or libreoffice writer, manual show/hide with the keybind does not work, tray icon does not work, cannot actually use the OSK

auto-rotate is missing from the menu.


round 5:

obsidian vault names need to receive auto-quoting treatment.

nix settings gui: new sysmon card item needs its settings menu popout thingie to be *Significantly* larger, it is currently about 2.5 text lines tall so it's really hard to actually read what's on ther, these items need to automatically size to fit their content in general.




