# darwin/system-commands/backups/librewolf.nix
# LibreWolf browser backup command: `librewolf-backup`.

{ lib, pkgs, ... }:

let
  librewolfBackup = import ./app-backup-helper.nix {
    inherit lib pkgs;
    appName = "LibreWolf";
    appSlug = "librewolf";
    destinationSegments = [ "browsers" "librewolf" ];
    sources = [
      { path = "/Users/ven/Library/Application Support/librewolf"; destination = "librewolf"; }
      { path = "/Users/ven/Library/Preferences/net.librewolf.librewolf.plist"; destination = "app-pref/net.librewolf.librewolf.plist"; }
      { path = "/Users/ven/Library/Preferences/org.mozilla.librewolf.plist"; destination = "app-pref/org.mozilla.librewolf.plist"; }
    ];
  };
in
{
  environment.systemPackages = [ librewolfBackup ];
}
