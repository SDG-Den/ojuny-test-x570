# Device tests (round 6)

These tests run on the x570 and are handed to `ojuny-agent` through GitHub.
Companion plan: `2026-11-27_PLAN-round-6-device-fixes.md`.

Prerequisite: T0 must pass first. Until the agent permission order is fixed,
the agent cannot edit, write or patch any file, so it cannot record results
in this repository.

Conventions:

- `FLAKE=/home/den/repos/nix-flake`, which is the same directory as
  `/home/den/repos/ojuny-deployed-test-devices/ojuny-test-x570` on this
  device.
- Commands marked **owner** mutate runtime state (`systemctl start|stop`,
  `mmsg dispatch`) and are denied to `ojuny-agent`; the device owner runs
  them.
- Everything else is read-only and can be run by the agent.
- Record each test with the block at the end and append it under "Results".

## T0. Agent permissions (blocking)

Purpose: prove the patched rule order prompts for flake edits, denies
generated files and secrets, and still allows read-only shell commands.

Run after the patched generation is active and a new agent session is open.

1. **Edit prompt.** Ask the agent to edit `modules/notes-scratch.md` (create
   it if the patch allows; a normal flake path). Expected: an approval
   prompt. Failure: immediate `permission.rejected` with no prompt.
2. **Generated file.** Ask to edit `flake.lock`. Expected: denial without a
   prompt.
3. **Secret read.** Ask to read `.env`. Expected: denial.
4. **Shell deny.** Ask to run `sudo -n true`. Expected: denial.
5. **Read-only shell.** Ask to run `git status -sb`. Expected: allowed, no
   prompt.
6. **Relative path.** Repeat step 1 while pointing at the same file with a
   relative path (`modules/notes-scratch.md`). Expected: same approval
   prompt.

Record `~/.local/share/opencode/log/opencode.log` lines for steps 1, 2, 4
and 6, including the evaluated pattern. That decides item 11 of the plan
(absolute versus relative matching).

Pass: steps 1, 5 and 6 prompt or allow as stated; steps 2, 3 and 4 deny
without a prompt.

## T1. NSG divergence dialog

Purpose: capture the exact text and the launched binary (plan item 1).

1. Open the settings GUI with auto-sync on.
2. If a git dialog appears, copy its first line verbatim.
3. While it is open:

```sh
pid=$(pgrep -n nix-settings-gui)
readlink -f /proc/$pid/exe
grep -a -F 'ahead/behind' /proc/$pid/exe
grep -a -F 'git pull refused by' /proc/$pid/exe
git -C $FLAKE status -sb
git -C $FLAKE rev-list --left-right --count 'HEAD...@{u}'
git -C $FLAKE config --get-regexp '^branch\.'
```

Pass: the dialog text, the exe path, the two binary strings, and the git
counts are recorded together. A missing string means the launch path is
stale.

## T2. OSK

Purpose: separate a dead unit from a focus defect (plan items 2, 21, 22, 23).

1. **owner** `systemctl --user start ojuny-osk`
2. `systemctl --user status ojuny-osk --no-pager`
3. `pgrep -a wvkbd`
4. Press `Super+Alt+O` twice. Record whether the keyboard appears and hides.
5. Click the tray icon. Record whether it toggles.
6. With Ghostty focused, type on the keyboard. Record whether text arrives.
7. Repeat step 6 in Firefox and in LibreOffice Writer.
8. With the keyboard visible, click a key and then type on the physical
   keyboard. Record whether focus stays in the application.
9. `journalctl --user -b -u ojuny-osk -u ojuny-osk-tray --no-pager`

Note: `onScreenKeyboard.auto = false`, so auto show/hide is expected not to
run. Do not test `--auto` until it is enabled from Settings > Accessibility.

Pass: the unit is `active`, wvkbd is running, the keybind toggles, the tray
toggles, and typing reaches the focused application.

## T3. Raven ODT

Purpose: decide whether the new Raven launches the Office deployment tool
(plan item 3).

1. `xdg-mime query filetype ~/Downloads/officedeploymenttool_20527-20150.exe`
2. Double-click the file. Wait 60 seconds, then record whether a window
   appears.
3. Run it explicitly: `ojuny-raven ~/Downloads/officedeploymenttool_20527-20150.exe`
4. `ls -lt ~/.local/state/ojuny/raven | head`
5. `cat ~/.local/state/ojuny/raven/last.log`
6. `od -An -tu4 -N4 ~/.local/state/ojuny/raven/last-exit.log`
7. `du -sh ~/.local/share/raven/default.snapshots`

Record: whether `--- output ---` appears, the guest exit code, the elapsed
time before the first window, and the snapshot size.

## T4. Flatpak launch

Purpose: separate sandbox startup from application startup (plan item 4).

```sh
time flatpak run --command=sh org.mozilla.Thunderbird -c true
time flatpak run org.mozilla.Thunderbird
time flatpak run --command=sh com.github.tchx84.Flatseal -c true
time flatpak run com.github.tchx84.Flatseal
journalctl --user -b -u 'xdg-desktop-portal*' --no-pager
```

Pass: the four times are recorded. If the app launch is much slower than the
`sh -c true` baseline, the cause is inside the application, not the sandbox.

## T5. Auto-rotate

Purpose: confirm whether the control is missing or merely per-output (plan
item 5).

```sh
nix eval --json .#nixosConfigurations.ojuny.config.services.nix-settings-gui.monitors
systemctl --user status ojuny-auto-rotate --no-pager
```

Then open Settings > Display, click the connected output card, and record
whether an "Auto rotation" dropdown is present. Screenshot it.

## T6. Opencode selection

Purpose: decide whether the selection loss involves wvkbd (plan item 6).

1. **owner** `systemctl --user stop ojuny-osk`
2. Try to select text in opencode. Record whether selection and copy work.
3. `ojuny-clipboard-doctor`
4. **owner** `systemctl --user start ojuny-osk`
5. Repeat step 2 with wvkbd running.

## T7. VSCodium to terminal paste

Purpose: verify the Ozone change (plan item 28). Run only after the wrapper
change is deployed.

1. `readlink -f /proc/$(pgrep -n codium)/exe`
2. Copy text in VSCodium.
3. Paste in Ghostty with `ctrl+shift+v`. Record.
4. `ojuny-clipboard-doctor` with VSCodium focused, then again with Ghostty
   focused.
5. `wl-paste --list-types` in both focus states.

## T8. G13 F14 stream

Purpose: confirm the shortcut-inhibitor path (plan item 41).

1. Open a ghostty window and hold the G13 stick until `^[[26~` appears.
2. **owner** `mmsg dispatch setoption,allow_shortcuts_inhibit,0`
3. Repeat step 1. Record whether the stream stops.
4. **owner** restore the option to its configured value.
5. Unplug the G13 and repeat step 1. Record.

## T9. Wallpaper strip

Purpose: confirm whether the presets exist and what the GUI shows (plan item
17).

```sh
nix eval --json .#nixosConfigurations.ojuny.config.desktop.ojuny.wallpaper
```

Check that every preset path exists. Open Settings > Wallpaper and record:
number of tiles, whether an "Auto-themed" tile appears, and any caption or
status text.

## T10. Wallpaper Auto tile after reconciliation

Purpose: verify plan item 33.

Open Settings > Wallpaper and record whether an "Auto-themed" tile is
present. Expected after reconciliation: absent.

## Handoff state

Source changes ready for the next device build:

- Agent permissions: rule order, generated-file paths, shell denies, precedence
  gate (plan items 7 to 12).
- OSK: restart policy, toggle error reporting, tray Activate test, `--auto`
  wording (items 21 to 24).
- USB automount: child partitions and foreign-uid remounts (item 25).
- Steam theme: JSON merge and XDG roots (item 26).
- Obsidian quoting (item 27) and VSCodium Ozone (item 28).
- Splash: `showOnRebuild` conditions and reload-marker readiness (items 18 to
  20).
- Raven: exit decode, output preview, sandbox filter, running log, dialog caps,
  MIME registration (items 34 to 39).
- Settings GUI: fetch before counting and the dirty-worktree message (item 13);
  sysmon popover natural size (item 16).

Retest order after the build: T0 first, then T2, T3, T7 and T9. T0 is blocking.

Still open in source: flake-input scroll, commit dates and wallpaper loading
(items 14, 15, 17); the display chord (29 and 30); the manual reader (32); the
mango quake and inhibitor changes (31 and 41); the G13 filter (40); the device
theme line (33).

## T11. Splash lifecycle

Purpose: verify the `showOnRebuild` condition and the reload marker (plan
items 18 to 20).

1. `systemctl --user show ojuny-login-splash -p ExecMainStartTimestamp`
2. `ls -l /run/user/$(id -u)/ojuny-login-splash.started`
3. `ls -l /run/user/$(id -u)/ojuny-shell-reloaded`
4. With `desktop.ojuny.splash.showOnRebuild = false`, run a rebuild through
   `ojuny rebuild`. Record whether the splash appears and whether the start
   timestamp changes.
5. Set `showOnRebuild = true`, rebuild, and record the same.
6. While the splash is visible, trigger a DMS reload and record whether the
   splash quits when `ojuny-shell-reloaded` changes.

Expected: no splash on rebuild when the switch is off; a splash on rebuild
when it is on; the splash quits after the reload marker advances. Record the
unit journal with `journalctl --user -u ojuny-login-splash -u ojuny-login-splash-ready -b`.

## Recording block

Append results under a `## Results` section:

```
### T<n>. <name>
- Date:
- Generation / build:
- Commands:
- Observed:
- Expected:
- Verdict: pass | fail | inconclusive
- Log excerpt:
```

## Results

Run 2026-11-28 on system-166 (`/nix/store/mmnw8h9c...-nixos-system-ojuny`),
build `2110fe9` plus the `355ade1` lock bump. Owner-executed steps are marked.

Two earlier notes in this file are superseded and should not be acted on:

- the 00:08 permission render (`nhn15cyn`) inverted the rule order, removed the
  Edit tool and made `.env` readable; the 00:15 render (`v0jw2xwy`) fixed both;
- the first T11 conclusion ("marker has no consumer") was read from stale
  sources; the deployed CLI and splash-ready script both consume the stamp.

### T0. Agent permissions — pass, one design decision

- 1. absolute flake edit: prompted, applied.
- 2. `flake.lock`: denied, no prompt.
- 3. `.env` read: denied, no prompt.
- 4. `sudo -n true`: denied, no prompt.
- 5. `git status -sb`: allowed, no prompt.
- 6. relative path edit (`repos/nix-flake/tests.md`): prompted, applied.

Open decision: the owner states the intended policy is **allow inside the
flake** so the role is fully agentic. The installed `docs/11-agent.md:51`, the
patch system prompt (`patch-ojuny-agent.nix:256-262`) and this test file all
say `ask`. The patch is device-only (absent from `origin/base`), so the choice
must be made in the registry and the docs updated to match.

Instrumentation gap: opencode 2.3.0 writes no `message=evaluated permission=`
lines, so the evaluated pattern cannot be recorded.

### T1. NSG divergence dialog — root cause identified

- Dialog: `/home/den/repos/nix-flake: git pull refused by origin/main:
  git pull --no-edit --ff-only: fatal: cannot fast-forward to multiple branches`
- That is the new `RemoteState::Current` branch of `pull_error`, so the fetch
  and classifier run and agree the repo is current; git itself refused.
- Reproduced in a scratch repo: the error needs **two** `branch.main.merge`
  refs. With one ref, the GUI's exact `fetch` then
  `pull --no-edit --ff-only` sequence succeeds, including with a dirty tree and
  with `origin/base` present.
- Repo at capture: one merge ref, config mtime 2026-11-25, no `MERGE_HEAD`;
  `.git/FETCH_HEAD` has `main` for-merge and `base` not-for-merge.
- Next: capture `git config --get-all branch.main.merge` while the dialog is
  up. Proposal: include that output and the resolved `@{u}` in the message.

### T2. OSK — keybind and tray pass, typing fails

- Super+Alt+O and the tray icon toggle the keyboard.
- Typing does not reach the application, and the keyboard does not react to
  clicks at all.
- Unit active/running, wvkbd `-H 300 -L 200`, journal clean.
- Owner confirms the keyboard **is visible on screen** when toggled. So it is
  not a hidden surface; the primary defect is that pointer input never reaches
  it, and typing fails because no key is ever emitted.
- `mmsg get all-layers` with the keyboard **hidden** showed 21 surfaces and no
  wvkbd. With it **open** it shows 22 and includes `wvkbd`:
  `{"monitor":"HDMI-A-1","layer":"overlay","name":"wvkbd"}`.
- mango reserves its space: the focused ghostty on HDMI-A-1 is 1912x838 while
  the output work area is 1912x1038, i.e. exactly the 200 px landscape height.
  So the surface is mapped, sized and known to the compositor.
- The keyboard is an `overlay` layer on **HDMI-A-1 only**, so it does not
  follow the focused output.
- Two DMS overlay surfaces are listed after wvkbd on the same output:
  `dms:tooltip` and `dms:context-menu`. mango composites layers with
  `wlr_scene` (`manage/layer.c:485`), so those nodes are above the keyboard; a
  closed-but-mapped DMS overlay with a non-empty input region is the remaining
  candidate for the swallowed clicks.
- Decisive test (owner): `dms kill`, then click the keyboard. If clicks land,
  the DMS overlay stack is the cause; if not, it is wvkbd's input region.
- Also record whether keys highlight on hover, which separates "no pointer at
  all" from "pointer arrives but not dispatched".

### T3. Raven ODT — launches, decode fixed; copy dialog broken

- Double-click launches Raven; no freeze.
- `20261128-002233-failure.log` and `20261128-002535-failure.log` show
  `Guest exit code: 4294967295 (signed -1)`. The `od` decode and the
  `--- output ---` section both work. Raven is `0-unstable-2026-11-27`
  (`e0427278`).
- Bug: `scripts/ojuny-raven-report.sh:66` opens
  `yad --text="Report copied to the clipboard." --timeout=2 --no-buttons`,
  which has no way to close, and it replaces the report window. Proposal:
  `notify-send`, or an OK button, and never replace the report dialog.
- The Office deployment tool itself exits -1; treat it as unsupported input.

### T4. Flatpak — app-side

- Sandbox `sh -c true`: Thunderbird 150 ms, Flatseal 892 ms.
- Real Thunderbird launch: 8 s (owner).
- The delay is inside the application, not the sandbox or portals.

### T5. Auto-rotate

- `ojuny-auto-rotate`: `not-found` (correct; no output is `automatic`).
- `monitors.*.autoRotation`: DP-1, DP-2, HDMI-A-1 all `never`.
- GUI output-card check still open.

### T6. Opencode selection — pass

- Selection works again.

### T7. VSCodium paste — fail

- The wrapper now passes `--ozone-platform=wayland`, and the main process has
  `DISPLAY` unset, but pasting into a terminal still fails.
- The cmdline reads `--profile --ozone-platform=wayland -n nix`, i.e. the flag
  lands between `--profile` and its value. Check the wrapper argument order.

### T8. G13 stick — no action

- The stick does nothing.
- `allow_shortcuts_inhibit = 1`; G13 present (`event26`, `js0`);
  `G13 Filtered` absent; `g13-filter.py` running.
- Needs a retest with the filter stopped, plus a decision on intended behaviour.

### T9/T10. Wallpaper — long-standing, not a lock-bump regression

- Observed: no previews, live-apply does nothing, no wallpaper applied, DMS
  default shown.
- Owner: broken since deployment, so **not** caused by the recent lock bump;
  do not revert on that basis. Possible origin: the attempt to remove the
  separate auto-themed entry (the preset-vs-`null` split).
- Concrete defect: `modules/02-core/05-theme.nix:39`
  `applyCommand = "case %%val%% in */*) dms ipc call wallpaper set %%val%% ;; esac"`
  never runs for a preset name, because a preset has no `/`.
- Backend sets `desktop.ojuny.wallpaper.image = null` with
  `preset = "retro"` (`modules/backend/02-core/05-theme-backend.nix:52-53`);
  whatever consumes `desktop.ojuny.wallpaper` must resolve the preset to a
  path.

### T11. Splash — both halves implemented

- The deployed `ojuny-login-splash-ready` reads
  `$XDG_RUNTIME_DIR/ojuny-shell-reloaded` and quits on a stamp change.
- `ojuny-cli` waits on the same stamp (`lib/subtrees/rebuild.sh:17,35`).
- The splash unit no longer has `ConditionPathExists` or `ExecStartPre`.
- Login start at 00:14 ran the ready unit to its 59 s deadline because a login
  has no reload; that is separate from the rebuild path.
- The rebuild test with `showOnRebuild` off and then on is still open.

### Open for the dev agent

1. Decide the permission policy (ask vs allow inside the flake) in the registry
   and align `docs/11-agent.md`, the patch system prompt and this file.
2. T1: add `branch.main.merge`/`@{u}` to the pull error and keep the new
   wording.
3. T3: replace the copy confirmation dialog (`ojuny-raven-report.sh:66`).
4. T9/T10: make the wallpaper apply path handle presets and resolve
   `preset` to a path.
5. T2, T7, T8, T11: need the retests listed above.
