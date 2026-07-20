# /Users/ven/.config/nix/nix-config/darwin/modules/system/homebrew.nix
  #
  # ==========================================================
  # HOMEBREW: UNIFIED PACKAGE MANAGER
  #
  # Bootstraps Homebrew through nix-homebrew and manages declarative
  # brews, casks, taps, and activation cleanup for nix-darwin.
  # ==========================================================
  
  { nix-homebrew, ... }:
  
  {
  # -----------------------------------------------------
    # ------ HOMEBREW: MODULE IMPORTS ----- #
    # Load the nix-homebrew module used by nix-darwin
    # -----------------------------------------------------
  
    imports = [
      nix-homebrew.darwinModules.nix-homebrew
      # ./quarantine-fixes.nix
    ];
  
    # -----------------------------------------------------
  
  
    # -----------------------------------------------------
    # ------ HOMEBREW: BACKEND ----- #
    # Configure the Homebrew installation and migration behavior
    # -----------------------------------------------------
  
    nix-homebrew = {
      enable = true;
      user = "ven";
      enableRosetta = false;
      autoMigrate = true;
    };
  
    # -----------------------------------------------------
  
  
    # -----------------------------------------------------
    # ------ HOMEBREW: PACKAGES ----- #
    # Declaratively manage Homebrew taps, brews, and casks
    # -----------------------------------------------------
  
    homebrew = {
      enable = true;
  
      global.autoUpdate = true;
  
      onActivation = {
        cleanup = "uninstall";
        upgrade = true;
      };
  
  
      # CASK INSTALL LOCATION
      # -----------------------------------------------------
  
      caskArgs = {
        appdir = "/Applications";
      };
  
  
      # HOMEBREW TAPS
      # -----------------------------------------------------
  
      taps = [
        "binary-beam/tap"
        "lutzifer/homebrew-tap"
        # "Ducksss/tap"
      ];
  
  
      # HOMEBREW FORMULAS
      # -----------------------------------------------------
  
      brews = [
        "lutzifer/homebrew-tap/keyboardSwitcher"

        # "Ducksss/tap/codex-profile"
      ];
  
  
      # HOMEBREW CASKS
      # -----------------------------------------------------
  
      casks = [
        # AI
        # "chatgpt"
        # "codex"
        # "claude-code"
  
        # Browsers
        "librewolf"
        "ungoogled-chromium"
  
        # Books and offline libraries
        "calibre"
        "kiwix"
  
        # Communication
        "vesktop"
  
        # Media
        "freetube"
  
        # System utilities
        "swiftdialog"
        "syncthing-app"
        "thaw"
      ];
    };
}