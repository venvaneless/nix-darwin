# darwin/system-commands/backups/karakeep.nix
#
# Backs up Karakeep container data to SystemBackup.
#
# Values only. Every knob below is declared in
# options/backups/container-backup-helper.nix, which owns what each one
# means and how the backup is carried out.

{ paths, ... }:

{
  services.backups.containers.karakeep = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.backups.enabled for this container.
    enable = true;

    # ---- IDENTITY
    appName = "Karakeep";

    # ---- PATHS ---- #

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Containers
    sourceRoot = paths.darwin.home.containers;

    # -- Container
    sourceDir = null;

    # -- Destination
    destinationDir = paths.darwin.backups.perContainer.karakeep.destination;

    # -- iCloud
    # Backups go to <iCloudRoot>/<appName in lowercase>.
    iCloudRoot = paths.darwin.backups.icloud;

    # ---- LIVE DATABASE
    sqliteDatabase = null;

    # ---- EDITABLE BACKUP PATHS
    # sourceEntries resolve from sourceRoot, configEntries from configRoot;
    # additionalSources are absolute.

    sourceEntries = [
      {
        sourcePath = "karakeep";
        destinationPath = "karakeep";
      }
    ];

    configEntries = [ ];

    # Absolute paths for data outside the roots above. Uncomment to add one.
    additionalSources = [
      # {
      #   sourcePath = [ "${paths.darwin.home.root}/Library/Somewhere/Karakeep" ];
      #   destinationPath = "additional/Somewhere/Karakeep";
      # }
    ];

    # ---- INDIVIDUAL ARCHIVE CONTROLS
    archive = true;
    stageInDownloads = true;
    archiveFilenameTemplate = "{timestamp}-{prefix}.zip";
    archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
    archivePrefix = "karakeep";
    preserveSymlinks = true;

    # ---- ENCRYPTION
    # The public key comes from the identity file on every run.
    encrypt = false;
    encryptionIdentityFile = paths.darwin.home.sopsAgeKeys;

    # ---- ICLOUD
    storeiCloud = false;
    cleanOldestiCloud = true;
    iCloudBackupsToKeep = 3;

    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    notifyOnAutomatic = true;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 35;
    minimumCpuLimitPercent = 5;
    maximumCpuLimitPercent = 50;
    transferLimitKiBps = 4096;
    runOnRebuild = false;

    # ---- SCHEDULE
    scheduledHour = 6;
    scheduledMinute = 0;

    # ---- OUTPUT
    showProgress = true;

    # ---- PROCESS PRIORITY
    processType = "Background";
    niceLevel = 20;
    lowPriorityIO = true;

    # ---- LOGS
    logDirectory = paths.darwin.backups.logs;
    logFilenameTemplate = "{appSlug}-{timestamp}.log";
    errorLogFilenameTemplate = "{appSlug}-{timestamp}-error.log";
    logTimestampFormat = "%Y-%m-%d-%H-%M-%S";
    logOnlyOnErrors = true;
  };
}
