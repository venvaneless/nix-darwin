# darwin/system-commands/backups/chrome-canary.nix
# Chrome Canary browser backup command: `chrome-canary-backup`.

{
  appBackupHelper,
  config,
  paths,
  ...
}:

let
  # ---- EDITABLE BACKUP CONTENTS
  destinationSegments = [ "chrome-canary" ];
  applicationSupportEntries = [
    {
      relativePath = "Google/Chrome Canary";
      destinationPath = "app-support/Google/Chrome Canary";
    }
  ];
  preferenceEntries = [
    {
      relativePath = "com.google.Chrome.canary.plist";
      destinationPath = "app-pref/com.google.Chrome.canary.plist";
    }
  ];
  configEntries = [
    # { relativePath = "chrome-canary"; destinationPath = "user-config/chrome-canary"; }
  ];
  additionalSources = [
    # { sourcePath = "/Users/ven/Library/Somewhere/Chrome Canary"; destinationPath = "additional/Chrome Canary"; }
  ];

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
  archivePrefix = "chrome-canary";
  preserveSymlinks = true;
  chromeCanaryBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Chrome Canary";
    appSlug = "chrome-canary";
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
    destinationRoot = "browserBackups";
    inherit
      destinationSegments
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
chromeCanaryBackup
