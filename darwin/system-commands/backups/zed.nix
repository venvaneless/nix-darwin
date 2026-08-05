# darwin/system-commands/backups/zed.nix
# Zed backup command: `zed-backup`.

{ lib, pkgs, ... }:

let
  zedBackup = import ./mk-app-backup.nix {
    inherit lib pkgs;
    appName = "Zed";
    appSlug = "zed";
    sources = [
      { path = "/Users/ven/Library/Application Support/zed"; destination = "app-support/zed"; }
      { path = "/Users/ven/.config/zed"; destination = "user-config/zed"; }
      { path = "/Users/ven/Library/Preferences/dev.zed.Zed.plist"; destination = "dev.zed.Zed.plist"; }
    ];
  };
in
{
  environment.systemPackages = [ zedBackup ];
}
