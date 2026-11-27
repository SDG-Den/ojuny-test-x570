{ inputs, ... }: {

  flake.modules.nixos.applications-appimage-raven-backend =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.ojuny.raven;

      ravenDiagnostics = ''
        echo "Raven revision: ${inputs.raven.rev or "unknown"}"
        echo "Raven package: ${config.programs.raven.package.unwrapped.version or "unknown"}"
        echo "System:"
        echo "  Architecture: $(uname -m)"
        echo "  Kernel: $(uname -srm)"
        grep -E '^(PRETTY_NAME|VERSION_ID|ID|ID_LIKE)=' /etc/os-release | sed 's/^/  /' || true
        echo "  CPU: $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//')"
        grep -E '^(MemTotal|MemAvailable):' /proc/meminfo | sed 's/^/  /' || true
        lspci -nn 2>/dev/null | grep -Ei 'vga|3d|display' | sed 's/^/  GPU: /' || true
        echo "  Compositor: ''${XDG_CURRENT_DESKTOP:-unknown}"
        echo "  Session: ''${XDG_SESSION_TYPE:-unknown}"
        echo "Environment:"
        env | LC_ALL=C sort | grep -E '^(RAVEN_|WAYLAND_|XDG_|DISPLAY=|HOME=|PATH=|LANG=|LC_|DESKTOP_|DBUS_SESSION_BUS_ADDRESS=)' | sed 's/^/  /' || true
      '';

      ravenShortcutTarget = pkgs.writeText "raven-shortcut-target.py" ''
        import argparse
        import re
        from pathlib import Path

        from LnkParse3.lnk_file import LnkFile

        ENVIRONMENT = {
            "%SystemDrive%": "C:",
            "%SystemRoot%": "C:\\windows",
            "%windir%": "C:\\windows",
            "%ProgramFiles%": "C:\\Program Files",
            "%ProgramFiles(x86)%": "C:\\Program Files (x86)",
            "%ProgramW6432%": "C:\\Program Files",
            "%ALLUSERSPROFILE%": "C:\\ProgramData",
        }

        def user_profile(prefix):
            for folder in ("Users", "users"):
                root = Path(prefix) / "drive_c" / folder
                try:
                    entries = sorted(root.iterdir())
                except OSError:
                    continue
                for entry in entries:
                    lowered = entry.name.lower()
                    if entry.is_dir() and lowered != "public" and not lowered.startswith("default"):
                        return "C:\\Users\\" + entry.name
            return None

        def expand(target, prefix):
            values = dict(ENVIRONMENT)
            profile = user_profile(prefix)
            if profile:
                values["%USERPROFILE%"] = profile
                values["%APPDATA%"] = profile + "\\AppData\\Roaming"
                values["%LOCALAPPDATA%"] = profile + "\\AppData\\Local"
            for name in sorted(values, key=len, reverse=True):
                target = re.sub(re.escape(name), lambda _: values[name], target, flags=re.IGNORECASE)
            return target

        def windows_target(lnk):
            data = lnk.get_json()
            info = data.get("link_info") or {}
            base = info.get("local_base_path") or info.get("local_base_path_unicode") or ""
            suffix = info.get("common_path_suffix") or info.get("common_path_suffix_unicode") or ""
            if base:
                if not suffix:
                    return base
                if base.endswith("\\") or suffix.startswith("\\"):
                    return base + suffix
                return base + "\\" + suffix
            items = (data.get("target") or {}).get("items") or []
            volume = ""
            names = []
            for item in items:
                if item.get("class") == "Volume Item":
                    volume = item.get("volume_name") or ""
                elif item.get("class") == "File entry":
                    name = item.get("primary_name")
                    if name:
                        names.append(name)
            if volume and names:
                return volume.rstrip("\\") + "\\" + "\\".join(names)
            strings = data.get("data") or {}
            relative = strings.get("relative_path") or ""
            working = strings.get("working_directory") or ""
            if relative:
                if re.match(r"^[A-Za-z]:[\\/]", relative) or relative.startswith("\\\\"):
                    return relative
                relative = relative.removeprefix(".\\")
                if working:
                    return working.rstrip("\\") + "\\" + relative
            return ""

        def host_path(target, prefix):
            target = target.strip().strip('"')
            if not target:
                return ""
            match = re.match(r"^([A-Za-z]):", target)
            if match:
                drive = match.group(1).lower()
                rest = target[2:].replace("/", "\\").lstrip("\\").replace("\\", "/")
                root = Path(prefix) / ("drive_" + drive)
                if drive == "z":
                    root = Path("/")
                candidate = (root / rest).resolve()
                if not candidate.is_relative_to(root.resolve()):
                    return ""
                return str(candidate)
            if target.startswith("/"):
                return target
            return ""

        def main():
            parser = argparse.ArgumentParser(description="Resolve a Windows shortcut to a host path")
            parser.add_argument("--prefix", required=True)
            parser.add_argument("shortcuts", nargs="+")
            args = parser.parse_args()
            for shortcut in args.shortcuts:
                try:
                    with open(shortcut, "rb") as stream:
                        target = windows_target(LnkFile(fhandle=stream))
                    host = host_path(expand(target, args.prefix), args.prefix)
                    if host and Path(host).is_file():
                        print(f"{host}\t{shortcut}")
                except Exception:
                    continue

        if __name__ == "__main__":
            main()
      '';

      ravenSandboxLog = ''
        prefix="''${RAVEN_PREFIX:-$HOME/.local/share/raven/default}"
        if [ -f "$prefix/sandbox.log" ]; then
          {
            echo
            echo "--- sandbox refusals ---"
            tail -n 100 "$prefix/sandbox.log"
          } >> "$report"
        fi
      '';

      ravenReport = import ../../../packages/raven-report.nix { inherit pkgs; };

      ravenRefresh = pkgs.writeShellApplication {
        name = "ojuny-raven-refresh";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.gnugrep
          pkgs.gnused
          pkgs.util-linux
          pkgs.desktop-file-utils
          (pkgs.python3.withPackages (ps: [ ps.lnkparse3 ]))
        ];
        text = ''
          prefix="''${RAVEN_PREFIX:-$HOME/.local/share/raven/default}"
          drive="$prefix/drive_c"
          [ -d "$drive" ] || exit 0

          applications="''${XDG_DATA_HOME:-$HOME/.local/share}/applications"
          mkdir -p "$applications"
          rm -f "$applications"/ojuny-raven-*.desktop

          desktops=()
          for desktop in "$drive"/Users/*/Desktop "$drive"/users/*/Desktop; do
            if [ -d "$desktop" ]; then
              desktops+=("$desktop")
            fi
          done
          [ "''${#desktops[@]}" -gt 0 ] || exit 0

          declare -A seen=()
          while IFS= read -r -d "" shortcut; do
            result="$(python3 ${ravenShortcutTarget} --prefix "$prefix" "$shortcut" 2>/dev/null)" || continue
            [ -n "$result" ] || continue
            target="''${result%%$'\t'*}"
            [ -n "$target" ] || continue
            case "''${target,,}" in
              *.exe) ;;
              *) continue ;;
            esac
            base="$(basename "$target")"
            case "''${base,,}" in
              *unins*|*setup*|*update*|*crashpad*|*helper*) continue ;;
            esac
            if [ -n "''${seen["$target"]:-}" ]; then
              continue
            fi
            seen["$target"]=1
            name="''${shortcut##*/}"
            name="''${name%.[lL][nN][kK]}"
            name="''${name% - Shortcut}"
            exec_path="''${target//%/%%}"
            hash="$(printf '%s' "$target" | sha256sum | cut -c1-16)"
            {
              echo "[Desktop Entry]"
              echo "Type=Application"
              echo "Name=$name"
              echo "Comment=Installed Windows application (Raven)"
              echo "Exec=/run/current-system/sw/bin/ojuny-raven \"$exec_path\""
              echo "Icon=application-x-executable"
              echo "Terminal=false"
              echo "Categories=Utility;"
              echo "NoDisplay=false"
            } > "$applications/ojuny-raven-$hash.desktop"
          done < <(find "''${desktops[@]}" -type f -iname '*.lnk' -print0 2>/dev/null | sort -z)

          update-desktop-database "$applications" >/dev/null 2>&1 || true
        '';
      };

      ravenRun = pkgs.writeShellApplication {
        name = "ojuny-raven";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnused
          pkgs.gnugrep
          pkgs.pciutils
        ];
        text = ''
          if [ "$#" -eq 0 ]; then
            echo "usage: ojuny-raven FILE.exe" >&2
            exit 2
          fi
          original_args=("$@")
          host_file="$(realpath -- "$1")"
          shift
          win_dir="Z:$(dirname -- "$host_file" | sed 's|/|\\|g')"
          log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/ojuny/raven"
          mkdir -p "$log_dir"
          log="$log_dir/last.log"
          exit_log="$log_dir/last-exit.log"
          {
            echo "Raven launch"
            echo "Time: $(date -Is)"
            echo "Application: $host_file"
            echo "Wrapper: $0"
            echo "Raven command: ${config.programs.raven.package}/bin/raven --run-process --execution=native --exit-code-fd=3 --timeout-ms=86400000 --desktop=wayland --directory=$win_dir $host_file -- $*"
            ${ravenDiagnostics}
            echo "Report this at https://github.com/mirkobrombin/raven/issues"
            echo
            echo "--- output ---"
          } > "$log"

          exec 3>"$exit_log"
          if [ -t 1 ] || [ -t 2 ]; then
            set +e
            ${config.programs.raven.package}/bin/raven --run-process --execution=native --exit-code-fd=3 --timeout-ms=86400000 --desktop=wayland --directory="$win_dir" "$host_file" -- "$@" 2>&1 | tee -a "$log"
            status="''${PIPESTATUS[0]}"
            set -e
          else
            set +e
            ${config.programs.raven.package}/bin/raven --run-process --execution=native --exit-code-fd=3 --timeout-ms=86400000 --desktop=wayland --directory="$win_dir" "$host_file" -- "$@" >> "$log" 2>&1
            status=$?
            set -e
          fi
          exec 3>&-
          guest_status="$(cat "$exit_log" 2>/dev/null || true)"

          if [ "$status" -eq 0 ]; then
            ${ravenRefresh}/bin/ojuny-raven-refresh >/dev/null 2>&1 || true
            exit 0
          fi
          echo "Exit status: $status" >> "$log"
          echo "Guest exit code: ''${guest_status:-unknown}" >> "$log"
          if [ -t 1 ] || [ -t 2 ]; then
            exit "$status"
          fi
          report="$log_dir/$(date +%Y%m%d-%H%M%S)-failure.log"
          cp "$log" "$report"
          ${ravenSandboxLog}
          echo "Report file: $report" >> "$report"
          ${ravenReport}/bin/ojuny-raven-report "$report" "$host_file" "$0" "$status" "''${original_args[@]}"
          exit "$status"
        '';
      };

      ravenDesktop = pkgs.makeDesktopItem {
        name = "ojuny-raven";
        exec = "${ravenRun}/bin/ojuny-raven %f";
        desktopName = "Raven (experimental)";
        genericName = "Windows application runtime";
        comment = "Optional experimental runtime for Windows .exe files. Not guaranteed to run a given program.";
        noDisplay = true;
        icon = "application-x-executable";
        mimeTypes = [ "application/x-ms-dos-executable" ];
        categories = [ "Utility" ];
      };

      ravenControlRun = pkgs.writeShellApplication {
        name = "ojuny-raven-control";
        text = ''
          exec ${config.programs.raven.package}/bin/raven --run-process --execution=native --desktop=wayland --timeout-ms=86400000 ${config.programs.raven.package.unwrapped}/libexec/raven/control.exe
        '';
      };

      ravenControlDesktop = pkgs.makeDesktopItem {
        name = "ojuny-raven-control";
        exec = "${ravenControlRun}/bin/ojuny-raven-control";
        desktopName = "Raven control panel (experimental)";
        genericName = "Windows application runtime settings";
        comment = "Folders, network access, refusals, snapshots and layers of the Raven prefix.";
        icon = "preferences-system";
        categories = [
          "Settings"
          "Utility"
        ];
      };

      ravenMsiRun = pkgs.writeShellApplication {
        name = "ojuny-raven-msi";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnused
          pkgs.gnugrep
          pkgs.pciutils
        ];
        text = ''
          if [ "$#" -eq 0 ]; then
            echo "usage: ojuny-raven-msi FILE.msi" >&2
            exit 2
          fi
          original_args=("$@")
          host_file="$(realpath -- "$1")"
          host_dir="$(dirname -- "$host_file")"
          shift
          win_file="Z:$(printf '%s' "$host_file" | sed 's|/|\\|g')"
          win_dir="Z:$(dirname -- "$host_file" | sed 's|/|\\|g')"
          log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/ojuny/raven"
          mkdir -p "$log_dir"
          log="$log_dir/last-msi.log"
          exit_log="$log_dir/last-msi-exit.log"
          {
            echo "Raven MSI launch"
            echo "Time: $(date -Is)"
            echo "Application: $host_file"
            echo "Wrapper: $0"
            echo "Raven command: ${config.programs.raven.package}/bin/raven --run-process --execution=native --exit-code-fd=3 --timeout-ms=86400000 --desktop=wayland --directory=$win_dir --grant-read=$host_dir ${config.programs.raven.package.unwrapped}/libexec/raven/msiexec.exe -- /i $win_file"
            ${ravenDiagnostics}
            echo "Report this at https://github.com/mirkobrombin/raven/issues"
            echo
            echo "--- output ---"
          } > "$log"

          exec 3>"$exit_log"
          if [ -t 1 ] || [ -t 2 ]; then
            set +e
            ${config.programs.raven.package}/bin/raven --run-process --execution=native --exit-code-fd=3 --timeout-ms=86400000 --desktop=wayland --directory="$win_dir" --grant-read="$host_dir" ${config.programs.raven.package.unwrapped}/libexec/raven/msiexec.exe -- /i "$win_file" 2>&1 | tee -a "$log"
            status="''${PIPESTATUS[0]}"
            set -e
          else
            set +e
            ${config.programs.raven.package}/bin/raven --run-process --execution=native --exit-code-fd=3 --timeout-ms=86400000 --desktop=wayland --directory="$win_dir" --grant-read="$host_dir" ${config.programs.raven.package.unwrapped}/libexec/raven/msiexec.exe -- /i "$win_file" >> "$log" 2>&1
            status=$?
            set -e
          fi
          exec 3>&-
          guest_status="$(cat "$exit_log" 2>/dev/null || true)"

          if [ "$status" -eq 0 ]; then
            ${ravenRefresh}/bin/ojuny-raven-refresh >/dev/null 2>&1 || true
            exit 0
          fi
          echo "Exit status: $status" >> "$log"
          echo "Guest exit code: ''${guest_status:-unknown}" >> "$log"
          if [ -t 1 ] || [ -t 2 ]; then
            exit "$status"
          fi
          report="$log_dir/$(date +%Y%m%d-%H%M%S)-msi-failure.log"
          cp "$log" "$report"
          ${ravenSandboxLog}
          echo "Report file: $report" >> "$report"
          ${ravenReport}/bin/ojuny-raven-report "$report" "$host_file" "$0" "$status" "''${original_args[@]}"
          exit "$status"
        '';
      };

      ravenMsiDesktop = pkgs.makeDesktopItem {
        name = "ojuny-raven-msi";
        exec = "${ravenMsiRun}/bin/ojuny-raven-msi %f";
        desktopName = "Raven MSI installer (experimental)";
        genericName = "Windows Installer package";
        comment = "Optional experimental Raven handler for .msi packages. Not guaranteed to run a given installer.";
        noDisplay = true;
        icon = "application-x-executable";
        mimeTypes = [ "application/x-msi" ];
        categories = [ "Utility" ];
      };

      ravenBatRun = pkgs.writeShellApplication {
        name = "ojuny-raven-bat";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnused
          pkgs.gnugrep
          pkgs.pciutils
        ];
        text = ''
          if [ "$#" -eq 0 ]; then
            echo "usage: ojuny-raven-bat FILE.bat" >&2
            exit 2
          fi
          original_args=("$@")
          host_file="$(realpath -- "$1")"
          host_dir="$(dirname -- "$host_file")"
          shift
          win_file="Z:$(printf '%s' "$host_file" | sed 's|/|\\|g')"
          win_dir="Z:$(dirname -- "$host_file" | sed 's|/|\\|g')"
          log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/ojuny/raven"
          mkdir -p "$log_dir"
          log="$log_dir/last-bat.log"
          exit_log="$log_dir/last-bat-exit.log"
          {
            echo "Raven batch launch"
            echo "Time: $(date -Is)"
            echo "Application: $host_file"
            echo "Wrapper: $0"
            echo "Raven command: ${config.programs.raven.package}/bin/raven --run-process --execution=native --exit-code-fd=3 --timeout-ms=86400000 --desktop=wayland --directory=$win_dir --grant-write=$host_dir ${config.programs.raven.package.unwrapped}/libexec/raven/cmd.exe -- /c $win_file"
            ${ravenDiagnostics}
            echo "Report this at https://github.com/mirkobrombin/raven/issues"
            echo
            echo "--- output ---"
          } > "$log"

          exec 3>"$exit_log"
          if [ -t 1 ] || [ -t 2 ]; then
            set +e
            ${config.programs.raven.package}/bin/raven --run-process --execution=native --exit-code-fd=3 --timeout-ms=86400000 --desktop=wayland --directory="$win_dir" --grant-write="$host_dir" ${config.programs.raven.package.unwrapped}/libexec/raven/cmd.exe -- /c "$win_file" 2>&1 | tee -a "$log"
            status="''${PIPESTATUS[0]}"
            set -e
          else
            set +e
            ${config.programs.raven.package}/bin/raven --run-process --execution=native --exit-code-fd=3 --timeout-ms=86400000 --desktop=wayland --directory="$win_dir" --grant-write="$host_dir" ${config.programs.raven.package.unwrapped}/libexec/raven/cmd.exe -- /c "$win_file" >> "$log" 2>&1
            status=$?
            set -e
          fi
          exec 3>&-
          guest_status="$(cat "$exit_log" 2>/dev/null || true)"

          if [ "$status" -eq 0 ]; then
            ${ravenRefresh}/bin/ojuny-raven-refresh >/dev/null 2>&1 || true
            exit 0
          fi
          echo "Exit status: $status" >> "$log"
          echo "Guest exit code: ''${guest_status:-unknown}" >> "$log"
          if [ -t 1 ] || [ -t 2 ]; then
            exit "$status"
          fi
          report="$log_dir/$(date +%Y%m%d-%H%M%S)-bat-failure.log"
          cp "$log" "$report"
          ${ravenSandboxLog}
          echo "Report file: $report" >> "$report"
          ${ravenReport}/bin/ojuny-raven-report "$report" "$host_file" "$0" "$status" "''${original_args[@]}"
          exit "$status"
        '';
      };

      ravenBatDesktop = pkgs.makeDesktopItem {
        name = "ojuny-raven-bat";
        exec = "${ravenBatRun}/bin/ojuny-raven-bat %f";
        desktopName = "Raven batch file (experimental)";
        genericName = "Windows batch file";
        comment = "Optional experimental Raven handler for .bat files. Interactive scripts need a terminal and behavior is not guaranteed.";
        noDisplay = true;
        terminal = true;
        icon = "application-x-executable";
        mimeTypes = [ "application/x-bat" ];
        categories = [ "Utility" ];
      };
    in
    {
      config = {
        programs.raven.enable = cfg.enable;

        desktop.ojuny.mango.rules.window_rule = lib.mkIf cfg.enable [
          {
            app_id = "ojuny-raven-report";
            is_floating = 1;
          }
        ];

        environment.systemPackages = lib.mkIf cfg.enable [
          ravenRefresh
          ravenReport
          ravenRun
          ravenDesktop
          ravenControlRun
          ravenControlDesktop
          ravenMsiRun
          ravenMsiDesktop
          ravenBatRun
          ravenBatDesktop
        ];

        system.activationScripts.ojuny-raven-refresh = lib.mkIf cfg.enable {
          deps = [ "users" ];
          text = lib.concatMapStrings (user: ''
            if [ -d ${lib.escapeShellArg user.home} ]; then
              ${pkgs.util-linux}/bin/runuser -u ${lib.escapeShellArg user.name} -- ${pkgs.coreutils}/bin/env HOME=${lib.escapeShellArg user.home} ${ravenRefresh}/bin/ojuny-raven-refresh >/dev/null 2>&1 || true
            fi
          '') (lib.filter (user: user.isNormalUser && user.home != "/") (lib.attrValues config.users.users));
        };

        xdg.mime.defaultApplications = lib.mkIf cfg.enable {
          "application/x-ms-dos-executable" = lib.mkDefault "ojuny-raven.desktop";
          "application/x-msi" = lib.mkDefault "ojuny-raven-msi.desktop";
          "application/x-bat" = lib.mkDefault "ojuny-raven-bat.desktop";
        };
      };
    };

}
