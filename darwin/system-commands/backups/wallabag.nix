# darwin/system-commands/backups/wallabag.nix
#
# Backs up Wallabag container data to SystemBackup.
#
# Values only. Every knob below is declared in
# options/backups/container-backup-helper.nix, which owns what each one
# means and how the backup is carried out.

{ paths, ... }:

{
  services.backups.containers.wallabag = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.backups.enabled for this container.
    enable = true;

    # ---- IDENTITY
    appName = "Wallabag";

    # ---- PATHS ---- #

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Containers
    sourceRoot = paths.darwin.home.containers;

    # -- Container
    sourceDir = paths.darwin.docker.data.wallabag;

    # -- Destination
    destinationDir = paths.darwin.backups.perContainer.wallabag.destination;

    # -- iCloud
    # Backups go to <iCloudRoot>/<appName in lowercase>.
    iCloudRoot = paths.darwin.backups.icloud;

    # ---- LIVE DATABASE
    sqliteDatabase = null;

    # ---- EDITABLE BACKUP PATHS
    # sourceEntries resolve from sourceRoot, configEntries from configRoot;
    # additionalSources are absolute.

    sourceEntries = [ ];

    configEntries = [ ];

    # Absolute paths for data outside the roots above. Uncomment to add one.
    additionalSources = [
      # {
      #   sourcePath = [ "${paths.darwin.home.root}/Library/Somewhere/Wallabag" ];
      #   destinationPath = "additional/Somewhere/Wallabag";
      # }
    ];

    # ---- INDIVIDUAL ARCHIVE CONTROLS
    archive = true;
    stageInDownloads = true;
    archiveFilenameTemplate = "{timestamp}-{prefix}.zip";
    archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
    archivePrefix = "wallabag";

    /* iCloud */
    storeiCloud = false;
    cleanOldestiCloud = true;
    iCloudBackupsToKeep = 3;

    # ---- BACKUP CONTROLS
    automatic = false;
    notifyOnAutomatic = true;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 35;
    minimumCpuLimitPercent = 5;
    maximumCpuLimitPercent = 50;
    transferLimitKiBps = 4096;
    runOnRebuild = false;

    /* Schedule */
    scheduledHour = 5;
    scheduledMinute = 0;

    /* Encryption */
    encrypt = false;
    encryptionIdentityFile = paths.darwin.home.sopsAgeKeys;
    # The public key comes from the identity file on every run

    # ---- BACKUP ARCHITECTURE
    preserveSymlinks = true;

    /* Backup Process */
    showProgress = true;
    processType = "Background";
    niceLevel = 20;
    lowPriorityIO = true;

    /* Logs */
    logDirectory = paths.darwin.backups.logs;
    logFilenameTemplate = "{appSlug}-{timestamp}.log";
    errorLogFilenameTemplate = "{appSlug}-{timestamp}-error.log";
    logTimestampFormat = "%Y-%m-%d-%H-%M-%S";
    logOnlyOnErrors = true;
  };
}
