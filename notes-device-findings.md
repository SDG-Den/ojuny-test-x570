# x570 device findings

Device-side investigation for `notes-for-fixes.md`. Read-only work on the x570
test machine, 2026-11-27. Companion to `notes-for-fixes-analysis.md` (written on
the other device from upstream sources). This file carries device evidence and
corrections; it is the input for template-side fixes.

Every claim is marked **[verified]** (observed on this device or read out of the
exact revision in the store), **[inferred]** (reasoned, not yet confirmed by a
live test) or **[user]** (reported by the device owner).

## Baseline

- **[verified]** Deployed system is profile `system-164`, switched 2026-11-27
  16:36, toplevel `rzvqa2qh...-nixos-system-ojuny-26.11.20261121.2786a2a`.
- **[verified]** Code under test is `810d0ca`. `HEAD` is
  `d5718cae8ad805fabab59d08bd528f4391e09360`; the two later commits
  (`d75d7e8`, `d5718ca`) only add/edit `notes-for-fixes-analysis.md`.
- **[verified]** `git ls-remote origin refs/heads/main` returns the same
  `d5718ca`, and `git rev-list --left-right --count 'HEAD...@{u}'` returns
  `0 0`. The repository is genuinely synced.
- **[verified]** The running settings GUI is PID 146345, started 16:26, exe
  `/nix/store/cmgl2crp...-nix-settings-gui-0.1.0/bin/.nix-settings-gui-wrapped`.
  That binary contains the classifier fix (`git pull refused by` is present).
- **[verified]** Store history of the GUI binary:
  `x9m9m87` (25 Nov 20:28 - 26 Nov 00:05) has the counts-less wording
  "the local branch has diverged from its upstream; merge it, then open the GUI
  again". `sxdavyaa` (26 Nov 00:05 - 26 Nov 18:04), `w607qpn1b`
  (26 Nov 18:04 - 27 Nov 15:19) and `cmgl2crp` (27 Nov 15:19 onward) all carry
  the counts-bearing message **and** the `behind == 0 -> Current` classifier.
- **[verified]** Deployed Raven is the new input:
  `raven-unwrapped-0-unstable-2026-11-27` (the `29fb3f0` lock). Every Raven log
  on disk (`~/.local/state/ojuny/raven/*`) was written by the previous build,
  `de8bf5d5` / `0-unstable-2026-11-19`, before the 16:36 switch.
- **[verified]** `ojuny.binaries.mode = "source"`
  (`modules/07-system/01-configuration.nix:61`), so the GUI, CLI and Raven are
  built from the flake inputs, not from release tarballs.

Device-only settings that still differ from the template:

- **[verified]** `ojuny.accessibility.onScreenKeyboard.auto = false`
  (`modules/07-system/08-accessibility.nix:124`).
- **[verified]** `nullable = true` and `ojuny.style.wallpaperPreset = "retro"`
  (`modules/02-core/05-theme.nix:39-40`).

## New root causes

### A. The splash can never start twice per boot

**[verified]** The rebuild splash "does not happen at all" because systemd skips
the unit, not because of a readiness bug.

Installed unit `/etc/systemd/user/ojuny-login-splash.service`:

```
ConditionPathExists=!%t/ojuny-login-splash.started
ExecStartPre=/nix/store/...-coreutils-9.12/bin/touch %t/ojuny-login-splash.started
ExecStart=.../ojuny-login-splash --seconds 60 --fade-in 0.3 --fade-out 1
Restart=no
TimeoutStopSec=1
```

At the 16:36 switch `journalctl --user` recorded:

```
Condition: start condition unmet at Fri 2026-11-27 16:36:05 CET
  ConditionPathExists=!/run/user/1000/ojuny-login-splash.started was not met
```

`/run/user/1000/ojuny-login-splash.started` was created at 16:10 by the login
start and is never removed, so every later start in the same boot is skipped.
The same marker gates the ready unit
(`ojuny-desktop/modules/nixos/default.nix:246-255`), so the ready service is
skipped too.

Source (`ojuny-desktop`, pin `f5c4bd2`, store
`1y3f98ck...-source/modules/nixos/default.nix`):

- `:228-244` the splash unit; `:235` and `:238` apply the condition and the
  `touch` unconditionally. `cfg.splash.showOnRebuild` is not read in this file.
- `:57-75` `loginSplashReady`, which polls `dms version`.
- `:246-258` the ready unit, gated on the same marker.

### B. DMS readiness must be the mango reload, not `dms version`

**[user]** Readiness used to be measured by mango reloading and triggering an
`exec=` line, because mango reloads when DMS restarts. That behaviour regressed
to a `dms version` poll.

**[verified]** The mango mechanism is exactly that. `reload_config()` calls
`parse_config()` and `reset_option()`
(`mango/src/config/parse_config.c:4498`), and `reset_option()` calls
`run_exec()` at `:2562`. `run_exec()` spawns every `exec` entry (`:347-354`).
`run_exec_once()` is only called from `src/main.c:344-345`, so `execOnce` runs
at startup only while `exec` runs again on every reload.

**[verified]** The template exposes the hook as `desktop.ojuny.mango.exec`
("Run on every reload", `modules/02-core/09-autostart.nix:32-33`), and it is
empty on this device.

**[verified]** `ojuny-cli` waits for DMS by polling `dms version`
(`src/ojuny-cli/lib/subtrees/rebuild.sh:28-39`), and the desktop module does the
same in `loginSplashReady`. `dms version` only prints a version string; it does
not contact the running shell, so it returns success before DMS is usable.

**[inferred]** The reliable signal is the reload itself: DMS restarts, mango
reloads, `exec` re-runs. That is also exactly the interval the splash exists to
cover.

## Item-by-item device evidence

### 1. GUI reports divergence with `ahead 0, behind 0` (notes line 5)

**[verified]** Not reproducible, and not emittable by the deployed build.

- `classify()` is byte-identical in every GUI build since 26 Nov and returns
  `Current` when `behind == 0`, so `"0 0"` can never reach
  `divergence_message()`.
- Reproduced the pull matrix in a scratch repository with the same command the
  GUI runs (`git pull --no-edit --ff-only`):

  | state | rc | error contains `fast-forward` | counts after |
  |---|---|---|---|
  | synced | 0 | no | `0 0` |
  | ahead only | 0 | no | `1 0` |
  | behind, clean | 0 | no | `0 0` |
  | behind, dirty file the merge touches | 1 | **no** | `0 1` |
  | diverged | 128 | yes | `1 1` |
  | remote force-rewritten | 0 | no | `0 0` |
  | untracked file collision | 1 | no | `0 1` |

  Only real divergence produces the counts-bearing "diverged" dialog, and it
  then prints `1 1`, not `0 0`.
- The repository is `0 0` against the live remote right now.
- The reflog shows repeated merges of `origin/base` and several notes commits,
  so history does diverge here, but never with zero counts.
- Likely: the note quotes the old build's counts-less wording plus the owner's
  own `git status` numbers, or is a paraphrase. A screenshot of the exact dialog
  would settle it.

**[verified]** Separate real defect on the same path: the on-open pull is
`--ff-only` and fails whenever the worktree is dirty in a file the incoming
commit touches. That is the normal state of this repo (locally edited notes,
notes pushed from the other device), and the error is
`error: Your local changes to the following files would be overwritten by merge`
with counts `0 1`.

Proposal:

- fetch before counting, then print the ref, the fetched tip and a timestamp;
- separate "local changes block the pull of N commits" from "diverged";
- keep the classifier.

### 2. Raven Office installer exits 255 (notes line 7)

**[verified]** `~/.local/state/ojuny/raven/last-exit.log` is 4 bytes,
`od -An -tu4 -N4` = `4294967295` = `0xFFFFFFFF` = guest `-1`. The wrapper reports
it as 255.

**[verified]** `last.log` tail:

```
Native process exited with status 4294967295
Exit status: 255
Guest exit code: <4 replacement chars>
```

The garbage after "Guest exit code:" is the wrapper `cat`-ing a binary file.

**[verified]** Five failure logs exist between 16:12 and 16:14, all from the old
Raven, all `-1`. `ojuny crashes` lists only coredumps (oldest from September),
so Raven failures never appear there.

**[verified]** The current failure report's `--- sandbox refusals ---` section
contains Notepad++ refuse lines dated 2026-11-25, two days before the run. The
append is unfiltered.

Proposal: as in `notes-for-fixes-analysis.md` (decode with `od`, preview from
`--- output ---`, filter sandbox lines by program and launch time, write a
timestamped running log, list it in `ojuny crashes`).

### 3. Wallpaper previews, Auto tile (notes line 10)

**[verified]** `nix eval .#nixosConfigurations.ojuny.config.desktop.ojuny.wallpaper`
returns `preset: "retro"`, `image: null`, and a `presets` map whose paths all
resolve into `/nix/store/j76qfxq...-ojuny-wallpapers/user/builtin/*.png`.
`modules/02-core/wallpapers` contains only `.gitkeep`.

So the data the GUI needs exists and the eval works; the missing strip is a GUI
metadata/realise problem, not missing wallpaper data. The extra Auto tile is the
device divergence (`nullable = true`), which the template already has as `false`.

### 4. OSK mouse focus (notes line 13)

**[verified]** Current state: `ojuny-osk.service` is `failed (Result: signal)`,
`MainPID` killed with SIGKILL at 21:41:40. That was the owner killing wvkbd
while testing the opencode selection problem, not a crash. `Restart=no`
(`modules/07-system/08-accessibility.nix:324`), so it stays dead until started.

**[verified]** `ojuny-osk-toggle` starts the unit when `MainPID` is 0 and sends
`SIGRTMIN` otherwise (`scripts/ojuny-osk-toggle.sh:4-16`); it never reports a
failed start.

**[verified]** `onScreenKeyboard.auto = false`, so `--auto` is never passed.

A retest of mouse focus and typing needs the unit running again.

### 5. Login splash (notes line 16)

See root cause A, and root cause B for the readiness half. Additionally
**[verified]** the rebuild splash is spawned by `ojuny-cli` as a private process
(`rebuild.sh:60-86`), not through the unit, so the unit's marker/condition
problem does not affect it, while the ready unit does not run for it at all.
`ojuny-cli` also uses the `dms version` check (`:28-39`).

Proposal:

- gate the splash unit's `ConditionPathExists` and `ExecStartPre` on
  `!cfg.splash.showOnRebuild` (or clear the marker for rebuild starts);
- stop using `dms version`; add a reload marker and use it in both
  `loginSplashReady` and `ojuny_wait_for_dms`;
- have the CLI restart the unit instead of spawning a private splash.

Concrete reload-marker design, matching the pre-regression behaviour:

1. Template adds one entry to `desktop.ojuny.mango.exec` that stamps
   `$XDG_RUNTIME_DIR/ojuny-shell-reloaded` (epoch nanoseconds).
2. `ojuny_wait_for_dms` records the stamp, runs the reload command, then waits
   for the stamp to advance instead of polling `dms version`.
3. `loginSplashReady` waits for the same advance, then calls
   `ojuny-login-splash --quit`.

The startup reload also stamps the file (`reset_option()` runs at startup), so
the rebuild path must compare against a value recorded *before* the DMS restart,
not merely wait for the file to exist.

### 7. Flatpak startup (notes line 20)

**[verified]** Sandbox startup is not the slow part:

| command | time |
|---|---|
| `flatpak run --command=sh org.mozilla.Thunderbird -c true` | 89 ms |
| `flatpak run --command=sh com.github.tchx84.Flatseal -c true` | 794 ms |
| `flatpak run --command=sh org.mozilla.Thunderbird -c 'ls /app/lib'` | 120 ms |
| `flatpak run --command=sh org.mozilla.Thunderbird -c 'fc-list'` | 1219 ms |

Thunderbird profile is 29 MB, host font set is 349 fonts. Portals are all
running. So the 10 s is app startup, not the sandbox, the portal or the font
directory as a whole. Next step is timing a real launch, not a template change.

### 9. Steam theming (notes line 25)

**[verified]** `~/.config/millennium/config.json` exists and has no `themes`
key. That is exactly the state the write-once guard leaves behind:

```sh
if [ ! -f "$config_file" ]; then
  printf '{"themes":{"activeTheme":"%s"}}\n' "$theme_name" >"$config_file"
fi
```

Millennium created the file first, so `activeTheme` is never set.

Proposal: merge the JSON, set `themes.activeTheme` when it is missing, empty or
`default`, keep any user choice.

### 10. Quake position (notes line 27)

**[verified]** `scratchpad_cross_monitor = true` is generated
(`modules/backend/03-desktop/06-mangoworkspaces-backend.nix:13`). The mango
behaviour described in the analysis applies unchanged; no new device data.

### 11. `Super+Shift+O` (notes line 31)

**[verified]** In the generated `~/.config/mango/ojuny.toml` there is exactly
one binding on that chord:

```
301:"SUPER+SHIFT+O" = "spawn,ojuny-capture-text"
292:"SUPER+O" = "spawn,/nix/store/149855...-ojuny-display-toggle/bin/ojuny-display-toggle focused"
```

The `displayAll` row (`modules/02-core/03-binds.nix:495-506`,
`ojuny-display-toggle all`) is **absent**. So the conflict is currently resolved
by silently dropping display-all, not by rejecting it. Either way the feature
the note asks for does not exist on the device.

Proposal: move one binding to a free chord and make the generator report
duplicate chords instead of dropping one silently.

### 12. USB automount at boot (notes line 33)

**[verified]** Two independent causes.

1. `lsblk --json` nests child partitions. The script selects only
   `.blockdevices[]` and requires a non-empty `fstype`
   (`scripts/ojuny-automount-present.sh:16-23`), so a partitioned stick is
   dropped. On this device: `sdg` is `type=disk`, `tran=usb`, `fstype=null`,
   with 4 children.
2. The stick was already mounted at 16:10 by the greeter session:
   `/run/media/greeter/Data`, exfat, `uid=992,gid=989`. The user service
   `ojuny-automount-present` ran at 16:10:44 and finished with nothing to do.

Proposal: recurse into `children`; treat a mount owned by another uid as "not
mounted for this user" and remount at login; log mount failures instead of
`|| true`.

### 13. Manual TTY reader (notes line 38)

**[verified]** `ojuny-manual-0.1.0` installs `bin/ojuny-manual` (a generated
wrapper), `share/ojuny-manual/book` and `SUMMARY.md` only. The wrapper execs
`.ojuny-manual-wrapped` with `w3m` on `PATH`. There is no Markdown payload to
read, so the analysis's "package the Markdown" proposal is the right one.

### 14. VSCodium copy to terminal (notes line 42)

**[verified]** `ojuny-clipboard-doctor` on this device:

- every VSCodium process is reported with protocol `x11`, i.e. it is an
  XWayland client (`--ozone-platform-hint=auto`, no `--ozone-platform=wayland`
  on the main process);
- only `wl-clip-persist --clipboard regular` and two
  `wl-paste --type ... --watch cliphist store` watchers run; DMS's own clipboard
  daemon is **not** running;
- at test time the X11 and Wayland clipboard previews are identical (`nk`), so
  bridging works while the source is alive.

That points at XWayland/Chromium selection ownership on focus loss, not a
missing bridge and not a second history owner.

Proposal: launch VSCodium with `--ozone-platform=wayland` in the wrapper and
retest; if it persists, capture `WAYLAND_DEBUG=1` in both focus orders (the
doctor supports it).

### 15. OSK auto, keybind, tray, typing (notes line 44)

**[verified]** `auto = false`, so the auto-popup observation cannot come from
this configuration. The tray is registered:
`org.kde.StatusNotifierItem-242794-1` appears in `busctl --user list` and in the
StatusNotifierWatcher's registered items. The tray unit exited once at 16:10:59
(14 s after start) and was started again at 16:22 and 16:36; the current
invocation is healthy.

The tray only calls `ojuny-osk-toggle` on `Activate`
(`ojuny-osk-tray.py:79-87`), so it inherits every toggle defect. The test
harness only checks registration (`tests/check-osk-tray.sh:58-72`).

Proposal: `Restart=on-failure` on the OSK unit, report failed starts in the
toggle, extend the tray test to call `Activate`, correct the `--auto` text.

### 16. Auto-rotate missing from the menu (notes line 46)

**[verified]** Not a defect. The unit is only created when an output is
`"automatic"` (`modules/backend/02-core/01-display-backend.nix:126`), and all
outputs are `"never"`. `services.nix-settings-gui.monitors.DP-1.autoRotation`
evaluates to `"never"`. NSG renders the control inside the selected output card.
No `ojuny-auto-rotate.service` exists on the device, correctly.

### 17. Obsidian vault names (notes line 53)

**[verified]** `modules/05-applications/03-office.nix:134-135` is a `list` widget
with no `itemType`, so rows are written as bare identifiers. Template-side fix
as in the analysis.

### 18. Sysmon popout size (notes line 55)

**[verified]** In the pinned GUI source (`76b1856`, store `qm1v5dgm...-source`),
`src/widgets/grid.rs`:

- `:673` `content.set_size_request(1, -1)`;
- `:695-701` `ScrolledWindow` with `min_content_height(120)`,
  `max_content_height(420)`, no `propagate-natural-height` or
  `propagate-natural-width`.

That is the 2.5-line popover. The analysis's fix is correct.

### 19. Raven log window, ODT (notes line 57)

**[verified]** Dialog: `yad --text` with `--width=900 --height=600`, which are
resize requests, not limits. The preview is `head -c 8192` of a 19,835-byte
report; `--- output ---` starts at byte 4734, so it is inside the preview, but
the unbroken `PATH=` line dominates the layout. The report also carries the
stale Notepad++ refusals from 2026-11-25.

**[verified]** MIME detection of the ODT setup file:

```
xdg-mime query filetype .../officedeploymenttool_20527-20150.exe
  -> application/vnd.microsoft.portable-executable
xdg-mime query default application/vnd.microsoft.portable-executable -> (none)
xdg-mime query default application/x-msdownload                     -> (none)
xdg-mime query default application/x-ms-dos-executable              -> ojuny-raven.desktop
```

**[user]** The file manager still offers "open with Raven" and Raven used to
open on double-click, so MIME is **not** the cause of the ODT failure. Register
`application/vnd.microsoft.portable-executable` and `application/x-msdownload`
as hardening, but do not treat it as the fix.

**[verified]** ODT history: ten snapshots exist under
`~/.local/share/raven/default.snapshots/`, one per launch named
`...-install-officedeploymenttool_20527-20150` (first 1.3 MB, later ones 208 KB,
97 MB total). Raven launched five times in two minutes and exited `-1` each
time. All of that was the old build.

**[user]** The original freeze happened when selecting text in the error dialog;
the current `yad --text` dialog has no selection surface, which is the intended
mitigation. Do not add `--text-info` back without a decision.

**Retest ODT on the current build before changing Raven.** The silent prefix
snapshot is still the leading hypothesis for "never launches", but the new
revision has not been tried.

### Round 6a. `^[[26~` stream during a rebuild

**[verified]** `^[[26~` is ghostty's F14 encoding (`\x1B[26~`, ghostty
`src/input/function_keys.zig`).

**[verified]** The only F14 source on this system is the G13. The driver's
generated bindings map the stick directly to the F13-F16 range:

```
~/.config/g13/bindings-0.properties
G37=p,k.183   # stick-left  -> KEY_F13
G38=p,k.184   # stick-right -> KEY_F14
G36=p,k.185   # stick-up    -> KEY_F15
G39=p,k.186   # stick-down  -> KEY_F16
```

`/proc/bus/input/devices` shows `Name="G13"`,
`Sysfs=/devices/virtual/input/input30`, handlers `event26 js0`, and the mango
binds in `modules/patches/patch-logitech-g13.nix:422-425` match those codes
(`"code:184" = "focusdir,right"` in `ojuny.toml:360`).

**[verified]** The debounce filter is not doing its job: `g13-filter.py`
(PID 3323) holds `/dev/input/event26`, but there is no `G13 Filtered` uinput
device in `/proc/bus/input/devices`, and the process is sitting in
`synchronize_rcu` (device close/destroy). The 0.3 s lockout at
`patch-logitech-g13.nix:1387-1445` therefore never applies to a real stick
event.

**[verified]** Why a terminal and not other apps: mango disables **all**
bindings when the focused surface holds a keyboard-shortcuts inhibitor:

```c
/* mango/src/input/keyboard.c:561-563 */
if (is_keyboard_shortcut_inhibitor(
        server.seat->keyboard_state.focused_surface)) {
    return false;
}
```

`allow_shortcuts_inhibit = 1` (`~/.config/mango/ojuny.toml:3`, template
`modules/backend/03-desktop/02-mangosettings-backend.nix:25`). While an
inhibitor is active, F14 is forwarded to the client
(`keyboard.c:744-760`). Ghostty turns it into `ESC[26~` and repeats it
client-side while the stick is held. TUIs that consume keys themselves (micro,
opencode) and GUI apps never display it, which is exactly the "only in ghostty"
pattern.

**[verified]** `repeats = 0` on the G13 rows is inert: no `repeats` key is
emitted into `ojuny.toml`, and this mango has no per-bind repeat option. Held
binds are repeated by mango's own `key_repeat_source`
(`keyboard.c:690-700`).

Live tests, no rebuild needed:

```sh
mmsg dispatch setoption,allow_shortcuts_inhibit,0   # then retry the rebuild window
# or unplug the G13 and retry
```

Proposal:

- fix or remove `g13-filter.py` so the stick lockout actually runs;
- do not let a client inhibitor silently disable global (G13) binds, or at
  least expose that state in the bar/status;
- log "Adding keyboard shortcuts inhibitor" at a level visible in the journal;
- consider sentinel codes for the stick that are harmless if they leak.

Sub-question: whether the repeated `Dependency graph` lines are part of the same
event. NOM 2.2.0 has no `26~` byte in its binary, so they are probably full
redraws triggered by focus/resize (SIGWINCH), independent of the F14 stream.

### Round 6b. Opencode text selection

**[verified]** The owner killed wvkbd specifically to test this, and the kill at
21:41:40 is that test. No conclusion yet. The clipboard doctor shows VSCodium as
an XWayland client, and the general GTK/Wayland selection-loss issue is still
unexplained. Needs a retest result with wvkbd stopped.

## Agent-harness permission bug (blocking, template-side)

**[verified]** In `modules/patches/patch-ojuny-agent.nix:340-350`, every file
action starts with a blanket deny:

```nix
fileRules = action: [
  (deny action "*")
  (ask action "${flakeRoot}/**")
  (deny action "${flakeRoot}/flake.lock")
  ...
];
```

**[verified]** The evaluator applies the **first matching rule**, so the blanket
deny wins and the `ask` line is unreachable. Result: the `ojuny-agent` role
cannot edit, write or patch any file at all, and gets an immediate
`permission.rejected` with no approval prompt. This was observed twice while
trying to create this file. The owner reports the same class of bug previously
broke `ojuny-assist` shell commands.

**[inferred]** `readRules` has the mirror-image bug: `(allow "read" "*")` is
first, so the later `*.env`, `*.age`, `*.key` and `*secret*` denies are
unreachable. That should be checked and fixed at the same time.

Fix: put specific rules first and the blanket rule last, e.g.

```nix
fileRules = action: [
  (deny action "flake.lock")
  (deny action "modules/00-hardware.nix")
  (deny action "modules/facter.json")
  (deny action "modules/backend/00-hardware-quirks.nix")
  (deny action "modules/00-user.nix")
  (deny action "modules/00-configuration.nix")
  (deny action "modules/00-host.nix")
  (ask action "**")
  (deny action "*")
];
```

and the same reordering for `readRules`, with the specific denies before the
blanket allow.

One more thing to verify while reordering: the permission log in
`~/.local/share/opencode/log/opencode.log` shows the evaluated pattern as
**relative** (`pattern=devnotes/filestructure.md` matched `action.pattern=*`).
If that is still true for this build, absolute `${flakeRoot}/**` patterns will
not match after the reorder either, and the rules need the session-relative form
(or the harness needs to match both forms).

This file was written through an explicitly approved shell redirection as a
one-off workaround for the above; the intended path is the normal edit approval.

## Proposed template changes, in priority order

1. **Agent permissions**: fix the rule order (blanket deny last) so flake edits
   prompt instead of failing; audit `readRules` for the same mistake.
2. **Splash**: gate the unit's `ConditionPathExists`/`ExecStartPre` on
   `!showOnRebuild`; replace both `dms version` readiness checks with the mango
   reload marker; make the CLI use the unit instead of a private process.
3. **Reload marker**: restore the `desktop.ojuny.mango.exec` stamp and wait for
   it to advance (`reset_option()` -> `run_exec()` is the mechanism).
4. **G13/F14**: repair the stick filter, expose inhibitor state, log inhibitor
   add/remove.
5. **GUI**: fetch-before-count plus distinct dirty-worktree wording; wallpaper
   loading states; popover propagate flags; commit dates in the scan.
6. **Raven**: `od` decode, output-section preview, per-launch log, MIME
   hardening, then a real ODT retest on the new build.
7. **Small**: Steam config merge, Obsidian `itemType`, display-all chord,
   automount recursion, OSK restart policy, VSCodium Ozone flag.

## Open questions from this device

- Exact text of the GUI git dialog the next time it appears (screenshot), to
  close item 1 for good.
- Does `allow_shortcuts_inhibit = 0` stop the F14 stream?
- ODT on the current Raven build.
- Opencode selection with wvkbd stopped.

## Harness notes (this session)

- `python3` and `strings` are not on the sandbox `PATH`; both are reachable with
  `nix shell nixpkgs#python3 nixpkgs#binutils -c ...`.
- The `write` tool is blocked by the permission-order bug above; shell
  redirection worked with explicit approval. `/tmp/opencode` is denied as
  `external_directory`, consistent with the rules.
- `nix flake archive` is auto-backgrounded and its output arrives only after a
  completion notification.
- `notes-for-fixes.md` claims shell `cat`/`head`/`tail`/`grep` are blocked; they
  are in fact allowed.
- No read access to evdev (the G13 device is grabbed) or to process
  environments, so the F14 check used `/proc/bus/input/devices`,
  `/proc/<pid>/fd`, and the driver's generated bindings.

## Commands used (read-only unless noted)

```sh
git status -sb; git rev-list --left-right --count 'HEAD...@{u}'
git ls-remote origin refs/heads/main
for g in /nix/var/nix/profiles/system-*-link; do ...; done   # generation -> GUI store path
grep -a -F 'git pull refused by' /nix/store/*/bin/.nix-settings-gui-wrapped
od -An -tu4 -N4 ~/.local/state/ojuny/raven/last-exit.log
grep -bo -- '--- output ---' ~/.local/state/ojuny/raven/*-failure.log
systemctl --user status ojuny-osk ojuny-osk-tray ojuny-login-splash
journalctl --user -b -u ojuny-login-splash --no-pager
lsblk --json -o NAME,PATH,TYPE,TRAN,RM,FSTYPE,MOUNTPOINTS | jq ...
findmnt -T /run/media/greeter/Data -o TARGET,SOURCE,FSTYPE,OPTIONS
ojuny-clipboard-doctor
xdg-mime query filetype ~/Downloads/officedeploymenttool_20527-20150.exe
xdg-mime query default application/vnd.microsoft.portable-executable
nix eval --json .#nixosConfigurations.ojuny.config.desktop.ojuny.wallpaper
nix eval --json .#nixosConfigurations.ojuny.config.services.nix-settings-gui.monitors
grep -n 'code:184' ~/.config/mango/ojuny.toml
busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher \
  org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems
```
