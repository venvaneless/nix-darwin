# shared/terminal/aliases/gc-aliases.nix
#
# =====================================================================
# NIX GARBAGE COLLECTION & GENERATION HELPERS
# =====================================================================

{ config, lib, pkgs, ... }:

let
  # ---- Variables from platforms.nix
  # Platform detection is defined once in options/platforms.nix,
  # so every module tests the current system the same way.
  platforms = import ../../../options/platforms.nix { inherit pkgs; };
  inherit (platforms) isDarwin isLinux;

  # Nix profile and garbage collection helpers.
  installOn = {
    darwin = true;
    linux = true;
  };

  enabledForCurrentSystem =
    (isDarwin && installOn.darwin) || (isLinux && installOn.linux);
in
{
  config = lib.mkIf enabledForCurrentSystem {
    programs.fish.shellAliases = {
      # List all generations of the system profile
      drg = "sudo -H nix-env --list-generations --profile /nix/var/nix/profiles/system";
    };

    programs.fish.functions = {
      # Delete old generations of the system profile
      ddg = ''
        sudo -H nix-env --delete-generations $argv --profile /nix/var/nix/profiles/system
      '';

      # Delete old generations and collect garbage after the requested number of days
      ndg = ''
        sudo nix-collect-garbage --delete-older-than "$argv[1]"d
      '';

      # Delete old generations and collect garbage older than 30 days
      ndgcg30 = ''
        echo "Deleting old generations (+5) and collecting garbage older than 30 days..."
        sudo -H nix-env --delete-generations +5 --profile /nix/var/nix/profiles/system
        sudo nix-collect-garbage --delete-older-than 30d
        echo "Cleanup complete."
      '';
    };
  };
}
