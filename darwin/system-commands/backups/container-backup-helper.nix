# darwin/system-commands/backups/container-backup-helper.nix
#
# =====================================================================
# CONTAINER BACKUP HELPER
#
# Creates an optional scheduled LaunchAgent and optional rebuild hook for one
# container directory. Each backup is compressed and verified locally in
# Downloads before its completed archive is moved to SystemBackup.
# =====================================================================

{ lib, pkgs }:

let
  # ---- SHARED PATHS ---- #
  # Option defaults, the lock directories, the mount check, and the
  # LaunchAgent log directory come from the centralized path definitions.
  # default.nix sets the same values explicitly; these defaults keep the
  # option surface usable on its own.
  paths = import ../../../options/paths.nix { };

  userPaths = paths.darwin.home;
  libraryPaths = paths.darwin.library;
  backupPaths = paths.darwin.backups;
  systemPaths = paths.darwin.system;

  # ---- PER-CONTAINER LOCATION LOOKUP
  # Resolves one container's backup locations from the registry in
  # options/paths.nix. Kept as a helper so an unregistered container
  # fails with a message that says what to do, rather than with a bare
  # "attribute missing" error.
  containerLocations = config: appSlug:
    config.services.containerBackups.paths.perContainer.${appSlug}
      or (throw ''
        container backup "${appSlug}" has no registered backup locations.

        Add an entry for it under darwin.backups.perContainer in
        options/paths.nix, with a destination and a staging directory.
      '');

  # ---- GLOBAL CONTAINER BACKUP CONTROLS
  # Imported once by default.nix. Per-container modules retain their own
  # schedule, interval, CPU cap, and rebuild toggles.
  settingsModule = { lib, ... }: {
    options.services.containerBackups = {
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

      runOnRebuild = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Run enabled container backups during darwin-rebuild activation.";
      };
    };
  };

  mkContainerBackup = {
    config,
    appName,
    appSlug,
    sourceDir ? null,
    sourceRoot ? config.services.containerBackups.paths.containerDirectory,
    sourceEntries ? [ ],
    containerConfig ? [ ],
    destinationDir ? (containerLocations config appSlug).destination,
    externalBackupVolume ? config.services.containerBackups.paths.externalBackupVolume,
    localStagingDir ? (containerLocations config appSlug).staging,
    sourceMarkerFile ? null,
    destinationMarkerFile ? null,
    lockDir ? "${backupPaths.lockRoot}/com.ven.${appSlug}-backup.lock",
    globalLockDir ? backupPaths.archiveLock,
    scheduledHour ? 4,
    scheduledMinute ? 0,
    prepareArchive ? "",
    automatic ? false,
    automaticIntervalSeconds ? config.services.containerBackups.defaultAutomaticIntervalSeconds,
    minimumIntervalSeconds ? config.services.containerBackups.defaultMinimumIntervalSeconds,
    cpuLimitPercent ? config.services.containerBackups.defaultCpuLimitPercent,
    runOnRebuild ? false,
    extraExcludePatterns ? [ ],
    archive ? true,
    stageInDownloads ? true,
    archiveFilenameTemplate ? "{timestamp}-{appSlug}.zip",
    archiveTimestampFormat ? "%Y-%m-%d--%H%M%S",
    archivePrefix ? appSlug,
    preserveSymlinks ? true,
  }:
  let
  resolvedSourceEntries = map (entry: {
    sourcePath = if entry ? sourcePath then entry.sourcePath else "${sourceRoot}/${entry.relativePath}";
    destinationPath = entry.destinationPath;
  }) sourceEntries;
  resolvedSourceDir =
    if resolvedSourceEntries != [ ] then
      (builtins.head resolvedSourceEntries).sourcePath
    else if sourceDir != null then
      sourceDir
    else if containerConfig != [ ] then
      (builtins.head containerConfig).sourcePath
    else
      throw "A container backup needs sourceDir or a non-empty containerConfig list.";
  resolvedSourceMarkerFile = if sourceMarkerFile == null then "${resolvedSourceDir}/.last-backup" else sourceMarkerFile;
  resolvedDestinationMarkerFile = if destinationMarkerFile == null then "${destinationDir}/.last-backup" else destinationMarkerFile;
  cfg = config.services.containerBackups.${appSlug};
  backupCfg = config.services.containerBackups;
  extraExcludes = lib.concatMapStringsSep "\n" (pattern: ''
        --exclude=${lib.escapeShellArg pattern}
  '') (backupCfg.defaultExtraExcludePatterns ++ extraExcludePatterns);
  zipExtraExcludes = lib.concatMapStringsSep " " (pattern: "-x ${lib.escapeShellArg pattern}") (backupCfg.defaultExtraExcludePatterns ++ extraExcludePatterns);
  rsyncSymlinkArguments = if cfg.preserveSymlinks then "-a" else "-aL";
  stageSourceEntries = lib.concatMapStringsSep "\n" (entry: ''
        ${pkgs.coreutils}/bin/mkdir -p -- "$staged_source/${entry.destinationPath}"
        ${pkgs.rsync}/bin/rsync ${rsyncSymlinkArguments} "''${exclude_args[@]}" -- \
          ${lib.escapeShellArg "${entry.sourcePath}/"} "$staged_source/${entry.destinationPath}/"
  '') resolvedSourceEntries;
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
      cpu_limit_percent=${toString cfg.cpuLimitPercent}
      archive_enabled=${if cfg.archive then "1" else "0"}
      archive_in_downloads=${if cfg.stageInDownloads then "1" else "0"}
      archive_name_template="$(printf '%s' ${lib.escapeShellArg cfg.archiveFilenameTemplate})"
      archive_timestamp_format="$(printf '%s' ${lib.escapeShellArg cfg.archiveTimestampFormat})"
      archive_prefix="$(printf '%s' ${lib.escapeShellArg cfg.archivePrefix})"

      mode="manual"
      temporary_archive=""
      local_archive=""
      temporary_marker=""
      staging_dir=""
      global_lock_acquired=0
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

      release_lock() {
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

        release_lock
        release_global_lock
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

      # Create only this explicitly configured local staging directory.
      ${pkgs.coreutils}/bin/mkdir -p -- "$local_staging_dir"

      if [ ! -d "$local_staging_dir" ]; then
        fail "could not create local staging directory: $local_staging_dir"
      fi

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
      trap cleanup EXIT INT TERM

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

      ${prepareSourceEntries}
      ${prepareArchive}

      # Only one backup may compress, verify, or hand off to external storage at once.
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

      timestamp="$(
        ${pkgs.coreutils}/bin/date "+$archive_timestamp_format"
      )"
      archive_name="''${archive_name_template//\{timestamp\}/$timestamp}"
      archive_name="''${archive_name//\{prefix\}/$archive_prefix}"
      archive_name="''${archive_name//\{appSlug\}/$app_slug}"
      archive="$destination_dir/$archive_name"
      local_archive="$local_staging_dir/$archive_name"
      temporary_archive="$local_staging_dir/.$archive_name.$$.incomplete"
      temporary_marker="$local_staging_dir/.last-backup-$$.incomplete"

      if [ "$archive_enabled" -eq 1 ] && { [ -e "$archive" ] || [ -e "$local_archive" ]; }; then
        fail "refusing to overwrite an existing archive: $archive"
      fi

      if [ "$archive_enabled" -eq 0 ]; then
        log "syncing unarchived backup: $destination_dir"
        ${pkgs.rsync}/bin/rsync ${rsyncSymlinkArguments} "''${exclude_args[@]}" -- \
          "$archive_source_parent/$archive_source_name/" "$destination_dir/"
        ${pkgs.coreutils}/bin/touch -- "$marker_file" "$source_marker_file"
        log "completed successfully: $destination_dir"
        exit 0
      fi

      if [ "$archive_in_downloads" -eq 0 ]; then
        temporary_archive="$destination_dir/.$archive_name.$$.incomplete"
      fi

      log "creating archive: $temporary_archive"

      (
        cd -- "$archive_source_parent"

        ${pkgs.cpulimit}/bin/cpulimit -l "$cpu_limit_percent" -- \
          ${pkgs.zip}/bin/zip -q -r -y "$temporary_archive" "$archive_source_name" \
          -x '*/.DS_Store' \
          -x '*/._*' \
          -x '*/.AppleDouble' \
          -x '*/__MACOSX/*' \
          -x '*/Thumbs.db' \
          -x '*/desktop.ini' \
          ${zipExtraExcludes}
      )

      ${pkgs.cpulimit}/bin/cpulimit -l "$cpu_limit_percent" -- \
        ${pkgs.unzip}/bin/unzip -t "$temporary_archive" >/dev/null
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
{
  options.services.containerBackups.${appSlug} = {
    enable = lib.mkEnableOption "${appName} container backup";

    automatic = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run the ${appName} backup automatically through its interval-based LaunchAgent schedule when explicitly enabled.";
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
      description = "Maximum CPU percentage used for ${appName} archive creation and verification.";
    };

    runOnRebuild = lib.mkOption {
      type = lib.types.bool;
      default = runOnRebuild;
      description = "Include the ${appName} backup during rebuild only when explicitly enabled.";
    };

    archive = lib.mkOption {
      type = lib.types.bool;
      default = archive;
      description = "Create a ZIP archive for ${appName}; false keeps an unarchived rsync copy at its destination.";
    };

    stageInDownloads = lib.mkOption {
      type = lib.types.bool;
      default = stageInDownloads;
      description = "Create ${appName} archives in Downloads before moving them to the external destination.";
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

  config = lib.mkIf (backupCfg.enabled && cfg.enable) (lib.mkMerge [
    {
      # Makes the enabled container backup available for manual use.
      environment.systemPackages = [ backupRunner ];
    }

    (lib.mkIf (backupCfg.automaticEnabled && cfg.automatic) {
      launchd.user.agents."backup-${appSlug}" = {
        serviceConfig = {
          Label = launchdLabel;
          ProgramArguments = [
            "${backupRunner}/bin/${commandName}"
            "--scheduled"
          ];
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

    (lib.mkIf (backupCfg.runOnRebuild && cfg.runOnRebuild) {
      system.activationScripts."run-${appSlug}-backup".text = lib.mkAfter ''
        echo ">>> [${appSlug} backup] Running requested rebuild backup"
        /usr/bin/sudo -H -u ven "${backupRunner}/bin/${commandName}" --rebuild \
          || echo ">>> [${appSlug} backup] Rebuild backup failed (continued)"
      '';
    })
  ]);
}
;
in
{
  inherit mkContainerBackup settingsModule;
}
