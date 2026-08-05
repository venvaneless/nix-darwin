# darwin/system-commands/backups/better-finder-attributes.nix
# A Better Finder Attributes backup command: `better-attributes-backup`.

{ lib, pkgs, ... }:

let
  betterAttributesBackup = import ./mk-app-backup.nix {
    inherit lib pkgs;
    appName = "A Better Finder Attributes";
    appSlug = "better-finder-attributes";
    commandName = "better-attributes-backup";
    sources = [
      { path = "/Users/ven/Library/Application Support/A Better Finder Attributes 7"; destination = "app-support/A Better Finder Attributes 7"; }
      { path = "/Users/ven/Library/Preferences/net.publicspace.abfa7.plist"; destination = "net.publicspace.abfa7.plist"; }
    ];
  };
in
{
  environment.systemPackages = [ betterAttributesBackup ];
}
