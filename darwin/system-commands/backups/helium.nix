# darwin/system-commands/backups/helium.nix
# Helium browser backup command: `helium-backup`.

{
  appBackupHelper,
  config,
  paths,
  ...
}:

let
  # ---- EDITABLE BACKUP PATHS
  # Browser-specific mutable locations come from the centralized paths.
  browserPaths = paths.darwin.home.browsers;

  # ---- EDITABLE BACKUP CONTENTS
  destinationSegments = [ "helium" ];
  applicationSupportEntries = [
    {
      relativePath = "net.imput.helium";
      destinationPath = "app-support/net.imput.helium";
    }
  ];
  preferenceEntries = [
    {
      relativePath = "net.imput.helium.plist";
      destinationPath = "app-pref/net.imput.helium.plist";
    }
  ];
  configEntries = [
    # { relativePath = "helium"; destinationPath = "user-config/helium"; }
  ];
  additionalSources = [
    {
      sourcePath = browserPaths.heliumExtensions;
      destinationPath = "profile/helium-extensions";
    }
    {
      sourcePath = browserPaths.heliumProfile;
      destinationPath = "profile/helium-ven";
    }
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
  archivePrefix = "helium";
  preserveSymlinks = true;

  heliumBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "Helium";
    appSlug = "helium";
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
heliumBackup
