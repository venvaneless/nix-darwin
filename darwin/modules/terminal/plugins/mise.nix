# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/mise.nix
#
# DARWIN: MISE VERSION MANAGER
# ====================================================================
# - Installs mise via Nix
# - Forces ALL mise dirs into ~/ven-dots/zsh/mise
# - Global tools in ~/ven-dots/zsh/mise/config.toml
# - Shims on PATH from ~/ven-dots/zsh/mise/shims
# ====================================================================

{ config, pkgs, ... }:

let
  miseDir = "${config.home.homeDirectory}/.config/zsh/mise/";
in
{
  home.packages = [
    pkgs.mise
  ];

  programs.zsh = {
    # EARLY: make sure these exist before mise activation happens
    envExtra = ''
      export MISE_CONFIG_DIR="${miseDir}"
      export MISE_DATA_DIR="${miseDir}"
      export MISE_CACHE_DIR="${miseDir}/cache"
      export MISE_STATE_DIR="${miseDir}/state"
    '';

    # LATE: activate mise after vars are set
    initContent = ''
      #### MISE INITIALIZATION ####
      if command -v mise >/dev/null 2>&1; then
        eval "$(mise activate zsh)"
      fi
    '';
  };

  # PATH: match what mise reports as its shims dir (now forced to ven-dots)
  home.sessionPath = [
    "${miseDir}/shims"
  ];
}
