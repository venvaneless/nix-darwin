# darwin/system-commands/backups/default.nix
#
# =====================================================================
# APPLICATION AND CONTAINER BACKUPS
#
# Container backups are manual by default. Set an individual `automatic`
# toggle only when that container should receive a scheduled LaunchAgent.
# =====================================================================
{...}: {
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
