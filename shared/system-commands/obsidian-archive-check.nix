# shared/system-commands/obsidian-archive-check.nix
#
# =====================================================================
# OBSIDIAN ARCHIVE REPOSITORY CHECK
#
# Installs one portable command that promotes locally available Obsidian
# extensions and themes into their archival repositories when their GitHub
# source is archived or repeatedly unavailable. macOS additionally schedules
# the command weekly; Linux can use the same command when its host is added.
# =====================================================================

{ installTarget ? "system" }:

{ lib, pkgs, ... }:

let
  # ---- PLATFORM AND PATH SELECTION
  # The SystemBackup volume has the same name on both platforms. Its mount
  # point differs, so paths.nix resolves the correct root before rendering
  # the command.
  platforms = import ../../options/platforms.nix { inherit pkgs; };
  inherit (platforms) isDarwin;
  paths = import ../../options/paths.nix { };
  backupPaths = if isDarwin then paths.darwin.backups else paths.linux.backups;
  mountCommand =
    if isDarwin
    then paths.darwin.system.bin.mount
    else "${pkgs.util-linux}/bin/mount";

  # ---- ARCHIVE CHECKER
  # The runner stores only its small, versioned observation ledger inside
  # each archival repository. Extension and theme contents remain untouched.
  obsidianArchiveCheck = pkgs.writeShellApplication {
    name = "obsidian-archive-check";

    runtimeInputs = with pkgs; [
      coreutils
      curl
      git
      gnugrep
      jq
    ];

    # The shell passes values to jq with --arg; jq filters deliberately keep
    # their own $variables literal, which ShellCheck otherwise flags as SC2016.
    excludeShellChecks = [ "SC2016" ];

    text = ''
      set -euo pipefail

      extensions_root=${lib.escapeShellArg backupPaths.obsidianExtensions}
      themes_root=${lib.escapeShellArg backupPaths.obsidianThemes}
      backup_volume=${lib.escapeShellArg backupPaths.volume}
      mount_command=${lib.escapeShellArg mountCommand}
      missing_recheck_seconds=518400
      dry_run=0

      # ---- COMMAND OPTIONS
      # A dry run performs the GitHub checks but never writes, commits, or
      # pushes. The scheduled invocation intentionally uses the normal mode.
      if [ "''${1:-}" = "--dry-run" ]; then
        dry_run=1
        shift
      fi
      if [ "$#" -ne 0 ]; then
        printf 'Usage: obsidian-archive-check [--dry-run]\n' >&2
        exit 2
      fi

      log() {
        printf '[obsidian archive check] %s\n' "$*"
      }

      fail() {
        log "ERROR $*" >&2
        exit 1
      }

      # ---- EXTERNAL VOLUME SAFETY
      # Refuse an unmounted volume rather than writing into an ordinary local
      # directory that happens to have the same mount-point name.
      if [ ! -d "$backup_volume" ] || ! "$mount_command" | ${pkgs.gnugrep}/bin/grep -Fq " on $backup_volume "; then
        fail "external backup volume is not mounted: $backup_volume"
      fi

      # Check both repositories before asking the Keychain helper for GitHub
      # credentials. A local safety refusal should not prompt for a password.
      preflight_library() {
        local label="$1"
        local root="$2"
        local ignore_file="$root/.gitignore"
        local state_file="$root/.archive-status.json"

        [ -d "$root" ] || fail "missing $label directory: $root"
        ${pkgs.git}/bin/git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "not a Git repository: $root"
        [ -z "$( ${pkgs.git}/bin/git -C "$root" status --porcelain )" ] || fail "repository has uncommitted changes: $root"
        [ ! -L "$ignore_file" ] && [ -f "$ignore_file" ] || fail "missing or symlinked ignore file: $ignore_file"
        [ ! -L "$state_file" ] || fail "refusing to write through symlink: $state_file"
      }

      preflight_library "extensions" "$extensions_root"
      preflight_library "themes" "$themes_root"

      # ---- GITHUB API CREDENTIAL
      # Reuse the Keychain or credential-manager entry that Git already uses
      # for the HTTPS remotes. The token stays in process memory and is sent
      # to curl through standard input, never via an argument or a log.
      credential="$(${pkgs.git}/bin/git credential fill <<'CREDENTIAL' || true
protocol=https
host=github.com

CREDENTIAL
)"
      github_token="$(printf '%s\n' "$credential" | ${pkgs.gnused}/bin/sed -n 's/^password=//p' | ${pkgs.coreutils}/bin/head -n 1)"
      if [ -z "$github_token" ]; then
        fail "GitHub API credential is unavailable through Git's credential helper"
      fi

      api_status=0
      api_body=""

      github_api() {
        local endpoint="$1"
        local response

        if ! response="$({
          printf 'header = "Accept: application/vnd.github+json"\n'
          printf 'header = "Authorization: Bearer %s"\n' "$github_token"
        } | ${pkgs.curl}/bin/curl --silent --show-error --config - --write-out '\n%{http_code}' "https://api.github.com/$endpoint")"; then
          api_status=0
          api_body=""
          return 1
        fi

        api_status="''${response##*$'\n'}"
        api_body="''${response%$'\n'*}"
        [[ "$api_status" =~ ^[0-9]{3}$ ]]
      }

      github_remaining() {
        if ! github_api rate_limit || [ "$api_status" -ne 200 ]; then
          fail "could not read the authenticated GitHub API rate limit"
        fi

        printf '%s' "$api_body" | ${pkgs.jq}/bin/jq -er '.resources.core.remaining'
      }

      update_state() {
        local filter="$1"
        shift
        ${pkgs.jq}/bin/jq "$@" "$filter" "$state_work" > "$state_next"
        ${pkgs.coreutils}/bin/mv "$state_next" "$state_work"
      }

      process_library() {
        local label="$1"
        local root="$2"
        local url_field="$3"
        local state_file="$root/.archive-status.json"
        local ignore_file="$root/.gitignore"
        local state_work state_next ignore_work ignore_next
        local today now_epoch remaining request_count=0
        local directory manifest abandoned raw_url repository status archived
        local previous_epoch previous_count observation_count state_changed=0
        local ignore_changed=0 transient_count=0
        local -a candidate_names=()
        local -a candidate_repositories=()
        local -a promotion_names=()
        local -a promotion_reasons=()

        [ -d "$root" ] || fail "missing $label directory: $root"
        ${pkgs.git}/bin/git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "not a Git repository: $root"
        [ -z "$( ${pkgs.git}/bin/git -C "$root" status --porcelain )" ] || fail "repository has uncommitted changes: $root"
        [ ! -L "$ignore_file" ] && [ -f "$ignore_file" ] || fail "missing or symlinked ignore file: $ignore_file"
        [ ! -L "$state_file" ] || fail "refusing to write through symlink: $state_file"

        state_work="$( ${pkgs.coreutils}/bin/mktemp )"
        state_next="$( ${pkgs.coreutils}/bin/mktemp )"
        if [ -f "$state_file" ]; then
          ${pkgs.coreutils}/bin/cp -- "$state_file" "$state_work"
          ${pkgs.jq}/bin/jq -e 'type == "object" and .version == 1 and (.entries | type == "object")' "$state_work" >/dev/null || fail "archive status file has an unsupported shape: $state_file"
        else
          printf '%s\n' '{"version":1,"entries":{}}' > "$state_work"
        fi

        while IFS= read -r -d $'\0' directory; do
          manifest="$directory/manifest.json"
          [ ! -L "$manifest" ] && [ -f "$manifest" ] || continue
          abandoned="$( ${pkgs.jq}/bin/jq -r 'if .abandoned == true then "true" else "false" end' "$manifest" 2>/dev/null || true )"
          [ "$abandoned" = "true" ] && continue
          raw_url="$( ${pkgs.jq}/bin/jq -r --arg field "$url_field" '.[$field] // empty | strings' "$manifest" 2>/dev/null || true )"
          [ -n "$raw_url" ] || continue

          if [[ "$raw_url" =~ ^https?://(www\.)?github\.com/([A-Za-z0-9][A-Za-z0-9-]*)/([A-Za-z0-9_.-]+)(\.git)?/?$ ]]; then
            repository="''${BASH_REMATCH[2]}/''${BASH_REMATCH[3]}"
          else
            continue
          fi

          if ${pkgs.jq}/bin/jq -e --arg name "$( ${pkgs.coreutils}/bin/basename -- "$directory" )" '.entries[$name].promotion? | type == "object"' "$state_work" >/dev/null; then
            continue
          fi
          candidate_names+=("$( ${pkgs.coreutils}/bin/basename -- "$directory" )")
          candidate_repositories+=("$repository")
          request_count=$((request_count + 1))
        done < <(${pkgs.findutils}/bin/find "$root" -mindepth 1 -maxdepth 1 -type d -not -name .git -print0)

        remaining="$(github_remaining)"
        if [ "$remaining" -lt "$((request_count + 10))" ]; then
          fail "GitHub API has only $remaining requests remaining; $request_count are required for $label"
        fi

        today="$( ${pkgs.coreutils}/bin/date +%F )"
        now_epoch="$( ${pkgs.coreutils}/bin/date +%s )"

        for index in "''${!candidate_names[@]}"; do
          directory="$root/''${candidate_names[$index]}"
          repository="''${candidate_repositories[$index]}"
          if ! github_api "repos/$repository"; then
            transient_count=$((transient_count + 1))
            log "SKIP $label ''${candidate_names[$index]}: GitHub request failed"
            continue
          fi

          status="unknown"
          case "$api_status" in
            200)
              archived="$(printf '%s' "$api_body" | ${pkgs.jq}/bin/jq -r '.archived // false' 2>/dev/null || printf 'false')"
              if [ "$archived" = "true" ]; then
                status="archived"
              else
                status="live"
              fi
              ;;
            404|410) status="missing" ;;
            301|302) status="moved" ;;
            403) status="rate-limited" ;;
          esac

          case "$status" in
            archived)
              update_state \
                --arg name "''${candidate_names[$index]}" \
                --arg repository "$repository" \
                --arg today "$today" \
                '.entries[$name] = { promotion: { date: $today, reason: "github-archived", repository: $repository } }'
              promotion_names+=("''${candidate_names[$index]}")
              promotion_reasons+=("GitHub archived")
              state_changed=1
              ;;
            missing)
              previous_epoch="$( ${pkgs.jq}/bin/jq -r --arg name "''${candidate_names[$index]}" '.entries[$name].lastMissingEpoch // 0' "$state_work" )"
              previous_count="$( ${pkgs.jq}/bin/jq -r --arg name "''${candidate_names[$index]}" '.entries[$name].missingObservations // 0' "$state_work" )"
              if [ "$((now_epoch - previous_epoch))" -ge "$missing_recheck_seconds" ]; then
                observation_count=$((previous_count + 1))
              else
                observation_count="$previous_count"
              fi

              if [ "$observation_count" -ge 2 ]; then
                update_state \
                  --arg name "''${candidate_names[$index]}" \
                  --arg repository "$repository" \
                  --arg today "$today" \
                  '.entries[$name] = { promotion: { date: $today, reason: "github-missing-twice", repository: $repository } }'
                promotion_names+=("''${candidate_names[$index]}")
                promotion_reasons+=("GitHub unavailable twice")
              else
                update_state \
                  --arg name "''${candidate_names[$index]}" \
                  --arg repository "$repository" \
                  --arg today "$today" \
                  --argjson epoch "$now_epoch" \
                  --argjson observations "$observation_count" \
                  '.entries[$name] = { repository: $repository, firstMissingDate: (.entries[$name].firstMissingDate // $today), lastMissingDate: $today, lastMissingEpoch: $epoch, missingObservations: $observations }'
              fi
              state_changed=1
              ;;
            live)
              if ${pkgs.jq}/bin/jq -e --arg name "''${candidate_names[$index]}" '.entries | has($name)' "$state_work" >/dev/null; then
                update_state --arg name "''${candidate_names[$index]}" 'del(.entries[$name])'
                state_changed=1
              fi
              ;;
            *)
              transient_count=$((transient_count + 1))
              log "SKIP $label ''${candidate_names[$index]}: GitHub status is $status"
              ;;
          esac
        done

        if [ "$state_changed" -eq 0 ]; then
          log "No $label archive changes; $transient_count inconclusive GitHub responses"
          ${pkgs.coreutils}/bin/rm -f -- "$state_work" "$state_next"
          return 0
        fi

        if [ "$dry_run" -eq 1 ]; then
          for index in "''${!promotion_names[@]}"; do
            log "DRY RUN promote $label ''${promotion_names[$index]}: ''${promotion_reasons[$index]}"
          done
          [ "''${#promotion_names[@]}" -gt 0 ] || log "DRY RUN update $state_file"
          ${pkgs.coreutils}/bin/rm -f -- "$state_work" "$state_next"
          return 0
        fi

        ignore_work="$( ${pkgs.coreutils}/bin/mktemp )"
        ignore_next="$( ${pkgs.coreutils}/bin/mktemp )"
        ${pkgs.coreutils}/bin/cp -- "$ignore_file" "$ignore_work"
        for index in "''${!promotion_names[@]}"; do
          ${pkgs.gnugrep}/bin/grep -Fvx -- "/''${promotion_names[$index]}/" "$ignore_work" > "$ignore_next" || true
          ${pkgs.coreutils}/bin/mv "$ignore_next" "$ignore_work"
          ignore_next="$( ${pkgs.coreutils}/bin/mktemp )"
        done
        if ! ${pkgs.diffutils}/bin/cmp -s "$ignore_file" "$ignore_work"; then
          ${pkgs.coreutils}/bin/mv "$ignore_work" "$ignore_file"
          ignore_changed=1
        else
          ${pkgs.coreutils}/bin/rm -f -- "$ignore_work"
        fi
        ${pkgs.coreutils}/bin/rm -f -- "$ignore_next"
        ${pkgs.coreutils}/bin/mv "$state_work" "$state_file"
        ${pkgs.coreutils}/bin/rm -f -- "$state_next"

        ${pkgs.git}/bin/git -C "$root" add -- .archive-status.json
        if [ "$ignore_changed" -eq 1 ]; then
          ${pkgs.git}/bin/git -C "$root" add -- .gitignore
        fi
        if [ "''${#promotion_names[@]}" -gt 0 ]; then
          ${pkgs.git}/bin/git -C "$root" add -- "''${promotion_names[@]}"
          message="Archive $label: ''${promotion_names[*]}"
        else
          message="Record unavailable GitHub $label repositories"
        fi

        if ! ${pkgs.git}/bin/git -C "$root" diff --cached --quiet; then
          ${pkgs.git}/bin/git -C "$root" commit -m "$message"
          ${pkgs.git}/bin/git -C "$root" push origin HEAD
        fi

        for index in "''${!promotion_names[@]}"; do
          log "PROMOTED $label ''${promotion_names[$index]}: ''${promotion_reasons[$index]}"
        done
      }

      process_library "extensions" "$extensions_root" "pluginUrl"
      process_library "themes" "$themes_root" "themeUrl"
    '';
  };
in
(
  if installTarget == "system" then
    {
      environment.systemPackages = [ obsidianArchiveCheck ];
    }
  else
    {
      home.packages = [ obsidianArchiveCheck ];
    }
)
// lib.optionalAttrs (isDarwin && installTarget == "system") {
  # ---- macOS SCHEDULE
  # Linux receives the same manual command. Its service manager is not yet
  # configured, so only nix-darwin owns the current weekly schedule.
  launchd.user.agents.obsidian-archive-check = {
    serviceConfig = {
      Label = "com.ven.obsidian-archive-check";
      ProgramArguments = [ "${obsidianArchiveCheck}/bin/obsidian-archive-check" ];
      RunAtLoad = false;
      KeepAlive = false;
      StartInterval = 604800;
      ProcessType = "Background";
      Nice = 20;
      LowPriorityIO = true;
      LowPriorityBackgroundIO = true;
      StandardOutPath = "${paths.darwin.library.logs}/obsidian-archive-check.log";
      StandardErrorPath = "${paths.darwin.library.logs}/obsidian-archive-check-error.log";
    };
  };
}
