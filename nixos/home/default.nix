# nixos/home/default.nix
#
# =====================================================================
# ZEPHYRUS: STANDALONE HOME MANAGER
#
# The user configuration for the ROG Zephyrus while Home Manager is
# standalone. It is independent from nixosConfigurations.zephyrus:
#
#   home-manager switch --flake .#zephyrus
# =====================================================================
{
  inputs,
  paths,
  ...
}: {
  imports = [
    # ---- SHARED SERVICE OPTIONS ---- #
    # Services remain disabled until this host enables them explicitly.
    inputs.self.homeModules.shared.services

    # ---- SHARED TERMINAL CONFIGURATION ---- #
    inputs.self.homeModules.shared.terminal

    # ---- SHARED ENVIRONMENT CONFIGURATION ---- #
    inputs.self.homeModules.shared.environment
  ];

  # ---- HOME MANAGER IDENTITY ---- #
  home = {
    username = paths.user.name;
    homeDirectory = paths.user.linuxHome;
    stateVersion = "26.05";
  };

  # ---- HOST TERMINAL FEATURES ---- #
  # CLI/TUI defaults come from shared/terminal/cli-tuis/default.nix.
  ven.features.terminal.nvim = {
    enable = true;
    neovide.enable = false;
  };

  # ---- NIX ALIAS HOST ---- #
  ven.features.terminal.fish.nixProfile.flakeHost = "zephyrus";
}
