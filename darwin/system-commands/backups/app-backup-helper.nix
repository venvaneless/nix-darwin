# darwin/system-commands/backups/app-backup-helper.nix
#
# =====================================================================
# APPLICATION BACKUP HELPER
#
# Builds a dated TAR archive in Downloads, verifies it, then moves the
# completed archive to the mounted SystemBackup volume. Source entries map
# exact application files or directories into the archive layout.
# =====================================================================

{ lib, pkgs }:

let
  # ---- SHARED PATHS ---- #
  # Option defaults, the lock directory, the mount check, and the
  # LaunchAgent log directory come from the centralized path definitions.
  # default.nix sets the same values explicitly; these defaults keep the
  # option surface usable on its own.
  paths = import ../../../options/paths.nix { };

  userPaths = paths.darwin.home;
  libraryPaths = paths.darwin.library;
  backupPaths = paths.darwin.backups;
  systemPaths = paths.darwin.system;
  excludeHelper = import ./backup-exclude-helper.nix { inherit lib; };

  # ---- GLOBAL APPLICATION BACKUP CONTROLS
  # Imported once by default.nix. Individual app modules keep their own
  # toggles below, while this switch controls every automatic app schedule.
  settingsModule = { lib, ... }: {
    options.services.appBackups = {
      paths = {
        homeDirectory = lib.mkOption {
          type = lib.types.str;
          default = userPaths.root;
          description = "Home directory used by macOS application backup modules.";
        };

        configDirectory = lib.mkOption {
          type = lib.types.str;
          default = userPaths.config;
          description = "Configuration root used by macOS application backup modules.";
        };

        applicationSupportDirectory = lib.mkOption {
          type = lib.types.str;
          default = libraryPaths.applicationSupport;
          description = "macOS Application Support root used by application backup modules.";
        };

        preferencesDirectory = lib.mkOption {
          type = lib.types.str;
          default = libraryPaths.preferences;
          description = "macOS Preferences root used by application backup modules.";
        };

        externalBackupVolume = lib.mkOption {
          type = lib.types.str;
          default = backupPaths.volume;
          description = "Mounted external backup volume root.";
        };

        downloadsDirectory = lib.mkOption {
          type = lib.types.str;
          default = userPaths.downloads;
          description = "Local staging root for application archives.";
        };

        stagingDirectory = lib.mkOption {
          type = lib.types.str;
          default = backupPaths.staging;
          description = "Local staging directory used for completed application archives before they are moved to the external volume.";
        };

        dataBackupsDirectory = lib.mkOption {
          type = lib.types.str;
          default = backupPaths.data;
          description = "Shared data-backup root on the external backup volume.";
        };

        appBackupsDirectory = lib.mkOption {
          type = lib.types.str;
          default = backupPaths.apps;
          description = "Application archive root on the external backup volume.";
        };

        browserBackupsDirectory = lib.mkOption {
          type = lib.types.str;
          default = backupPaths.browsers;
          description = "Browser backup root on the external backup volume.";
        };

        terminalBackupsDirectory = lib.mkOption {
          type = lib.types.str;
          default = backupPaths.terminal;
          description = "Terminal backup root on the external backup volume.";
        };
      };

      automaticEnabled = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Allow application backup modules with automatic = true to create their LaunchAgents.";
      };

      enabled = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Allow enabled application backup commands to be installed.";
      };

      defaultExtraExcludePatterns = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "sockets/"
          "private/socket"
          "*.sock"
        ];
        description = "Socket paths excluded from every application backup unless its module adds more patterns.";
      };

      defaultAutomaticIntervalSeconds = lib.mkOption {
        type = lib.types.ints.positive;
        default = 86400;
        description = "Default seconds between automatic application backup attempts.";
      };

      defaultMinimumIntervalSeconds = lib.mkOption {
        type = lib.types.ints.positive;
        default = 28800;
        description = "Default minimum seconds between successful scheduled application backups.";
      };

      defaultCpuLimitPercent = lib.mkOption {
        type = lib.types.ints.between 1 100;
        default = 25;
        description = "Default CPU percentage used by application backup archive work.";
      };

      maximumCpuLimitPercent = lib.mkOption {
        type = lib.types.ints.between 1 100;
        default = 10;
        description = "Hard CPU ceiling for every application backup process, including manual runs.";
      };

      defaultTransferLimitKiBps = lib.mkOption {
        type = lib.types.ints.positive;
        default = 4096;
        description = "Default maximum local rsync transfer rate in KiB/s for application backups.";
      };

      defaultShowProgress = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Show rsync transfer progress for application backups unless an individual backup overrides it.";
      };
    };
  };

  mkAppBackup = {
    config,
    appName,
    appSlug,
    commandName ? "${appSlug}-backup",
    destinationRoot ? "appBackups",
    destinationSegments ? [ appSlug ],
    destinationDir ? null,
    externalBackupVolume ? config.services.appBackups.paths.externalBackupVolume,
    downloadsDir ? config.services.appBackups.paths.downloadsDirectory,
    localStagingDir ? "${config.services.appBackups.paths.stagingDirectory}/${appSlug}",
    globalLockDir ? backupPaths.archiveLock,
    sourceMarkerFiles ? [ ],
    destinationMarkerFile ? null,
    sources ? [ ],
    additionalSources ? [ ],
    applicationSupportSources ? [ ],
    applicationPreferences ? [ ],
    applicationConfig ? [ ],
    applicationSupportEntries ? [ ],
    preferenceEntries ? [ ],
    configEntries ? [ ],
    applicationSupportRoot ? config.services.appBackups.paths.applicationSupportDirectory,
    preferencesRoot ? config.services.appBackups.paths.preferencesDirectory,
    configRoot ? config.services.appBackups.paths.configDirectory,
    requiredAny ? [ ],
    extraExcludePatterns ? [ ],
    archive ? true,
    stageInDownloads ? true,
    archiveFilenameTemplate ? "{timestamp}-{appSlug}.tar",
    archiveTimestampFormat ? "%Y-%m-%d-%H%M%S",
    archivePrefix ? appSlug,
    preserveSymlinks ? true,
    automatic ? false,
    notifyOnAutomatic ? true,
    automaticIntervalSeconds ? config.services.appBackups.defaultAutomaticIntervalSeconds,
    minimumIntervalSeconds ? config.services.appBackups.defaultMinimumIntervalSeconds,
    cpuLimitPercent ? config.services.appBackups.defaultCpuLimitPercent,
    transferLimitKiBps ? config.services.appBackups.defaultTransferLimitKiBps,
    showProgress ? config.services.appBackups.defaultShowProgress,
  }:
  let
    cfg = config.services.appBackups.${appSlug};
  effectiveCpuLimitPercent = lib.min cfg.cpuLimitPercent config.services.appBackups.maximumCpuLimitPercent;
  destinationSuffix = lib.concatStringsSep "/" destinationSegments;
  backupPaths = config.services.appBackups.paths;
  localStagingUsesSharedRoot = lib.hasPrefix "${backupPaths.stagingDirectory}/" localStagingDir;
  resolvedApplicationSupportEntries = map (entry: {
    path = "${applicationSupportRoot}/${entry.relativePath}";
    destination = entry.destinationPath or entry.destination;
    excludePatterns = entry.excludePatterns or [ ];
  }) applicationSupportEntries;
  preferenceSources = map (entry: {
    path = "${preferencesRoot}/${entry.relativePath}";
    destination = entry.destinationPath or entry.destination;
    excludePatterns = entry.excludePatterns or [ ];
  }) preferenceEntries;
  configSources = map (entry: {
    path = "${configRoot}/${entry.relativePath}";
    destination = entry.destinationPath or entry.destination;
    excludePatterns = entry.excludePatterns or [ ];
  }) configEntries;
  readableApplicationSupportSources = map (entry: {
    path = entry.sourcePath;
    destination = entry.destinationPath;
    excludePatterns = entry.excludePatterns or [ ];
  }) applicationSupportSources;
  readableApplicationPreferences = map (entry: {
    path = entry.sourcePath;
    destination = entry.destinationPath;
    excludePatterns = entry.excludePatterns or [ ];
  }) applicationPreferences;
  readableApplicationConfig = map (entry: {
    path = entry.sourcePath;
    destination = entry.destinationPath;
    excludePatterns = entry.excludePatterns or [ ];
  }) applicationConfig;
  readableAdditionalSources = map (entry: {
    path = entry.sourcePath;
    destination = entry.destinationPath;
    excludePatterns = entry.excludePatterns or [ ];
  }) additionalSources;
  resolvedSources = sources ++ readableAdditionalSources ++ resolvedApplicationSupportEntries ++ preferenceSources ++ configSources ++ readableApplicationSupportSources ++ readableApplicationPreferences ++ readableApplicationConfig;
  resolvedDestinationDir =
    if destinationDir != null then
      destinationDir
    else if destinationRoot == "appBackups" then
      "${backupPaths.appBackupsDirectory}/${destinationSuffix}"
    else if destinationRoot == "browserBackups" then
      "${backupPaths.browserBackupsDirectory}/${destinationSuffix}"
    else if destinationRoot == "terminalBackups" then
      "${backupPaths.terminalBackupsDirectory}/${destinationSuffix}"
    else
      throw "Unsupported app backup destination root: ${destinationRoot}";
  resolvedDestinationMarkerFile =
    if destinationMarkerFile == null then
      "${resolvedDestinationDir}/.last-backup"
    else
      destinationMarkerFile;
  defaultMetadataExcludes = excludeHelper.mkRsyncExcludeArguments excludeHelper.defaultMetadataExcludePatterns;
  extraExcludes = excludeHelper.mkRsyncExcludeArguments (config.services.appBackups.defaultExtraExcludePatterns ++ extraExcludePatterns);

  rsyncSymlinkArguments = if cfg.preserveSymlinks then "-a" else "-aL";
  rsyncTransferArguments =
    if cfg.transferLimitKiBps == null then
      ""
    else
      "--bwlimit=${toString cfg.transferLimitKiBps}";
  rsyncProgressArguments = if cfg.showProgress then "--info=progress2" else "";

  copySources = lib.concatMapStringsSep "\n" (source: ''
    copy_source ${lib.escapeShellArg source.path} ${lib.escapeShellArg source.destination} ${lib.escapeShellArgs (source.excludePatterns or [ ])}
  '') resolvedSources;

  touchSourceMarkers = lib.concatMapStringsSep "\n" (marker: ''
    if [ -d ${lib.escapeShellArg (builtins.dirOf marker)} ]; then
      ${pkgs.coreutils}/bin/touch -- ${lib.escapeShellArg marker}
    fi
  '') sourceMarkerFiles;

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

  backupRunner = pkgs.writeShellApplication {
  name = commandName;

  runtimeInputs = with pkgs; [
    cpulimit
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
    external_backup_volume="$(printf '%s' ${lib.escapeShellArg externalBackupVolume})"
    destination_dir="$(printf '%s' ${lib.escapeShellArg resolvedDestinationDir})"
    downloads_dir="$(printf '%s' ${lib.escapeShellArg downloadsDir})"
    local_staging_root="$(printf '%s' ${lib.escapeShellArg backupPaths.stagingDirectory})"
    local_staging_dir="$(printf '%s' ${lib.escapeShellArg localStagingDir})"

    timestamp="$(${pkgs.coreutils}/bin/date ${lib.escapeShellArg "+${cfg.archiveTimestampFormat}"})"
    archive_prefix="$(printf '%s' ${lib.escapeShellArg cfg.archivePrefix})"
    archive_name_template="$(printf '%s' ${lib.escapeShellArg cfg.archiveFilenameTemplate})"
    archive_name="''${archive_name_template//\{timestamp\}/$timestamp}"
    archive_name="''${archive_name//\{prefix\}/$archive_prefix}"
    archive_name="''${archive_name//\{appSlug\}/$app_slug}"
    archive_path="$destination_dir/$archive_name"
    marker_file="$(printf '%s' ${lib.escapeShellArg resolvedDestinationMarkerFile})"
    archive_in_downloads=${if cfg.stageInDownloads then "1" else "0"}
    archive_enabled=${if cfg.archive then "1" else "0"}
    staging_base_dir="$destination_dir"
    if [ "$archive_in_downloads" -eq 1 ]; then
      staging_base_dir="$local_staging_dir"
    fi
    staging_dir="$staging_base_dir/.$app_slug-backup-$timestamp-$$"
    archive_root="$staging_dir/$app_slug"
    temporary_archive="$staging_base_dir/.$archive_name.$$.incomplete"
    global_lock_dir="$(printf '%s' ${lib.escapeShellArg globalLockDir})"
    global_lock_acquired=0
    cpu_limit_percent="$(printf '%s' ${toString effectiveCpuLimitPercent})"
    minimum_interval_seconds=${toString cfg.minimumIntervalSeconds}
    automatic_notifications_enabled=${if cfg.notifyOnAutomatic then "1" else "0"}
    mode="manual"
    copied_count=0
    backup_started=0
    exclude_args=(
${defaultMetadataExcludes}
${extraExcludes}
    )

    log() {
      printf '[%s backup] %s\n' "$app_slug" "$*"
    }

    fail() {
      log "ERROR $*"
      exit 1
    }

    case "''${1:-}" in
      "")
        ;;
      --scheduled)
        mode="scheduled"
        ;;
      *)
        fail "usage: $0 [--scheduled]"
        ;;
    esac

    cleanup() {
      ${pkgs.coreutils}/bin/rm -f -- "$temporary_archive" 2>/dev/null || true
      ${pkgs.coreutils}/bin/rm -rf -- "$staging_dir" 2>/dev/null || true

      # A failed handoff deliberately leaves its verified local archive in
      # place. rmdir therefore removes only an empty helper-owned directory.
      if [ "$archive_in_downloads" -eq 1 ]; then
        ${pkgs.coreutils}/bin/rmdir -- "$local_staging_dir" 2>/dev/null || true
        if [ ${if localStagingUsesSharedRoot then "1" else "0"} -eq 1 ]; then
          ${pkgs.coreutils}/bin/rmdir -- "$local_staging_root" 2>/dev/null || true
        fi
      fi

      if [ "$global_lock_acquired" -eq 1 ]; then
        ${pkgs.coreutils}/bin/rm -f -- "$global_lock_dir/pid" 2>/dev/null || true
        ${pkgs.coreutils}/bin/rmdir -- "$global_lock_dir" 2>/dev/null || true
      fi
    }

    notify_automatic() {
      if [ "$mode" != "scheduled" ] || [ "$automatic_notifications_enabled" -ne 1 ]; then
        return 0
      fi

      if ! ${systemPaths.bin.osascript} \
        -e 'on run argv
              display notification (item 1 of argv) with title (item 2 of argv)
            end run' \
        "$1" "$app_slug backup"; then
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

    ensure_volume_mounted() {
      if [ ! -d "$external_backup_volume" ] || ! ${systemPaths.bin.mount} | ${pkgs.gnugrep}/bin/grep -Fq " on $external_backup_volume "; then
        fail "external backup volume is not mounted: $external_backup_volume"
      fi
    }

    copy_source() {
      source_path="$1"
      archive_relative_path="$2"
      shift 2
      source_exclude_args=()

      for exclude_pattern in "$@"; do
        source_exclude_args+=("--exclude=$exclude_pattern")
      done

      if [ ! -e "$source_path" ] && [ ! -L "$source_path" ]; then
        log "SKIP missing source: $source_path"
        return 0
      fi

      destination_path="$archive_root/$archive_relative_path"
      log "COPY $source_path -> $archive_relative_path"
      if [ -d "$source_path" ]; then
        ${pkgs.coreutils}/bin/mkdir -p -- "$destination_path"
        ${pkgs.coreutils}/bin/nice -n 20 ${pkgs.cpulimit}/bin/cpulimit -l "$cpu_limit_percent" -- \
          ${pkgs.rsync}/bin/rsync ${rsyncSymlinkArguments} ${rsyncTransferArguments} --human-readable ${rsyncProgressArguments} "''${exclude_args[@]}" "''${source_exclude_args[@]}" -- "$source_path/" "$destination_path/"
      else
        ${pkgs.coreutils}/bin/mkdir -p -- "$( ${pkgs.coreutils}/bin/dirname -- "$destination_path" )"
        ${pkgs.coreutils}/bin/nice -n 20 ${pkgs.cpulimit}/bin/cpulimit -l "$cpu_limit_percent" -- \
          ${pkgs.rsync}/bin/rsync ${rsyncSymlinkArguments} ${rsyncTransferArguments} --human-readable ${rsyncProgressArguments} "''${exclude_args[@]}" "''${source_exclude_args[@]}" -- "$source_path" "$destination_path"
      fi
      copied_count=$((copied_count + 1))
      log "COPIED $source_path -> $archive_relative_path"
    }

    trap on_exit EXIT
    trap 'exit 130' INT TERM

    ${checkRequiredGroups}

    ensure_volume_mounted

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

    ${pkgs.coreutils}/bin/mkdir -p -- "$destination_dir"
    if [ "$archive_in_downloads" -eq 1 ]; then
      ${pkgs.coreutils}/bin/mkdir -p -- "$local_staging_dir"
    fi
    ${pkgs.coreutils}/bin/mkdir -p -- "$archive_root"

    if [ "$mode" = "scheduled" ] && [ -e "$marker_file" ]; then
      previous_backup_epoch="$( ${pkgs.coreutils}/bin/stat -c '%Y' "$marker_file" )"
      current_epoch="$( ${pkgs.coreutils}/bin/date '+%s' )"
      elapsed_seconds="$((current_epoch - previous_backup_epoch))"
      if [ "$elapsed_seconds" -lt "$minimum_interval_seconds" ]; then
        log "SKIP scheduled backup: next run is due in $((minimum_interval_seconds - elapsed_seconds)) seconds"
        exit 0
      fi
    fi

    if [ "$archive_enabled" -eq 1 ] && [ -e "$archive_path" ]; then
      fail "refusing to overwrite an existing archive: $archive_path"
    fi

    backup_started=1
    notify_automatic "Backup started."

    ${copySources}

    if [ "$copied_count" -eq 0 ]; then
      fail "no backup sources were found"
    fi

    if [ "$archive_enabled" -eq 0 ]; then
      log "SYNC unarchived backup: $destination_dir"
      ${pkgs.coreutils}/bin/nice -n 20 ${pkgs.cpulimit}/bin/cpulimit -l "$cpu_limit_percent" -- \
        ${pkgs.rsync}/bin/rsync ${rsyncSymlinkArguments} ${rsyncTransferArguments} --human-readable ${rsyncProgressArguments} "''${exclude_args[@]}" -- "$archive_root/" "$destination_dir/"
      ${pkgs.coreutils}/bin/touch -- "$marker_file"
      ${touchSourceMarkers}
      log "DONE $destination_dir"
      exit 0
    fi

    if [ "$archive_in_downloads" -eq 1 ]; then
      archive_work_path="$temporary_archive"
    else
      archive_work_path="$destination_dir/.$archive_name.$$.incomplete"
      temporary_archive="$archive_work_path"
    fi

    log "CREATE archive: $archive_work_path"
    (
      cd -- "$staging_dir"
      ${pkgs.coreutils}/bin/nice -n 20 ${pkgs.cpulimit}/bin/cpulimit -l "$cpu_limit_percent" -- \
        ${pkgs.gnutar}/bin/tar --create --file "$archive_work_path" --directory "$staging_dir" "$app_slug"
    )

    ${pkgs.coreutils}/bin/nice -n 20 ${pkgs.cpulimit}/bin/cpulimit -l "$cpu_limit_percent" -- \
      ${pkgs.gnutar}/bin/tar --list --file "$archive_work_path" >/dev/null
    ${pkgs.coreutils}/bin/mv -- "$archive_work_path" "$archive_path"
    temporary_archive=""
    ${pkgs.coreutils}/bin/touch -- "$marker_file"
    ${touchSourceMarkers}

    log "DONE $archive_path"
  '';
  };
in
{
  options.services.appBackups.${appSlug} = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the ${appName} backup command.";
    };

    automatic = lib.mkOption {
      type = lib.types.bool;
      default = automatic;
      description = "Run the ${appName} backup automatically only when services.appBackups.automaticEnabled is also true.";
    };

    notifyOnAutomatic = lib.mkOption {
      type = lib.types.bool;
      default = notifyOnAutomatic;
      description = "Show macOS notifications when an automatic ${appName} backup starts and completes or fails.";
    };

    automaticIntervalSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = automaticIntervalSeconds;
      description = "Seconds between automatic ${appName} backup attempts.";
    };

    minimumIntervalSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = minimumIntervalSeconds;
      description = "Minimum seconds between successful scheduled ${appName} backups.";
    };

    cpuLimitPercent = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = cpuLimitPercent;
      description = "Maximum CPU percentage used for ${appName} backup archive work.";
    };

    transferLimitKiBps = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = transferLimitKiBps;
      description = "Maximum local copy rate in KiB/s for ${appName} backups.";
    };

    showProgress = lib.mkOption {
      type = lib.types.bool;
      default = showProgress;
      description = "Show rsync transfer progress for ${appName} backups.";
    };

    archive = lib.mkOption {
      type = lib.types.bool;
      default = archive;
      description = "Create a TAR archive for ${appName}; false keeps an unarchived rsync copy at its destination.";
    };

    stageInDownloads = lib.mkOption {
      type = lib.types.bool;
      default = stageInDownloads;
      description = "Create and verify ${appName} archives in its Downloads staging directory before moving them to the external destination; false creates them directly on the external volume.";
    };

    archiveFilenameTemplate = lib.mkOption {
      type = lib.types.str;
      default = archiveFilenameTemplate;
      description = "Archive name template for ${appName}; use {timestamp}, {prefix}, and {appSlug}.";
    };

    archiveTimestampFormat = lib.mkOption {
      type = lib.types.str;
      default = archiveTimestampFormat;
      description = "strftime timestamp format for ${appName} archives, for example %Y-%m-%d or %Y-%m-%d-%H%M%S.";
    };

    archivePrefix = lib.mkOption {
      type = lib.types.str;
      default = archivePrefix;
      description = "Prefix substituted for {prefix} in ${appName} archive names.";
    };

    preserveSymlinks = lib.mkOption {
      type = lib.types.bool;
      default = preserveSymlinks;
      description = "Preserve symbolic links while backing up ${appName}.";
    };
  };

  config = lib.mkIf (config.services.appBackups.enabled && cfg.enable) (lib.mkMerge [
    {
      environment.systemPackages = [ backupRunner ];
    }

    (lib.mkIf (config.services.appBackups.automaticEnabled && cfg.automatic) {
      launchd.user.agents."backup-${appSlug}" = {
        serviceConfig = {
          Label = "com.ven.backup.${appSlug}";
          ProgramArguments = [ "${backupRunner}/bin/${commandName}" "--scheduled" ];
          RunAtLoad = false;
          KeepAlive = false;
          StartInterval = cfg.automaticIntervalSeconds;
          ProcessType = "Background";
          Nice = 20;
          LowPriorityIO = true;
          LowPriorityBackgroundIO = true;
          StandardOutPath = "${libraryPaths.logs}/${commandName}.log";
          StandardErrorPath = "${libraryPaths.logs}/${commandName}-error.log";
        };
      };
    })
  ]);
}
;
in
{
  inherit mkAppBackup settingsModule;
}
