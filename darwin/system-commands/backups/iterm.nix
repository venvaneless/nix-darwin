# darwin/system-commands/backups/iterm.nix
# iTerm2 backup command: `iterm-backup`.

{ lib, pkgs, ... }:

let
  itermBackup = import ./mk-app-backup.nix {
    inherit lib pkgs;
    appName = "iTerm2";
    appSlug = "iterm";
    sources = [
      { path = "/Users/ven/Library/Application Support/iTerm2"; destination = "app-support/iTerm2"; }
      { path = "/Users/ven/Library/Preferences/com.googlecode.iterm2.plist"; destination = "app-pref/com.googlecode.iterm2.plist"; }
      { path = "/Users/ven/Library/Preferences/com.googlecode.iterm2.private.plist"; destination = "app-pref/com.googlecode.iterm2.private.plist"; }
    ];
  };
in
{
  environment.systemPackages = [ itermBackup ];
}
