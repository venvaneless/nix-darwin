# options/pkgs-configs/espanso/markdown.nix
#
# =====================================================================
# ESPANSO: MARKDOWN FEATURE DEFINITIONS
#
# Defines Markdown's toggles, subfeatures, and rendered match content.
# This file never creates user files; Home Manager owns that separately.
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.ven.espanso.markdown;

  # ------------------------------------------------------------
  # ------ MARKDOWN FEATURE RENDERING ------ #
  # The feature translates selected toggles into Espanso YAML content.

  standardMatch = lib.optionalString cfg.links.standard.enable ''
      - trigger: "${cfg.links.standard.trigger}"
        replace: "[{{form1.title}}]({{form1.link}})"
        vars:
          - name: form1
            type: form
            params:
              layout: "Title: [[title]]\\nURL: [[link]]"
              fields:
                title:
                  default: "${cfg.links.standard.title}"
                link:
                  default: "${cfg.links.standard.link}"
  '';

  obsidianMatch = lib.optionalString cfg.links.obsidian.enable ''
      - trigger: "${cfg.links.obsidian.trigger}"
        replace: "[[{{form1.text}}]]"
        vars:
          - name: form1
            type: form
            params:
              layout: "Note: [[text]]"
              fields:
                text:
                  default: "${cfg.links.obsidian.text}"
  '';

  obsidianAliasMatch = lib.optionalString cfg.links.obsidianAlias.enable ''
      - trigger: "${cfg.links.obsidianAlias.trigger}"
        replace: "[[{{form1.link}}|{{form1.title}}]]"
        vars:
          - name: form1
            type: form
            params:
              layout: "Link: [[link]]\\nTitle: [[title]]"
              fields:
                link:
                  default: "${cfg.links.obsidianAlias.link}"
                title:
                  default: "${cfg.links.obsidianAlias.title}"
  '';

  autolinkMatch = lib.optionalString cfg.links.autolink.enable ''
      - trigger: "${cfg.links.autolink.trigger}"
        replace: "<{{form1.link}}>"
        vars:
          - name: form1
            type: form
            params:
              layout: "URL: [[link]]"
              fields:
                link:
                  default: "${cfg.links.autolink.link}"
  '';

  imageMatch = lib.optionalString cfg.links.image.enable ''
      - trigger: "${cfg.links.image.trigger}"
        replace: "![{{form1.alt}}]({{form1.link}})"
        vars:
          - name: form1
            type: form
            params:
              layout: "Alt text: [[alt]]\\nImage URL: [[link]]"
              fields:
                alt:
                  default: "${cfg.links.image.alt}"
                link:
                  default: "${cfg.links.image.link}"
  '';

  boldMatch = lib.optionalString cfg.formatting.bold.enable ''
      - trigger: "${cfg.formatting.bold.trigger}"
        replace: "**{{form1.text}}**"
        vars:
          - name: form1
            type: form
            params:
              layout: "Text: [[text]]"
              fields:
                text:
                  default: "${cfg.formatting.bold.text}"
  '';

  taskMatch = lib.optionalString cfg.formatting.task.enable ''
      - trigger: "${cfg.formatting.task.trigger}"
        replace: "- [ ] "
  '';

  linkMatches = lib.optionalString cfg.links.enable (
    standardMatch
    + obsidianMatch
    + obsidianAliasMatch
    + autolinkMatch
    + imageMatch
  );

  formattingMatches = lib.optionalString cfg.formatting.enable (
    boldMatch
    + taskMatch
  );

  matches = linkMatches + formattingMatches;
in
{
  # ------------------------------------------------------------
  # ------ MARKDOWN FEATURE OPTIONS ------ #
  # Shared Espanso configuration selects these feature values.

  options.ven.espanso.markdown = {
    enable = lib.mkEnableOption "Espanso Markdown matches";

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
          description = "Trigger for an Obsidian wiki link expansion.";
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
          description = "Trigger for an aliased Obsidian wiki link expansion.";
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
          description = "Trigger for the Markdown autolink expansion.";
        };

        link = lib.mkOption {
          type = lib.types.str;
          default = "Link";
          description = "Default link placeholder for a Markdown autolink.";
        };
      };

      image = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Markdown image link expansion.";
        };

        trigger = lib.mkOption {
          type = lib.types.str;
          default = ":mdimage";
          description = "Trigger for the Markdown image link expansion.";
        };

        alt = lib.mkOption {
          type = lib.types.str;
          default = "Alt text";
          description = "Default alt-text placeholder for a Markdown image.";
        };

        link = lib.mkOption {
          type = lib.types.str;
          default = "Image URL";
          description = "Default image URL placeholder for a Markdown image.";
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
          description = "Trigger for the Markdown bold expansion.";
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
          description = "Trigger for the Markdown task expansion.";
        };
      };
    };

    renderedMatchFile = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      internal = true;
      description = "Rendered Espanso YAML selected by the Markdown feature options.";
    };
  };

  config.ven.espanso.markdown.renderedMatchFile =
    if matches == "" then
      "matches: []\n"
    else
      "matches:\n${matches}";
}
