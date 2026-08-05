# darwin/system-commands/backups/raycast.nix
# Raycast backup command: `raycast-backup`.

{ lib, pkgs, ... }:

let
  raycastBackup = import ./mk-app-backup.nix {
    inherit lib pkgs;
    appName = "Raycast";
    appSlug = "raycast";
    requiredAny = [ [
      "/Users/ven/Library/Application Support/com.raycast.macos"
      "/Users/ven/Library/Application Support/com.raycast-x.macos"
    ] ];
    sources = [
      { path = "/Users/ven/Library/Application Support/com.raycast.macos"; destination = "app-support/com.raycast.macos"; }
      { path = "/Users/ven/Library/Application Support/com.raycast-x.macos"; destination = "app-support/com.raycast-x.macos"; }
      { path = "/Users/ven/Library/Application Support/com.raycast.shared"; destination = "app-support/com.raycast.shared"; }
      { path = "/Users/ven/Library/Preferences/com.raycast.macos.plist"; destination = "com.raycast.macos.plist"; }
      { path = "/Users/ven/.config/raycast"; destination = "user-config/raycast"; }
    ];
  };
in
{
  environment.systemPackages = [ raycastBackup ];
}
