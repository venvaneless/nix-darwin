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
  # ---- GLOBAL APPLICATION BACKUP CONTROLS
  # Imported once by default.nix. Individual app modules keep their own
  # toggles below, while this switch controls every automatic app schedule.
  settingsModule = { lib, ... }: {
    options.services.appBackups = {
      paths = {
        homeDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/Users/ven";
          description = "Home directory used by macOS application backup modules.";
        };

        configDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/Users/ven/.config";
          description = "Configuration root used by macOS application backup modules.";
        };

        applicationSupportDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/Users/ven/Library/Application Support";
          description = "macOS Application Support root used by application backup modules.";
        };

        preferencesDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/Users/ven/Library/Preferences";
          description = "macOS Preferences root used by application backup modules.";
        };

        externalBackupVolume = lib.mkOption {
          type = lib.types.str;
          default = "/Volumes/SystemBackup";
          description = "Mounted external backup volume root.";
        };

        downloadsDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/Users/ven/Downloads";
          description = "Local staging root for application archives.";
        };

        dataBackupsDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/Volumes/SystemBackup/data-backups";
          description = "Shared data-backup root on the external backup volume.";
        };

        appBackupsDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/Volumes/SystemBackup/data-backups/app-backups";
          description = "Application archive root on the external backup volume.";
        };

        browserBackupsDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/Volumes/SystemBackup/data-backups/app-backups/browsers";
          description = "Browser backup root on the external backup volume.";
        };

        terminalBackupsDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/Volumes/SystemBackup/system/terminal";
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
    globalLockDir ? "/private/tmp/com.ven.app-backup.lock",
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
    automaticIntervalSeconds ? config.services.appBackups.defaultAutomaticIntervalSeconds,
    minimumIntervalSeconds ? config.services.appBackups.defaultMinimumIntervalSeconds,
    cpuLimitPercent ? config.services.appBackups.defaultCpuLimitPercent,
  }:
  let
    cfg = config.services.appBackups.${appSlug};
  destinationSuffix = lib.concatStringsSep "/" destinationSegments;
  backupPaths = config.services.appBackups.paths;
  resolvedApplicationSupportEntries = map (entry: {
    path = "${applicationSupportRoot}/${entry.relativePath}";
    destination = entry.destinationPath or entry.destination;
  }) applicationSupportEntries;
  preferenceSources = map (entry: {
    path = "${preferencesRoot}/${entry.relativePath}";
    destination = entry.destinationPath or entry.destination;
  }) preferenceEntries;
  configSources = map (entry: {
    path = "${configRoot}/${entry.relativePath}";
    destination = entry.destinationPath or entry.destination;
  }) configEntries;
  readableApplicationSupportSources = map (entry: {
    path = entry.sourcePath;
    destination = entry.destinationPath;
  }) applicationSupportSources;
  readableApplicationPreferences = map (entry: {
    path = entry.sourcePath;
    destination = entry.destinationPath;
  }) applicationPreferences;
  readableApplicationConfig = map (entry: {
    path = entry.sourcePath;
    destination = entry.destinationPath;
  }) applicationConfig;
  readableAdditionalSources = map (entry: {
    path = entry.sourcePath;
    destination = entry.destinationPath;
  }) additionalSources;
  resolvedSources = sources ++ additionalSources ++ resolvedApplicationSupportEntries ++ preferenceSources ++ configSources ++ readableApplicationSupportSources ++ readableApplicationPreferences ++ readableApplicationConfig;
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
  extraExcludes = lib.concatMapStringsSep "\n" (pattern: ''
      --exclude=${lib.escapeShellArg pattern}
  '') (config.services.appBackups.defaultExtraExcludePatterns ++ extraExcludePatterns);

  rsyncSymlinkArguments = if cfg.preserveSymlinks then "-a" else "-aL";

  copySources = lib.concatMapStringsSep "\n" (source: ''
    copy_source ${lib.escapeShellArg source.path} ${lib.escapeShellArg source.destination}
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

    timestamp="$(${pkgs.coreutils}/bin/date ${lib.escapeShellArg "+${cfg.archiveTimestampFormat}"})"
    archive_prefix="$(printf '%s' ${lib.escapeShellArg cfg.archivePrefix})"
    archive_name_template="$(printf '%s' ${lib.escapeShellArg cfg.archiveFilenameTemplate})"
    archive_name="''${archive_name_template//\{timestamp\}/$timestamp}"
    archive_name="''${archive_name//\{prefix\}/$archive_prefix}"
    archive_name="''${archive_name//\{appSlug\}/$app_slug}"
    archive_path="$destination_dir/$archive_name"
    marker_file="$(printf '%s' ${lib.escapeShellArg resolvedDestinationMarkerFile})"
    staging_dir="$downloads_dir/.$app_slug-backup-$timestamp-$$"
    archive_root="$staging_dir/$app_slug"
    archive_in_downloads=${if cfg.stageInDownloads then "1" else "0"}
    archive_enabled=${if cfg.archive then "1" else "0"}
    temporary_archive="$downloads_dir/.$archive_name.$$.incomplete"
    global_lock_dir="$(printf '%s' ${lib.escapeShellArg globalLockDir})"
    global_lock_acquired=0
    cpu_limit_percent="$(printf '%s' ${toString cfg.cpuLimitPercent})"
    minimum_interval_seconds=${toString cfg.minimumIntervalSeconds}
    mode="manual"
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
      if [ "$global_lock_acquired" -eq 1 ]; then
        ${pkgs.coreutils}/bin/rm -f -- "$global_lock_dir/pid" 2>/dev/null || true
        ${pkgs.coreutils}/bin/rmdir -- "$global_lock_dir" 2>/dev/null || true
      fi
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
      log "COPY $source_path -> $archive_relative_path"
      if [ -d "$source_path" ]; then
        ${pkgs.coreutils}/bin/mkdir -p -- "$destination_path"
        ${pkgs.coreutils}/bin/nice -n 20 ${pkgs.cpulimit}/bin/cpulimit -l "$cpu_limit_percent" -- \
          ${pkgs.rsync}/bin/rsync ${rsyncSymlinkArguments} --human-readable --info=progress2 "''${exclude_args[@]}" -- "$source_path/" "$destination_path/"
      else
        ${pkgs.coreutils}/bin/mkdir -p -- "$( ${pkgs.coreutils}/bin/dirname -- "$destination_path" )"
        ${pkgs.coreutils}/bin/nice -n 20 ${pkgs.cpulimit}/bin/cpulimit -l "$cpu_limit_percent" -- \
          ${pkgs.rsync}/bin/rsync ${rsyncSymlinkArguments} --human-readable --info=progress2 "''${exclude_args[@]}" -- "$source_path" "$destination_path"
      fi
      copied_count=$((copied_count + 1))
      log "COPIED $source_path -> $archive_relative_path"
    }

    trap cleanup EXIT INT TERM

    ${checkRequiredGroups}

    ensure_volume_mounted

    if ! ${pkgs.coreutils}/bin/mkdir -- "$global_lock_dir" 2>/dev/null; then
      previous_pid=""
      if [ -r "$global_lock_dir/pid" ]; then
        IFS= read -r previous_pid < "$global_lock_dir/pid" || true
      fi
      if [ -n "$previous_pid" ] && kill -0 "$previous_pid" 2>/dev/null; then
        fail "another application backup is already running"
      fi
      ${pkgs.coreutils}/bin/rm -f -- "$global_lock_dir/pid"
      ${pkgs.coreutils}/bin/rmdir -- "$global_lock_dir" || fail "refusing to replace an unexpected app backup lock"
      ${pkgs.coreutils}/bin/mkdir -- "$global_lock_dir"
    fi
    printf '%s\n' "$$" > "$global_lock_dir/pid"
    global_lock_acquired=1

    ${pkgs.coreutils}/bin/mkdir -p -- "$destination_dir"
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

    ${copySources}

    if [ "$copied_count" -eq 0 ]; then
      fail "no backup sources were found"
    fi

    if [ "$archive_enabled" -eq 0 ]; then
      log "SYNC unarchived backup: $destination_dir"
      ${pkgs.rsync}/bin/rsync ${rsyncSymlinkArguments} --human-readable --info=progress2 "''${exclude_args[@]}" -- "$archive_root/" "$destination_dir/"
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

    archive = lib.mkOption {
      type = lib.types.bool;
      default = archive;
      description = "Create a TAR archive for ${appName}; false keeps an unarchived rsync copy at its destination.";
    };

    stageInDownloads = lib.mkOption {
      type = lib.types.bool;
      default = stageInDownloads;
      description = "Create ${appName} archives in Downloads before publishing them to the external destination.";
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
          StandardOutPath = "/Users/ven/Library/Logs/${commandName}.log";
          StandardErrorPath = "/Users/ven/Library/Logs/${commandName}-error.log";
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
