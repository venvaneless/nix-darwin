# darwin/terminal/default.nix
#
# =====================================================================
# FISH: DARWIN-ONLY EXTRAS
#
# - Shared Fish configuration lives in shared/terminal
# - This module keeps Apple paths, Docker Desktop integration, and macOS
#   maintenance helpers out of the shared Fish module
# =====================================================================

{ config, pkgs, ... }:

{
  # ---- MAN PAGE CACHE ---- #
  # macOS uses its built-in `man`; Home Manager's GNU man package is null.
  # Fish enables cache generation by default, but it cannot run without it.
  programs.man.generateCaches = false;

  programs.fish.interactiveShellInit = ''
    # Common paths
    set -gx ICLOUD_MOBILE "$HOME/Library/Mobile Documents"
  '';

  # ---- COMPLETIONS ---- #
  xdg.configFile."fish/completions/docker.fish".source =
    "${pkgs.docker_29}/share/fish/vendor_completions.d/docker.fish";

  # ---- ENVIRONMENT ---- #
  home = {
    sessionPath = [
      # Docker PATH
      "/Applications/Programming/Docker.app/Contents/Resources/bin"
    ];

    sessionVariables = {
      MICRO_TRUECOLOR = "1";
      ICLOUD = "$HOME/iCloudDocs";
      CHATGPT_APP = "/Applications/ChatGPT.app";
    };
  };

  imports = [
    # Darwin-only Fish aliases and abbreviations
    ./fish-aliases.nix

    # iCloud folder navigation and ditto-backed copying
    ./commands/files-darwin.nix

    # macOS commands
    ./commands/macos.nix

    # Managing macOS Trash
    ./commands/trash.nix
  ];
}
