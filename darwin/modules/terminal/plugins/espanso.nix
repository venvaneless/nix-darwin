# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/espanso.nix
#
# ZSH / SYSTEM: ESPANSO ENVIRONMENT
# ============================================================
# - Sets ESPANSO_DIR so espanso uses a custom config root
# - Works for all shells, not only zsh
# ============================================================

{ config, pkgs, ... }:

{
  environment.variables = {
    ESPANSO_DIR = "/Users/ven/ven-dots/espanso";
  };
}
