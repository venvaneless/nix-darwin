# /Users/ven/dotfiles/nix/darwin/modules/terminal/shell.nix

{ config, pkgs, lib, ... }:

{
  # ============================================================
  # System-level environment for Nix + Zsh
  # ============================================================

  environment.systemPath = [
    pkgs.nix
  ];
}
