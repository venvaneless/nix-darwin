# darwin/system-commands/backups/other-preferences.nix
# Other preferences backup command: `other-preferences-backup`.

{ lib, pkgs, ... }:

let
  otherPreferencesBackup = import ./app-backup-helper.nix {
    inherit lib pkgs;
    appName = "Other Preferences";
    appSlug = "other-preferences";
    commandName = "other-preferences-backup";
    sources = [
      { path = "/Users/ven/Library/Preferences/com.stonerl.Thaw.plist"; destination = "app-pref/com.stonerl.Thaw.plist"; }
      { path = "/Users/ven/Library/Preferences/com.apple.Terminal.plist"; destination = "app-pref/com.apple.Terminal.plist"; }
    ];
  };
in
{
  environment.systemPackages = [ otherPreferencesBackup ];
}
