# darwin/home/default.nix
#
# =====================================================================
# DARWIN: HOME MANAGER (INTEGRATED)
# =====================================================================

{ inputs, paths, pkgs, serviceOptions, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs paths serviceOptions;
    };

    # Provides the Home Manager sops.* options used by shared/secrets.nix.
    sharedModules = [
      inputs.sops-nix.homeManagerModules.sops
    ];


    # ------------------------------------------------------------
    # User
    # ------------------------------------------------------------
    users.ven = {
      home.username = "ven";
      home.homeDirectory = "/Users/ven";
      home.stateVersion = "26.05";


      # ------------------------------------------------------------
      # Home Manager packages
      # ------------------------------------------------------------
      home.packages = [
        # bat is installed by shared/terminal/cli-tuis/bat/bat.nix
        pkgs.python312Packages.internetarchive
      ];

      # ------------------------------------------------------------
      # Darwin Home Manager defaults
      # ------------------------------------------------------------

      targets.darwin.defaults = {
        NSGlobalDomain = {
          # Preferred UI languages, in priority order
          AppleLanguages = [
            "en"
            "de"
            "pl"
          ];

          # Locale used for dates, numbers, etc.
          AppleLocale = "en_DE";

          # Measurement units
          AppleMeasurementUnits = "Centimeters";
        };
      };

      # ------------------------------------------------------------
      # Session environment
      # ------------------------------------------------------------

      home.sessionVariables = {
      };

      # ------------------------------------------------------------
      # Shared terminal features
      # ------------------------------------------------------------

      ven.features.terminal.nvim = {
        enable = true;
        neovide.enable = true;
      };

      ven.features.terminal.wezterm = {
        enable = true;
        appearance.theme = "gruvbox";
      };

      # ------------------------------------------------------------
      # Nix alias host
      # ------------------------------------------------------------

      # The flake host name differs from macOS's networking host name.
      ven.features.terminal.fish.nixProfile.flakeHost = "macbook";

      # ------------------------------------------------------------
      # Imports
      # ------------------------------------------------------------

      imports = [
        # Darwin-only Home Manager
        ../terminal
        ./clock.nix

        # Shared Home Manager
        ../../shared/home

        # Shared terminal modules
        ../../shared/terminal
        ../../shared/terminal/nvim
        ../../shared/terminal/cli-tuis
        ../../shared/terminal/wezterm

        # Shared secrets
        ../../shared/home/secrets.nix
        ../../shared/home/sops.nix

        # Shared service options and per-machine settings
        serviceOptions
        ./services.nix
      ];
    };
  };
}
