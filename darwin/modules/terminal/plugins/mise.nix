# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/mise.nix
#
# DARWIN: MISE VERSION MANAGER
# ====================================================================
# - Installs mise via Nix
# - Global config lives in ~/ven-dots/zsh/mise/config.toml
# - Local project overrides via mise.toml (or .tool-versions if needed)
# - No symlinks required
# - Designed to coexist with asdf
# ====================================================================

{ config, pkgs, ... }:

let
  miseDir = "${config.home.homeDirectory}/ven-dots/zsh/mise";
in
{
  # ------------------------------------------------------------
  # MISE PACKAGE
  # ------------------------------------------------------------
  home.packages = [
    pkgs.mise
  ];

  # ------------------------------------------------------------
  # GLOBAL MISE CONFIG (DECLARATIVE)
  # This is your global default tool set, tracked in Git
  # ------------------------------------------------------------
  home.file."${miseDir}/config.toml".text = ''
    [tools]
    node = "25.0.0"
    python = "3.13.9"
  '';

  # ------------------------------------------------------------
  # ZSH INTEGRATION
  # ------------------------------------------------------------
  programs.zsh = {
    sessionVariables = {
      # Tell mise where its global config lives
      MISE_CONFIG_FILE = "${miseDir}/config.toml";

      # Optional: keep mise cache out of $HOME clutter
      MISE_CACHE_DIR = "${miseDir}/cache";
    };

    initContent = ''
      #### MISE INITIALIZATION ####

      # Activate mise for interactive shells
      if command -v mise >/dev/null 2>&1; then
        eval "$(mise activate zsh)"
      fi
    '';
  };

  # ------------------------------------------------------------
  # PATH PRIORITY
  # Ensure mise shims take precedence over asdf
  # ------------------------------------------------------------
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/share/mise/shims"
  ];
}
