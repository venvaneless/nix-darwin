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
    # ---- SHARED HOME MANAGER VALUES ---- #
    # Same shared environment, service, and terminal configuration as
    # integrated Darwin.
    inputs.self.homeModules."shared.home"
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
