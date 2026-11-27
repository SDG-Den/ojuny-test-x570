# notes-for-fixes analysis

Temporary handoff for investigation, 2026-11-27. Not a device change and not
for commit. Source of the items: `notes-for-fixes.md` in this repo.

Research was read-only across `ojuny-template`, `nix-settings-gui`, `raven`,
`ojuny-manual`, `ojuny-desktop`, `ojuny-cli`, `ojuny-login-splash`, `mango`,
`dux-shell` and `ojuny-patches`. Every claim below carries a file and line.

## Build and repository state

- Device branch `main` at `810d0ca`, a merge of `06aff67` with template
  `origin/base` at `85d3cac`. The build that produced the current notes is
  `06aff67`. `810d0ca` is the first build with the native OSK tray.
- `06aff67` still installed `yad` and `xembedsniproxy` in
  `modules/07-system/08-accessibility.nix`. `810d0ca` has the native
  StatusNotifierItem tray, `ojuny-osk-run`, and the Auto-popup menu row.
- The device resolves tools from source: `ojuny.binaries.mode = "source"` at
  `modules/07-system/01-configuration.nix:61`, so `settingsGui`, `cli` and the
  other `auto` entries build from their flake inputs.
- `nix-settings-gui` is pinned to `76b1856` in both the template and the device
  (`flake.lock:1218-1224`). `76b1856` contains `2ad02fe`, the divergence
  classifier change.
- `raven` is pinned to `29fb3f06` in both locks (`flake.lock:1710`). The failing
  device log names `bd450e51` (`0-unstable-2026-11-19`), which is an ancestor of
  `29fb3f06`: 391 commits behind the locked input.
- Device-only settings that differ from the template:
  - `onScreenKeyboard.auto = false` at
    `modules/07-system/08-accessibility.nix:124` (template default is true).
    `06aff67:121` also has false.
  - `onScreenKeyboard.enable = true` (same as template).
  - `services.orca.enable = true` at `:100` (template false).
  - `nullable = true` and `wallpaperPreset = "retro"` at
    `modules/02-core/05-theme.nix:39-40` (template has `false` and
    `lib.mkDefault "default"`).

## Constraints that apply to any fix

- Code fixes go to `ojuny-template` and the related upstream repos, never to
  this device checkout, because the template is merged into the device. Notes
  and analysis documents are the exception: they travel in both directions
  through GitHub, the same way `notes-for-fixes.md` does.
- Do not reintroduce `xembedsniproxy` or a `yad` XEmbed tray. The old tray
  created an override-redirect X11 window on wlroots and stole pointer and
  keyboard focus; it caused the GTK selection loss. See
  `ojuny-template/docs/05-settings-gui-limitations.md:164-168`.
- Display toggling must use `toggle_monitor`, never `sleep_toggle_monitor`
  (`mango/docs/bindings/keys.md:213-216`).
- `@option` comments bind only to assignments in a plain attribute set. Never
  inside lists, `lib.mkMerge`, `map`, `forEach` or `lib.optionalAttrs`. Never
  add list descent to `nix-settings-gui/src/scan.rs`
  (`docs/05-settings-gui-limitations.md:3-16`).
- Raven packaging changes go through Nix. `raven` native changes cross an
  approved no-native-edits boundary and need an explicit decision plus a
  reproducing test (`raven/CONTRIBUTING.md:33`).
- `dux-shell` and `dms-plugins` are not to be modified.

## Items

### 1. notes line 5: NSG reports divergence with `ahead 0, behind 0`

Verbatim: `nix-settings-gui: opening the GUI when local repo is synced and git
auto-sync is on reports "the local branch has diverged from upstream (ahead 0,
behind 0)" when it is not actually ahead or behind or diverged.`

Owner: `nix-settings-gui`.

Evidence:
- `src/app/git.rs:132-138`: `behind == 0` returns `Current`, so `0 0` cannot
  reach `Diverged`.
- `src/app/git.rs:76-99` is the only producer of the counts message.
- `src/app/git.rs:69-71` (`pull`) does not fetch explicitly; `git pull` fetches
  internally.
- Tests pin the behaviour: `src/app/git.rs:318-321` and `:409-466`.
- `docs/architecture.md:163-171` and `docs/usage.md:23-25` describe the pull
  semantics but not the message.

Root cause: not established. The code at the pinned revision cannot emit that
string for `0 0`. Either the generation under test predates the classifier
change, or the tracking ref read by `rev-list` differed from the ref used by the
pull.

Fix if still reproducible on `76b1856`: fetch before counting in `pull()`, the
way `save_sync_state` already does at `src/app/git.rs:149`, and include the
fetched tip in the message. Do not change the classifier.

Status: needs device data.

Device checks:
```sh
git -C <flake> status -sb
git -C <flake> fetch && git -C <flake> rev-list --left-right --count 'HEAD...@{u}'
git -C <flake> pull --no-edit --ff-only
readlink -f "$(command -v nix-settings-gui)"
```

### 2. notes line 7: Raven Office installer exits 255, selection freezes, no crash entry

Verbatim: `raven: office installer exits with error 255, trying to select the
full error in raven for copying causes a full system freeze. `ojuny crashes`
does not show a crash, but a hard reset was required to fix it. this is
replicable.`

Owner: `ojuny-template` wrapper plus `ojuny-cli` for the crash list.

Evidence:
- `raven/native/main.cpp:130-137` maps a guest exit of `-1` (`0xFFFFFFFF`) to
  host status `0xFF`, i.e. 255.
- The wrapper reads Raven's 4-byte exit file with `cat` at
  `modules/backend/05-applications/08-appimage-raven-backend.nix:269`, so the
  reported guest code is binary garbage. `raven/flake.nix:40` repeats the
  defect.
- The report preview is `head -c 8192` of the diagnostics block
  (`scripts/ojuny-raven-report.sh:33-41`); the guest message under
  `--- output ---` is usually outside it.
- `sandbox.log` is appended with `tail -n 100` unfiltered
  (`08-appimage-raven-backend.nix:142-151`), so it carries stale lines from
  other programs and days.
- The current dialog is `yad --text` with no selection surface
  (`scripts/ojuny-raven-report.sh:48`). The freeze predates that change, when
  the dialog was `--text-info`.
- Raven's clipboard callbacks are declared but never assigned
  (`raven/native/desktop/user_ext.cpp:490-505`), so Raven cannot be the
  clipboard side.
- The report is written after Raven exits, and `last.log` is truncated on the
  next launch (`08-appimage-raven-backend.nix:242-256`). `ojuny crashes` only
  lists `*failure.log` (`ojuny-cli/src/ojuny-cli/lib/crashes.sh:54-60`), so a
  hard reset leaves nothing.

Fixes:
- Decode with `od -An -tu4 -N4` and print signed and unsigned.
- Build the preview from the `--- output ---` section, not the head of the file.
- Filter `sandbox.log` by program and launch time.
- Write a timestamped running log before launch and list it in the crash CLI.
- Keep the non-selectable `--text` dialog. Do not add `--selectable-labels` or
  `--text-info` without a decision (see item 18).

Status: exit-code decoding and crash evidence are fixable now. The freeze cause
remains unverified; the mitigation is already in place.

### 3. notes line 10: wallpaper previews missing, Auto-themed is a separate option

Verbatim: `nix-settings-gui: wallpaper previews are missing, and auto-themed
shouldn't be its own separate option, since the bundled wallpapers are
auto-themed.`

Owner: device module for the tile, `nix-settings-gui` for previews.

Evidence:
- The Auto tile exists only when `nullable = true`
  (`src/widgets/wallpaper.rs:319-326`; documented at
  `docs/comment-syntax.md:417`). The template sets `nullable = false` at
  `modules/02-core/05-theme.nix:39`. The device sets `true` at `:39`.
- The device value entered through `a266b60` (2026-10-29, "update through ojuny
  flake resolve script"); the merge at `810d0ca` keeps the device hunk because
  the base already had `false`.
- Bundled presets are palette-recoloured at build time
  (`ojuny-desktop/lib/mk-wallpaper-set.nix:58-68`), so a separate `null` choice
  is redundant.
- Preset tiles come from a full `nix eval` plus `nix-store --realise`
  (`nix-settings-gui/src/metadata.rs:284-338`). Until it returns, the strip has
  one empty-path tile drawn as "Preview unavailable"
  (`src/widgets/wallpaper.rs:682-706`), with no loading state and no timeout.
- The device `modules/02-core/wallpapers` contains only `.gitkeep`, so no
  preview can come from `wallpaperDir`.

Fixes:
- Reconcile the device `05-theme.nix` with the template. The template cannot
  override the device hunk.
- In `wallpaper.rs:232-247` and `:308-311`, seed the strip with named
  placeholders and distinguish "not built yet" from "fetch failed".

Status: Auto-themed is a device divergence; previews need a GUI change plus a
device check that the eval succeeds.

Device checks:
```sh
nix eval .#nixosConfigurations.<host>.config.desktop.ojuny.wallpaper --json
```

### 4. notes line 13: OSK mouse focus does not reach the application

Verbatim: `acessibility: on-screen keyboard does not work using the mouse, as
when the mouse is over it, it focuses the keyboard and does not pass through the
information to your application. this same issue was not the case using WVKBD
when tested in the past.`

Owner: environment or upstream; no template flag change is supported.

Evidence:
- wvkbd 0.21 uses layer-shell and `zwp_virtual_keyboard_v1`, and requests
  keyboard interactivity `NONE` (`wvkbd` v0.21 `main.c`). A `NONE` layer is not
  focused by mango (`mango/src/manage/layer.c:44-53`, `:294-299`).
- Mango implements layer-shell, virtual-keyboard, text-input-v3 and
  input-method-v2 (`mango/src/main.c:711`, `:818-821`, `:889-895`).
- The old XEmbed tray caused this class of failure and is gone from `810d0ca`
  (`docs/05-settings-gui-limitations.md:164-168`).
- The observation was made on `06aff67`, which still ran `yad` and
  `xembedsniproxy`.

Root cause: none in the template's wvkbd flags. Possibilities: a stale pre-fix
process, the unit not running, or a mango layer-focus defect.

Fix: retest on `810d0ca` first. If it persists, report upstream to mango or
wvkbd. Do not add a settings GUI workaround.

Status: needs device data.

Device checks:
```sh
ps -ef | grep -E 'wvkbd|xembedsniproxy|yad'
systemctl --user status ojuny-osk --no-pager
journalctl --user -b -u ojuny-osk --no-pager
```

### 5. notes line 16: login splash never starts on rebuild, never quits on DMS load

Verbatim: `ojuny-login-splash: launch-on-rebuild doesnt end automatically
because it gets started *before* the user presses any button to close the
window, while the DMS reload it's supposed to cover happens *after* > doesn't
happen at all now, and the splash no longer quits once DMS is loaded.`

Owner: `ojuny-desktop` (NixOS module) and `ojuny-cli` (rebuild wait).

Evidence:
- `ojuny-desktop/modules/nixos/default.nix:235` and `:238` apply the
  `.started` marker unconditionally. `showOnRebuild` is never read in that
  file; only the Home Manager module forwards it
  (`ojuny-desktop/modules/home-manager/default.nix:218-225`).
- The readiness script tests `dms version`, which only prints a version string
  (`dux-shell/core/cmd/dms/commands_common.go:215-217`). The real shell
  connection is a socket dial (`dux-shell/core/cmd/dms/server_client.go:28-45`).
- `ojuny rebuild` stops the unit and spawns a private splash binary instead
  (`ojuny-cli/src/ojuny-cli/lib/subtrees/rebuild.sh:50-86`), then uses the same
  fake readiness test at `:28-39`.

Fixes:
- Make `ConditionPathExists` and `ExecStartPre` conditional on
  `!cfg.splash.showOnRebuild` in `ojuny-desktop`.
- Replace both readiness tests with a real check: `systemctl --user is-active
  dms.service`, or the DMS IPC socket under `$XDG_RUNTIME_DIR`.
- Restart the unit from the CLI instead of spawning a private process.

Status: fix known.

### 6. notes line 18: NSG resets scroll on the flake inputs page

Verbatim: `nix-settings-gui resets scroll on flake inputs page for every update
check it does, so you cannot scroll down to see it progress while it is going.`

Owner: `nix-settings-gui`.

Evidence:
- Each `InputCheckProgress` message rebuilds the page
  (`src/app/pump.rs:386-388` -> `src/app/inputs.rs:299-301`, `:450-451`).
- The restore at `:452-476` returns early and never retries when
  `upper - page < scroll_position` (`:459-461`).
- `docs/gui-design.md:137-138` already requires scroll retention.

Fix: update the affected row in place on progress and reserve the full refresh
for done and updated messages. Alternatively, restore on `notify::page-size`
and map, and clamp instead of returning early.

Status: fix known. Verify the deployed GUI is `76b1856` first.

### 7. notes line 20: Flatpak apps take about 10 seconds

Verbatim: `flatpak applications (flatseal and thunderbird) take very long to
load. > still the case. 10 seconds for thunderbird.`

Owner: undetermined.

Evidence:
- The template only enables `services.flatpak` and Bazaar
  (`modules/patches/patch-flatpak.nix:40-44`).
- Portal default is `"*"` with no backend declared in this repo
  (`modules/03-desktop/00-mango.nix:12`).
- `services.flatpak.enable` forces `fonts.fontDir.enable`, and the host font set
  is large (`modules/backend/02-core/05-typography-backend.nix:73-80`).
- Updater Flatpak repair is off (`modules/02-core/10-updates.nix:67-68`).
- Flatseal and Thunderbird both being slow points at the shared sandbox path.

Fix: none can be named yet. Equal timing for `flatpak run --command=sh <app> -c
true` and the app isolates the sandbox. Unequal timing isolates the app.

Status: needs device data.

Device checks:
```sh
time flatpak run --command=sh org.mozilla.Thunderbird -c true
time flatpak run org.mozilla.Thunderbird
journalctl --user -b -u 'xdg-desktop-portal*' --no-pager
du -sh ~/.var/app/org.mozilla.Thunderbird /var/lib/flatpak
findmnt -T /var/lib/flatpak -o TARGET,SOURCE,FSTYPE,OPTIONS
```

### 8. notes line 22: commit scan needs a date stamp

Verbatim: `nix-settings-gui flake inputs: "scan commits" does nothing, commit
hash pin is a free text field. > works, but not useful, should show a date stamp
as well.`

Owner: `nix-settings-gui`.

Evidence:
- GitHub dates are available and discarded in the hash mapping
  (`src/ref_suggest.rs:196-205`); GitLab the same (`:212-225`).
- The fallback `git_tip` has no date (`:355-378`).
- The results are sorted alphabetically, which also loses newest-first order
  (`:197`).
- The picker row has one monospace label (`src/app/nixpkgs.rs:540-544`).
- `docs/gui-design.md:126-129` allows the typed hash field; the note's
  complaint about free text is satisfied by the picker, not by removing the
  field.

Fix: return `{sha, date}` from a new detailed scan, render hash plus date, keep
the `Vec<String>` wrapper for the existing tests, and keep the typed field.

Status: fix known.

### 9. notes line 25: Steam not themed by default

Verbatim: `steam settings in ojuny: steam is not themed by default when
installed, it should be with a toggle to turn it off > uses millenium now, which
is good, but theme is not applied by default.`

Owner: `ojuny-template`.

Evidence:
- `docs/02-settings-menu.md:233-235` promises default theming through
  Millennium and Adwaita-for-Steam.
- `scripts/ojuny-steam-theme.sh:16-18` writes `{"themes":{"activeTheme":...}}`
  only when `config.json` is absent.
- Millennium's `validate_theme()` resets an invalid name to `default` and saves
  it, after which the guard never recovers.
- `scripts/check-desktop-interaction.sh:169-179` enshrines the write-once
  behaviour.
- The script hardcodes `$HOME/.config` and `$HOME/.steam/steam`
  (`ojuny-steam-theme.sh:8-10`), while Millennium honours `XDG_CONFIG_HOME`.

Fix: merge the JSON and set `themes.activeTheme` when it is missing, empty or
`default`, preserving any other value and marking the write so a later user
choice is not overwritten. Use `XDG_CONFIG_HOME`/`XDG_DATA_HOME`. Do not
`mkdir -p ~/.steam/steam`. Extend the check to cover missing, `default`, empty
and user-selected cases.

Status: fix known.

### 10. notes line 27: quake resets position on a second monitor

Verbatim: `quake terminal is positioned centered on the screen, rather than near
the top. it is also behind the bar instead of above. > works on initial spawn,
but re-triggers reset it once you trigger it on a different monitor once.`

Owner: `mango`.

Evidence:
- `client_adapt_geometry_to_monitor` recenters a cross-monitor scratchpad with
  `client_center_geometry(c, c->mon, c->float_geom, 0, 0)`
  (`mango/src/manage/client.c:3316-3328`).
- `offset_y = -100` is applied only at first map (`client.c:1708-1712`) and is
  not stored on the client.
- The template opts in through `scratchpad_cross_monitor = true`
  (`modules/backend/03-desktop/06-mangoworkspaces-backend.nix:10-15`).

Fix: in mango, preserve a custom-positioned client's relative position instead
of recentering. The template-only workaround is `scratchpad_cross_monitor =
false`, which stops the reset but also stops the quake following the focused
monitor.

Status: fix known; needs a decision on the mango change.

### 11. notes line 31: `Super+Shift+O` collides with OCR

Verbatim: `there should be a keybind that the user can use to either toggle
off/on the focused display, or while holding shift, toggle off/on all displays.
> works with super+o, but super+shift+o overlaps with OCR by default.`

Owner: `ojuny-template`.

Evidence:
- OCR: `modules/05-applications/07-screenshot.nix:98-109`, `captureText`,
  SUPER+SHIFT+O.
- Display all: `modules/02-core/03-binds.nix:495-506`, `displayAll`,
  SUPER+SHIFT+O.
- Mango rejects duplicate bindings (`mango/src/config/conflict_check.c:140-204`).
- The display command is correct: `scripts/ojuny-display-toggle.sh:19-41` uses
  `toggle_monitor`.
- Free candidates under SUPER+SHIFT: G, I, J, N, P, U, Y.
- Docs and the test hardcode the current chord:
  `docs/02-settings-menu.md:91-92`,
  `modules/backend/03-desktop/17-desktop-interaction-check.nix:121`.

Fix: move one of the two bindings to a free chord, then update the description,
the docs and the check together.

Status: needs a decision on which binding moves.

### 12. notes line 33: devices plugged in at boot are not automounted

Verbatim: `USB automount does not occur if the device was already plugged in at
boot. it has to be re-plugged to automount.`

Owner: `ojuny-template`.

Evidence:
- `scripts/ojuny-automount-present.sh:16-23` iterates only `.blockdevices[]`
  and never descends into `.children[]`.
- `lsblk --json` nests partitions under `children`, so a partitioned stick's
  top-level disk fails `select(.fstype != "")` and the partition is never
  examined.
- `|| true` at `:26` hides `NotAuthorized` if the logind session is not active.

Fix: add `recurse(.children[]?)` after `.blockdevices[]`, and extend
`modules/backend/03-desktop/17-desktop-interaction-check.nix:125-126` with a
nested fixture. Log or retry mount failures instead of discarding them.

Status: fix known.

### 13. notes line 38: manual TTY path is unusable

Verbatim: `ojuny-manual lists theme selection and keybinds, neither of which are
correct for the w3m version. > unchanged. using it via tty is impossible, needs
to not directly use the generated HTML, we need to have it package the MD
directly, and make the viewer actually have good controls.`

Owner: `ojuny-manual`.

Evidence:
- `flake.nix:57-71` builds mdBook HTML; `:95-96` installs only `book/` and
  `SUMMARY.md`; `bin/ojuny-manual:55-60` runs `w3m index.html`.
- The check harness pins that HTML index (`flake.nix:120-151`).
- Desktop-only content remains in `src/usage/desktop.md:73-96` and
  `src/install/first-boot.md:100-109`.
- Docs conflict: `README.md:11-13` says the package was verified on 2026-11-03;
  `src/offline.md:96-97` says it has not been built or run.

Fix: install `src/` into the package, point the TTY branch at Markdown, replace
the HTML pin in the check, and correct or gate the desktop-only chapters. The
reader is an open choice: `glow`, `mdcat` + `less`, `frogmouth`, `bat`,
`w3m` with a generated no-JS index, `pandoc` text, or an `fzf` chapter picker.
Their navigation and dependency trade-offs differ.

Status: needs a reader decision.

### 14. notes line 42: VSCodium copy cannot be pasted into a terminal

Verbatim: `copy-pasting from vscodium to a terminal is not possible, the data
shows up on the clipboard but cannot be pasted into a terminal.`

Owner: undetermined.

Evidence:
- Autostart runs `wl-clip-persist --clipboard regular`, then two
  `wl-paste --watch cliphist store` watchers
  (`modules/02-core/09-autostart.nix:20-29`).
- DMS also runs its own clipboard daemon
  (`modules/03-desktop/08-clipboard.nix:18-37`), so two history owners coexist.
- `OZONE_PLATFORM` is exported (`09-autostart.nix:37-46`) but is not the
  standard Chromium switch; the VSCodium wrapper adds only `--profile nix`
  (`modules/patches/patch-development.nix:1001-1013`).
- `ojuny-clipboard-doctor` exists and covers owners, types, previews, cliphist,
  client protocols and `WAYLAND_DEBUG` (`scripts/ojuny-clipboard-doctor.sh:8-62`).
- `docs/02-settings-menu.md:165-169` requires the doctor output in both focus
  orders before changing the autostart clipboard commands.
- The doctor does not list DMS.

Candidate causes: XWayland versus native Wayland mismatch; Chromium clearing
its data source on focus loss, with only the regular clipboard persisted; the
DMS daemon racing the watchers; primary selection not persisted.

Fix: none until the doctor output exists. Do not disable portal, sandbox or
paste protection.

Status: needs device data.

### 15. notes line 44: OSK auto, keybind, tray, typing

Verbatim: `OSK - auto show/hide only works with vscodium, not with firefox,
ghostty or libreoffice writer, manual show/hide with the keybind does not work,
tray icon does not work, cannot actually use the OSK > still mostly broken.`

Owner: `ojuny-template` plus device state.

Evidence:
- `auto = false` on the device
  (`modules/07-system/08-accessibility.nix:124`), so `--auto` is never passed.
  The observation cannot come from the current configuration.
- The keybind path is correct: `modules/07-system/08-accessibility.nix:155-166`
  calls `${oskToggle}/bin/ojuny-osk-toggle`; the unit name matches
  `scripts/ojuny-osk-toggle.sh:4,12,14`.
- The unit can start before `WAYLAND_DISPLAY` is imported (`mango/src/main.c:292-327`,
  `:446-449`; `mango/src/config/reapply.c:73-80`), and `Restart = "no"`
  (`08-accessibility.nix:324`) leaves a failed start dead.
- The toggle treats an empty `LoadState` as disabled and never reports a failed
  `systemctl start` (`scripts/ojuny-osk-toggle.sh:4-16`).
- wvkbd signal semantics are confirmed: SIGUSR1 hide, SIGUSR2 show, SIGRTMIN
  toggle (wvkbd v0.21 README). `--auto` requires `zwp_input_method_v2` and only
  fires on text-input-v3 activation.
- Ghostty is a terminal and cannot trigger `--auto`. Firefox and LibreOffice
  depend on their GTK IM path; the docs' blanket statement is narrower than
  upstream capability.
- The tray registers `org.kde.StatusNotifierItem-<pid>-1`
  (`scripts/ojuny-osk-tray.py:113`) and calls the toggle from `Activate`
  (`:79-87`). The test only checks registration and never calls `Activate`
  (`tests/check-osk-tray.sh:58-72`).
- The tray inherits every toggle defect.

Fixes:
- `Restart = "on-failure"` with a short `RestartSec` on the OSK unit.
- Distinguish a failed `systemctl show` from `not-found` and report a failed
  start in the toggle.
- Extend `tests/check-osk-tray.sh` to call `Activate` against a stub toggle and
  assert the marker.
- Correct the `--auto` description in `docs/02-settings-menu.md:327-328` and the
  option text.

Status: template fixes known. Typing and focus need a retest on `810d0ca`.

Device checks:
```sh
systemctl --user status ojuny-osk ojuny-osk-tray --no-pager
journalctl --user -b -u ojuny-osk -u ojuny-osk-tray --no-pager
systemctl --user show-environment | grep -E 'WAYLAND_DISPLAY|XDG_RUNTIME_DIR|DBUS_SESSION_BUS_ADDRESS'
ojuny-osk-toggle; echo $?
busctl --user list | grep -E 'StatusNotifier|ojuny-osk'
wayland-info | grep -E 'virtual_keyboard|input_method|text_input|layer_shell'
```

### 16. notes line 46: auto-rotate missing from the menu

Verbatim: `auto-rotate is missing from the menu.`

Owner: undetermined; likely discoverability.

Evidence:
- `autoRotation` is not in `disabledFeatures`
  (`modules/02-core/01-display.nix:21`) and the `@option` is in a plain set.
- The backend name matches exactly
  (`modules/backend/02-core/01-display-backend.nix:13-15`).
- The pinned GUI renders it as a per-output feature
  (`nix-settings-gui/src/widgets/monitor_features.rs:274-281`), inside the
  selected output's form (`src/widgets/monitors.rs:584-610`, `:973-997`).
- It is not a top-level setting row, which is why it appears absent until the
  output card is selected.

Fix: verify on the device by selecting the output. If it is genuinely absent
there, the defect is in the NSG monitors widget. A top-level row would be a
design change, and distinguishing an explicit `never` from the default `never`
is not currently possible in the monitors contract.

Status: needs device data.

Device checks:
```sh
nix eval .#nixosConfigurations.<host>.config.services.nix-settings-gui.monitors.eDP-1.autoRotation
systemctl --user status ojuny-auto-rotate --no-pager
```

### 17. notes line 53: Obsidian vault names need auto-quoting

Verbatim: `obsidian vault names need to receive auto-quoting treatment.`

Owner: `ojuny-template`.

Evidence:
- The option is a `list` widget with no `itemType`
  (`modules/05-applications/03-office.nix:134-135`).
- Rows serialize through `expr_literal`
  (`nix-settings-gui/src/widgets/editor.rs:743-756`,
  `src/widgets/nix.rs:67-78`), so a bare identifier is written unquoted and
  becomes an undefined variable.
- `itemType = "string"` quotes every row
  (`nix-settings-gui/docs/comment-syntax.md:103`).

Fix: add `itemType = "string"` to the option comment and add a check in
`tests/check-ojuny-apps.py` mirroring `:78`.

Status: fix known.

### 18. notes line 55: sysmon popout too small

Verbatim: `nix settings gui: new sysmon card item needs its settings menu popout
thingie to be *Significantly* larger, it is currently about 2.5 text lines tall
so it's really hard to actually read what's on ther, these items need to
automatically size to fit their content in general.`

Owner: `nix-settings-gui`.

Evidence:
- `src/widgets/grid.rs:695-701` builds a `ScrolledWindow` with
  `min_content_height(120)` and `max_content_height(420)` inside a `Popover`,
  without `propagate-natural-height` or `propagate-natural-width`.
- `content.set_size_request(1, -1)` at `:673` sets no width floor.
- The popover therefore sizes to the 120 px minimum, which is the reported
  height.
- The sysmon editor sets no size of its own
  (`src/widgets/sysmon.rs:214-231`, `:270-366`).
- `05-settings-gui-limitations.md:155-158` requires the dedicated card editor;
  this is not a `dashCards` shape issue.

Fix: enable both propagate flags, keep `max_content_height`, and set a real
width floor. Applies to every dashboard card.

Status: fix known.

### 19. notes line 57: Raven log window exceeds screen, ODT never launches

Verbatim: `raven: the error log window on crash can expand past screen bounds
instead of becoming scrollable. trying to use the office deployment tool from
microsoft causes raven to never even launch now.`

Owner: `ojuny-template` for the dialog and the launch, Raven source for a
snapshot change.

Evidence:
- `scripts/ojuny-raven-report.sh:48` uses `yad --text` with `--width=900
  --height=600`, which are resize requests, not limits.
- `--text` creates a wrapping `GtkLabel` with no scroller. `fold -s -w 4000` at
  `:28` leaves the unbroken `PATH=` value at up to 4000 columns, so the label's
  minimum width is enormous.
- The existing check only asserts the fold width and the file cap
  (`tests/check-raven-report.sh:76-77`, `:89-91`), so the oversized dialog
  passes.
- ODT ranked causes: the MIME gap (the template registers only
  `application/x-ms-dos-executable` at
  `08-appimage-raven-backend.nix:297` and `:521-525`, while nixpkgs resolves
  `.exe` to `application/x-msdownload`, which can point at protontricks); the
  silent pre-guest prefix snapshot (`raven/native/main.cpp:555-570`); or a
  guest-side Click-to-Run failure, which Raven does not document as supported
  (`raven/README.md:98`, `:110-123`).
- Raven exposes `RAVEN_NO_SNAPSHOT` at `native/main.cpp:559` as a diagnostic
  switch.

Fixes:
- Fold at 100, cap the preview at 24 lines and 2048 bytes, and add a check that
  no preview line exceeds 100 columns.
- Register `application/x-msdownload` and write a per-launch log.
- For the snapshot: template diagnostic flag, or a Raven source change that
  moves the snapshot after window creation with progress and a size bound. The
  latter needs approval and a reproducing test.

Status: dialog fix known; ODT needs device data; the snapshot change needs a
decision.

Device checks:
```sh
xdg-mime query filetype /path/to/setup.exe
xdg-mime query default application/x-msdownload
xdg-mime query default application/x-ms-dos-executable
cat ~/.local/state/ojuny/raven/last.log
od -An -tu4 -N4 ~/.local/state/ojuny/raven/last-exit.log
du -sh ~/.local/share/raven/* ~/.local/share/raven/*.snapshots
```

## Documentation conflicts

1. `ojuny-desktop/options.md:24` and `tests.log:17` say the NixOS splash
   service reads `showOnRebuild`. It does not.
2. `ojuny-cli/README.md:196` says the rebuild waits for DMS. The wait tests
   `dms version`, which never contacts the shell.
3. `docs/02-settings-menu.md:339` says the boot pass mounts pre-plugged
   devices. The script cannot see partitions.
4. `docs/02-settings-menu.md:91-92` assigns SUPER+SHIFT+O to display-all while
   `modules/05-applications/07-screenshot.nix` owns it.
5. `docs/02-settings-menu.md:255` says the Raven dialog opens with the log. It
   shows an 8 KiB preview.
6. `docs/05-settings-gui-limitations.md:70-79` and `:128-129` disagree on
   whether the scanner descends into `lib.mkIf`. Neither current item depends
   on the difference.
7. `ojuny-manual/README.md:11-13` and `src/offline.md:96-97` disagree on
   whether the package has been built and run.

## Decisions required

1. Which binding moves off SUPER+SHIFT+O: display-all to a free chord (G, I, J,
   N, P, U, Y) or OCR.
2. Raven dialog: bounded non-selectable preview, or `--text-info` to restore
   scrolling at the cost of selectable text.
3. Manual TTY reader: `glow`, `mdcat`, `frogmouth`, `bat`, generated index for
   `w3m`, `pandoc` text, or an `fzf` chapter picker.
4. Quake: mango source change, or the `scratchpad_cross_monitor = false`
   workaround.
5. Raven prefix snapshot: diagnostic flag only, or a Raven native source change
   with a reproducing test.

## Corrections to the notes' assumptions

- The OSK auto-popup observation cannot come from the current configuration:
  `auto = false` on the device. Retest before changing code.
- The OSK observations were made on `06aff67`, which still ran the `yad` and
  `xembedsniproxy` tray. `810d0ca` is the first build with the native tray.
- The Auto-themed tile persists because the device reverted `nullable` to
  `true` and the merge keeps the device hunk. The template value is already
  correct.
- The USB script and the keybind path are byte-identical between `06aff67` and
  the current template, so those observations are valid for the current code.

## Other current state

- `ojuny-template` has staged deletions for five tracked `__pycache__` files
  and a modified `.gitignore` adding `__pycache__/` and `*.py[cod]`. This is
  uncommitted and unrelated to the items above.
- The template still tracks no `__pycache__` files.
