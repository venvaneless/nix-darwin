# options/pkgs-configs/espanso-options.nix
#
# =====================================================================
# ESPANSO: FEATURE OPTIONS
#
# Defines the optional Espanso features and their sub-options.
#
# Generic package behavior such as enable, installOn, platform
# detection, and Darwin application links stays in the shared package
# helper infrastructure.
# =====================================================================

{ lib, ... }:

{
  options.ven.espanso = {
    base = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Espanso base matches.";
      };
    };

    markdown = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Espanso Markdown matches.";
      };

      links = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Markdown link expansions.";
        };

        standard = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable standard Markdown link expansion.";
          };

          trigger = lib.mkOption {
            type = lib.types.str;
            default = ":mdlink";
            description = "Trigger for the standard Markdown link expansion.";
          };

          title = lib.mkOption {
            type = lib.types.str;
            default = "Title";
            description = "Default title placeholder for standard Markdown links.";
          };

          link = lib.mkOption {
            type = lib.types.str;
            default = "Link";
            description = "Default link placeholder for standard Markdown links.";
          };
        };

        obsidian = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable Obsidian-style wiki link expansion.";
          };

          trigger = lib.mkOption {
            type = lib.types.str;
            default = ":wikilink";
            description = "Trigger for the Obsidian-style wiki link expansion.";
          };

          text = lib.mkOption {
            type = lib.types.str;
            default = "Text";
            description = "Default text inserted inside an Obsidian wiki link.";
          };
        };

        obsidianAlias = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable Obsidian-style aliased wiki link expansion.";
          };

          trigger = lib.mkOption {
            type = lib.types.str;
            default = ":wikialias";
            description = "Trigger for an Obsidian aliased wiki link.";
          };

          link = lib.mkOption {
            type = lib.types.str;
            default = "Link";
            description = "Default target for an Obsidian aliased wiki link.";
          };

          title = lib.mkOption {
            type = lib.types.str;
            default = "Title";
            description = "Default visible title for an Obsidian aliased wiki link.";
          };
        };

        autolink = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable Markdown autolink expansion.";
          };

          trigger = lib.mkOption {
            type = lib.types.str;
            default = ":mdurl";
            description = "Trigger for a Markdown autolink.";
          };

          link = lib.mkOption {
            type = lib.types.str;
            default = "Link";
            description = "Default link placeholder for Markdown autolinks.";
          };
        };
      };

      formatting = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Markdown formatting expansions.";
        };

        bold = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable Markdown bold expansion.";
          };

          trigger = lib.mkOption {
            type = lib.types.str;
            default = ":mdbold";
            description = "Trigger for Markdown bold text.";
          };

          text = lib.mkOption {
            type = lib.types.str;
            default = "Text";
            description = "Default text wrapped in Markdown bold markers.";
          };
        };

        task = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable Markdown task expansion.";
          };

          trigger = lib.mkOption {
            type = lib.types.str;
            default = ":mdtask";
            description = "Trigger for a Markdown task.";
          };
        };
      };
    };
  };
}