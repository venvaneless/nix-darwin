# darwin/system-commands/backups/paste.nix
# Paste backup command: `paste-backup`.

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
      relativePath = "com.wiheads.paste-direct";
      destinationPath = "app-support/com.wiheads.paste-direct";
    }
  ];
  preferenceEntries = [
    {
      relativePath = "com.wiheads.paste-direct.plist";
      destinationPath = "app-pref/com.wiheads.paste-direct.plist";
    }
  ];
  configEntries = [
    # { relativePath = "paste"; destinationPath = "user-config/paste"; }
  ];
  additionalSources = [
    # {
    #   sourcePath = "${paths.darwin.home.root}/Library/Somewhere/Paste";
    #   destinationPath = "additional/Somewhere/Paste";
    # }
  ];

  # ---- EDITABLE EXCLUSIONS
  # Add folders or file patterns that Paste should not include.
  extraExcludePatterns = [
    "sockets/"
    "private/socket"
    "*.sock"
  ];

  # ---- INDIVIDUAL ARCHIVE CONTROLS
  archive = true;
  stageInDownloads = true;
  archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
  archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
  archivePrefix = "paste";
  preserveSymlinks = true;

  # ---- INDIVIDUAL AUTOMATIC BACKUP CONTROLS
  automatic = false;
  automaticIntervalSeconds = 86400;
  minimumIntervalSeconds = 28800;
  cpuLimitPercent = 25;
  showProgress = true;

  pasteBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Paste";
    appSlug = "paste";
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
pasteBackup
