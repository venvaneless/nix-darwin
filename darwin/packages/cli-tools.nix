# darwin/packages/cli-tools.nix
#
# =====================================================================
# PACKAGES: DARWIN CLI TOOLS
#
# Declares macOS-only command-line tools using the same enable and
# platform toggles as every other package-list module.
# =====================================================================

{ inputs, lib, options, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ SHARED PACKAGE HELPERS ------ #
  # ------------------------------------------------------------

  helpers = import ../../options { inherit lib options pkgs; };

  # ------------------------------------------------------------
  # ------ CLI PACKAGE DEFINITIONS ------ #
  # ------------------------------------------------------------

  cliPackages = {
    darwinRebuild = {
      enable = true;
      installOn = { darwin = true; linux = false; };
      package = inputs.darwin.packages.${pkgs.stdenv.hostPlatform.system}.darwin-rebuild;
    };

    bashInteractive = { enable = true; installOn = { darwin = true; linux = false; }; package = pkgs.bashInteractive; };

    # fd is installed cross-platform by shared/terminal/cli-tuis/fd/fd.nix,
    # which also owns its ignore file and colours.

    ffmpegthumbnailer = { enable = true; installOn = { darwin = true; linux = false; }; package = pkgs.ffmpegthumbnailer; };
    fish = { enable = true; installOn = { darwin = true; linux = false; }; package = pkgs.fish; };
    gawk = { enable = true; installOn = { darwin = true; linux = false; }; package = pkgs.gawk; };
    gum = { enable = true; installOn = { darwin = true; linux = false; }; package = pkgs.gum; };
    imagemagick = { enable = true; installOn = { darwin = true; linux = false; }; package = pkgs.imagemagick; };
    p7zip = { enable = true; installOn = { darwin = true; linux = false; }; package = pkgs.p7zip; };
    tree = { enable = true; installOn = { darwin = true; linux = false; }; package = pkgs.tree; };
    unar = { enable = true; installOn = { darwin = true; linux = false; }; package = pkgs.unar; };
    wget = { enable = true; installOn = { darwin = true; linux = false; }; package = pkgs.wget; };
    zstd = { enable = true; installOn = { darwin = true; linux = false; }; package = pkgs.zstd; };
  };
in
helpers.packageOptions.mkPackageModule {
  name = "darwin-cli";
  packages = cliPackages;
}
