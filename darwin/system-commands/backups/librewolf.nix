# darwin/system-commands/backups/librewolf.nix
# LibreWolf browser backup command: `librewolf-backup`.

{
  appBackupHelper,
  config,
  paths,
  ...
}:

let
  # ---- EDITABLE BACKUP CONTENTS
  # Browser-specific mutable locations come from the centralized paths.
  browserPaths = paths.darwin.home.browsers;

  destinationSegments = [ "librewolf" ];
  applicationSupportEntries = [
    {
      relativePath = "librewolf";
      destinationPath = "app-support/librewolf";
    }
  ];
  preferenceEntries = [
    # The current Nix-installed LibreWolf bundle uses this identifier.
    {
      relativePath = "org.nixos.librewolf.plist";
      destinationPath = "app-pref/org.nixos.librewolf.plist";
    }
  ];
  configEntries = [
    # The profile below is outside the ordinary .config root.
  ];
  additionalSources = [
    {
      sourcePath = browserPaths.firefoxProfile;
      destinationPath = "profile/firefox-ven";
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
  archivePrefix = "librewolf";
  preserveSymlinks = true;
  librewolfBackup = appBackupHelper.mkAppBackup {
    inherit config;
    appName = "LibreWolf";
    appSlug = "librewolf";
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
librewolfBackup
