# darwin/system-commands/backups/vaultwarden.nix
#
# Backs up Vaultwarden container data to SystemBackup.
#
# Values only. Every knob below is declared in
# options/backups/container-backup-helper.nix, which owns what each one
# means and how the backup is carried out.

{ paths, ... }:

{
  services.backups.containers.vaultwarden = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.backups.enabled for this container.
    enable = true;

    # ---- IDENTITY
    appName = "Vaultwarden";

    # ---- PATHS ---- #

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Containers
    sourceRoot = paths.darwin.home.containers;

    # -- Container
    sourceDir = paths.darwin.docker.data.vaultwarden;

    # -- Destination
    destinationDir = paths.darwin.backups.perContainer.vaultwarden.destination;

    # ---- LIVE DATABASE
    # ** Vaultwarden writes to this database while it runs, so it is
    # ** named rather than copied with the rest of the directory.
    sqliteDatabase = "db.sqlite3";

    # ---- EDITABLE BACKUP PATHS
    # Absolute sourcePath entries for data outside sourceDir, staged on top
    # of the archive. Add as many as required. (sourceEntries is not used
    # here: it would bypass the live-database handling above.)
    additionalSources = [
      # {
      #   sourcePath = [ "${paths.darwin.home.root}/Library/Somewhere/Vaultwarden" ];
      #   destinationPath = "additional/Somewhere/Vaultwarden";
      # }
    ];

    # ---- INDIVIDUAL BACKUP CONTROLS
    archive = true;
    stageInDownloads = true;
    archiveFilenameTemplate = "{timestamp}-{prefix}.zip";
    archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
    archivePrefix = "vaultwarden";
    preserveSymlinks = true;

    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 35;
    minimumCpuLimitPercent = 5;
    maximumCpuLimitPercent = 50;
    transferLimitKiBps = 4096;
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
    runOnRebuild = false;

    # ---- SCHEDULE
    scheduledHour = 4;
    scheduledMinute = 0;
  };
}
