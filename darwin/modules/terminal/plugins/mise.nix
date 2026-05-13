# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/modules/mise.nix
#
# =====================================================================
# MISE VERSION MANAGER
#
# Polyglot runtime manager
# =====================================================================

{ config, pkgs, ... }:

let
  miseDir = "${config.home.homeDirectory}/.config/mise";
in
{
  home.packages = [
    pkgs.mise
  ];

  home.sessionPath = [
    "${miseDir}/shims"
  ];

  programs.fish.shellInit = ''
    # MISE: ENVIRONMENT
    # =========================

    set -gx MISE_CONFIG_DIR "${miseDir}"
    set -gx MISE_DATA_DIR "${miseDir}"
    set -gx MISE_CACHE_DIR "${miseDir}/cache"
    set -gx MISE_STATE_DIR "${miseDir}/state"
  '';

  programs.fish.interactiveShellInit = ''
    # MISE: FISH INTEGRATION
    # =========================

    if type -q mise
      mise activate fish | source
    end
  '';
}