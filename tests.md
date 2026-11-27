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

### T0. Agent permissions
- Date: 2026-11-28
- Generation / build: system-166 (`/nix/store/mmnw8h9c...-nixos-system-ojuny`), build `2110fe9`.
- Commands:
  - `write modules/notes-scratch.md` (absolute path)
  - `edit flake.lock`
  - `read .env`
  - `shell: sudo -n true`
  - `shell: git status -sb`
  - `write repos/nix-flake/modules/notes-scratch.md` (relative path)
- Observed:
  - 1. Edit prompt: immediate `permission.rejected` ("Permission denied: edit"), no prompt.
  - 2. Generated file: denied, no prompt (expected).
  - 3. Secret read: denied, no prompt (expected).
  - 4. Shell deny: denied, no prompt (expected).
  - 5. Read-only shell: allowed, no prompt (expected).
  - 6. Relative path: immediate `permission.rejected`, no prompt.
- Expected: steps 1, 5 and 6 prompt or allow; steps 2, 3 and 4 deny.
- Verdict: fail (steps 1 and 6).
- Log excerpt: opencode 2.3.0 does not write `message=evaluated permission=` lines in
  `~/.local/share/opencode/log/opencode.log`; the newest such lines are from
  2026-09-27 and use a different build. The evaluated pattern for steps 1, 2, 4
  and 6 therefore cannot be recorded from this build.

### T0. Notes for the fix pass
- The installed `modules/patches/patch-ojuny-agent.nix:341-351` still starts with
  `(deny action "*")`, and that file is **not** present in `origin/base`
  (`git diff --stat HEAD origin/base -- modules/patches/patch-ojuny-agent.nix`
  shows the whole file deleted), so the template merge cannot fix it. The fix
  has to come from the `ojuny-patches` registry (reinstall `patch-ojuny-agent`)
  or a device-side edit.
- Reordering alone is probably not enough. The read step proves the evaluator is
  not first-match: `read .env` is denied although `(allow "read" "*")` is first,
  so the later/specific rule wins. For edits the ask rule is
  `${flakeRoot}/**`, and the only consistent explanation for a denial is that
  the evaluated path is not absolute (or `**` does not match it), so the ask
  never fires. The September log shows relative patterns
  (`pattern=devnotes/filestructure.md`). Make the ask match the form the harness
  actually evaluates (relative), then keep the generated-file denies specific.
- T2, T3, T5, T6, T7, T8, T9 and T11 were not run: T0 is the stated
  prerequisite and results cannot be recorded through the normal edit path.

### T0. Correction after the 00:08 render
- Date: 2026-11-28
- Render: `~/.config/opencode/opencode.json` -> `/nix/store/nhn15cyn...-opencode.json`
  (00:08:53). Generator: `modules/patches/patch-ojuny-agent.nix`.
- Observed after the reorder:
  - The `edit`/`write`/`patch` tools are **not exposed to the agent session at
    all**; only `read`, `shell`, `grep`, `glob` and the rest are offered. A T0
    step 1 edit prompt therefore cannot be produced.
  - `read /home/den/repos/nix-flake/.env` now returns
    `tool.execution: File not found`, i.e. the read was **allowed**. Under the
    previous rule order the same call returned `permission.rejected`.
- Conclusion: the evaluator is **last-match-wins**, not first-match.
  `readRules` now has `deny *.env` first and `allow *` last, so `.env` is
  readable. `fileRules` has the specific denies and `ask **` first and
  `deny *` last, so every edit is denied and the tool is withheld.
- Fix: restore blanket-first / specifics-after ordering, and fix the pattern
  form instead:
  - `read`: `(allow "read" "*")` first, then `*.env`, `*.env.*`, `*.age`,
    `*.key`, `*secret*`, then `(allow "read" "*.env.example")` last.
  - `edit`/`write`/`patch`: `(deny action "*")` first, then
    `(ask action "**")` and `(ask action "${flakeRoot}/**")`, then the
    generated-file denies in both relative and absolute form.
  - Add a harness test that asserts `.env` is denied and a flake edit asks, so
    an ordering inversion cannot ship again.
