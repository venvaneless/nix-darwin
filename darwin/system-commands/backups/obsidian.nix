# darwin/system-commands/backups/obsidian.nix
#
# =====================================================================
# OBSIDIAN BACKUP
#
# Synchronizes the requested Obsidian configuration folders directly to
# SystemBackup. Plugins and themes are version-aware; this command never
# archives, deletes, or otherwise changes the iCloud-backed source vaults.
# =====================================================================

{ pkgs, ... }:

let
  # ---- SHARED PATHS ---- #
  # The backup volume layout, the iCloud container root, and the mount
  # check come from the centralized path definitions.
  paths = import ../../../options/paths.nix { };
  backupPaths = paths.darwin.backups;

  # ** Reached through the user's iCloudContainers symlink rather than
  # ** the long Mobile Documents path. The vaults are read-only sources:
  # ** this command never archives, deletes, or modifies them.
  obsidianVaultsRoot = paths.darwin.icloud.obsidianVaults;

  obsidianBackup = pkgs.writeShellApplication {
    name = "obsidian-backup";

    runtimeInputs = with pkgs; [
      cpulimit
      coreutils
      gnugrep
      gnused
      rsync
    ];

    text = ''
      set -euo pipefail

      # -----------------------------------------------------------------
      # BACKUP PATHS
      # -----------------------------------------------------------------
      external_backup_volume="${backupPaths.volume}"
      app_backups_root="${backupPaths.apps}"
      backup_root="$app_backups_root/obsidian"
      extensions_dir="$backup_root/obsidian_extensions"
      themes_dir="$backup_root/obsidian_themes"
      preferences_dir="$backup_root/preferences"
      cpu_limit_percent=10
      transfer_limit_kibps=4096
      global_lock_dir="${backupPaths.archiveLock}"
      global_lock_acquired=0

      vault_names=("Obsidian_Hub" "Ven_MainVault")
      vaults_root="${obsidianVaultsRoot}"
      settings_files=(
        "core-plugins.json"
        "workspace.json"
        "appearance.json"
        "command-palette.json"
        "backlink.json"
        "community-plugins.json"
        "app.json"
        "bookmarks.json"
        "types.json"
        "hotkeys.json"
      )
      exclude_args=(
        --exclude='.DS_Store'
        --exclude='._*'
        --exclude='.AppleDouble'
        --exclude='.DocumentRevisions-V100'
        --exclude='.fseventsd'
        --exclude='.LSOverride'
        --exclude='.Spotlight-V100'
        --exclude='.TemporaryItems'
        --exclude='.Trashes'
        --exclude='.Trash'
        --exclude='.Trash-*'
        --exclude='__MACOSX'
      )

      log() {
        printf '[obsidian backup] %s\n' "$*"
      }

      fail() {
        log "ERROR $*"
        exit 1
      }

      backup_process() {
        ${pkgs.coreutils}/bin/nice -n 20 ${pkgs.cpulimit}/bin/cpulimit -l "$cpu_limit_percent" -- "$@"
      }

      release_backup_lock() {
        if [ "$global_lock_acquired" -eq 1 ]; then
          ${pkgs.coreutils}/bin/rm -f -- "$global_lock_dir/pid" 2>/dev/null || true
          ${pkgs.coreutils}/bin/rmdir -- "$global_lock_dir" 2>/dev/null || true
        fi
      }

      acquire_backup_lock() {
        if ! ${pkgs.coreutils}/bin/mkdir -- "$global_lock_dir" 2>/dev/null; then
          previous_pid=""
          if [ -r "$global_lock_dir/pid" ]; then
            IFS= read -r previous_pid < "$global_lock_dir/pid" || true
          fi
          if [ -n "$previous_pid" ] && kill -0 "$previous_pid" 2>/dev/null; then
            fail "another backup is already running"
          fi
          ${pkgs.coreutils}/bin/rm -f -- "$global_lock_dir/pid"
          ${pkgs.coreutils}/bin/rmdir -- "$global_lock_dir" || fail "refusing to replace an unexpected backup lock"
          ${pkgs.coreutils}/bin/mkdir -- "$global_lock_dir"
        fi

        printf '%s\n' "$$" > "$global_lock_dir/pid"
        global_lock_acquired=1
      }

      ensure_volume_mounted() {
        if [ ! -d "$external_backup_volume" ] || ! ${paths.darwin.system.bin.mount} | ${pkgs.gnugrep}/bin/grep -Fq " on $external_backup_volume "; then
          fail "external backup volume is not mounted: $external_backup_volume"
        fi
      }

      version_is_higher() {
        source_version="$1"
        destination_version="$2"
        [ "$source_version" != "$destination_version" ] && \
          [ "$(printf '%s\n%s\n' "$source_version" "$destination_version" | ${pkgs.coreutils}/bin/sort -V | ${pkgs.coreutils}/bin/tail -n 1)" = "$source_version" ]
      }

      sync_versioned_item() {
        source_item="$1"
        destination_parent="$2"
        item_kind="$3"
        item_name="$( ${pkgs.coreutils}/bin/basename -- "$source_item" )"
        source_manifest="$source_item/manifest.json"
        destination_item="$destination_parent/$item_name"
        destination_manifest="$destination_item/manifest.json"

        if [ ! -f "$source_manifest" ]; then
          log "SKIP $item_kind without manifest: $source_item"
          return 0
        fi

        source_version="$( ${pkgs.gnugrep}/bin/grep -E '"version"[[:space:]]*:' "$source_manifest" | head -n 1 | ${pkgs.gnused}/bin/sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' )"
        source_version="''${source_version:-0.0.0}"

        if [ ! -f "$destination_manifest" ]; then
          ${pkgs.coreutils}/bin/mkdir -p -- "$destination_item"
          backup_process ${pkgs.rsync}/bin/rsync -a --bwlimit="$transfer_limit_kibps" --human-readable --info=progress2 "''${exclude_args[@]}" -- "$source_item/" "$destination_item/"
          log "SYNC $item_kind: $item_name (new or missing manifest)"
          return 0
        fi

        destination_version="$( ${pkgs.gnugrep}/bin/grep -E '"version"[[:space:]]*:' "$destination_manifest" | head -n 1 | ${pkgs.gnused}/bin/sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' )"
        destination_version="''${destination_version:-0.0.0}"

        if version_is_higher "$source_version" "$destination_version"; then
          backup_process ${pkgs.rsync}/bin/rsync -a --bwlimit="$transfer_limit_kibps" --human-readable --info=progress2 "''${exclude_args[@]}" -- "$source_item/" "$destination_item/"
          log "UPDATE $item_kind: $item_name ($destination_version -> $source_version)"
        else
          log "SKIP $item_kind unchanged/newer: $item_name ($destination_version >= $source_version)"
        fi
      }

      trap release_backup_lock EXIT
      trap 'exit 130' INT TERM

      ensure_volume_mounted
      acquire_backup_lock
      ${pkgs.coreutils}/bin/mkdir -p -- "$extensions_dir" "$themes_dir" "$preferences_dir"

      for vault_name in "''${vault_names[@]}"; do
        vault_path="$vaults_root/$vault_name"
        obsidian_path="$vault_path/.obsidian"
        vault_slug="$(printf '%s' "$vault_name" | tr '[:upper:]' '[:lower:]' | ${pkgs.gnused}/bin/sed -E 's/[^a-z0-9]//g')"
        vault_backup_dir="$backup_root/$vault_slug"

        if [ ! -d "$obsidian_path" ]; then
          log "SKIP missing vault configuration: $obsidian_path"
          continue
        fi

        for plugin_path in "$obsidian_path/plugins"/*; do
          [ -d "$plugin_path" ] || continue
          sync_versioned_item "$plugin_path" "$extensions_dir" "plugin"
        done

        for theme_path in "$obsidian_path/themes"/*; do
          [ -d "$theme_path" ] || continue
          sync_versioned_item "$theme_path" "$themes_dir" "theme"
        done

        for setting_name in "''${settings_files[@]}"; do
          setting_source="$obsidian_path/$setting_name"
          if [ -f "$setting_source" ]; then
            backup_process ${pkgs.rsync}/bin/rsync -a --bwlimit="$transfer_limit_kibps" --human-readable --info=progress2 "''${exclude_args[@]}" -- "$setting_source" "$preferences_dir/$vault_slug-$setting_name"
            log "SYNC setting: $vault_slug-$setting_name"
          fi
        done

        ${pkgs.coreutils}/bin/mkdir -p -- "$vault_backup_dir"
        for relative_path in ".makemd" ".space" ".obsidian/regex-rulesets" "CardNavigatorPresets" "Excalidraw" "_dev-tools"; do
          source_path="$vault_path/$relative_path"
          if [ -d "$source_path" ]; then
            destination_path="$vault_backup_dir/$relative_path"
            ${pkgs.coreutils}/bin/mkdir -p -- "$( ${pkgs.coreutils}/bin/dirname -- "$destination_path" )"
            backup_process ${pkgs.rsync}/bin/rsync -a --bwlimit="$transfer_limit_kibps" --human-readable --info=progress2 "''${exclude_args[@]}" -- "$source_path/" "$destination_path/"
            log "SYNC $vault_slug/$relative_path"
          fi
        done
      done
    '';
  };
in
{
  environment.systemPackages = [ obsidianBackup ];
}
