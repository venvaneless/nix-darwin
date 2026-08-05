# darwin/system-commands/backups/vlc.nix
# VLC backup command: `vlc-backup`.

{ lib, pkgs, ... }:

let
  vlcBackup = import ./app-backup-helper.nix {
    inherit lib pkgs;
    appName = "VLC";
    appSlug = "vlc";
    sources = [
      { path = "/Users/ven/Library/Application Support/org.videolan.vlc"; destination = "org.videolan.vlc"; }
      { path = "/Users/ven/Library/Preferences/org.videolan.vlc"; destination = "app-pref/org.videolan.vlc"; }
      { path = "/Users/ven/Library/Preferences/org.videolan.vlc.plist"; destination = "app-pref/org.videolan.vlc.plist"; }
    ];
  };
in
{
  environment.systemPackages = [ vlcBackup ];
}
