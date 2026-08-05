# darwin/system-commands/backups/chrome-canary.nix
# Chrome Canary browser backup command: `chrome-canary-backup`.

{ lib, pkgs, ... }:

let
  chromeCanaryBackup = import ./mk-app-backup.nix {
    inherit lib pkgs;
    appName = "Chrome Canary";
    appSlug = "chrome-canary";
    destinationSegments = [ "browsers" "chrome-canary" ];
    sources = [
      { path = "/Users/ven/Library/Application Support/Google/Chrome Canary"; destination = "app-support/Chrome Canary"; }
      { path = "/Users/ven/Library/Preferences/com.google.Chrome.canary.plist"; destination = "com.google.Chrome.canary.plist"; }
    ];
  };
in
{
  environment.systemPackages = [ chromeCanaryBackup ];
}
