# darwin/system-commands/backups/paste.nix
# Paste backup command: `paste-backup`.

{ lib, pkgs, ... }:

let
  pasteBackup = import ./mk-app-backup.nix {
    inherit lib pkgs;
    appName = "Paste";
    appSlug = "paste";
    sources = [
      { path = "/Users/ven/Library/Application Support/com.wiheads.paste-direct"; destination = "com.wiheads.paste-direct"; }
      { path = "/Users/ven/Library/Preferences/com.wiheads.paste-direct.plist"; destination = "com.wiheads.paste-direct.plist"; }
    ];
  };
in
{
  environment.systemPackages = [ pasteBackup ];
}
