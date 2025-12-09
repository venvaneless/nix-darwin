# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/user-data/obsidian-sync.nix
# 
# DARWIN: OBSIDIAN VAULT + BACKUP SYNC (HM)
# =========================================
# - Syncs Obsidian vaults between:
#     * /Users/ven/ven-dots/user-data/apps/obsidian
#     * /Users/ven/Library/Mobile Documents/iCloud~md~obsidian/Documents
# - Backs up plugins/themes/snippets from all vaults to:
#     * /Users/ven/iCloudDocs/my-system/user-data/obsidian/plugins
#     * /Users/ven/iCloudDocs/my-system/user-data/obsidian/themes
#     * /Users/ven/iCloudDocs/my-system/user-data/obsidian/snippets/00 mine/<vault>
# - Runs automatically on Home Manager activation (drs),
#   and provides a manual `obsidian-sync` command.
# =========================================

{ config, pkgs, lib, ... }:

let
  obsidianSyncScript = pkgs.writeShellScriptBin "obsidian-sync" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo "[obsidian-sync] Starting Obsidian sync..."

    # --- Paths ---------------------------------------------------------
    VAULTS_DOTS="/Users/ven/ven-dots/user-data/apps/obsidian"
    VAULTS_ICLOUD="/Users/ven/Library/Mobile Documents/iCloud~md~obsidian/Documents"

    BACKUP_ROOT="/Users/ven/iCloudDocs/my-system/user-data/obsidian"
    BACKUP_PLUGINS="${BACKUP_ROOT}/plugins"
    BACKUP_THEMES="${BACKUP_ROOT}/themes"
    BACKUP_SNIPPETS="${BACKUP_ROOT}/snippets/00 mine"

    # --- Ensure base directories exist ---------------------------------
    mkdir -p "${VAULTS_DOTS}"
    mkdir -p "${VAULTS_ICLOUD}"

    mkdir -p "${BACKUP_PLUGINS}"
    mkdir -p "${BACKUP_THEMES}"
    mkdir -p "${BACKUP_SNIPPETS}"

    echo "[obsidian-sync] Vault roots:"
    echo "  - ven-dots : ${VAULTS_DOTS}"
    echo "  - iCloud   : ${VAULTS_ICLOUD}"

    echo "[obsidian-sync] Backup dirs:"
    echo "  - plugins  : ${BACKUP_PLUGINS}"
    echo "  - themes   : ${BACKUP_THEMES}"
    echo "  - snippets : ${BACKUP_SNIPPETS}"

    # --- Basic sanity checks -------------------------------------------
    if [ ! -d "${VAULTS_DOTS}" ]; then
      echo "[obsidian-sync] ERROR: ven-dots vault root does not exist: ${VAULTS_DOTS}" >&2
      exit 1
    fi

    if [ ! -d "${VAULTS_ICLOUD}" ]; then
      echo "[obsidian-sync] WARN: iCloud vault root does not exist yet: ${VAULTS_ICLOUD}"
      echo "[obsidian-sync] Creating empty directory so future syncs work."
      mkdir -p "${VAULTS_ICLOUD}"
    fi

    # --- Two-way safe sync (no deletes, newer wins) --------------------
    echo "[obsidian-sync] Syncing ven-dots -> iCloud (newer files only)..."
    rsync -av \
      --update \
      --exclude ".DS_Store" \
      --exclude ".Trash" \
      "${VAULTS_DOTS}/" "${VAULTS_ICLOUD}/"

    echo "[obsidian-sync] Syncing iCloud -> ven-dots (newer files only)..."
    rsync -av \
      --update \
      --exclude ".DS_Store" \
      --exclude ".Trash" \
      "${VAULTS_ICLOUD}/" "${VAULTS_DOTS}/"

    # --- Backup plugins / themes / snippets from each vault ------------
    echo "[obsidian-sync] Collecting plugins/themes/snippets from all vaults..."

    vault_count=0

    for vault_path in "${VAULTS_DOTS}"/*; do
      if [ ! -d "${vault_path}" ]; then
        continue
      fi

      vault_name="$(basename "${vault_path}")"
      obsidian_dir="${vault_path}/.obsidian"

      if [ ! -d "${obsidian_dir}" ]; then
        echo "[obsidian-sync] Skipping ${vault_name} (no .obsidian dir)."
        continue
      fi

      echo "[obsidian-sync] Processing vault: ${vault_name}"
      vault_count=$((vault_count + 1))

      # --- Plugins backup ----------------------------------------------
      if [ -d "${obsidian_dir}/plugins" ]; then
        target_plugins="${BACKUP_PLUGINS}/${vault_name}"
        mkdir -p "${target_plugins}"
        echo "[obsidian-sync]  - Backing up plugins -> ${target_plugins}"
        rsync -av --delete "${obsidian_dir}/plugins/" "${target_plugins}/"
      else
        echo "[obsidian-sync]  - No plugins directory."
      fi

      # --- Themes backup -----------------------------------------------
      if [ -d "${obsidian_dir}/themes" ]; then
        target_themes="${BACKUP_THEMES}/${vault_name}"
        mkdir -p "${target_themes}"
        echo "[obsidian-sync]  - Backing up themes  -> ${target_themes}"
        rsync -av --delete "${obsidian_dir}/themes/" "${target_themes}/"
      else
        echo "[obsidian-sync]  - No themes directory."
      fi

      # --- Snippets backup ---------------------------------------------
      if [ -d "${obsidian_dir}/snippets" ]; then
        target_snippets="${BACKUP_SNIPPETS}/${vault_name}"
        mkdir -p "${target_snippets}"
        echo "[obsidian-sync]  - Backing up snippets -> ${target_snippets}"
        rsync -av --delete "${obsidian_dir}/snippets/" "${target_snippets}/"
      else
        echo "[obsidian-sync]  - No snippets directory."
      fi
    done

    echo "[obsidian-sync] Processed ${vault_count} vault(s)."
    echo "[obsidian-sync] Done."
  '';
in
{
  # Make the `obsidian-sync` command available in your PATH
  home.packages = [
    obsidianSyncScript
    pkgs.rsync
  ];

  # Run the sync automatically whenever Home Manager activates (drs)
  home.activation.obsidianSync =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "[obsidian-sync] Running via Home Manager activation..."
      "${obsidianSyncScript}/bin/obsidian-sync" || {
        echo "[obsidian-sync] ERROR: obsidian-sync script failed" >&2
      }
    '';
}
