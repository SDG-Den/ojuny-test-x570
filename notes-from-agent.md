# notes from the x570 agent

Response to `notes-for-fixes.md` (round 8). Device: x570, system-170
(`/nix/store/drfzj0rc...-nixos-system-ojuny`), build `5a810f4`.

Each item gives a cause first, then the evidence, then the fix.
Markers: **[verified]** observed on the device or read from the exact store
revision; **[inferred]** reasoned; **[owner]** needs a device action.

## 1. Wallpaper: menu correct, application stale

Cause: the wallpaper path is **seeded session state**, not a regenerated
setting, and the seed runs through a wrapper whose store paths are fixed when
the session starts. The lock screen works because it lives in the regenerated
settings fragment.

| DMS key | Channel | Applied on switch? |
|---|---|---|
| `lockScreenWallpaperPath` | `desktop.ojuny.dux.settings` -> `config.d/00-ojuny.json` | yes (symlinked + `restartTriggers`) |
| `wallpaperPath` | `desktop.ojuny.dux.session` -> seeded `~/.local/state/dms/session.json` | only when the wrapper runs |

**[verified]** Sources (`ojuny-desktop` pin `dfbed69`, store `r4jacjj...`):
`modules/nixos/default.nix:317` (lock screen), `:322-326` (session),
`lib/mk-config.nix:88`, `lib/mk-linker.nix:35-48` (seed keyed by
`~/.local/state/dms/.ojuny-session-source`), `lib/mk-dux-wrapper.nix:9-18`
(`ojuny-config --seed` before `dms run`),
`modules/nixos/default.nix:345-358` (NixOS `ojuny-config` service runs
**without** `--seed`).

**[verified]** Live-apply for presets has never worked: the option changed to a
preset-name model in `ab2cead`, but `modules/02-core/05-theme.nix:39` still
gates on `case %%val%% in */*)`, so a preset name never calls
`dms ipc call wallpaper set`.

**[verified]** The current screen mismatch is a stale session PATH:

| layer | running session | current system |
|---|---|---|
| `dms` | `/nix/store/0hvmysm9...-dms` | `/nix/store/vpb89am4...-dms` |
| linker | `/nix/store/w694n8sv...-ojuny-config` | `/nix/store/aj0iqyfq...-ojuny-config` |
| seed source | `a7x3a4ic...` -> retro.png | `2vp1m4nj...` -> default.png |

`w694n8sv` hardcodes retro; `aj0iqyfq` hardcodes default. The session started
before the 10:58 switch, so `dms kill` re-seeds retro.

Fix, immediate **[owner]**: re-login, or run
`/nix/store/aj0iqyfq88lapi947rv5x6jggdzgfmjr-ojuny-config/bin/ojuny-config --seed`
and confirm `jq -r .wallpaperPath ~/.local/state/dms/session.json`.

Fix, template: add `--seed` to the NixOS `ojuny-config` service (or an
ExecStartPost), so a switch applies the wallpaper without re-login; add
preset-name handling to the GUI apply command (resolve
`desktop.ojuny.wallpaper.presets.<name>.path`).

## 2. Login splash

Cause: the ready script quits on a **recent** stamp mtime, not on a change:

```bash
started="$(date +%s)"
...
modified="$(stat -c %Y "$stamp")"
if [ "$modified" -ge $((started - 2)) ]; then "$splash" --quit; exit 0; fi
```

At login, mango's startup `exec` writes the stamp around the time the splash
starts, so `modified >= started - 2` is true within a second and the splash is
dismissed almost immediately. At rebuild, the stamp only changes if the
environment reload command runs (item 5); it does not, so the splash waits until
its own timeout ("does not end at all").

**[verified]** Deployed ready script
`/nix/store/7cib8g8...-ojuny-login-splash-ready`; login run 10:58:56-10:59:18,
ready unit ran its full 60 s deadline.

Fix: record the stamp value/mtime **before** waiting and quit only when it
changes; for the login case, wait on DMS readiness (socket/`dms.service`)
instead of the reload stamp.

## 3. WVKBD

Cause: not the monitor, not DMS — the pointer never reaches wvkbd.

**[verified]** Owner test: pointer placed over a key, `mmsg get cursorpos`
confirmed, **DMS disabled**, and the keyboard still does not react to clicks or
type. So the surface is visible and sized, but the input never lands.

**[verified]** The keyboard is an `overlay` layer on HDMI-A-1; mango reserves
its 200 px (ghostty 1912x838 on a 1912x1038 work area). Protocols present:
layer-shell v4, virtual-keyboard v1, input-method v2, text-input v3.
`auto=false` does not stop wvkbd starting; the unit is
`wantedBy=mango-session.target`.

Remaining cause is in the wvkbd input path or mango's layer pointer routing,
not in configuration. Next step is code-level, not more device tests: check
whether wvkbd sets a non-empty `wl_surface.set_input_region` for the layer
surface, and whether mango's pointer hit-testing delivers events to `overlay`
layer surfaces on a non-selected output. (The wvkbd 0.21 source is fetched by
`nix eval` but not realised in the store, so it was not read here.)

## 4. NSG "cannot fast-forward to multiple branches"

Intended flow (owner): auto-sync exists so a change pushed from another device
reaches this one when NSG opens. NSG's flake path is selectable
(`recent_flake_paths`), so the sync must work for whichever repository is
selected, independent of its branch/head layout. If the upstream is ahead,
apply it when it can be applied without a conflict; otherwise report an error.
Conflict-free merge commits are acceptable: these repositories are personal
backups and shareable templates. `git pull` cannot implement this reliably: it
merges FETCH_HEAD and whatever heads git presents, so it depends on the
repository's shape. Replace it with an explicit single-ref sync against the
selected path.

**[verified]** The message is git's `merge.c` refusal when more than one head
is passed with `--ff-only`. The current GUI path is `pull()` -> `git fetch`
(all branches, from `remote.origin.fetch`) -> `git pull --no-edit --ff-only`
(`azd4lcc...-source`, `src/app/git.rs:24-46`, `:69-72`).

**[verified]** The repo itself is clean: one `branch.main.merge`, one
`remote.origin.fetch`, no aliases, no tags, no replace refs, no grafts, not
shallow, one worktree. A throwaway clone of the same remote (both `main` and
`base`, HEAD -> main) fast-forwards with the exact sequence; repeated opens
also pass. So the repo does not need fixing, and neither does its config.

Fix: stop using `git pull`, and implement the flow directly.

```rust
// 1. fetch only the current branch's upstream ref
let branch = current_branch(dir)?;
let remote = git_config(dir, &format!("branch.{branch}.remote"))?; // origin
let merge  = git_config(dir, &format!("branch.{branch}.merge"))?;  // refs/heads/main
run_git(dir, &["fetch", "--no-tags", remote, merge])?;

// 2. one explicit target commit
let target = run_git(dir, &["rev-parse", "FETCH_HEAD"])?;
let target = target.trim();

// 3. apply it; do not pre-check the worktree
//    HEAD == target            -> nothing to do (no message)
//    HEAD is ancestor          -> git merge --ff-only <target> (no message)
//    otherwise (diverged)      -> git merge --no-edit <target> (no message)
//    any overwrite / conflict  -> git merge --abort; report the error
```

Do not inspect `git status` first, and do not refuse on a dirty worktree. Git
already checks this: if the incoming content does not touch the modified files,
the fast-forward or merge applies; if it would overwrite local changes, git
aborts before changing anything and that is the conflict case to report. That
abort is the only failure path.

Reporting rule: on success (fast-forward applied, merge commit created, or
nothing to sync) produce **no dialog and no user-visible message**. Only the
aborted/conflicted case reports. In the current code that means removing the
`Msg::GitPulled(Ok(false)) => "Git: already up to date"` status.

`git merge` with one explicit target cannot produce "multiple branches". For
the ancestor case use `git merge --ff-only <target>` (no merge commit). For the
diverged case use `git merge --no-edit <target>` and `git merge --abort` on
failure. Apply the same path to `start_git_sync` and drop the extra pre-fetch.

Merge commits are accepted (owner), so the diverged case merges and stays
silent when conflict-free. The repository's branch layout must not change the
outcome: the only question is whether the selected upstream applies cleanly.
The same code must run against whichever flake path NSG has open, since a
change is often pushed from a different repository than the one the device
boots from.

## 5. NSG environment reload command never runs

Cause: `sudo`. NSG runs `sudo ojuny rebuild`; the CLI resolves the config with
`${XDG_CONFIG_HOME:-$HOME/.config}/nix-settings-gui/config.json`
(`rebuild.sh:9`). Under sudo, `HOME` is root's (`security.sudo` on this system
keeps no `HOME`; see below), so the file is
`/root/.config/nix-settings-gui/config.json`, which does not exist. The command
comes back empty and `ojuny_run_environment_reload` returns success without
running anything.

**[verified]** `nix eval .#nixosConfigurations.ojuny.config.security.sudo`
gives `defaultOptions=["SETENV"]`, `extraConfig` keeps only
`NIXOS_NO_CHECK`/`TERMINFO_DIRS`; no `env_keep+=HOME`.

**[verified]** The CLI already knows this pattern:
`lib/crashes.sh:44-46` switches to `getent passwd "$SUDO_USER"` when
`id -u` is 0; `rebuild.sh` and `discovery.sh:23` do not.

Fix: resolve the invoking user's home in `ojuny_environment_reload_command`
(and `discovery.sh`) via `SUDO_USER`, or have NSG pass the command through
`OJUNY_ENVIRONMENT_RELOAD`. This also unblocks item 2's rebuild case.

## 6. Flatpak

Cause: application startup, not the sandbox. **[verified]** `sh -c true`
baseline is 150 ms (Thunderbird) and 892 ms (Flatseal); real launches are 2-9 s
per app. No template change expected.

## 7. Steam: Millenium present, not stylix-themed

Cause: the theme is installed and active, but **no stylix colours are ever
generated for Steam**. `ojuny.steam.themeName = "Adwaita"`, the theme symlink
exists, `themes.activeTheme = "Adwaita"`, and
`~/.config/millennium/quick.css` is Millennium's empty default
(`/* Quick CSS file created by Millennium */`). The backend installs the theme
and sets the active key only (`05-steam-backend.nix:78-100`).

Fix: generate a Millennium CSS (or Adwaita-for-Steam colour overrides) from
`config.lib.stylix.colors` and write/refresh it at activation.

## 8. Quake terminal

Cause: mango recenters a cross-monitor scratchpad.
**[verified]** `client_adapt_geometry_to_monitor` calls
`client_center_geometry(c, c->mon, c->float_geom, 0, 0)`
(`mango/src/manage/client.c:3316-3328`); `offset_y = -100` is only applied at
first map (`:1708-1712`). The proposed script (detect, toggle, set position) is
a valid template workaround; `scratchpad_cross_monitor=false` avoids it but
loses follow-focus.

## 9. Monitor toggle

Cause: `scripts/ojuny-display-toggle.sh` logic, not mango.

- `focused` keeps a state file and the next press always re-enables the stored
  monitor, so a second monitor cannot be toggled.
- `all` toggles only **active** monitors, so it cannot re-enable the off ones
  until everything is off.
- `reload_layout` runs only when no monitor was active, so positions are never
  restored on the normal path.

Fix the script: track the set it turned off, toggle the complement in `all`,
reload after every toggle, save/restore positions. **Do not** switch to
`sleep_toggle_monitor`; mango's docs require `toggle_monitor` for display
toggling.

## 10. USB automount

Cause: the filter still drops the partitions. **[verified]** after the
`recurse(.children[]?)` fix, `sdg` reports `tran=usb, rm=false, fstype=null`
while `sdg1..4` report `tran=null, rm=false`, so
`select((.tran // "") == "usb" or .rm == true)` never matches a child. `sdg4`
is also still mounted by the greeter at `/run/media/greeter/Data`
(uid 992/gid 989).

Fix: carry the parent's `tran`/`rm` into the child selection, treat a
foreign-uid mount as not mounted for this user, and log decisions.

## 11. ojuny-manual

Cause (both parts):

1. The picker lacks `--layout=reverse`; only the pager has it.
2. The preview double-quotes an fzf placeholder. fzf already shell-quotes
   `{1}`, so `"$md_dir/{1}"` becomes a path containing literal quotes and bat
   reports the file as inaccessible. **[verified]** reproduced:
   `bat .../md/'index.md'` -> `No such file or directory`; without the inner
   quotes it reads fine.

Installed wrapper
`/nix/store/al0gcnd...-ojuny-manual-0.1.0/bin/.ojuny-manual-wrapped:81-82`
(picker) and `:88` (pager).

Fix: add `--layout=reverse` to the picker and drop the inner quotes around
`{1}` (for example `--preview="bat ... $md_dir/{1}"`).

## 12. VSCodium to terminal paste

Cause: the wrapper passes `--profile nix` as **two argv entries** and appends
the ozone flag, and the launched app reorders them. The process cmdline is
`--profile --ozone-platform=wayland -n nix`, so the ozone flag sits where the
profile value should be. **[verified]** the wrapper is a C wrapper generated
with `--add-flags '--profile nix --ozone-platform=wayland'`
(`byf58qm0...-vscodium-default-nix`), and the string table shows the three
tokens separately.

Fix: pass `--profile=nix` as one atomic flag (and keep
`--ozone-platform=wayland` separate), then retest. If paste still fails, the
clipboard doctor must capture `WAYLAND_DEBUG=1` with VSCodium focused and
again with Ghostty focused.

## 13. Auto-rotate "missing"

Cause: it is a per-output control rendered inside the selected output card, and
the menu search only matches record paths/labels (and keybinds values):
`record_matches_query` checks `record.path()`, `record.spec.label`, and the
value only for `WidgetKind::Keybinds` (`azd4lcc...-source`,
`src/app/controls.rs:542-562`). Per-output monitor features are not records, so
"rotate" cannot match. `ojuny-auto-rotate` is correctly absent (all outputs
`never`).

Fix: if it should be searchable/top-level, add a record or index monitor
features in search. Otherwise it is discoverability only.

## 14. Old network monitor tile

Cause: it is still defined in the flake. **[verified]** the generated
`config.d/00-ojuny.json` has
`dashCards=[..., {"col":3,"h":1,"id":"network","row":7,"w":3}, ...]` and
`dashOptions.network={tone:"primary",trend:true}`; both the device and
`origin/base` set `desktop.ojuny.dux.dashCards`
(`modules/04-gui/04-dashboard.nix:215`) and `dashOptions.network`
(`:90,93`).

Fix: remove the `network` entry from `dashCards` (and optionally
`dashOptions.network`) in the template and regenerate the DMS config.

## Cross-cutting: seeded session state

Anything written into `~/.local/state/dms/session.json` is applied by the
`dms` wrapper (`ojuny-config --seed`), and the wrapper's store paths are fixed
when the session starts. A switch alone does not refresh them until the session
restarts or the seed is run from the current generation. This is the root of
the wallpaper symptom and can affect any other seeded session value.

A second cross-cutting issue: `sudo ojuny rebuild` loses `HOME`, so every
user-config lookup in the CLI that is not `SUDO_USER`-aware sees root's home.
`crashes.sh` already handles it; `rebuild.sh` and `discovery.sh` do not.
