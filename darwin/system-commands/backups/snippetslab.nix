# darwin/system-commands/backups/snippetslab.nix
# SnippetsLab backup command: `snippetslab-backup`.

{ lib, pkgs, ... }:

let
  snippetslabBackup = import ./mk-app-backup.nix {
    inherit lib pkgs;
    appName = "SnippetsLab";
    appSlug = "snippetslab";
    sources = [
      { path = "/Users/ven/Library/Containers/com.renfei.SnippetsLab/Data/Library/Application Support/Markdown Themes"; destination = "app-support/Markdown Themes"; }
      { path = "/Users/ven/Library/Containers/com.renfei.SnippetsLab/Data/Library/Application Support/Themes"; destination = "app-support/Themes"; }
      { path = "/Users/ven/Library/Containers/com.renfei.SnippetsLab/Data/Library/Preferences/com.renfei.SnippetsLab.plist"; destination = "com.renfei.SnippetsLab.plist"; }
    ];
  };
in
{
  environment.systemPackages = [ snippetslabBackup ];
}
