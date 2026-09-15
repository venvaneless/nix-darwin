# darwin/system-commands/backups/pearcleaner.nix
# Pearcleaner backup command: `pearcleaner-backup`.

{
  appBackupHelper,
  config,
  paths,
  ...
}:

let
  # ---- EDITABLE BACKUP CONTENTS
  applicationSupportEntries = [
    {
      relativePath = "Pearcleaner";
      destinationPath = "app-support/Pearcleaner";
    }
  ];
  preferenceEntries = [
    {
      relativePath = "com.alienator88.Pearcleaner.plist";
      destinationPath = "app-pref/com.alienator88.Pearcleaner.plist";
    }
    {
      relativePath = "group.com.alienator88.Pearcleaner.plist";
      destinationPath = "app-pref/group.com.alienator88.Pearcleaner.plist";
    }
  ];
  configEntries = [
    # { relativePath = "pearcleaner"; destinationPath = "user-config/pearcleaner"; }
  ];
  additionalSources = [ ];

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
  cpuLimitPercent = 25;
  showProgress = true;

  # ---- INDIVIDUAL ARCHIVE CONTROLS
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "pearcleaner";
  preserveSymlinks = true;

  pearcleanerBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Pearcleaner";
    appSlug = "pearcleaner";
    inherit
      automatic
      automaticIntervalSeconds
      minimumIntervalSeconds
      cpuLimitPercent
      showProgress
      ;
    inherit
      archive
      stageInDownloads
      archiveFilenameTemplate
      archiveTimestampFormat
      archivePrefix
      preserveSymlinks
      ;
    inherit
      applicationSupportEntries
      preferenceEntries
      configEntries
      additionalSources
      extraExcludePatterns
      ;
    applicationSupportRoot = paths.darwin.library.applicationSupport;
    preferencesRoot = paths.darwin.library.preferences;
    configRoot = paths.darwin.home.config;
  };
in
pearcleanerBackup
