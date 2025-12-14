# DARWIN: MISE VERSION MANAGER
# ====================================================================
# - Installs mise via Nix
# - ALL mise state lives in ~/ven-dots/zsh/mise
# - Global tools defined in config.toml
# - No symlinks, no files in $HOME
# ====================================================================

{ config, pkgs, ... }:

let
  miseDir = "${config.home.homeDirectory}/ven-dots/zsh/mise";
in
{
  home.packages = [
    pkgs.mise
  ];

  programs.zsh = {
    sessionVariables = {
      # ---- MISE ROOT LOCATIONS ----
      MISE_CONFIG_DIR = miseDir;
      MISE_DATA_DIR   = "${miseDir}/data";
      MISE_CACHE_DIR  = "${miseDir}/cache";
    };

    initContent = ''
      #### MISE INITIALIZATION ####
      if command -v mise >/dev/null 2>&1; then
        eval "$(mise activate zsh)"
      fi
    '';
  };

  # Ensure mise shims win
  home.sessionPath = [
    "${miseDir}/shims"
  ];
}
