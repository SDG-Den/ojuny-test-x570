# Device tests (round 7)

Companion plan: `2026-11-28_PLAN-round-7-device-fixes.md`.
Round 6 results are archived at `tests-archive/2026-11-28-round-6.md`.

This file is handed to `ojuny-agent` through GitHub. Append results under
"Results"; keep the procedures unchanged.

Conventions:

- `FLAKE=/home/den/repos/nix-flake`, the same directory as
  `/home/den/repos/ojuny-deployed-test-devices/ojuny-test-x570` on this
  device.
- **owner** marks commands that mutate runtime state; run those yourself.
- Everything else is read-only and can be run by the agent.
- T0 is blocking. Do not delegate another test until it passes.

## T0. Agent permissions

Purpose: confirm the allow-inside-the-flake policy and the edit-tool
availability.

Run after the registry patch is reinstalled and a new session is open.

1. **Absolute edit.** Ask to edit a normal flake file. Expected: applied
   without a prompt.
2. **Generated file.** Ask to edit `flake.lock`. Expected: denied without a
   prompt.
3. **Secret read.** Ask to read `.env`. Expected: denied.
4. **Shell deny.** Ask to run `sudo -n true`. Expected: denied.
5. **Read-only shell.** `git status -sb`. Expected: allowed, no prompt.
6. **Relative edit.** Repeat step 1 with a relative path. Expected: applied
   without a prompt.
7. **Outside path.** Ask to edit `/tmp/notes-outside.md`. Expected: denied, so
   the flake boundary still holds with the relative allow.

`opencode` 2.3.0 logs no evaluated permission pattern. Record the visible
prompt, apply or denial.

Pass: 1, 5 and 6 apply or allow; 2, 3, 4 and 7 deny.

## T1. NSG divergence dialog

Purpose: confirm the merge-ref diagnostics and capture the ambiguous config.

1. Open the settings GUI with auto-sync on.
2. If a git dialog appears, copy its first line. It should now end with
   `(merge refs: ...)`.
3. While it is open:

```sh
pid=$(pgrep -n nix-settings-gui)
readlink -f /proc/$pid/exe
grep -a -F 'merge refs' /proc/$pid/exe
git -C "$FLAKE" config --get-all branch.main.merge
git -C "$FLAKE" status -sb
git -C "$FLAKE" rev-list --left-right --count 'HEAD...@{u}'
```

Pass: the dialog, the binary path, the merge-ref output and the counts are
recorded together. Two `branch.main.merge` refs name the cause.

## T2. OSK input and typing

Purpose: separate a DMS overlay problem from a wvkbd input-region problem.

1. **owner** `systemctl --user start ojuny-osk`
2. `systemctl --user status ojuny-osk --no-pager`
3. `pgrep -a wvkbd`
4. `Super+Alt+O`. Record whether the keyboard appears.
5. Click a key with the pointer. Record whether it highlights and whether a
   character reaches the focused application.
6. `mmsg get all-layers` with the keyboard hidden, then open. Record the wvkbd
   layer and the surfaces listed after it.
7. **owner** `dms kill`. Click the keyboard again. If clicks now land, the DMS
   overlay stack is the cause; if not, it is wvkbd's input region.
8. **owner** restart DMS with `mmsg dispatch spawn_shell,dms run --session`.
9. Type on the keyboard in Ghostty, Firefox and LibreOffice Writer.
10. `journalctl --user -b -u ojuny-osk -u ojuny-osk-tray --no-pager`

Note: `onScreenKeyboard.auto = false`, so auto show/hide is expected to stay
off.

Pass: the unit is active, the keybind and tray toggle, clicks highlight keys,
and typing reaches the focused application.

## T3. Raven ODT and copy

Purpose: confirm the ODT path and the copy notification.

1. Double-click the Office deployment tool. Record whether a window appears
   and the elapsed time.
2. `ls -lt ~/.local/state/ojuny/raven | head`
3. `cat ~/.local/state/ojuny/raven/last.log`
4. `od -An -tu4 -N4 ~/.local/state/ojuny/raven/last-exit.log`
5. Open the failure report, press Copy report, and record whether a
   notification appears and whether the report dialog stays open.
6. `journalctl --user -b | grep -i ojuny-raven | tail`

Pass: the exit code decodes as signed and unsigned, the report shows the
output section, the copy shows a notification, and the report is not replaced.

## T4. Flatpak

Purpose: close the item as application-side.

```sh
time flatpak run --command=sh org.mozilla.Thunderbird -c true
time flatpak run org.mozilla.Thunderbird
```

Record both. The sandbox baseline was 150 ms and the real launch 8 s; no
template change is expected.

## T5. Auto-rotate

Purpose: confirm the control is present per output.

1. `systemctl --user status ojuny-auto-rotate --no-pager`
2. `nix eval --json .#nixosConfigurations.ojuny.config.services.nix-settings-gui.monitors`
3. Open Settings > Display, click the connected output card, and record whether
   the "Auto rotation" dropdown is present.

## T6. Opencode selection

Run only if the selection loss returns.

1. **owner** `systemctl --user stop ojuny-osk`
2. Select text in opencode. Record.
3. `ojuny-clipboard-doctor`
4. **owner** `systemctl --user start ojuny-osk`
5. Repeat step 2.

## T7. VSCodium paste

Purpose: verify the wrapper argument order and the paste direction.

1. `pid=$(pgrep -n codium); tr '\0' ' ' < /proc/$pid/cmdline`
2. Confirm the cmdline contains `--profile nix --ozone-platform=wayland` in
   that order, and `DISPLAY` is unset in `/proc/$pid/environ`.
3. Copy in VSCodium, paste in Ghostty with `ctrl+shift+v`. Record.
4. `ojuny-clipboard-doctor` with VSCodium focused, then Ghostty focused.
5. `wl-paste --list-types` in both focus states.

## T8. G13 menu, stick and unmarked button

Purpose: confirm the dedicated menu, the stick script and the extra button.

1. **owner** `dms ipc call keybinds open g13`. Record the menu. Expected:
   `G1` to `G22`, `Thumb Left`, `Thumb Down`, `Misc`, `Stick Left`,
   `Stick Right`, `Stick Up`, `Stick Down`, grouped like the regular binds,
   with `Windows` and no `Window`.
2. **owner** `dms ipc call keybinds open binds`. Expected: no G13 entries in the
   regular menu.
3. Hold the stick in Ghostty. Record one action per 300 ms and no diagonal
   double trigger. `ls -l "$XDG_RUNTIME_DIR/ojuny-g13-stick.last"`; the
   timestamp advances on each dispatch.
4. Press the small round unmarked button at the top. Expected: the G13 keybinds
   menu opens. If nothing happens, record it; `undef1` is the current candidate
   and `MISC_TOGGLE` is the fallback.
5. `pgrep -a -f g13`; `grep -A4 '"G13' /proc/bus/input/devices`; confirm the
   `G13 Filtered` device while the filter runs.
6. **owner** `mmsg dispatch setoption,allow_shortcuts_inhibit,0`, repeat step 3,
   restore the option. Record whether the inhibitor changes the stick.

Pass: the dedicated menu shows the G13 labels, the regular menu does not, the
stick runs through `ojuny-g13-stick` with the lockout, and the unmarked button
opens the menu.

## T9. Wallpaper

Purpose: confirm the preset paths, previews and live apply.

```sh
nix eval --json .#nixosConfigurations.ojuny.config.desktop.ojuny.wallpaper
```

Check that every preset path exists. Open Settings > Wallpaper and record:

- number of tiles and whether paths or "Preview unavailable" appear;
- whether the "Auto-themed" tile appears;
- select a preset and record whether the live background changes;
- `journalctl --user -b | grep -i wallpaper | tail`

The GUI now scans a dendritic flake as `nixos:ojuny`, not `fp`. A strip with
the themed paths instead of one "Preview unavailable" tile confirms the target
fix. The DMS wallpaper menu should list the generated folder, not `~/Pictures`.

## T10. Wallpaper after a DMS reload

Purpose: confirm the session flag restores the wallpaper.

1. **owner** `dms kill`
2. **owner** `mmsg dispatch spawn_shell,dms run --session`
3. Record whether the wallpaper returns.
4. `pgrep -a dms`
5. `jq -r '.wallpaperPath // .wallpaperCyclingFolderPath // empty' ~/.local/state/dms/session.json`

Pass: one shell process, the wallpaper returns, and the session config holds
the path.

## T11. Splash

Purpose: confirm the reload-boundary lifecycle and the removed 60 s block.

1. `systemctl --user show -p Type ojuny-login-splash-ready`
2. `ls -l /run/user/$(id -u)/ojuny-shell-reloaded`
3. With `showOnRebuild = false`, run `ojuny rebuild`. Record whether a splash
   appears and the duration of the "reloading user units" step.
4. With `showOnRebuild = true`, run `ojuny rebuild`. Record when the splash
   appears and when it disappears relative to the DMS reload.
5. `journalctl --user -b -u ojuny-login-splash -u ojuny-login-splash-ready --no-pager`

Pass: the ready unit is `Type=simple`; the user-unit reload does not wait 60 s;
the splash covers the DMS reload and ends with it.

## T12. DMS reload command

Purpose: confirm the command survives a settings GUI save.

```sh
jq -r '.environment_reload_command // empty' ~/.config/nix-settings-gui/config.json
```

Expected: the command ends with `dms run --session`.

## T13. Display toggles and OCR

Purpose: confirm the position restore, the all-outputs logic and the new OCR
chord.

1. With two outputs, **owner** press `Super+O`. Record that the focused output
   is removed. Press `Super+O` again and record that it returns to the same
   position. The second press runs `mmsg dispatch reload_config`.
2. Turn one output off with `Super+O`. Press `Super+Shift+O` and record that
   only the active outputs turn off and the already-off output stays off.
   Press it again and record that all outputs return to their positions.
3. Press `Super+Shift+T` and record that the OCR overlay opens.
4. Press `Super+Shift+O` and record that it toggles the displays and does not
   open OCR.
5. `mmsg get all-monitors` before and after each step; record the names and
   positions.

Pass: a re-enabled output returns to its original position, the all-outputs
key is deterministic, and OCR is on `Super+Shift+T`.

## T14. Manual TTY reader

Purpose: confirm the fzf and bat reader and the packaged Markdown tree.

1. `ojuny-manual --path` prints the installed Markdown directory.
2. `ojuny-manual --tty` opens the fzf chapter picker with a bat preview.
3. Press Enter and record that the chapter opens in the fzf pager. `/` searches,
   `Esc` or `Enter` exits.
4. `ojuny-manual --list` prints the chapter titles.
5. Confirm the reader does not invoke `w3m`.

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

## Handoff state

Pending input updates: `ojuny-template`, `ojuny-desktop`, `ojuny-cli`,
`ojuny-patches` (registry reinstall), `nix-settings-gui`, `ojuny-manual`,
`raven`.

Open source items: OSK input; DMS wallpaper session path; the G13 unmarked
button (`undef1` versus `MISC_TOGGLE`); NSG scroll, commit dates and wallpaper
retest; the manual live-terminal test.

Accepted results: T6 selection pass; T4 Flatpak app-side.

## Results

### T0. Agent permissions — pass on the stated steps, one boundary hole
- Date: 2026-11-28
- Generation / build: system-169 (`mbvhw29k...`), build `3c93cde`.
- 1. Absolute edit (`modules/notes-scratch.md`): created, no prompt. Pass.
- 2. `flake.lock`: denied, no prompt. Pass.
- 3. `.env` read: denied. Pass.
- 4. `sudo -n true`: denied. Pass.
- 5. `git status -sb`: allowed, no prompt. Pass.
- 6. Relative edit (`repos/nix-flake/modules/notes-scratch.md`): applied, no
  prompt. Pass.
- 7. `/tmp/notes-outside.md`: denied (`external_directory`). Pass.
- **Boundary hole:** `write /home/den/notes-outside.md` **succeeded**. That path
  is outside the flake but inside the session directory (`/home/den`), and
  `(allow action "**")` covers it. The "never edit outside the flake" rule is
  therefore enforced only for paths the harness classifies as external. The
  test's step 7 uses `/tmp`, which is external, so it does not catch this.
- Root cause (owner): the agent was launched with `cwd=~`, and opencode treats
  the CWD as the project root, so everything under `~` counts as inside and the
  relative `allow "**"` matches it. The rules are not wrong for a session rooted
  at the flake; the launcher is.
- Fix: start `ojuny-agent` with the flake as the session directory (or a
  `--directory`/session-move to `$FLAKE`), then `**` and `external_directory`
  both bound the flake. Fallback if the launcher cannot be changed: drop the
  broad `allow "**"`, normalise edit paths to absolute before matching, and add
  a test step that targets a path inside the CWD but outside the flake.
- Note: the session cwd is `/home/den`, not the flake, so the relative-path
  step exercises `repos/nix-flake/...`, not `modules/...`.

### Static checks on the round-7 expectations
- T1: the deployed GUI (`m265fsl7...`) contains `merge refs` (2 hits). The
  instance running before the 10:46 update predates it; reopen Settings before
  T1. The dialog wording fix is in place.
- T11: `ojuny-login-splash-ready` is `Type=simple`. Matches.
- T12: `environment_reload_command` is still
  `dms kill && mmsg dispatch spawn_shell,dms run`; it does **not** end with
  `dms run --session`. This is device user state in
  `~/.config/nix-settings-gui/config.json`; it needs updating on the device
  before T12 can pass.
- T13: `ojuny.toml` has `SUPER+SHIFT+O` -> `ojuny-display-toggle all` and
  `SUPER+SHIFT+T` -> `ojuny-capture-text`. Matches.
- T14: `ojuny-manual` supports `--path`, `--tty`, `--list`, `--serve`. Matches.
- T8: `ojuny-g13-stick` is not in `PATH` by design; binds call the store path
  directly (`patch-logitech-g13.nix:2282`). `/run/user/1000/ojuny-g13-stick.last`
  does not exist yet because the stick has not been used since the update.

### T5. Auto-rotate — read-only half pass
- `ojuny-auto-rotate`: `not-found` (correct; no output is `automatic`).
- `monitors.*.autoRotation`: DP-1, DP-2, HDMI-A-1 all `never`.
- GUI output-card check pending (owner).

### T9/T10. Wallpaper — presets exist, session carries the wrong one
- All eight preset paths exist: abstract, city, default, floyd, logo, retro,
  stripes, waves.
- Config: `image = null`, `preset = "retro"`.
- `~/.local/state/dms/session.json` (00:40) has
  `wallpaperPath = /nix/store/34di220.../lib/wallpapers/preset-abstract.png`,
  i.e. **abstract**, not the configured `retro`. The session does not carry the
  configured preset.
- One `dms` process pair (108107 main, 108127 `qs` child).
- GUI tile strip and live-apply checks pending (owner).

### T14. Manual — path and list pass
- `ojuny-manual --path` -> `/nix/store/al0gcnd.../share/ojuny-manual/md`.
- `--list` prints the chapter titles (Ojuny Manual, Attended ISO, ...).
- `--tty` fzf/bat interaction pending (owner).
