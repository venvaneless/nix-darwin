# darwin/system-commands/backups/better-finder-attributes.nix
# A Better Finder Attributes backup command: `better-attributes-backup`.

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
      relativePath = "A Better Finder Attributes 7";
      destinationPath = "app-support/A Better Finder Attributes 7";
    }
  ];
  preferenceEntries = [
    {
      relativePath = "net.publicspace.abfa7.plist";
      destinationPath = "app-pref/net.publicspace.abfa7.plist";
    }
  ];
  configEntries = [
    # { relativePath = "better-finder-attributes"; destinationPath = "user-config/better-finder-attributes"; }
  ];
  additionalSources = [
    # {
    #   sourcePath = "${paths.darwin.home.root}/Library/Somewhere/Better Finder Attributes";
    #   destinationPath = "additional/Somewhere/Better Finder Attributes";
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
  archivePrefix = "better-finder-attributes";
  preserveSymlinks = true;

in
appBackupHelper.mkAppBackup {
  inherit config;

  appName = "A Better Finder Attributes";
  appSlug = "better-finder-attributes";
  commandName = "better-attributes-backup";
  inherit
    automatic
    automaticIntervalSeconds
    minimumIntervalSeconds
    cpuLimitPercent
    showProgress
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
  inherit
    archive
    stageInDownloads
    archiveFilenameTemplate
    archiveTimestampFormat
    archivePrefix
    preserveSymlinks
    ;
}
