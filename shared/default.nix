# shared/default.nix
#
# =====================================================================
# SHARED: HOST AND NIXPKGS SETTINGS
# =====================================================================
#
# The shared knobs for every machine live here. This file deliberately
# contains values only: options/nix-config.nix owns their option types,
# platform selection, validation, and translation into Nix settings.
# =====================================================================

{ nixOptions, ... }: {
  # ------------------------------------------------------------
  # Nix option semantics
  # ------------------------------------------------------------
  # Shared values below use the option shape and translation owned by options/.
  imports = [
    nixOptions
  ];

  ven.nix = {
    # ------------------------------------------------------------
    # Nix daemon and command settings
    # ------------------------------------------------------------
    # These settings apply to every system host. Machine-specific Nix
    # settings remain in that machine's own default.nix.
    settings = {
      # Enables the command and flake interfaces used by this repository.
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Uses the official Nix binary cache on every host.
      substituters = [
        "https://cache.nixos.org"
      ];

      # Trusts the official Nix binary cache signing key.
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];

      # Keeps routine configuration edits from producing dirty-tree warnings.
      warn-dirty = false;
    };

    # ------------------------------------------------------------
    # Nixpkgs package sets
    # ------------------------------------------------------------
    nixpkgs = {
      # Applies this policy to the stable package set and, when enabled,
      # to the unstable package set as well.
      config = {
        allowUnfree = true;

        permittedInsecurePackages = [
        ];
      };

      unstable = {
        # Makes the unstable package set available to enabled consumers.
        enable = true;

        # Enabled on both platforms: VS Code is tracked from unstable
        # everywhere, and unstablePkgs is a throw on a disabled platform.
        installOn = {
          darwin = true;
          linux = true;
        };
      };
    };
  };
}
