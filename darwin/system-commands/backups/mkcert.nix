# darwin/system-commands/backups/mkcert.nix
# mkcert CA backup command: `mkcert-backup`.
#
# Values only. Every knob below is declared in
# options/backups/app-backup-helper.nix, which owns what each one means
# and how the backup is carried out.

{ paths, ... }:

{
  services.backups.apps.mkcert = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.appBackups.enabled for this app.
    enable = true;

    # ---- IDENTITY
    appName = "mkcert";
    commandName = "mkcert-backup";

    # ---- PATHS ---- #

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Destination
    destinationRoot = paths.darwin.backups.data;
    destinationSegments = [ "certificates" ];

    # -- iCloud
    # Backups go to <iCloudRoot>/<appName in lowercase>.
    iCloudRoot = paths.darwin.backups.icloud;

    # ---- EDITABLE BACKUP CONTENTS
    # ** The CA files land directly in the archive root, so extracting the
    # ** archive into ~/.config/mkcert restores it.
    configEntries = {
      configPaths = [
        {
          sourcePath = "mkcert";
          destinationPath = ".";
        }
      ];

      excludePatterns = [ ];
    };

    # ---- INDIVIDUAL ARCHIVE CONTROLS
    archive = true;
    stageInDownloads = true;
    archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
    archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
    archivePrefix = "mkcert";

    /* iCloud */
    storeiCloud = false;
    cleanOldestiCloud = true;
    iCloudBackupsToKeep = 3;

    /* Encryption */
    encrypt = true;
    encryptionIdentityFile = paths.darwin.home.sopsAgeKeys;
    # The public key comes from the identity file on every run

    /* Backup Process */
    showProgress = true;

    /* Logs */
    logDirectory = paths.darwin.backups.logs;
    logFilenameTemplate = "{appSlug}-{timestamp}.log";
    errorLogFilenameTemplate = "{appSlug}-{timestamp}-error.log";
    logTimestampFormat = "%Y-%m-%d-%H-%M-%S";
    logOnlyOnErrors = true;
  };
}
