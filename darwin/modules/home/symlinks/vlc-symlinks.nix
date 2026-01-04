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
# - If <dirSRC> or <dirConf> is polluted, migration is skipped
# - Exception: if runtime paths are NOT symlinks, they are repaired
#   ONLY when destination source-of-truth is empty / missing
# - Never creates duplicate profiles
# - Never overwrites existing dotfiles
# - Never creates empty plist files
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

      path_exists() {
        local p="$1"
        [ -e "$p" ] || [ -L "$p" ]
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

      # conf must exist as the source-of-truth folder (may be empty)
      ensure_dir "${dirConf}"

      srcEmpty="0"
      confEmpty="0"

      if dir_is_empty "${dirSRC}"; then
        srcEmpty="1"
      fi

      if dir_is_empty "${dirConf}"; then
        confEmpty="1"
      fi

      if [ "$srcEmpty" = "1" ] && [ "$confEmpty" = "1" ]; then
        echo "[$APP] Source-of-truth is clean (dirSRC empty + conf empty). Migration allowed ✅"
      else
        echo "[$APP] Source-of-truth is not clean (dirSRC or conf not empty). Migration skipped (repair still allowed) ⚠️"
      fi

      # ------------------------------------------------------------
      # --- APPLICATION SUPPORT: MOVE FOLDER + SYMLINK BACK ---
      # ------------------------------------------------------------
      # Goal:
      # - Move:  ~/Library/Application Support/org.videolan.vlc
      #   To:    /Users/ven/ven-dots/user-data/apps/vlc/conf
      # - Then:  symlink runtime folder name back to conf
      #
      # Rules:
      # - Never create nested symlinks
      # - If runtime is already a symlink → skip or repair target only
      # - Only move runtime folder when conf is empty / missing
      # ------------------------------------------------------------
      if path_is_symlink "${asPath}"; then
        echo "[$APP] Runtime folder already a symlink. Verifying: ${asPath} 🔎"
        ensure_symlink "${asPath}" "${dirConf}" || true
      else
        if [ -d "${asPath}" ]; then
          if [ "$confEmpty" = "1" ]; then
            echo "[$APP] '${asRealName}' is being moved from Application Support 📦"
            move_with_backup "${asPath}" "${dirConf}"

            echo "[$APP] '${asRealName}' is being symlinked back to Application Support 🔗"
            ensure_symlink "${asPath}" "${dirConf}" || true
          else
            echo "[$APP] Skipping Application Support move: conf is not empty (would risk overwrite) ⚠️"
            echo "[$APP] If you want migration, clear: ${dirConf} (and keep it safe) 🧼"
          fi
        else
          if [ -e "${asPath}" ]; then
            echo "[$APP] Runtime path exists but is not a directory (unexpected). Skipping: ${asPath} ⚠️"
          else
            if [ -d "${dirConf}" ] && [ "$confEmpty" = "0" ]; then
              echo "[$APP] Runtime folder missing; conf exists. Creating runtime symlink 🔗"
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
      # Rules:
      # - Never create empty plist files
      # - If runtime plist is already a symlink → verify/repair symlink only
      # - Only move runtime plist when destination plist does not exist
      # ------------------------------------------------------------
      plistName="$(basename "${prefPlist}")"

      if path_is_symlink "${prefPlist}"; then
        echo "[$APP] Preferences item is already a symlink. Verifying: ${prefPlist} 🔎"
        if [ -e "${dotPlist}" ]; then
          ensure_symlink "${prefPlist}" "${dotPlist}" || true
        else
          echo "[$APP] Destination plist missing; will not create an empty file. Skipping repair ⚠️"
        fi
      else
        if [ -e "${prefPlist}" ]; then
          if [ -e "${dotPlist}" ]; then
            echo "[$APP] Destination plist already exists. Not overwriting: ${dotPlist} ⚠️"
            echo "[$APP] If runtime plist is not a symlink, fix manually or remove destination first (safely) 🧰"
          else
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
            echo "[$APP] Preferences plist missing (and no destination). Skipping: ${prefPlist} ✅"
          fi
        fi
      fi

      # ------------------------------------------------------------
      # --- END LOG ---
      # ------------------------------------------------------------
      echo "[$APP] User-data sync complete ✅"
    '';
}
