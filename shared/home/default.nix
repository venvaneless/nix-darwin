# shared/home/default.nix
#
# =====================================================================
# SHARED HOME MANAGER
#
# Collects every portable Home Manager module and selects its shared values
# for integrated Darwin, standalone Linux, and NixOS Home Manager hosts.
#
# Darwin-only Home Manager settings remain in darwin/home/default.nix.
# =====================================================================
{ inputs, ... }: {
  imports = [
    # Shared Home Manager module boundaries.
    inputs.self.homeModules."shared.environment"
    inputs.self.homeModules."shared.services"
    inputs.self.homeModules."shared.terminal"
    inputs.self.homeModules."shared.terminal.wezterm"
  ];

  # ------------------------------------------------------------
  # ------ SHARED ESPANSO FEATURE SELECTION ------ #
  # These values apply to every Home Manager host that imports Espanso.

  home.shared.espanso = {
    enable = true;
    installOn = {
      darwin = true;
      linux = true;
    };
    autostart = {
      enable = true;

      # Relaunch Espanso after a crash; a normal quit keeps it closed.
      restartOnCrash = true;
    };

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
