# shared/home/pkgs-configs/espanso/modules.nix
#
# =====================================================================
# ESPANSO: FEATURE TOGGLES
#
# Chooses which optional Espanso features and sub-features are enabled.
#
# Option definitions live in:
#
#   options/pkgs-configs/espanso-options.nix
#
# Actual feature implementations live beside this file.
# =====================================================================

{ paths }:

{ ... }:

{
  imports = [
    (import ./markdown.nix {
      inherit paths;
    })
  ];

  ven.espanso = {
    base.enable = true;

    markdown = {
      enable = true;

      links = {
        enable = true;

        standard = {
          enable = true;
          trigger = ":mdlink";
          title = "Title";
          link = "Link";
        };

        obsidian = {
          enable = true;
          trigger = ":wikilink";
          text = "Text";
        };

        obsidianAlias = {
          enable = false;
          trigger = ":wikialias";
          link = "Link";
          title = "Title";
        };

        autolink = {
          enable = false;
          trigger = ":mdurl";
          link = "Link";
        };
      };

      formatting = {
        enable = true;

        bold = {
          enable = true;
          trigger = ":mdbold";
          text = "Text";
        };

        task = {
          enable = true;
          trigger = ":mdtask";
        };
      };
    };
  };
}