# shared/home/pkgs-configs/espanso/default.nix
#
# =====================================================================
# ESPANSO
#
# Enables Espanso, chooses the platforms where it is installed, and
# selects the individual Espanso match modules and features.
#
# Runtime configuration is implemented in modules.nix and the match
# modules imported from this directory.
# =====================================================================

{ ... }:

{
  imports = [
    ./modules.nix
    ./base.nix
    ./markdown.nix
  ];

  ven.espanso = {
    enable = true;

    installOn = {
      darwin = true;
      linux = true;
    };

    matches = {
      base.enable = true;

      markdown = {
        enable = true;

        links = {
          standard.enable = true;
          image.enable = false;
          autolink.enable = false;
          wikilink.enable = false;
        };

        formatting = {
          bold.enable = true;
          task.enable = true;
        };
      };
    };
  };
}