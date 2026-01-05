# /Users/ven/.config/nix/nix-darwin/darwin/modules/home/userdata/snippetslab-userdata.nix
#
# DARWIN: SNIPPETSLAB USER-DATA (COPY / MIRROR)
# ============================================================
# SnippetsLab is sandboxed. We do NOT symlink anything.
# We only COPY/MIRROR selected runtime data into iCloudDocs
# for easy backup and Git workflow.
#
# SOURCE (RUNTIME)
# ----------------
# - ~/Library/Containers/com.renfei.SnippetsLab/Data/Library/Application Support/Markdown Themes/
# - ~/Library/Containers/com.renfei.SnippetsLab/Data/Library/Application Support/Themes/
# - ~/Library/Containers/com.renfei.SnippetsLab/Data/Library/Preferences/com.renfei.SnippetsLab.plist
#
# BACKUP (ICLOUDDOCS DEST)
# ------------------------
# - ~/iCloudDocs/my-system/user-data/snippetslab/snippetslab-theme-files/snippetslab-markdown-themes/
# - ~/iCloudDocs/my-system/user-data/snippetslab/snippetslab-theme-files/snippetslab-syntax-themes/
# - ~/iCloudDocs/my-system/user-data/snippetslab/com.renfei.SnippetsLab.plist
#
# SAFETY MODEL
# ------------
# - Never symlink to iCloud
# - Never touch FileProvider system folders
# - Only operate inside the snippetslab backup subtree
# - Mirror semantics:
#   - New/changed files are copied to backup
#   - Deleted files are deleted in backup (rsync --delete)
#   - If an entire source folder or plist disappears, its backup is removed too
# - No daemons killed, no iCloud resets, no destructive global ops
# ============================================================

{ config, lib, pkgs, ... }:

let
  home = config.home.homeDirectory;

  # ------------------------------------------------------------
  # USER BACKUP ROOT (ICLOUDDOCS)
  # ------------------------------------------------------------
  dirBackupRoot = "${home}/iCloudDocs/my-system/user-data/snippetslab";

  # Destination for themes (renamed folders)
  dirThemeRoot = "${dirBackupRoot}/snippetslab-theme-files";
  dirDstMarkdownThemes = "${dirThemeRoot}/snippetslab-markdown-themes";
  dirDstSyntaxThemes   = "${dirThemeRoot}/snippetslab-syntax-themes";

  # Destination plist
  dstPlist = "${dirBackupRoot}/com.renfei.SnippetsLab.plist";

  # ------------------------------------------------------------
  # RUNTIME (SANDBOX CONTAINER)
  # ------------------------------------------------------------
  containerLib = "${home}/Library/Containers/com.renfei.SnippetsLab/Data/Library";

  srcMarkdownThemes = "${containerLib}/Application Support/Markdown Themes";
  srcSyntaxThemes   = "${containerLib}/Application Support/Themes";
  srcPlist          = "${containerLib}/Preferences/com.renfei.SnippetsLab.plist";

  # ------------------------------------------------------------
  # TOOLS
  # ------------------------------------------------------------
  rsyncBin = "${pkgs.rsync}/bin/rsync";
in
{
  home.activation.snippetslabUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail

      # ------------------------------------------------------------
      # DARWIN: START LOG
      # ------------------------------------------------------------
      APP="SnippetsLab"
      echo "[$APP] User-data copy/mirror starting…"
      echo "[$APP] Source container: ${containerLib}"
      echo "[$APP] Backup root:      ${dirBackupRoot}"
      echo "[$APP] Using rsync:      ${rsyncBin}"

      # ------------------------------------------------------------
      # HELPERS
      # ------------------------------------------------------------
      ensure_dir() {
        local d="$1"
        if [ -d "$d" ]; then
          return 0
        fi
        echo "[$APP] Creating directory: $d"
        mkdir -p "$d"
      }

      path_exists() { [ -e "$1" ]; }
      dir_exists()  { [ -d "$1" ]; }

      remove_path_if_exists() {
        local p="$1"
        if [ -e "$p" ] || [ -L "$p" ]; then
          echo "[$APP] Removing backup path (source missing): $p"
          rm -rf "$p"
        fi
      }

      # ------------------------------------------------------------
      # WARN IF APP IS RUNNING
      # ------------------------------------------------------------
      if pgrep -x "SnippetsLab" >/dev/null 2>&1; then
        echo "[$APP] WARNING: SnippetsLab appears to be running."
        echo "[$APP] WARNING: Copy may capture in-flight changes. Recommended: quit the app before rebuild."
      fi

      # ------------------------------------------------------------
      # DESTINATION SETUP
      # ------------------------------------------------------------
      ensure_dir "${dirBackupRoot}"
      ensure_dir "${dirThemeRoot}"

      # ------------------------------------------------------------
      # THEMES: MARKDOWN THEMES (MIRROR)
      # ------------------------------------------------------------
      if dir_exists "${srcMarkdownThemes}"; then
        ensure_dir "${dirDstMarkdownThemes}"

        echo "[$APP] Mirroring: Markdown Themes → snippetslab-markdown-themes"
        echo "[$APP]   FROM: ${srcMarkdownThemes}/"
        echo "[$APP]   TO:   ${dirDstMarkdownThemes}/"

        "${rsyncBin}" -a --delete --itemize-changes \
          "${srcMarkdownThemes}/" \
          "${dirDstMarkdownThemes}/" || {
            echo "[$APP] ERROR: rsync failed for Markdown Themes"
            exit 1
          }
      else
        echo "[$APP] Source missing: ${srcMarkdownThemes}"
        remove_path_if_exists "${dirDstMarkdownThemes}"
      fi

      # ------------------------------------------------------------
      # THEMES: SYNTAX THEMES (MIRROR)
      # ------------------------------------------------------------
      if dir_exists "${srcSyntaxThemes}"; then
        ensure_dir "${dirDstSyntaxThemes}"

        echo "[$APP] Mirroring: Themes → snippetslab-syntax-themes"
        echo "[$APP]   FROM: ${srcSyntaxThemes}/"
        echo "[$APP]   TO:   ${dirDstSyntaxThemes}/"

        "${rsyncBin}" -a --delete --itemize-changes \
          "${srcSyntaxThemes}/" \
          "${dirDstSyntaxThemes}/" || {
            echo "[$APP] ERROR: rsync failed for Themes"
            exit 1
          }
      else
        echo "[$APP] Source missing: ${srcSyntaxThemes}"
        remove_path_if_exists "${dirDstSyntaxThemes}"
      fi

      # ------------------------------------------------------------
      # PREFERENCES: PLIST (COPY / REPLACE)
      # ------------------------------------------------------------
      if path_exists "${srcPlist}"; then
        echo "[$APP] Syncing plist:"
        echo "[$APP]   FROM: ${srcPlist}"
        echo "[$APP]   TO:   ${dstPlist}"

        ensure_dir "${dirBackupRoot}"

        "${rsyncBin}" -a --itemize-changes \
          "${srcPlist}" \
          "${dstPlist}" || {
            echo "[$APP] ERROR: rsync failed for plist"
            exit 1
          }
      else
        echo "[$APP] Source plist missing: ${srcPlist}"
        if path_exists "${dstPlist}"; then
          echo "[$APP] Deleting backup plist to match source deletion: ${dstPlist}"
          rm -f "${dstPlist}" || true
        fi
      fi

      # ------------------------------------------------------------
      # END LOG
      # ------------------------------------------------------------
      echo "[$APP] User-data copy/mirror complete."
    '';
}
