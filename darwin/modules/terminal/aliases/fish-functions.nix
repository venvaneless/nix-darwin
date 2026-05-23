# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/aliases/fish-functions.nix
#
# FISH FUNCTIONS
# =============================================================
# Custom reusable Fish shell functions
# =============================================================

{ ... }:

{
  programs.fish.functions = {
    # ---------- General Fish Functions ---------- #

    # ---------------------------------------------------------
    # vfix
    # ---------------------------------------------------------
    # Commit Vaultwarden reload changes
    # Remove old Vaultwarden and Nginx launch daemon plists
    # Run darwin-rebuild switch afterwards
    #
    # Example:
    # vfix
    # ---------------------------------------------------------
    vfix = ''
      gaa "Reloading Vaultwarden"

      # Vaultwarden
      sudo -H launchctl bootout system/com.ven.vaultwarden 2>/dev/null; or true
      sudo -H rm -f /Library/LaunchDaemons/com.ven.vaultwarden.plist

      # Nginx
      sudo -H launchctl bootout system/com.ven.nginx-custom 2>/dev/null; or true
      sudo -H rm -f /Library/LaunchDaemons/com.ven.nginx-custom.plist

      drs
    '';
  };
}