# darwin/system-commands/backups/helium.nix
# Helium browser backup command: `helium-backup`.

{ lib, pkgs, ... }:

let
  heliumBackup = import ./app-backup-helper.nix {
    inherit lib pkgs;
    appName = "Helium";
    appSlug = "helium";
    destinationSegments = [ "browsers" "helium" ];
    sources = [
      { path = "/Users/ven/Library/Application Support/net.imput.helium"; destination = "net.imput.helium"; }
      { path = "/Users/ven/Library/Preferences/net.imput.helium.plist"; destination = "net.imput.helium.plist"; }
    ];
  };
in
{
  environment.systemPackages = [ heliumBackup ];
}
