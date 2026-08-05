# darwin/system-commands/backups/yate.nix
# Yate backup command: `yate-backup`.

{ lib, pkgs, ... }:

let
  yateBackup = import ./app-backup-helper.nix {
    inherit lib pkgs;
    appName = "Yate";
    appSlug = "yate";
    sources = [
      { path = "/Users/ven/Library/Application Support/Yate/Backups"; destination = "Backups"; }
      { path = "/Users/ven/Library/Preferences/com.2manyrobots.Yate.plist"; destination = "com.2manyrobots.Yate.plist"; }
    ];
  };
in
{
  environment.systemPackages = [ yateBackup ];
}
