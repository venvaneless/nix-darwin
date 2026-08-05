# darwin/system-commands/backups/vesktop.nix
# Vesktop backup command: `vesktop-backup`.

{ lib, pkgs, ... }:

let
  vesktopBackup = import ./app-backup-helper.nix {
    inherit lib pkgs;
    appName = "Vesktop";
    appSlug = "vesktop";
    sources = [
      { path = "/Users/ven/Library/Application Support/vesktop"; destination = "vesktop"; }
      { path = "/Users/ven/Library/Preferences/dev.vencord.vesktop.plist"; destination = "dev.vencord.vesktop.plist"; }
    ];
  };
in
{
  environment.systemPackages = [ vesktopBackup ];
}
