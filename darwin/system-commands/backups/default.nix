# darwin/system-commands/backups/default.nix
#
# =====================================================================
# APPLICATION AND CONTAINER BACKUPS
#
# Container backups are independently enabled. Set runOnRebuild to
# true to run every enabled backup during darwin-rebuild switch. Each
# individual backup can still opt out with its runOnRebuild option.
# =====================================================================

{ lib, ... }:

{
  options.services.containerBackups.runOnRebuild = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Run enabled container backups during darwin-rebuild activation.";
  };

  config.services.containerBackups = {
    archivebox.enable = true;
    browsertrix.enable = true;
    karakeep.enable = true;
    vaultwarden.enable = true;
    wallabag.enable = true;
  };

  imports = [
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
