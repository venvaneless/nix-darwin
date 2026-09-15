# darwin/system-commands/backups/archivebox.nix
#
# Backs up ArchiveBox container data to SystemBackup.
#
# Values only. Every knob below is declared in
# options/backups/container-backup-helper.nix, which owns what each one
# means and how the backup is carried out.

{ paths, ... }:

{
  services.backups.containers.archivebox = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.backups.enabled for this container.
    enable = true;

    # ---- IDENTITY
    appName = "ArchiveBox";

    # ---- SOURCE
    # ** The source is defined centrally in options/paths.nix.
    #
    # ** Destination and staging directories are registered under
    # ** darwin.backups.perContainer in options/paths.nix and resolved
    # ** from the slug. Change them there, not here.
    sourceDir = paths.darwin.docker.data.archivebox;

    # ---- LIVE DATABASE
    # ** ArchiveBox writes to this database while it runs, so it is
    # ** named rather than copied with the rest of the directory.
    sqliteDatabase = "index.sqlite3";

    # ---- EDITABLE BACKUP PATHS
    # Absolute sourcePath entries for data outside sourceDir, staged on top
    # of the archive. Add as many as required. (sourceEntries is not used
    # here: it would bypass the live-database handling above.)
    additionalSources = [
      # {
      #   sourcePath = "${paths.darwin.home.root}/Library/Somewhere/ArchiveBox";
      #   destinationPath = "additional/Somewhere/ArchiveBox";
      # }
    ];

    # ---- INDIVIDUAL BACKUP CONTROLS
    archive = true;
    stageInDownloads = true;
    archiveFilenameTemplate = "{timestamp}-{prefix}.zip";
    archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
    archivePrefix = "archivebox";
    preserveSymlinks = true;

    # ---- EDITABLE EXCLUSIONS
    extraExcludePatterns = [
      "sockets/"
      "private/socket"
      "*.sock"
    ];

    # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
    automatic = false;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 35;
    minimumCpuLimitPercent = 5;
    maximumCpuLimitPercent = 50;
    transferLimitKiBps = 4096;
    showProgress = true;
    runOnRebuild = false;

    # ---- SCHEDULE
    scheduledHour = 1;
    scheduledMinute = 0;
  };
}
