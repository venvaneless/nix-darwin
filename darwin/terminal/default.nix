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

let
  # ---- SHARED PATHS ---- #
  # Reuse the centralized macOS application, Library, and iCloud paths
  # instead of repeating literal /Applications and $HOME locations.
  paths = import ../../options/paths.nix { };
in
{
  # ---- MAN PAGE CACHE ---- #
  # macOS uses its built-in `man`; Home Manager's GNU man package is null.
  # Fish enables cache generation by default, but it cannot run without it.
  programs.man.generateCaches = false;

  programs.fish.interactiveShellInit = ''
    # Common paths
    set -gx ICLOUD_MOBILE "${paths.darwin.library.mobileDocuments}"
  '';

  # ---- COMPLETIONS ---- #
  xdg.configFile."fish/completions/docker.fish".source =
    "${pkgs.docker_29}/share/fish/vendor_completions.d/docker.fish";

  # ---- ENVIRONMENT ---- #
  home = {
    sessionPath = [
      # Docker PATH
      paths.darwin.docker.binDir
    ];

    sessionVariables = {
      ICLOUD = paths.darwin.icloud.docs;
      CHATGPT_APP = paths.darwin.applications.bundles.chatgpt;
    };
  };

  imports = [
    # Darwin-only Fish aliases and abbreviations
    ./fish-aliases.nix

    # macOS commands
    ./commands/macos.nix

    # Managing macOS Trash
    ./commands/trash.nix
  ];
}
