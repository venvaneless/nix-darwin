# /Users/ven/dotfiles/nix/darwin/modules/services/nix-homebrew.nix
#
# NIX-HOMEBREW SERVICE
# ============================================================
# Enables the nix-homebrew service for the user "ven"
# on nix-darwin
# ============================================================

{ config, pkgs, lib, inputs ? {}, nix-homebrew ? {}, ... }:

let
  nh = if nix-homebrew != {} then nix-homebrew else (inputs.nix-homebrew or {});
in
{
  imports = [ nh.darwinModules.nix-homebrew ];

  nix-homebrew = {
    enable = true;
    user = "ven";
    enableRosetta = false;
    autoMigrate = true;
  };
}
