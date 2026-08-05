# darwin/system-commands/backups/default.nix
#
# =====================================================================
# APPLICATION AND CONTAINER BACKUPS
#
# Container backups are manual by default. Set an individual `automatic`
# toggle only when that container should receive a scheduled LaunchAgent.
# =====================================================================

{ lib, ... }:

{
  options.services.containerBackups.runOnRebuild = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Run enabled container backups during darwin-rebuild activation.";
  };

  config.services.containerBackups = {
    # ---- ENABLED MANUAL COMMANDS
    archivebox.enable = true;
    browsertrix.enable = true;
    karakeep.enable = true;
    vaultwarden.enable = true;
    wallabag.enable = true;

    # ---- OPTIONAL AUTOMATIC SCHEDULE
    # Keep these commented defaults manual. To schedule one container, change
    # its automatic value and tune its attempt, minimum-success, and CPU caps.
    # vaultwarden = {
    #   automatic = true;
    #   automaticIntervalSeconds = 86400;
    #   minimumIntervalSeconds = 28800;
    #   cpuLimitPercent = 35;
    # };
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
