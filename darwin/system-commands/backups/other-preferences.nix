# darwin/system-commands/backups/other-preferences.nix
# Copy-ready plist backup template.
#
# Thaw and macOS Terminal are intentionally not backed up. Copy this file to
# create a dedicated app or container backup module, then use one destination:
#
#   /Volumes/SystemBackup/data-backups/app-backups/<app>
#   /Volumes/SystemBackup/data-backups/container-backups/<container>
#   /Volumes/SystemBackup/system/terminal/<terminal>/backups
#
# Use `applicationPreferences = [ { sourcePath = "...";
# destinationPath = "..."; } ];` with app-backup-helper.nix for an app.

{ ... }:
{
}
