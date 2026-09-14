# darwin/system-commands/backups/browsertrix.nix
#
# Backs up Browsertrix container data to SystemBackup.
#
# Values only. Every knob below is declared in
# options/backups/container-backup-helper.nix, which owns what each one
# means and how the backup is carried out.

{ config, ... }:

let
  # ---- EDITABLE BACKUP ROOTS
  # ** Destination and staging directories are registered under
  # ** darwin.backups.perContainer in options/paths.nix and resolved by
  # ** the helper from the slug. Change them there, not here.
  backupPaths = config.services.backups.paths;
  containerDirectory = backupPaths.containerDirectory;

  # ---- EDITABLE BACKUP PATHS
  # These entries resolve from containerDirectory. Add as many Browsertrix
  # directories or files as required, each with its archive destination.
  containerEntries = [
    {
      relativePath = "browsertrix";
      destinationPath = "browsertrix";
    }
  ];
  # Use absolute sourcePath entries for data outside containerDirectory.
  additionalSources = [
    # {
    #   sourcePath = "${backupPaths.homeDirectory}/Library/Somewhere/Browsertrix";
    #   destinationPath = "additional/Somewhere/Browsertrix";
    # }
  ];
  sourceEntries = containerEntries;
in
{
  services.backups.containers.browsertrix = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.backups.enabled for this container.
    enable = true;

    # ---- IDENTITY
    appName = "Browsertrix";

    # ---- SOURCE
    # sourceEntries resolve from sourceRoot (the container-data root);
    # additionalSources are absolute paths staged on top of them.
    sourceRoot = containerDirectory;
    inherit sourceEntries additionalSources;

    # ---- INDIVIDUAL BACKUP CONTROLS
    archive = true;
    stageInDownloads = true;
    archiveFilenameTemplate = "{timestamp}-{prefix}.zip";
    archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
    archivePrefix = "browsertrix";
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
    scheduledHour = 2;
    scheduledMinute = 0;
  };
}
