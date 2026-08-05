# darwin/system-commands/backups/iterm.nix
# iTerm2 backup command: `iterm-backup`.

{ lib, pkgs, ... }:

let
  itermBackup = import ./app-backup-helper.nix {
    inherit lib pkgs;
    appName = "iTerm2";
    appSlug = "iterm";
    destinationRoot = "terminalBackups";
    destinationSegments = [ "iterm" "backups" ];
    extraExcludePatterns = [
      "sockets/"
      "private/socket"
      "*.sock"
    ];
    sources = [
      { path = "/Users/ven/Library/Application Support/iTerm2"; destination = "iTerm2"; }
      { path = "/Users/ven/Library/Preferences/com.googlecode.iterm2.plist"; destination = "com.googlecode.iterm2.plist"; }
    ];
  };
in
{
  environment.systemPackages = [ itermBackup ];
}
