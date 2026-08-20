# darwin/packages/codex/codex-repair.nix
#
# CODEX: PROFILE STORAGE REPAIR
# =====================================================================
# One command that finishes the shared-conversation migration that
# extensions/shared.nix deliberately refuses to perform during
# activation, because it moves user conversations and rewrites an
# application database.
#
# Two defects are repaired:
#
#   1. archived_sessions is still a real directory inside each profile
#      while sessions is a symlink into the shared tree. Archiving moves
#      a conversation between the two, so they have to live under one
#      root.
#
#   2. threads.rollout_path in each profile's state database records the
#      same conversation files under two different names: the profile
#      form ($CODEX_HOME/sessions/...) and the resolved shared form
#      (shared/sessions/...). Codex derives the archive destination
#      relative to $CODEX_HOME, so a row that carries the resolved form
#      has no reachable destination and thread/archive silently does
#      nothing. That is the "state db discrepancy during
#      find_thread_path_by_id_str_in_subdir: falling_back" warning in
#      the application log.
#
# The command is a dry run unless --apply is passed, refuses to touch
# anything while ChatGPT is running, never deletes a conversation, and
# backs up every database before writing to it.
# =====================================================================

{ lib, options, pkgs, ... }:

let
  helpers = import ../../../options { inherit lib options pkgs; };

  inherit (helpers) paths;

  codex = paths.darwin.agents.codex;

  profiles = [
    {
      name = "api";
      root = codex.api;
    }
    {
      name = "chatgpt";
      root = codex.chatgpt;
    }
  ];

  renderProfile = profile: ''
    repair_profile \
      ${lib.escapeShellArg profile.name} \
      ${lib.escapeShellArg profile.root}
  '';

  codexRepair = pkgs.writeShellApplication {
    name = "codex-repair";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.sqlite
    ];

    text = ''
      # PATHS
      # =========================

      shared_sessions=${lib.escapeShellArg codex.sharedSessions}
      shared_archive=${lib.escapeShellArg codex.sharedArchivedSessions}

      apply="false"


      # ARGUMENTS
      # =========================

      for argument in "$@"; do
        case "$argument" in
          --apply)
            apply="true"
            ;;
          -h|--help)
            printf 'Usage: codex-repair [--apply]\n\n'
            printf 'Reports, and with --apply repairs, Codex shared\n'
            printf 'conversation storage. ChatGPT must be closed.\n'
            exit 0
            ;;
          *)
            printf 'codex-repair: unknown argument: %s\n' "$argument" >&2
            exit 2
            ;;
        esac
      done

      if test "$apply" = "false"; then
        printf 'Running in report mode. Pass --apply to make changes.\n\n'
      fi


      # PREREQUISITES
      # =========================
      # Both steps move files the running application holds open, so a
      # live ChatGPT process is a hard stop.

      if /usr/bin/pgrep -qf '/Applications/ChatGPT.app/Contents/MacOS/ChatGPT'; then
        printf 'codex-repair: ChatGPT is running. Quit it first.\n' >&2
        exit 1
      fi

      if test ! -d "$shared_sessions"; then
        printf 'codex-repair: shared session root is missing: %s\n' "$shared_sessions" >&2
        exit 1
      fi

      mkdir -p "$shared_archive"


      # ARCHIVE MIGRATION
      # =========================
      # Conversations are moved, never replaced. A name that already
      # exists in the shared tree is left where it is and reported, so
      # the profile directory stays in place and nothing is lost.

      migrate_archive() {
        local profile_name="$1"
        local archive_root="$2"
        local existing_target
        local relative
        local destination
        local conflicts

        if test -L "$archive_root"; then
          existing_target="$(readlink "$archive_root")"

          if test "$existing_target" = "$shared_archive"; then
            printf '  archive: already shared\n'
          else
            printf '  archive: UNMANAGED link -> %s\n' "$existing_target"
          fi

          return 0
        fi

        if test ! -d "$archive_root"; then
          if test "$apply" = "true"; then
            ln -s "$shared_archive" "$archive_root"
            printf '  archive: linked to the shared tree\n'
          else
            printf '  archive: would be linked to the shared tree\n'
          fi

          return 0
        fi

        if test "$apply" = "false"; then
          printf '  archive: %s file(s) would move into the shared tree\n' \
            "$(find "$archive_root" -type f ! -name '.DS_Store' | wc -l | tr -d ' ')"
          return 0
        fi

        conflicts=0

        while IFS= read -r -d "" source; do
          relative="''${source#"$archive_root"/}"
          destination="$shared_archive/$relative"

          if test -e "$destination"; then
            printf '  archive: SKIPPED, already present: %s\n' "$relative"
            conflicts=$((conflicts + 1))
            continue
          fi

          mkdir -p "$(dirname "$destination")"
          mv "$source" "$destination"
        done < <(find "$archive_root" -type f ! -name '.DS_Store' -print0)

        find "$archive_root" -name '.DS_Store' -type f -delete

        if test "$conflicts" -ne 0; then
          printf '  archive: %s conflict(s); %s left in place\n' \
            "$conflicts" "$archive_root"
          return 0
        fi

        # Only an emptied directory is replaced, so a stray file always
        # wins over the migration.
        if find "$archive_root" -mindepth 1 -type f | read -r; then
          printf '  archive: unexpected leftover files; %s left in place\n' "$archive_root"
          return 0
        fi

        rm -r "$archive_root"
        ln -s "$shared_archive" "$archive_root"

        printf '  archive: migrated and linked to the shared tree\n'
      }


      # ROLLOUT PATH NORMALISATION
      # =========================
      # The profile form is the canonical one: it is what Codex builds
      # its archive destination from. Rows recorded under the resolved
      # shared form are rewritten to it. The files themselves are not
      # touched -- both spellings already name the same file.

      normalise_paths() {
        local profile_name="$1"
        local profile_root="$2"
        local database="$2/sqlite/state_5.sqlite"
        local backup_directory="$2/sqlite/backups"
        local stamp
        local affected

        if test ! -f "$database"; then
          printf '  database: not present (%s)\n' "$database"
          return 0
        fi

        affected="$(
          sqlite3 "file:$database?mode=ro" "
            SELECT COUNT(*) FROM threads
             WHERE rollout_path LIKE '$shared_sessions/%'
                OR rollout_path LIKE '$shared_archive/%';
          "
        )"

        if test "$affected" = "0"; then
          printf '  database: no rows need rewriting\n'
          return 0
        fi

        if test "$apply" = "false"; then
          printf '  database: %s row(s) would be rewritten\n' "$affected"
          return 0
        fi

        stamp="$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_directory"

        sqlite3 "$database" \
          ".backup '$backup_directory/state_5.sqlite.$stamp'"

        sqlite3 "$database" "
          UPDATE threads
             SET rollout_path = replace(
                   rollout_path,
                   '$shared_sessions/',
                   '$profile_root/sessions/'
                 )
           WHERE rollout_path LIKE '$shared_sessions/%';

          UPDATE threads
             SET rollout_path = replace(
                   rollout_path,
                   '$shared_archive/',
                   '$profile_root/archived_sessions/'
                 )
           WHERE rollout_path LIKE '$shared_archive/%';
        "

        printf '  database: rewrote %s row(s), backup in %s\n' \
          "$affected" "$backup_directory"
      }


      # PROFILE REPAIR
      # =========================

      repair_profile() {
        local profile_name="$1"
        local profile_root="$2"

        printf '%s\n' "$profile_name"

        if test ! -d "$profile_root"; then
          printf '  profile root is missing: %s\n\n' "$profile_root"
          return 0
        fi

        migrate_archive "$profile_name" "$profile_root/archived_sessions"
        normalise_paths "$profile_name" "$profile_root"

        printf '\n'
      }

      ${lib.concatMapStringsSep "\n" renderProfile profiles}

      if test "$apply" = "true"; then
        printf 'Done. Reopen ChatGPT and archive a conversation to verify.\n'
      fi
    '';
  };
in
{
  environment.systemPackages = [
    codexRepair
  ];
}
