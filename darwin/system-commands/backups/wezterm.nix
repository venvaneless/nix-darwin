# darwin/system-commands/backups/wezterm.nix
# WezTerm backup command: `wezterm-backup`.

{ lib, pkgs, ... }:

let
  weztermBackup = import ./mk-app-backup.nix {
    inherit lib pkgs;
    appName = "WezTerm";
    appSlug = "wezterm";
    sources = [
      { path = "/Users/ven/Library/Application Support/wezterm"; destination = "app-support/wezterm"; }
      { path = "/Users/ven/.config/wezterm"; destination = "user-config/wezterm"; }
      { path = "/Users/ven/Library/Preferences/com.github.wez.wezterm.plist"; destination = "com.github.wez.wezterm.plist"; }
    ];
  };
in
{
  environment.systemPackages = [ weztermBackup ];
}
