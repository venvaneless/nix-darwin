# darwin/system-commands/backups/wallabag.nix
#
# Backs up Wallabag container data to SystemBackup.
#
# Values only. Every knob below is declared in
# options/backups/container-backup-helper.nix, which owns what each one
# means and how the backup is carried out.

{ config, ... }:

{
  services.backups.containers.wallabag = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.backups.enabled for this container.
    enable = true;

    # ---- IDENTITY
    appName = "Wallabag";

    # ---- SOURCE
    # ** The source is the directory the Wallabag service itself
    # ** declares, so the backup follows the service if that data
    # ** directory moves.
    sourceDir = config.services.wallabag.dataDir;

    # ---- EDITABLE BACKUP PATHS
    # Absolute sourcePath entries for data outside sourceDir, staged on top
    # of the archive. Add as many as required.
    additionalSources = [
      # {
      #   sourcePath = "${config.services.backups.paths.homeDirectory}/Library/Somewhere/Wallabag";
      #   destinationPath = "additional/Somewhere/Wallabag";
      # }
    ];

    # ---- INDIVIDUAL BACKUP CONTROLS
    archive = true;
    stageInDownloads = true;
    archiveFilenameTemplate = "{timestamp}-{prefix}.zip";
    archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
    archivePrefix = "wallabag";
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
    scheduledHour = 5;
    scheduledMinute = 0;
  };
}
