# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/cli-tools.nix
#
# =====================================================================
# PACKAGES: CLI TOOLS
#
# Installs everyday terminal utilities:
# - Shells and terminal helpers
# - File navigation and search tools
# - Archive tools
# - Core command-line workflow tools
# =====================================================================

{ pkgs, inputs, ... }:

{
  # ------------------------------------------------------------
  # ------ CLI TOOLS ------ #
  #
  # Core terminal programs used for navigation, search, shell work,
  # archives, system inspection, and everyday command-line tasks.
  # ------------------------------------------------------------

  # ---- CLI packages
  # Installs general-purpose command-line tools available system-wide.
  environment.systemPackages = with pkgs; [
    inputs.darwin.packages.${pkgs.stdenv.hostPlatform.system}.darwin-rebuild

    atuin
    bat
    bashInteractive
    bottom
    eza
    fastfetch
    fd
    ffmpegthumbnailer
    fish
    gawk
    gum
    imagemagick
    micro
    p7zip
    ripgrep
    tmux
    tree
    unar
    wget
    yazi
    zoxide
    zstd
  ];
}