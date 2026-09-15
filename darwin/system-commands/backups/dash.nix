# darwin/system-commands/backups/dash.nix
# Dash backup command: `dash-backup`.

{
  appBackupHelper,
  config,
  paths,
  ...
}:

let
  # These entries resolve from applicationSupportDirectory. Add one entry for
  # every Dash path stored in Application Support.
  applicationSupportEntries = [
    {
      relativePath = "Dash";
      destinationPath = "app-support/Dash";
    }
    {
      relativePath = "com.kapeli.dash-setapp";
      destinationPath = "app-support/com.kapeli.dash-setapp";
    }
  ];
  # These entries resolve from preferencesDirectory. Add one entry for every
  # Dash preference file or directory that should be backed up.
  preferenceEntries = [
    {
      relativePath = "com.kapeli.dashdoc.plist";
      destinationPath = "app-pref/com.kapeli.dashdoc.plist";
    }
    {
      relativePath = "com.kapeli.dash-setapp.plist";
      destinationPath = "app-pref/com.kapeli.dash-setapp.plist";
    }
  ];
  configEntries = [
    # { relativePath = "dash"; destinationPath = "user-config/dash"; }
  ];
  # Use this list for any additional absolute source outside the standard
  # roots above; every item is copied to its own destinationPath.
  additionalSources = [
    # {
    #   sourcePath = "${paths.darwin.home.root}/Library/Somewhere/Dash";
    #   destinationPath = "additional/Somewhere/Dash";
    # }
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
  archivePrefix = "dash";
  preserveSymlinks = true;

  dashBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Dash";
    appSlug = "dash";
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
dashBackup
