 # /Users/ven/dotfiles/nix/darwin/modules/system/base.nix
 #
 # CORE CONFIG
  # ============================================================
  # BASE CONFIG
  # Enable flakes, small services, expose additional flags
  # and commands for the "nix-darwin" etc.
  # ============================================================

  { config, pkgs, lib, inputs, ... }:
  
  {
    # --- Core system identity ---
    networking.hostName = "Vens-MacBook-Pro";

    # --- Enable new Nix CLI and flakes ---
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      build-users-group = "nixbld";
    };

    # --- Enable Nix Determine ---
    nix.enable = false;


    # --- System state version (Darwin revision) ---
    system.stateVersion = 6;

    # --- Global system packages ---
    environment.systemPackages = with pkgs; [
    inputs.darwin.packages.${pkgs.system}.darwin-rebuild
    bashInteractive
    git-crypt
    nh
    home-manager
    mkcert
    nssTools
    nginx
    nixd
    nil
    ];
  }
