# shared/terminal/wezterm/wez-personal.nix
#
# =====================================================================
# WEZTERM: PERSONAL LUA MODULE KNOBS
#
# Values for the personal runtime modules live here. The matching files
# in options/package-options/wezterm/personal declare their interfaces
# and render these values into Lua.
# =====================================================================

{ ... }:

{
  config.shared.terminal.wezterm.personal = {
    # ------------------------------------------------------------
    # Personal runtime modules
    # ------------------------------------------------------------
    # command_palette.lua is loaded directly by the configured shortcut.
    # The remaining modules apply their settings during WezTerm startup.
    modules = [
      "context_palette"
      "save_scrollback"
      "replace_tab"
      "nvim_chrome"
    ];

    # ------------------------------------------------------------
    # Personal command palette
    # ------------------------------------------------------------
    commandPalette = {
      darwinFlake = ".config/nix/nix-config#macbook";
      fishConfig = ".config/fish/config.fish";

      folders = [
        {
          id = "config";
          label = "Configuration";
          path = ".config";
        }
        {
          id = "nix-config";
          label = "Nix configuration";
          path = ".config/nix/nix-config";
        }
        {
          id = "downloads";
          label = "Downloads";
          path = "Downloads";
        }
      ];
    };

    # ------------------------------------------------------------
    # Context-aware native palette
    # ------------------------------------------------------------
    contextPalette = {
      paletteRows = 24;
      parentSearchDepth = 20;
      darwinHost = "macbook";
      key = "phys:P";
      modifiers = [ "SUPER" "SHIFT" ];

      paths = {
        nixConfig = ".config/nix/nix-config";
        downloads = "Downloads";
        config = ".config";
        hammerspoon = ".config/.hammerspoon";
        projects = [
          "iCloudDocs/Documents/programming"
          "Projects"
          "Documents/programming"
        ];
        fishConfigs = [
          ".config/fish/config.fish"
          ".config/terminal/fish/config-ven.fish"
        ];
        fishFunctions = [
          ".config/fish/functions"
          ".config/terminal/fish/functions"
        ];
      };
    };

    # ------------------------------------------------------------
    # Neovim chrome
    # ------------------------------------------------------------
    nvimChrome.processSuffix = "/nvim$";

    # ------------------------------------------------------------
    # Scrollback export
    # ------------------------------------------------------------
    saveScrollback = {
      outputDirectory = "Downloads";
      fileName = "wezterm-scrollback";
      timestampSeparator = "-";
      timestampFormat = "%Y-%m-%d_%H-%M-%S";
      extension = "txt";
      key = "S";
      modifiers = [ "SUPER" "SHIFT" ];
    };

    # ------------------------------------------------------------
    # Tab replacement
    # ------------------------------------------------------------
    replaceTab = {
      key = "T";
      modifiers = [ "SUPER" "SHIFT" ];
    };
  };
}
