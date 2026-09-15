# options/backups/container-backup-helper.nix
#
# =====================================================================
# CONTAINER BACKUP HELPER
#
# Creates an optional scheduled LaunchAgent and optional rebuild hook for one
# container directory. Each backup is compressed and verified locally in
# Downloads before its completed archive is moved to SystemBackup.
# =====================================================================

{ backupExcludeHelper, lib, pkgs, paths }:

let
  # ---- SHARED PATHS ---- #
  # Option defaults, the lock directories, the mount check, and the
  # LaunchAgent log directory come from the centralized path definitions.
  # default.nix sets the same values explicitly; these defaults keep the
  # option surface usable on its own.
  userPaths = paths.darwin.home;
  libraryPaths = paths.darwin.library;
  backupPaths = paths.darwin.backups;
  systemPaths = paths.darwin.system;
  excludeHelper = backupExcludeHelper;

  # ---- PER-CONTAINER LOCATION LOOKUP
  # Resolves one container's backup locations from the registry in
  # options/paths.nix. Kept as a helper so an unregistered container
  # fails with a message that says what to do, rather than with a bare
  # "attribute missing" error.
  containerLocations = config: appSlug:
    config.services.backups.paths.perContainer.${appSlug}
      or (throw ''
        container backup "${appSlug}" has no registered backup locations.

        Add an entry for it under darwin.backups.perContainer in
        options/paths.nix, with a destination and a staging directory.
      '');

  # ---- PER-CONTAINER IMPLEMENTATION
  # Called once for every entry in services.backups.containers.
  # appSlug is the attribute name that entry was written under, and cfg is
  # that entry's merged option values, so every knob below reads from the
  # option surface rather than from a function argument.
  containerBackupConfig = config: appSlug: cfg:
  let
    # Knobs read straight from this container's entry. The names match the
    # option names one for one, so the body below is unchanged from when
    # they arrived as arguments.
    inherit (cfg)
      appName
      sourceDir
      sourceRoot
      sourceEntries
      additionalSources
      containerConfig
      externalBackupVolume
      sourceMarkerFile
      destinationMarkerFile
      globalLockDir
      prepareArchive
      sqliteDatabase
      sqliteBackupTimeoutSeconds
      extraExcludePatterns
      ;

    # ---- LOCATIONS RESOLVED FROM THE SLUG
    # ** These three default to values derived from appSlug, which an
    # ** option default cannot see. They stay null on the option and are
    # ** resolved here instead, so a container may still override them.
    destinationDir =
      if cfg.destinationDir != null then
        cfg.destinationDir
      else
        (containerLocations config appSlug).destination;

    localStagingDir =
      if cfg.localStagingDir != null then
        cfg.localStagingDir
      else
        (containerLocations config appSlug).staging;

    lockDir =
      if cfg.lockDir != null then
        cfg.lockDir
      else
        "${backupPaths.lockRoot}/com.ven.${appSlug}-backup.lock";

  # ------------------------------------------------------------
  # ------ LIVE SQLITE PREPARATION ------ #
  # A container whose data directory holds a live SQLite database cannot
  # be copied file by file. rsync can read the database while the
  # container is mid-write, and the -shm and -wal sidecars belong to that
  # moment rather than to the copy, so the archive can hold a database
  # that never existed.
  #
  # ** The staged copy therefore skips the database and both sidecars,
  # ** and SQLite's own online backup API writes a consistent copy into
  # ** the staging directory afterwards. Setting sqliteDatabase is all a
  # ** container module needs; prepareArchive stays available for a
  # ** container that has to stage itself some other way.
  # ------------------------------------------------------------

  sqliteOnlineBackup = database:
    let
      # The database and its sidecars are the only paths the staged copy
      # skips; every other exclude still comes from the option surface.
      liveDatabaseExcludes =
        lib.concatMapStringsSep " "
          (name: "--exclude=${lib.escapeShellArg name}")
          [
            database
            "${database}-shm"
            "${database}-wal"
          ];
    in
    ''
      staging_dir="$(
        ${pkgs.coreutils}/bin/mktemp -d "${backupPaths.lockRoot}/${appSlug}-backup.XXXXXX"
      )"
      archive_source_parent="$staging_dir"
      archive_source_name="$source_name"
      staged_source="$staging_dir/$source_name"

      ${pkgs.coreutils}/bin/mkdir -p -- "$staged_source"
      backup_process ${pkgs.rsync}/bin/rsync -a --bwlimit="$transfer_limit_kibps" --human-readable "''${rsync_progress_args[@]}" "''${exclude_args[@]}" \
        ${liveDatabaseExcludes} \
        -- "$source_dir/" "$staged_source/"

      if [ ! -f "$source_dir/${database}" ]; then
        fail "${appName} SQLite database does not exist: $source_dir/${database}"
      fi

      ${pkgs.coreutils}/bin/timeout ${toString sqliteBackupTimeoutSeconds} \
        ${pkgs.coreutils}/bin/nice -n 20 ${pkgs.cpulimit}/bin/cpulimit -l "$cpu_limit_percent" -- \
        ${pkgs.sqlite}/bin/sqlite3 \
        "$source_dir/${database}" \
        ".backup '$staged_source/${database}'"
    '';

  # A container declares one or the other. Silently preferring one would
  # hide a contradiction in the module that set both.
  archivePreparation =
    if sqliteDatabase != null && prepareArchive != "" then
      throw "${appName}: set either sqliteDatabase or prepareArchive, not both."
    else if sqliteDatabase != null then
      sqliteOnlineBackup sqliteDatabase
    else
      prepareArchive;

  # ---- SOURCE RESOLUTION
  # ** sourceDir is the root this container is backed up from, and
  # ** sourceEntries name folders inside it. A relativePath is therefore
  # ** resolved against sourceDir, so an entry never repeats the part of
  # ** the path the backup already knows. sourceRoot stays the base only
  # ** for a container that declares no sourceDir at all.
  sourceEntryRoot = if sourceDir != null then sourceDir else sourceRoot;

  resolvedSourceEntries = map (entry: {
    sourcePath = if entry ? sourcePath then entry.sourcePath else "${sourceEntryRoot}/${entry.relativePath}";
    destinationPath = entry.destinationPath;
  }) sourceEntries;
  resolvedAdditionalSources = map (entry: {
    sourcePath = entry.sourcePath;
    destinationPath = entry.destinationPath;
  }) additionalSources;
  resolvedSourceDir =
    if sourceDir != null then
      sourceDir
    else if resolvedSourceEntries != [ ] then
      (builtins.head resolvedSourceEntries).sourcePath
    else if containerConfig != [ ] then
      (builtins.head containerConfig).sourcePath
    else
      throw "A container backup needs sourceDir or a non-empty containerConfig list.";
  resolvedSourceMarkerFile = if sourceMarkerFile == null then "${resolvedSourceDir}/.last-backup" else sourceMarkerFile;
  resolvedDestinationMarkerFile = if destinationMarkerFile == null then "${destinationDir}/.last-backup" else destinationMarkerFile;
  backupCfg = config.services.backups;
  # ---- CPU LIMIT
  # ** A container picks any value between the two bounds. This used to
  # ** be lib.min against the maximum alone, so a container asking for 35
  # ** was quietly run at 10 and the knob in its file did nothing. An
  # ** out-of-range value now says so and names the range.
  effectiveCpuLimitPercent =
    if cfg.cpuLimitPercent < cfg.minimumCpuLimitPercent
      || cfg.cpuLimitPercent > cfg.maximumCpuLimitPercent then
      throw ''
        ${appName} backup: cpuLimitPercent is ${toString cfg.cpuLimitPercent}, which is outside the safe range.

        Pick a value between ${toString cfg.minimumCpuLimitPercent} and ${toString cfg.maximumCpuLimitPercent},
        or move the bounds with this container's minimumCpuLimitPercent and
        maximumCpuLimitPercent, or the global services.backups defaults.
      ''
    else
      cfg.cpuLimitPercent;
  localStagingUsesSharedRoot = lib.hasPrefix "${backupCfg.paths.stagingDirectory}/" localStagingDir;
  defaultMetadataExcludes = excludeHelper.mkRsyncExcludeArguments excludeHelper.defaultMetadataExcludePatterns;
  extraExcludes = excludeHelper.mkRsyncExcludeArguments (backupCfg.defaultExtraExcludePatterns ++ extraExcludePatterns);
  zipMetadataExcludes = excludeHelper.mkZipExcludeArguments excludeHelper.defaultMetadataExcludePatterns;
  zipExtraExcludes = excludeHelper.mkZipExcludeArguments (backupCfg.defaultExtraExcludePatterns ++ extraExcludePatterns);
  rsyncSymlinkArguments = if cfg.preserveSymlinks then "-a" else "-aL";
  stageSourceEntries = lib.concatMapStringsSep "\n" (entry: ''
        ${pkgs.coreutils}/bin/mkdir -p -- "$staged_source/${entry.destinationPath}"
        backup_process ${pkgs.rsync}/bin/rsync ${rsyncSymlinkArguments} --bwlimit="$transfer_limit_kibps" --human-readable "''${rsync_progress_args[@]}" "''${exclude_args[@]}" -- \
          ${lib.escapeShellArg "${entry.sourcePath}/"} "$staged_source/${entry.destinationPath}/"
  '') resolvedSourceEntries;
  stageAdditionalSources = lib.concatMapStringsSep "\n" (entry: ''
      if [ ! -e ${lib.escapeShellArg entry.sourcePath} ] && [ ! -L ${lib.escapeShellArg entry.sourcePath} ]; then
        log "SKIP missing additional source: ${entry.sourcePath}"
      elif [ -d ${lib.escapeShellArg entry.sourcePath} ]; then
        ${pkgs.coreutils}/bin/mkdir -p -- "$staged_source/${entry.destinationPath}"
        backup_process ${pkgs.rsync}/bin/rsync ${rsyncSymlinkArguments} --bwlimit="$transfer_limit_kibps" --human-readable "''${rsync_progress_args[@]}" "''${exclude_args[@]}" -- \
          ${lib.escapeShellArg "${entry.sourcePath}/"} "$staged_source/${entry.destinationPath}/"
      else
        ${pkgs.coreutils}/bin/mkdir -p -- "$( ${pkgs.coreutils}/bin/dirname -- "$staged_source/${entry.destinationPath}" )"
        backup_process ${pkgs.rsync}/bin/rsync ${rsyncSymlinkArguments} --bwlimit="$transfer_limit_kibps" --human-readable "''${rsync_progress_args[@]}" "''${exclude_args[@]}" -- \
          ${lib.escapeShellArg entry.sourcePath} "$staged_source/${entry.destinationPath}"
      fi
  '') resolvedAdditionalSources;
  prepareSourceEntries = lib.optionalString (resolvedSourceEntries != [ ]) ''
      staging_dir="$(
        ${pkgs.coreutils}/bin/mktemp -d "${backupPaths.lockRoot}/${appSlug}-backup.XXXXXX"
      )"
      archive_source_parent="$staging_dir"
      archive_source_name="$app_slug"
      staged_source="$staging_dir/$app_slug"
      ${pkgs.coreutils}/bin/mkdir -p -- "$staged_source"
${stageSourceEntries}
  '';
  prepareAdditionalSources = lib.optionalString (resolvedAdditionalSources != [ ]) ''
      additional_staging_dir="$(
        ${pkgs.coreutils}/bin/mktemp -d "${backupPaths.lockRoot}/${appSlug}-additional.XXXXXX"
      )"
      staged_source="$additional_staging_dir/$app_slug"
      ${pkgs.coreutils}/bin/mkdir -p -- "$staged_source"

      # Work from a staged copy so additional sources never change the live
      # container directory or its database-aware prepared snapshot.
      backup_process ${pkgs.rsync}/bin/rsync ${rsyncSymlinkArguments} --bwlimit="$transfer_limit_kibps" --human-readable "''${rsync_progress_args[@]}" "''${exclude_args[@]}" -- \
        "$archive_source_parent/$archive_source_name/" "$staged_source/"
${stageAdditionalSources}
      archive_source_parent="$additional_staging_dir"
      archive_source_name="$app_slug"
  '';

  commandName = "${appSlug}-backup";
  launchdLabel = "com.ven.backup.${appSlug}";

  backupRunner = pkgs.writeShellApplication {
    name = commandName;

    runtimeInputs = with pkgs; [
      cpulimit
      coreutils
      findutils
      rsync
      sqlite
      unzip
      zip
    ];

    text = ''
      set -euo pipefail

      # -----------------------------------------------------------------
      # BACKUP PATHS
      # -----------------------------------------------------------------
      app_name="$(printf '%s' ${lib.escapeShellArg appName})"
      app_slug="$(printf '%s' ${lib.escapeShellArg appSlug})"
      source_dir="$(printf '%s' ${lib.escapeShellArg resolvedSourceDir})"
      external_backup_volume="$(printf '%s' ${lib.escapeShellArg externalBackupVolume})"
      destination_dir="$(printf '%s' ${lib.escapeShellArg destinationDir})"
      local_staging_dir="$(printf '%s' ${lib.escapeShellArg localStagingDir})"

      source_marker_file="$(printf '%s' ${lib.escapeShellArg resolvedSourceMarkerFile})"
      marker_file="$(printf '%s' ${lib.escapeShellArg resolvedDestinationMarkerFile})"
      lock_dir="$(printf '%s' ${lib.escapeShellArg lockDir})"
      global_lock_dir="$(printf '%s' ${lib.escapeShellArg globalLockDir})"
      backup_interval_seconds=${toString cfg.minimumIntervalSeconds}
      cpu_limit_percent=${toString effectiveCpuLimitPercent}
      transfer_limit_kibps=${toString cfg.transferLimitKiBps}
      archive_enabled=${if cfg.archive then "1" else "0"}
      archive_in_downloads=${if cfg.stageInDownloads then "1" else "0"}
      archive_name_template="$(printf '%s' ${lib.escapeShellArg cfg.archiveFilenameTemplate})"
      archive_timestamp_format="$(printf '%s' ${lib.escapeShellArg cfg.archiveTimestampFormat})"
      archive_prefix="$(printf '%s' ${lib.escapeShellArg cfg.archivePrefix})"
      automatic_notifications_enabled=${if cfg.notifyOnAutomatic then "1" else "0"}
      show_progress=${if cfg.showProgress then "1" else "0"}
      rsync_progress_args=()
      if [ "$show_progress" -eq 1 ]; then
        rsync_progress_args+=(--info=progress2)
      fi

      mode="manual"
      temporary_archive=""
      local_archive=""
      temporary_marker=""
      staging_dir=""
      additional_staging_dir=""
      lock_acquired=0
      global_lock_acquired=0
      backup_started=0
      exclude_args=(
${defaultMetadataExcludes}
${extraExcludes}
      )

      usage() {
        printf 'Usage: %s [--scheduled|--rebuild]\n' "$0" >&2
      }

      fail() {
        printf '%s backup failed: %s\n' "$app_name" "$*" >&2
        exit 1
      }

      log() {
        printf '[%s backup] %s\n' "$app_slug" "$*"
      }

      backup_process() {
        ${pkgs.coreutils}/bin/nice -n 20 ${pkgs.cpulimit}/bin/cpulimit -l "$cpu_limit_percent" -- "$@"
      }

      release_lock() {
        if [ "$lock_acquired" -ne 1 ]; then
          return 0
        fi

        ${pkgs.coreutils}/bin/rm -f -- "$lock_dir/pid" 2>/dev/null || true
        ${pkgs.coreutils}/bin/rmdir -- "$lock_dir" 2>/dev/null || true
      }

      release_global_lock() {
        if [ "$global_lock_acquired" -eq 1 ]; then
          ${pkgs.coreutils}/bin/rm -f -- "$global_lock_dir/pid" 2>/dev/null || true
          ${pkgs.coreutils}/bin/rmdir -- "$global_lock_dir" 2>/dev/null || true
        fi
      }

      cleanup() {
        if [ -n "$temporary_archive" ]; then
          ${pkgs.coreutils}/bin/rm -f -- "$temporary_archive" 2>/dev/null || true
        fi

        if [ -n "$temporary_marker" ]; then
          ${pkgs.coreutils}/bin/rm -f -- "$temporary_marker" 2>/dev/null || true
        fi

        if [ -n "$staging_dir" ] && [ -d "$staging_dir" ]; then
          ${pkgs.coreutils}/bin/rm -rf -- "$staging_dir" 2>/dev/null || true
        fi

        if [ -n "$additional_staging_dir" ] && [ -d "$additional_staging_dir" ]; then
          ${pkgs.coreutils}/bin/rm -rf -- "$additional_staging_dir" 2>/dev/null || true
        fi

        # A failed handoff deliberately leaves its verified local archive in
        # place. rmdir therefore removes only an empty helper-owned directory.
        if [ "$archive_in_downloads" -eq 1 ]; then
          ${pkgs.coreutils}/bin/rmdir -- "$local_staging_dir" 2>/dev/null || true
${lib.optionalString localStagingUsesSharedRoot ''
          ${pkgs.coreutils}/bin/rmdir -- ${lib.escapeShellArg backupCfg.paths.stagingDirectory} 2>/dev/null || true
''}
        fi

        release_lock
        release_global_lock
      }

      notify_automatic() {
        if [ "$mode" != "scheduled" ] || [ "$automatic_notifications_enabled" -ne 1 ]; then
          return 0
        fi

        if ! ${systemPaths.bin.osascript} \
          -e 'on run argv
                display notification (item 1 of argv) with title (item 2 of argv)
              end run' \
          "$1" "$app_name backup"; then
          log "WARN could not deliver automatic-backup notification"
        fi
      }

      on_exit() {
        exit_status="$?"
        cleanup

        if [ "$backup_started" -eq 1 ]; then
          if [ "$exit_status" -eq 0 ]; then
            notify_automatic "Backup completed successfully."
          else
            notify_automatic "Backup failed. Check the backup log for details."
          fi
        fi

        return "$exit_status"
      }

      case "''${1:-}" in
        "")
          ;;
        --scheduled)
          mode="scheduled"
          ;;
        --rebuild)
          mode="rebuild"
          ;;
        *)
          usage
          exit 2
          ;;
      esac

      if [ ! -d "$source_dir" ]; then
        fail "source directory does not exist: $source_dir"
      fi

      if [ ! -d "$external_backup_volume" ]; then
        fail "external backup volume is not available at: $external_backup_volume"
      fi

      if ! ${systemPaths.bin.mount} | ${pkgs.gnugrep}/bin/grep -Fq \
          " on $external_backup_volume "; then
        fail "external backup volume is not mounted: $external_backup_volume"
      fi

      # Create only this explicitly configured external backup directory.
      ${pkgs.coreutils}/bin/mkdir -p -- "$destination_dir"

      if [ ! -d "$destination_dir" ]; then
        fail "could not create backup directory: $destination_dir"
      fi

      # Create the Downloads staging directory only for backups that use it.
      if [ "$archive_in_downloads" -eq 1 ]; then
        ${pkgs.coreutils}/bin/mkdir -p -- "$local_staging_dir"

        if [ ! -d "$local_staging_dir" ]; then
          fail "could not create local staging directory: $local_staging_dir"
        fi
      fi

      trap on_exit EXIT
      trap 'exit 130' INT TERM

      if ! ${pkgs.coreutils}/bin/mkdir -- "$lock_dir" 2>/dev/null; then
        previous_pid=""

        if [ -r "$lock_dir/pid" ]; then
          IFS= read -r previous_pid < "$lock_dir/pid" || true
        fi

        if [ -n "$previous_pid" ] && kill -0 "$previous_pid" 2>/dev/null; then
          log "skipped: another backup is already running"
          exit 0
        fi

        ${pkgs.coreutils}/bin/rm -f -- "$lock_dir/pid"
        ${pkgs.coreutils}/bin/rmdir -- "$lock_dir" || \
          fail "refusing to replace an unexpected lock directory: $lock_dir"
        ${pkgs.coreutils}/bin/mkdir -- "$lock_dir"
      fi

      printf '%s\n' "$$" > "$lock_dir/pid"
      lock_acquired=1

      if [ -e "$marker_file" ]; then
        previous_backup_epoch="$(
          ${pkgs.coreutils}/bin/stat -c '%Y' "$marker_file"
        )"
        previous_backup_time="$(
          ${pkgs.coreutils}/bin/date -d "@$previous_backup_epoch" '+%Y-%m-%d %H:%M:%S %Z'
        )"
        log "last successful backup: $previous_backup_time"

        if [ "$mode" = "scheduled" ]; then
          current_epoch="$(
            ${pkgs.coreutils}/bin/date '+%s'
          )"
          elapsed_seconds="$((current_epoch - previous_backup_epoch))"

          if [ "$elapsed_seconds" -lt "$backup_interval_seconds" ]; then
            remaining_seconds="$((backup_interval_seconds - elapsed_seconds))"
            log "skipped: next scheduled backup is due in $remaining_seconds seconds"
            exit 0
          fi
        fi
      else
        log "no successful backup marker exists yet"
      fi

      if [ -e "$marker_file" ]; then
        changed_path="$(
          ${pkgs.findutils}/bin/find "$source_dir" \
            \( \
              -name '.DS_Store' -o \
              -name '._*' -o \
              -name '.AppleDouble' -o \
              -name '.DocumentRevisions-V100' -o \
              -name '.fseventsd' -o \
              -name '.LSOverride' -o \
              -name '.Spotlight-V100' -o \
              -name '.TemporaryItems' -o \
              -name '.Trashes' -o \
              -name '.Trash' -o \
              -name '.Trash-*' -o \
              -name '__MACOSX' -o \
              -name 'Icon'$'\r' -o \
              -name '*-wal' -o \
              -name '*-shm' -o \
              -name 'Thumbs.db' -o \
              -name 'desktop.ini' \
            \) -prune -o \
            -newer "$marker_file" -print -quit
        )"

        if [ -z "$changed_path" ]; then
          log "skipped: no source changes since the previous successful backup"
          exit 0
        fi

        log "detected source change: $changed_path"
      fi

      source_parent="$(
        ${pkgs.coreutils}/bin/dirname -- "$source_dir"
      )"
      source_name="$(
        ${pkgs.coreutils}/bin/basename -- "$source_dir"
      )"
      archive_source_parent="$source_parent"
      archive_source_name="$source_name"

      # Only one backup may read, compress, verify, or hand off to external storage at once.
      if ! ${pkgs.coreutils}/bin/mkdir -- "$global_lock_dir" 2>/dev/null; then
        global_previous_pid=""

        if [ -r "$global_lock_dir/pid" ]; then
          IFS= read -r global_previous_pid < "$global_lock_dir/pid" || true
        fi

        if [ -n "$global_previous_pid" ] && kill -0 "$global_previous_pid" 2>/dev/null; then
          log "skipped: another backup is archiving or uploading"
          exit 0
        fi

        ${pkgs.coreutils}/bin/rm -f -- "$global_lock_dir/pid"
        ${pkgs.coreutils}/bin/rmdir -- "$global_lock_dir" || \
          fail "refusing to replace an unexpected global lock: $global_lock_dir"
        ${pkgs.coreutils}/bin/mkdir -- "$global_lock_dir"
      fi

      printf '%s\n' "$$" > "$global_lock_dir/pid"
      global_lock_acquired=1

      ${prepareSourceEntries}
      ${archivePreparation}
      ${prepareAdditionalSources}

      timestamp="$(
        ${pkgs.coreutils}/bin/date "+$archive_timestamp_format"
      )"
      archive_name="''${archive_name_template//\{timestamp\}/$timestamp}"
      archive_name="''${archive_name//\{prefix\}/$archive_prefix}"
      archive_name="''${archive_name//\{appSlug\}/$app_slug}"
      archive="$destination_dir/$archive_name"
      temporary_marker="$destination_dir/.last-backup-$$.incomplete"

      if [ "$archive_in_downloads" -eq 1 ]; then
        local_archive="$local_staging_dir/$archive_name"
        temporary_archive="$local_staging_dir/.$archive_name.$$.incomplete"
      else
        local_archive=""
        temporary_archive="$destination_dir/.$archive_name.$$.incomplete"
      fi

      if [ "$archive_enabled" -eq 1 ] && { [ -e "$archive" ] || { [ "$archive_in_downloads" -eq 1 ] && [ -e "$local_archive" ]; }; }; then
        fail "refusing to overwrite an existing archive: $archive"
      fi

      backup_started=1
      notify_automatic "Backup started."

      if [ "$archive_enabled" -eq 0 ]; then
        log "syncing unarchived backup: $destination_dir"
        backup_process ${pkgs.rsync}/bin/rsync ${rsyncSymlinkArguments} --bwlimit="$transfer_limit_kibps" --human-readable "''${rsync_progress_args[@]}" "''${exclude_args[@]}" -- \
          "$archive_source_parent/$archive_source_name/" "$destination_dir/"
        ${pkgs.coreutils}/bin/touch -- "$marker_file" "$source_marker_file"
        log "completed successfully: $destination_dir"
        exit 0
      fi

      log "creating archive: $temporary_archive"

      (
        cd -- "$archive_source_parent"

        backup_process ${pkgs.zip}/bin/zip -q -r -y "$temporary_archive" "$archive_source_name" \
          -x '*/Thumbs.db' \
          -x '*/desktop.ini' \
          ${zipMetadataExcludes} ${zipExtraExcludes}
      )

      backup_process ${pkgs.unzip}/bin/unzip -t "$temporary_archive" >/dev/null
      if [ "$archive_in_downloads" -eq 1 ]; then
        ${pkgs.coreutils}/bin/mv -- "$temporary_archive" "$local_archive"
      else
        ${pkgs.coreutils}/bin/mv -- "$temporary_archive" "$archive"
      fi
      temporary_archive=""

      if [ "$archive_in_downloads" -eq 1 ]; then
        log "moving verified local archive to external storage: $archive"
        if ! ${pkgs.coreutils}/bin/mv -- "$local_archive" "$archive"; then
          fail "could not move verified local archive to external storage: $local_archive"
        fi
      fi

      local_archive=""

      successful_backup_time="$(
        ${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S %Z'
      )"
      successful_backup_epoch="$(
        ${pkgs.coreutils}/bin/date '+%s'
      )"

      {
        printf 'last_successful_backup=%s\n' "$successful_backup_time"
        printf 'last_successful_backup_epoch=%s\n' "$successful_backup_epoch"
        printf 'archive=%s\n' "$archive"
        printf 'source=%s\n' "$source_dir"
      } > "$temporary_marker"

      if ! ${pkgs.coreutils}/bin/mv -f -- "$temporary_marker" "$marker_file"; then
        ${pkgs.coreutils}/bin/rm -f -- "$archive"
        fail "could not update backup marker: $marker_file"
      fi

      temporary_marker=""
      ${pkgs.coreutils}/bin/touch -- "$source_marker_file"
      log "completed successfully: $archive"
    '';
  };
in
# ** Returned as one definition per target option, not as a module
# ** config. The `config` block below lists these option names itself, so
# ** the module's top-level attribute names never depend on
# ** services.backups.containers; otherwise reading them would need that
# ** option's value, which needs this module's names: infinite recursion.
{
    # Makes the enabled container backup available for manual use.
    systemPackages = lib.mkIf cfg.enable [ backupRunner ];

    launchdAgents = lib.mkIf (cfg.enable && cfg.automatic) {
      "backup-${appSlug}" = {
        serviceConfig = {
          Label = launchdLabel;
          ProgramArguments = [
            "${backupRunner}/bin/${commandName}"
            "--scheduled"
          ];
          RunAtLoad = false;
          KeepAlive = false;

          # ** A calendar time, not StartInterval. The container modules
          # ** that set one mean it: archivebox 01:00, wallabag 05:00,
          # ** vaultwarden 04:00. StartInterval only counted seconds from
          # ** whenever the agent was last loaded, so those settings were
          # ** read by nothing and a rebuild silently moved the backup.
          # **
          # ** launchd holds a calendar run missed while the machine was
          # ** asleep and fires it once at the next wake, so an overnight
          # ** time still runs on a laptop that sleeps.
          StartCalendarInterval = [
            {
              Hour = cfg.scheduledHour;
              Minute = cfg.scheduledMinute;
            }
          ];

          ProcessType = "Background";
          Nice = 20;
          LowPriorityIO = true;
          LowPriorityBackgroundIO = true;
          StandardOutPath = "${libraryPaths.logs}/${commandName}.log";
          StandardErrorPath = "${libraryPaths.logs}/${commandName}-error.log";
        };
      };
    };

    activationScripts = lib.mkIf (cfg.enable && cfg.runOnRebuild) {
      "run-${appSlug}-backup".text = lib.mkAfter ''
        echo ">>> [${appSlug} backup] Running requested rebuild backup"
        /usr/bin/sudo -H -u ven "${backupRunner}/bin/${commandName}" --rebuild \
          || echo ">>> [${appSlug} backup] Rebuild backup failed (continued)"
      '';
    };
  };

  settingsModule = { config, lib, ... }: {
    options.services.backups = {
    paths = {
      homeDirectory = lib.mkOption {
        type = lib.types.str;
        default = userPaths.root;
        description = "Home directory used by macOS container backup modules.";
      };

      configDirectory = lib.mkOption {
        type = lib.types.str;
        default = userPaths.config;
        description = "Configuration root used by macOS container backup modules.";
      };

      containerDirectory = lib.mkOption {
        type = lib.types.str;
        default = userPaths.containers;
        description = "Container-data root used by macOS container backup modules.";
      };

      externalBackupVolume = lib.mkOption {
        type = lib.types.str;
        default = backupPaths.volume;
        description = "Mounted external backup volume root.";
      };

      dataBackupsDirectory = lib.mkOption {
        type = lib.types.str;
        default = backupPaths.data;
        description = "Shared data-backup root on the external backup volume.";
      };

      containerBackupsDirectory = lib.mkOption {
        type = lib.types.str;
        default = backupPaths.containers;
        description = "Container archive root on the external backup volume.";
      };

      downloadsDirectory = lib.mkOption {
        type = lib.types.str;
        default = userPaths.downloads;
        description = "Downloads directory used while container archives are built.";
      };

      stagingDirectory = lib.mkOption {
        type = lib.types.str;
        default = backupPaths.staging;
        description = "Local staging root holding one working directory per container backup.";
      };

      perContainer = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            destination = lib.mkOption {
              type = lib.types.str;
              description = "Directory on the external volume holding this container's archives.";
            };

            staging = lib.mkOption {
              type = lib.types.str;
              description = "Local working directory used while this container's archive is built.";
            };
          };
        });
        default = backupPaths.perContainer;
        description = ''
          Backup locations for each container, keyed by its slug.

          Defined in options/paths.nix. A container backup module never
          composes these paths itself: the helper looks them up by slug.
        '';
      };
    };

    automaticEnabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow container backup modules with automatic = true to create their LaunchAgents.";
    };

    enabled = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow enabled container backup commands to be installed.";
    };

    defaultExtraExcludePatterns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "sockets/"
        "private/socket"
        "*.sock"
      ];
      description = "Socket paths excluded from every container backup unless its module adds more patterns.";
    };

    defaultAutomaticIntervalSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 86400;
      description = "Default seconds between automatic container backup attempts.";
    };

    defaultMinimumIntervalSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 28800;
      description = "Default minimum seconds between successful scheduled container backups.";
    };

    defaultCpuLimitPercent = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = 35;
      description = "Default CPU percentage used by container backup archive work.";
    };

    minimumCpuLimitPercent = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = 5;
      description = "Lowest CPU percentage a container backup may be given. Below this a backup takes long enough to overlap its next run.";
    };

    maximumCpuLimitPercent = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = 50;
      description = "Hard CPU ceiling for every container backup process, including manual runs.";
    };

    defaultTransferLimitKiBps = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4096;
      description = "Default maximum local rsync transfer rate in KiB/s for container backups.";
    };

    defaultShowProgress = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show rsync transfer progress for container backups unless an individual backup overrides it.";
    };

    runOnRebuild = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run enabled container backups during darwin-rebuild activation.";
    };

    # ------------------------------------------------------------
    # ------ CONTAINER REGISTRY ------ #
    # One entry per container backup. A machine module writes values
    # into an entry; every knob a container can set is declared here,
    # so each backup offers the same names and accepts the same values.
    #
    # ** The attribute name is the container's slug. It selects the
    # ** backup locations registered under darwin.backups.perContainer
    # ** in options/paths.nix, and names the command and LaunchAgent.
    # ------------------------------------------------------------

    containers = lib.mkOption {
      default = { };
      description = "Container backups, keyed by the container's slug.";
      type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
        options = {
          # ---- BACKUP TOGGLE
          # Defaults to the global services.backups.enabled and overrides
          # it for this one container: a container may still be installed
          # when the global default is off, and skipped when it is on.
          enable = lib.mkOption {
            type = lib.types.bool;
            default = config.services.backups.enabled;
            description = "Install this container backup. Defaults to services.backups.enabled; set here to override the global for this container.";
          };

          # ---- IDENTITY
          appName = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "Human-readable name used in this backup's log lines and notifications.";
          };

          # ---- SOURCE
          sourceDir = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Single directory backed up by this container. Leave null when sourceEntries is used instead.";
          };

          sourceRoot = lib.mkOption {
            type = lib.types.str;
            default = config.services.backups.paths.containerDirectory;
            description = "Directory that each relativePath in sourceEntries is resolved against.";
          };

          sourceEntries = lib.mkOption {
            type = lib.types.listOf (lib.types.attrsOf lib.types.str);
            default = [ ];
            example = [ { relativePath = "karakeep"; destinationPath = "karakeep"; } ];
            description = "Directories staged into this backup, each given as relativePath or sourcePath plus destinationPath.";
          };

          containerConfig = lib.mkOption {
            type = lib.types.listOf (lib.types.attrsOf lib.types.str);
            default = [ ];
            description = "Legacy source list kept for containers that have not moved to sourceEntries.";
          };

          additionalSources = lib.mkOption {
            type = lib.types.listOf (lib.types.attrsOf lib.types.str);
            default = [ ];
            description = "Absolute paths copied into the staged snapshot only, never into the live container directory.";
          };

          # ---- LIVE DATABASE
          sqliteDatabase = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "index.sqlite3";
            description = ''
              Filename of a live SQLite database inside this container's
              source directory. The staged copy skips it and its -shm and
              -wal sidecars, and a consistent copy is taken through
              SQLite's online backup API.
            '';
          };

          sqliteBackupTimeoutSeconds = lib.mkOption {
            type = lib.types.ints.positive;
            default = 300;
            description = "Seconds allowed for this container's SQLite online backup before it is abandoned.";
          };

          prepareArchive = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = ''
              Shell run before the archive is created, for a container
              that has to stage itself some other way. Setting this and
              sqliteDatabase together is an error.
            '';
          };

          # ---- DESTINATION
          # Each defaults to the slug's entry under
          # darwin.backups.perContainer when left null.
          destinationDir = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Final directory this backup's archive is moved to.";
          };

          localStagingDir = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Directory this backup builds and verifies its archive in before moving it.";
          };

          lockDir = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Lock directory preventing two runs of this container's backup at once.";
          };

          globalLockDir = lib.mkOption {
            type = lib.types.str;
            default = backupPaths.archiveLock;
            description = "Lock directory shared by every backup, so only one archives or uploads at a time.";
          };

          externalBackupVolume = lib.mkOption {
            type = lib.types.str;
            default = config.services.backups.paths.externalBackupVolume;
            description = "Volume that must be mounted before this backup will run.";
          };

          sourceMarkerFile = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "File recording this backup's last success beside the source. Defaults to .last-backup in the source directory.";
          };

          destinationMarkerFile = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "File recording this backup's last success beside the destination. Defaults to .last-backup in the destination directory.";
          };

          # ---- INDIVIDUAL BACKUP CONTROLS
          archive = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Create a ZIP archive; false keeps an unarchived rsync copy at the destination.";
          };

          stageInDownloads = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Build and verify the archive in the Downloads staging directory before moving it to the external volume.";
          };

          archiveFilenameTemplate = lib.mkOption {
            type = lib.types.str;
            default = "{timestamp}-{prefix}.zip";
            description = "Archive name template; use {timestamp}, {prefix}, and {appSlug}.";
          };

          archiveTimestampFormat = lib.mkOption {
            type = lib.types.str;
            default = "%Y-%m-%d-%H%M%S";
            description = "strftime format substituted for {timestamp}, for example %Y-%m-%d or %Y-%m-%d-%H%M%S.";
          };

          archivePrefix = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "Text substituted for {prefix} in the archive name.";
          };

          preserveSymlinks = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Preserve symbolic links instead of following them into their targets.";
          };

          # ---- EDITABLE EXCLUSIONS
          extraExcludePatterns = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [ "sockets/" "*.sock" ];
            description = "Patterns excluded from this backup, on top of services.backups.defaultExtraExcludePatterns.";
          };

          # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
          automatic = lib.mkOption {
            type = lib.types.bool;
            default = config.services.backups.automaticEnabled;
            description = "Give this backup a scheduled LaunchAgent. Defaults to services.backups.automaticEnabled; set here to override the global for this container.";
          };

          automaticIntervalSeconds = lib.mkOption {
            type = lib.types.ints.positive;
            default = config.services.backups.defaultAutomaticIntervalSeconds;
            description = "Seconds between automatic backup attempts.";
          };

          minimumIntervalSeconds = lib.mkOption {
            type = lib.types.ints.positive;
            default = config.services.backups.defaultMinimumIntervalSeconds;
            description = "Minimum seconds between successful scheduled backups.";
          };

          cpuLimitPercent = lib.mkOption {
            type = lib.types.ints.between 1 100;
            default = config.services.backups.defaultCpuLimitPercent;
            description = "CPU percentage used for archive creation and verification. Must sit between this container's minimumCpuLimitPercent and maximumCpuLimitPercent.";
          };

          minimumCpuLimitPercent = lib.mkOption {
            type = lib.types.ints.between 1 100;
            default = config.services.backups.minimumCpuLimitPercent;
            description = "Lowest CPU percentage this container's backup may use. Defaults to services.backups.minimumCpuLimitPercent; set here to override the global for this container.";
          };

          maximumCpuLimitPercent = lib.mkOption {
            type = lib.types.ints.between 1 100;
            default = config.services.backups.maximumCpuLimitPercent;
            description = "Highest CPU percentage this container's backup may use. Defaults to services.backups.maximumCpuLimitPercent; set here to override the global for this container.";
          };

          transferLimitKiBps = lib.mkOption {
            type = lib.types.ints.positive;
            default = config.services.backups.defaultTransferLimitKiBps;
            description = "Maximum local copy rate in KiB/s.";
          };

          showProgress = lib.mkOption {
            type = lib.types.bool;
            default = config.services.backups.defaultShowProgress;
            description = "Show rsync transfer progress.";
          };

          runOnRebuild = lib.mkOption {
            type = lib.types.bool;
            default = config.services.backups.runOnRebuild;
            description = "Run this backup during darwin-rebuild activation. Defaults to services.backups.runOnRebuild; set here to override the global for this container.";
          };

          notifyOnAutomatic = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Show macOS notifications when an automatic backup starts and completes or fails.";
          };

          # ---- SCHEDULE
          scheduledHour = lib.mkOption {
            type = lib.types.ints.between 0 23;
            default = 4;
            description = "Hour at which the automatic backup runs.";
          };

          scheduledMinute = lib.mkOption {
            type = lib.types.ints.between 0 59;
            default = 0;
            description = "Minute past the hour at which the automatic backup runs.";
          };
        };
      }));
    };
  };

  # ------------------------------------------------------------
  # ------ REGISTERED CONTAINER BACKUPS ------ #
  # Every registered container contributes its command, its optional
  # LaunchAgent, and its optional rebuild hook.
  # ------------------------------------------------------------

  config =
    let
      containerBackups = lib.mapAttrsToList (containerBackupConfig config) config.services.backups.containers;
      collect = part: lib.mkMerge (map (backup: backup.${part}) containerBackups);
    in
    {
      environment.systemPackages = collect "systemPackages";
      launchd.user.agents = collect "launchdAgents";
      system.activationScripts = collect "activationScripts";
    };

  };
in
{
  inherit settingsModule;
}
