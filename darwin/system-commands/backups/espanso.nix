# darwin/system-commands/backups/espanso.nix
# Espanso backup command: `espanso-backup`.

{
  appBackupHelper,
  config,
  paths,
  ...
}:

let
  # ---- EDITABLE BACKUP CONTENTS
  configEntries = [
    {
      relativePath = "espanso";
      destinationPath = "user-config/espanso";
    }
  ];
  preferenceEntries = [
    {
      relativePath = "com.federicoterzi.espanso.plist";
      destinationPath = "app-pref/com.federicoterzi.espanso.plist";
    }
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
  archivePrefix = "espanso";
  preserveSymlinks = true;

  espansoBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Espanso";
    appSlug = "espanso";
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
      configEntries
      preferenceEntries
      additionalSources
      extraExcludePatterns
      ;
    applicationSupportRoot = paths.darwin.library.applicationSupport;
    preferencesRoot = paths.darwin.library.preferences;
    configRoot = paths.darwin.home.config;
  };
in
espansoBackup
