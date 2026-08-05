# darwin/system-commands/backups/app-backup-helper.nix
#
# =====================================================================
# APPLICATION BACKUP HELPER
#
# Builds a dated TAR archive in Downloads, verifies it, then moves the
# completed archive to the mounted SystemBackup volume. Source entries map
# exact application files or directories into the archive layout.
# =====================================================================

{
  lib,
  pkgs,
  appName,
  appSlug,
  commandName ? "${appSlug}-backup",
  destinationRoot ? "appBackups",
  destinationSegments ? [ appSlug ],
  sources,
  requiredAny ? [ ],
  extraExcludePatterns ? [ ],
}:

let
  destinationSuffix = lib.concatStringsSep "/" destinationSegments;
  destinationRootDefinitions =
    if destinationRoot == "appBackups" then
      ''
        data_backups_root="$external_backup_volume/data-backups"
        app_backups_root="$data_backups_root/app-backups"
        destination_base="$app_backups_root"
      ''
    else if destinationRoot == "terminalBackups" then
      ''
        system_backup_root="$external_backup_volume/system"
        terminal_backups_root="$system_backup_root/terminal"
        destination_base="$terminal_backups_root"
      ''
    else
      throw "Unsupported app backup destination root: ${destinationRoot}";

  extraExcludes = lib.concatMapStringsSep "\n" (pattern: ''
      --exclude=${lib.escapeShellArg pattern}
  '') extraExcludePatterns;

  copySources = lib.concatMapStringsSep "\n" (source: ''
    copy_source ${lib.escapeShellArg source.path} ${lib.escapeShellArg source.destination}
  '') sources;

  checkRequiredGroups = lib.concatMapStringsSep "\n" (group: ''
    required_found=0
    ${lib.concatMapStringsSep "\n" (path: ''
      if [ -e ${lib.escapeShellArg path} ] || [ -L ${lib.escapeShellArg path} ]; then
        required_found=1
      fi
    '') group}
    if [ "$required_found" -ne 1 ]; then
      fail "none of the required alternative sources exists: ${lib.concatStringsSep ", " group}"
    fi
  '') requiredAny;
in
pkgs.writeShellApplication {
  name = commandName;

  runtimeInputs = with pkgs; [
    coreutils
    gnutar
    rsync
  ];

  text = ''
    set -euo pipefail

    # -----------------------------------------------------------------
    # BACKUP PATHS
    # Every path is derived from the previous root to keep the layout
    # consistent for application backup commands.
    # -----------------------------------------------------------------
    app_slug="$(printf '%s' ${lib.escapeShellArg appSlug})"
    external_backup_volume="/Volumes/SystemBackup"
    ${destinationRootDefinitions}
    destination_dir="$destination_base/${destinationSuffix}"
    downloads_dir="/Users/ven/Downloads"

    timestamp="$(${pkgs.coreutils}/bin/date '+%Y-%m-%d-%H%M%S')"
    archive_name="$timestamp-$app_slug.tar"
    archive_path="$destination_dir/$archive_name"
    staging_dir="$downloads_dir/.$app_slug-backup-$timestamp-$$"
    archive_root="$staging_dir/$app_slug"
    temporary_archive="$downloads_dir/.$archive_name.$$.incomplete"
    copied_count=0
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
${extraExcludes}
    )

    log() {
      printf '[%s backup] %s\n' "$app_slug" "$*"
    }

    fail() {
      log "ERROR $*"
      exit 1
    }

    cleanup() {
      ${pkgs.coreutils}/bin/rm -f -- "$temporary_archive" 2>/dev/null || true
      ${pkgs.coreutils}/bin/rm -rf -- "$staging_dir" 2>/dev/null || true
    }

    ensure_volume_mounted() {
      if [ ! -d "$external_backup_volume" ] || ! /sbin/mount | ${pkgs.gnugrep}/bin/grep -Fq " on $external_backup_volume "; then
        fail "external backup volume is not mounted: $external_backup_volume"
      fi
    }

    copy_source() {
      source_path="$1"
      archive_relative_path="$2"

      if [ ! -e "$source_path" ] && [ ! -L "$source_path" ]; then
        log "SKIP missing source: $source_path"
        return 0
      fi

      destination_path="$archive_root/$archive_relative_path"
      if [ -d "$source_path" ]; then
        ${pkgs.coreutils}/bin/mkdir -p -- "$destination_path"
        ${pkgs.rsync}/bin/rsync -a "''${exclude_args[@]}" -- "$source_path/" "$destination_path/"
      else
        ${pkgs.coreutils}/bin/mkdir -p -- "$( ${pkgs.coreutils}/bin/dirname -- "$destination_path" )"
        ${pkgs.rsync}/bin/rsync -a "''${exclude_args[@]}" -- "$source_path" "$destination_path"
      fi
      copied_count=$((copied_count + 1))
      log "COPY $source_path -> $archive_relative_path"
    }

    trap cleanup EXIT INT TERM

    ${checkRequiredGroups}

    ensure_volume_mounted
    ${pkgs.coreutils}/bin/mkdir -p -- "$destination_dir"
    ${pkgs.coreutils}/bin/mkdir -p -- "$archive_root"

    if [ -e "$archive_path" ]; then
      fail "refusing to overwrite an existing archive: $archive_path"
    fi

    ${copySources}

    if [ "$copied_count" -eq 0 ]; then
      fail "no backup sources were found"
    fi

    log "CREATE local archive: $temporary_archive"
    (
      cd -- "$staging_dir"
      ${pkgs.gnutar}/bin/tar --create --file "$temporary_archive" --directory "$staging_dir" "$app_slug"
    )

    ${pkgs.gnutar}/bin/tar --list --file "$temporary_archive" >/dev/null
    ${pkgs.coreutils}/bin/mv -- "$temporary_archive" "$archive_path"
    temporary_archive=""

    log "DONE $archive_path"
  '';
}
