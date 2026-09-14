# shared/home/default.nix
#
# =====================================================================
# ESPANSO
#
# Selects Espanso's configuration values for every Home Manager host
# (integrated on Darwin, standalone on Linux).
#
# options/pkgs-configs/espanso owns the option shape, generated files,
# and login startup. Package installation and app linking remain in
# shared/packages.nix.
# =====================================================================
{...}: {
  # ------------------------------------------------------------
  # ------ SHARED ESPANSO FEATURE SELECTION ------ #
  # These values apply to every Home Manager host that imports Espanso.

  ven.espanso = {
    enable = true;
    autostart.enable = true;
    showNotifications = true;

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

        image = {
          enable = false;
          trigger = ":mdimage";
          alt = "Alt text";
          link = "Image URL";
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
