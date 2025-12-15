# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/mas.nix

# MAC APP STORE: INSTALL APPS
# ============================================================
# Installs Mac App Store applications declaratively using mas.
# Requires the user to be signed into the App Store once.
# ============================================================
#
# nix-darwin system module.

{ pkgs, ... }:

{
  # ------------------------------------------------------------
  # MAS CLI
  # ------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    mas
  ];

  # ------------------------------------------------------------
  # MAC APP STORE APPS
  # ------------------------------------------------------------
  services.mas = {
    enable = true;

    apps = {
      SnippetsLab = 1006087419;
      # or, if you want the exact store name:
      # "Snippets Lab" = 1006087419;
    };
  };
}
