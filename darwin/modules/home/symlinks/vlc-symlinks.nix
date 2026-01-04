# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/symlinks/vlc-symlinks.nix
#
# DARWIN: VLC USER-DATA
# ============================================================
# VLC is a media player for macOS.
#
# Source of truth:
# - Application Support folder lives in:     <dirSRC>/conf
# - Preferences plist lives in:             <dirSRC>
#
# Runtime paths (what VLC still "sees"):
# - ~/Library/Application Support/org.videolan.vlc
# - ~/Library/Preferences/org.videolan.vlc.plist
#
# Safety model:
# - "conf/" existence does NOT count as pollution
# - "Polluted" means real migrated artifacts exist, or unexpected items exist
# - Exception: if runtime paths are NOT symlinks, they are repaired
#   ONLY when destination source-of-truth is empty / missing (per-path)
# - Never creates duplicate profiles
# - Never overwrites existing dotfiles
# - CFPreferences exception (plist only): may create an empty destination plist
#   to prevent macOS from recreating a real runtime plist and resetting settings
# ============================================================

{ config, lib, ... }:

let
  # ------------------------------------------------------------
  # --- PATHS ---
  # ------------------------------------------------------------
  home = config.home.homeDirectory;

  # Source-of-truth root for all apps
  dirRoot = "/Users/ven/ven-dots/user-data/apps";

  # App slug (rules-compliant name)
  appSlug = "vlc";

  # App source-of-truth directories
  dirSRC  = "${dirRoot}/${appSlug}";
  dirConf = "${dirSRC}/conf";

  # Application Support runtime folder (symlink name MUST match original)
  asRealName = "org.videolan.vlc";
  asPath     = "${home}/Library/Application Support/${asRealName}";

  # Preferences runtime plist
  prefPlist = "${home}/Library/Preferences/org.videolan.vlc.plist";

  # Preferences source-of-truth plist
  dotPlist  = "${dirSRC}/org.videolan.vlc.plist";
in
{
  home.activation.vlcUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      # ------------------------------------------------------------
      # --- START LOG ---
      # ------------------------------------------------------------
      APP="VLC"
      echo "[$APP] User-data sync starting… 🚀"

      # ------------------------------------------------------------
      # --- HELPERS: FILESYSTEM CHECKS ---
      # ------------------------------------------------------------
      ensure_dir() {
        local d="$1"
        if [ ! -d "$d" ]; then
          echo "[$APP] Creating directory: $d 📁"
          mkdir -p "$d" || true
        fi
      }

      dir_is_empty() {
        local d="$1"
        [ -d "$d" ] || return 0
        [ -z "$(ls -A "$d" 2>/dev/null || true)" ]
      }

      path_is_symlink() {
        local p="$1"
        [ -L "$p" ]
      }

      unlink_if_symlink() {
        local p="$1"
        if [ -L "$p" ]; then
          echo "[$APP] Removing existing symlink: $p 🧹"
          unlink "$p" || true
        fi
      }

      # ------------------------------------------------------------
      # --- HELPERS: SAFE BACKUPS + MOVES ---
      # Non-empty destination (not symlink) → timestamped backup
      # ------------------------------------------------------------
      backup_dest_if_needed() {
        local dst="$1"

        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
          if [ -d "$dst" ] && dir_is_empty "$dst"; then
            rmdir "$dst" 2>/dev/null || true
            return 0
          fi

          local ts
          ts="$(date +%Y%m%d-%H%M%S)"
          local backup
          backup="$dst.backup-$ts"

          echo "[$APP] Destination collision. Backing up: $dst → $backup 📦"
          mv "$dst" "$backup" || true
        fi
      }

      move_with_backup() {
        local src="$1"
        local dst="$2"

        backup_dest_if_needed "$dst"
        echo "[$APP] Moving: $src → $dst 📦"
        mv "$src" "$dst" || true
      }

      backup_runtime_file_only() {
        local src="$1"

        if [ -e "$src" ] && [ ! -L "$src" ]; then
          local ts
          ts="$(date +%Y%m%d-%H%M%S)"
          local backup
          backup="$src.backup-$ts"

          echo "[$APP] Runtime collision. Backing up: $src → $backup 📦"
          mv "$src" "$backup" || true
        fi
      }

      # ------------------------------------------------------------
      # --- HELPERS: SYMLINK MANAGEMENT ---
      # Creates/repairs a single symlink when safe
      # ------------------------------------------------------------
      ensure_symlink() {
        local linkPath="$1"
        local targetPath="$2"

        if [ -L "$linkPath" ]; then
          local currentTarget
          currentTarget="$(readlink "$linkPath" || true)"

          if [ "$currentTarget" = "$targetPath" ]; then
            echo "[$APP] Symlink OK: $linkPath → $targetPath ✅"
            return 0
          fi

          echo "[$APP] Symlink wrong: $linkPath → $currentTarget (expected $targetPath) ⚠️"
          echo "[$APP] Fixing symlink: $linkPath → $targetPath 🔧"
          unlink_if_symlink "$linkPath"
          ln -s "$targetPath" "$linkPath" || true
          echo "[$APP] Symlink fixed: $linkPath → $targetPath ✅"
          return 0
        fi

        if [ -e "$linkPath" ]; then
          echo "[$APP] Not a symlink at: $linkPath (will not delete automatically) ⚠️"
          return 1
        fi

        echo "[$APP] Creating symlink: $linkPath → $targetPath 🔗"
        ln -s "$targetPath" "$linkPath" || true
        echo "[$APP] Symlink created: $linkPath → $targetPath ✅"
      }

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH SETUP ---
      # ------------------------------------------------------------
      ensure_dir "${dirSRC}"
      ensure_dir "${dirConf}"

      # ------------------------------------------------------------
      # --- SOURCE OF TRUTH: CLEAN / POLLUTED CHECK ---
      # ------------------------------------------------------------
      # Clean means:
      # - conf exists (allowed) but is empty
      # - destination plist does not exist
      # - dirSRC contains no unexpected items (conf/ is allowed)
      #
      # Polluted means:
      # - conf contains any files/folders (real migrated VLC data)
      # - destination plist exists (real migrated VLC prefs)
      # - any unexpected item exists in dirSRC
      # ------------------------------------------------------------
      confHasData="0"
      if [ -d "${dirConf}" ] && ! dir_is_empty "${dirConf}"; then
        confHasData="1"
      fi

      plistExists="0"
      if [ -e "${dotPlist}" ]; then
        plistExists="1"
      fi

      unexpectedInSRC="0"
      if [ -d "${dirSRC}" ]; then
        # Allowed at dirSRC root:
        # - conf/
        # - org.videolan.vlc.plist
        #
        # Anything else counts as unexpected.
        if ls -A "${dirSRC}" 2>/dev/null | while IFS= read -r item; do
          [ -n "$item" ] || continue
          if [ "$item" != "conf" ] && [ "$item" != "org.videolan.vlc.plist" ]; then
            exit 10
          fi
        done; then
          unexpectedInSRC="0"
        else
          unexpectedInSRC="1"
        fi
      fi

      if [ "$confHasData" = "0" ] && [ "$plistExists" = "0" ] && [ "$unexpectedInSRC" = "0" ]; then
        echo "[$APP] Source-of-truth is clean (no plist + conf empty + no extra items). Migration allowed ✅"
      else
        echo "[$APP] Source-of-truth is polluted (plist/conf/extra items detected). Migration skipped (repair still allowed) ⚠️"
      fi

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT: MOVE FOLDER + SYMLINK BACK ---
      # ------------------------------------------------------------
      # Goal:
      # - Move:  ~/Library/Application Support/org.videolan.vlc
      #   To:    /Users/ven/ven-dots/user-data/apps/vlc/conf
      # - Then:  symlink runtime folder name back to conf
      #
      # Per your rules:
      # - We only do the move when conf is empty (no migrated data exists)
      # - If runtime is already a symlink, we only verify/repair the symlink
      # ------------------------------------------------------------
      if path_is_symlink "${asPath}"; then
        echo "[$APP] Runtime folder already a symlink. Verifying: ${asPath} 🔎"
        ensure_symlink "${asPath}" "${dirConf}" || true
      else
        if [ -d "${asPath}" ]; then
          if [ "$confHasData" = "0" ]; then
            echo "[$APP] '${asRealName}' is being moved from Application Support 📦"
            move_with_backup "${asPath}" "${dirConf}"

            echo "[$APP] '${asRealName}' is being symlinked back to Application Support 🔗"
            ensure_symlink "${asPath}" "${dirConf}" || true
          else
            echo "[$APP] Skipping Application Support move: conf already has data (avoid overwrite) ⚠️"
            echo "[$APP] Runtime folder will not be replaced automatically: ${asPath} 🧰"
          fi
        else
          if [ -e "${asPath}" ]; then
            echo "[$APP] Runtime path exists but is not a directory (unexpected). Skipping: ${asPath} ⚠️"
          else
            if [ -d "${dirConf}" ] && [ "$confHasData" = "1" ]; then
              echo "[$APP] Runtime folder missing; conf has data. Creating runtime symlink 🔗"
              ensure_symlink "${asPath}" "${dirConf}" || true
            else
              echo "[$APP] Runtime folder missing and conf empty; nothing to migrate. Skipping ✅"
            fi
          fi
        fi
      fi

      # ------------------------------------------------------------
      # --- PREFERENCES: PLIST MOVE + SYMLINK BACK ---
      # ------------------------------------------------------------
      # Goal:
      # - Move:  ~/Library/Preferences/org.videolan.vlc.plist
      #   To:    /Users/ven/ven-dots/user-data/apps/vlc/org.videolan.vlc.plist
      # - Then:  symlink plist back to Preferences
      #
      # IMPORTANT (CFPreferences / macOS):
      # - VLC writes preferences via CFPreferences very early.
      # - If the runtime plist is a symlink but the destination file does not exist,
      #   macOS may recreate a REAL plist at the runtime path and VLC will reset settings.
      #
      # Exception (plist only):
      # - If we need a destination file for the symlink to be respected,
      #   we may create an empty destination plist file.
      # - This prevents macOS from recreating the runtime plist outside of the source-of-truth.
      # ------------------------------------------------------------
      plistName="$(basename "${prefPlist}")"

      if path_is_symlink "${prefPlist}"; then
        echo "[$APP] Preferences item is already a symlink. Verifying: ${prefPlist} 🔎"

        if [ ! -e "${dotPlist}" ]; then
          echo "[$APP] CFPreferences requires a real destination plist. Creating: ${dotPlist} 🧩"
          : > "${dotPlist}" || true
        fi

        ensure_symlink "${prefPlist}" "${dotPlist}" || true
      else
        if [ -e "${prefPlist}" ]; then
          if [ -e "${dotPlist}" ]; then
            # Common failure mode:
            # - destination exists (source-of-truth)
            # - macOS recreated runtime plist as a real file
            #
            # Fix:
            # - backup runtime file
            # - replace with symlink to destination
            echo "[$APP] Runtime plist is a real file but destination exists. Repairing symlink 🔧"
            backup_runtime_file_only "${prefPlist}"

            echo "[$APP] ''${plistName} being symlinked back to Preferences 🔗"
            ensure_symlink "${prefPlist}" "${dotPlist}" || true
          else
            # Destination missing → safe to migrate runtime plist into source-of-truth
            echo "[$APP] ''${plistName} is being moved from Preferences to ${dirSRC} 📄"
            move_with_backup "${prefPlist}" "${dotPlist}"

            echo "[$APP] ''${plistName} being symlinked back to Preferences 🔗"
            ensure_symlink "${prefPlist}" "${dotPlist}" || true
          fi
        else
          if [ -e "${dotPlist}" ]; then
            echo "[$APP] Runtime plist missing; destination exists. Creating runtime symlink 🔗"
            ensure_symlink "${prefPlist}" "${dotPlist}" || true
          else
            # Neither runtime nor destination exists.
            # To prevent VLC from creating a fresh runtime plist and resetting settings,
            # create an empty destination plist and symlink it back.
            echo "[$APP] Preferences plist missing. Creating destination plist for CFPreferences 🧩"
            : > "${dotPlist}" || true

            echo "[$APP] ''${plistName} being symlinked back to Preferences 🔗"
            ensure_symlink "${prefPlist}" "${dotPlist}" || true
          fi
        fi
      fi

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data sync complete ✅"
    '';
}
