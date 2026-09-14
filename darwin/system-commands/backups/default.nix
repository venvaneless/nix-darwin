# darwin/system-commands/backups/default.nix
#
# =====================================================================
# APPLICATION AND CONTAINER BACKUPS
#
# Container backups are manual by default. Set an individual `automatic`
# toggle only when that container should receive a scheduled LaunchAgent.
# =====================================================================

{ containerBackupOptions, lib, paths, pkgs, ... }:

let
  # ** App backups are still built by a constructor, so their settings
  # ** module has to be produced before it can be imported. Container
  # ** backups no longer need that: their module arrives as a path
  # ** through specialArgs, the way options/services does.
  appBackupHelper = import ../../../options/backups/app-backup-helper.nix { inherit lib pkgs paths; };
in
{
  imports = [
    appBackupHelper.settingsModule
    containerBackupOptions

    ./archivebox.nix
    ./better-finder-attributes.nix
    ./better-finder-renamer.nix
    ./browsertrix.nix
    ./chrome-canary.nix
    ./dash.nix
    ./espanso.nix
    ./helium.nix
    ./iterm.nix
    ./karakeep.nix
    ./librewolf.nix
    ./mkcert.nix
    ./obsidian.nix
    ./obsidian-library.nix
    ./other-preferences.nix
    ./paste.nix
    ./pearcleaner.nix
    ./raycast.nix
    ./snippetslab.nix
    ./vaultwarden.nix
    ./vesktop.nix
    ./vlc.nix
    ./wallabag.nix
    ./wezterm.nix
    ./yate.nix
    ./zed.nix
  ];
}
