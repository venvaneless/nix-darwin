# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/aliases/fish-functions.nix
#
# FISH FUNCTIONS
# =============================================================
# Custom reusable Fish shell functions
# 
# =============================================================
#
# ---- Git Helpers
# -- gm
# Stage everything, create commit, run darwin-rebuild switch
# =============================================================

{ ... }:

{
  programs.fish.functions = {

    # ---------------------------------------------------------
    # gm
    # ---------------------------------------------------------
    # Stages all changes
    # Creates a git commit using the provided message
    # Runs darwin-rebuild switch afterwards
    #
    # Example:
    # gm "Fixing fastfetch"
    # ---------------------------------------------------------
    gm = ''
      git add -A
      and git commit -m "$argv"
      and drs
    '';
    gaa = ''
      git add -A
      and git commit -m "$argv"
    '';

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