# shared/terminal/cli-tuis/pet.nix
#
# =====================================================================
# PET
#
# Command snippet manager for saving, searching, and running reusable
# shell commands.
#
# Pet stores snippets and optional sync credentials as mutable user data,
# so this module installs only the executable. It has no independent theme
# system: its interactive selector is fzf, which inherits the shared
# Gruvbox fzf palette.
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.pet;

  # ---- PLATFORM TOGGLES ---- #
  # Change these values to set Pet's default per platform. Hosts can
  # still override ven.features.terminal.cliTuis.pet.enable directly.
  pet = {
    enable = true;
    installOn = {
      darwin = true;
      linux = true;
    };
  };

  # ---- Variables from platforms.nix
  # Platform detection is defined once in options/platforms.nix,
  # so every module tests the current system the same way.
  platforms = import ../../../options/platforms.nix { inherit pkgs; };
  inherit (platforms) isDarwin isLinux;
  enabledForCurrentSystem =
    pet.enable && ((isDarwin && pet.installOn.darwin) || (isLinux && pet.installOn.linux));
in
{
  options.ven.features.terminal.cliTuis.pet.enable = lib.mkEnableOption "Pet command snippet manager";

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.pet.enable = lib.mkDefault enabledForCurrentSystem;
    }
    (lib.mkIf cfg.enable {
      home.packages = [
        # Pet keeps its snippets in user-owned mutable storage.
        pkgs.pet
      ];
    })
  ];
}
