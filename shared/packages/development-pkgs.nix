# shared/packages/development-pkgs.nix
#
# =====================================================================
# PACKAGES: SHARED DEVELOPMENT TOOLS
#
# Installs Nix development and package search tools shared between
# Darwin and Linux.
# =====================================================================

{ lib, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ PLATFORM DETECTION ------ #
  #
  # Determines which operating system is currently evaluating
  # this shared package module.
  # ------------------------------------------------------------

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  # ------------------------------------------------------------
  # ------ SHARED NIX DEVELOPMENT PACKAGES ------ #
  # ------------------------------------------------------------

  nixDevelopmentPackages = with pkgs; [
    # ------------------------------------------------
    ## nix tools

    # Nixpkgs Rust linter
    alejandra

    # Nix Home Manager
    home-manager

    # Check unused Nix code
    deadnix

    # Better rebuild output
    nh

    # Nix language server
    nil

    # Reproductible installation of packages from Github
    npins

    # Nix shell environment manager
    nix-direnv

    # Nix language server
    nixd

    # Format
    nixfmt

    # Check Nix style problems
    statix

    # Nix output monitor
    nix-output-monitor

    # Nix dependency tree viewer
    nix-tree
  ];

  # ------------------------------------------------------------
  # ------ SHARED NIX SEARCH TOOL DEFINITIONS ------ #
  #
  # enable:
  #   Controls whether the tool exists at all.
  #
  # installOn.darwin:
  #   Controls whether the tool is installed on macOS.
  #
  # installOn.linux:
  #   Controls whether the tool is installed on Linux.
  # ------------------------------------------------------------

  nixSearchTools = {
    # ---- nix-search
    # Searches Nix packages by name and metadata.
    nixSearch = {
      enable = true;

      installOn = {
        darwin = true;
        linux = true;
      };

      package = pkgs.nix-search;
    };

    # ---- nix-index and nix-locate
    # nix-index provides nix-locate for searching files inside Nix packages.
    nixIndex = {
      enable = true;

      installOn = {
        darwin = true;
        linux = true;
      };

      package = pkgs.nix-index;
    };

    # ---- comma
    # Runs a command from Nixpkgs without first installing its package.
    comma = {
      enable = true;

      installOn = {
        darwin = true;
        linux = true;
      };

      package = pkgs.comma;
    };
  };

  # ------------------------------------------------------------
  # ------ PACKAGE FILTERING ------ #
  #
  # Selects only tools that are enabled for the system currently
  # evaluating this module.
  # ------------------------------------------------------------

  enabledForCurrentSystem =
    nixSearchTool:
      nixSearchTool.enable
      && (
        (isDarwin && nixSearchTool.installOn.darwin)
        || (isLinux && nixSearchTool.installOn.linux)
      );

  enabledNixSearchTools =
    map
      (nixSearchTool: nixSearchTool.package)
      (
        lib.filter
          enabledForCurrentSystem
          (lib.attrValues nixSearchTools)
      );
in
{
  # ------------------------------------------------------------
  # ------ SHARED DEVELOPMENT PACKAGES ------ #
  # ------------------------------------------------------------

  environment.systemPackages = nixDevelopmentPackages ++ enabledNixSearchTools;
}
