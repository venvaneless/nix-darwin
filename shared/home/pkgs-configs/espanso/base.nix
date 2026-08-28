# shared/home/pkgs-configs/espanso/base.nix
#
# =====================================================================
# ESPANSO: BASE MATCHES
#
# Owns Espanso's default text-expansion match file:
#
#   ~/.config/espanso/match/base.yml
#
# Nix owns the contents of the file. Home Manager creates the normal
# Espanso path as a symlink to the immutable Nix-store file generated
# from the text declared below.
# =====================================================================

{
  enabledForCurrentPlatform,
  paths,
}:

{ lib, ... }:

{
  home.file.${paths.relative.espanso.baseMatches} = lib.mkIf enabledForCurrentPlatform {
    text = ''
      matches: []
    '';
  };
}