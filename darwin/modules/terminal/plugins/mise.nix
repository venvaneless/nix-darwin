# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/mise.nix
#
# DARWIN: MISE VERSION MANAGER
# ====================================================================
# - Installs mise via Nix
# - Global config lives in ~/ven-dots/zsh/mise/config.toml
# - Nix does NOT manage the config file
# - Changes to mise config take effect immediately (no rebuild)
# - Local project overrides via mise.toml or .tool-versions
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
  # ZSH INTEGRATION
  # ------------------------------------------------------------
  programs.zsh = {
    sessionVariables = {
      # Tell mise where the global config lives
      MISE_CONFIG_FILE = "${config.home.homeDirectory}/ven-dots/zsh/mise/config.toml";

      # Optional: keep mise cache out of $HOME clutter
      MISE_CACHE_DIR  = "${miseDir}/cache";
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
  # Ensure mise-managed tools win over asdf
  # ------------------------------------------------------------
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/share/mise/shims"
  ];
}
