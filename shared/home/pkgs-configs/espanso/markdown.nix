# shared/home/pkgs-configs/espanso/markdown.nix
#
# =====================================================================
# ESPANSO: MARKDOWN MATCH FILE
#
# Creates Espanso's separate Markdown match file:
#
#   ~/.config/espanso/match/markdown.yml
#
# The rendered content is defined by options/pkgs-configs/espanso/markdown.nix.
# =====================================================================

{ paths }:

{ config, lib, ... }:

let
  espanso = config.ven.espanso;
  cfg = espanso.markdown;
in
{
  home.file.${paths.relative.espanso.markdownMatches} = lib.mkIf (
    espanso.enable && cfg.enable
  ) {
    text = cfg.renderedMatchFile;
  };
}
