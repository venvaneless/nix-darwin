 # /Users/ven/dotfiles/nix/darwin/modules/system/base.nix
 #
 # CORE CONFIG
  # ============================================================
  # BASE CONFIG
  # Enable flakes, small services, expose additional flags
  # and commands for the "nix-darwin" etc.
  # ============================================================

  { config, pkgs, ... }:

  {
    # --- Core system identity ---
    networking.hostName = "Vens-MacBook-Pro";

    # --- Enable new Nix CLI and flakes ---
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      build-users-group = "nixbld";
    };

    # --- Default shell ---
    programs.zsh.enable = true;

    # --- System state version (Darwin revision) ---
    system.stateVersion = 5;

    # --- Global system packages ---
    environment.systemPackages = with pkgs; [
      nh
      home-manager
      nixd
    ];
  }
