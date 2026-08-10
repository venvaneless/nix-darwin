# shared/terminal/wezterm/default.nix
#
# =====================================================================
# WEZTERM: SHARED TERMINAL EMULATOR CONFIGURATION
#
# Nix equivalent of wezterm.lua. Installs and configures WezTerm
# through Home Manager on Darwin and Linux.
#
# The configuration is split in two halves:
#
# - Static configuration (appearance, keys, mouse, ssh) is expressed
#   as Nix attribute sets and rendered into wezterm.lua by Home
#   Manager through `settings`.
#
# - Runtime Lua modules that rely on closures, callbacks or the
#   WezTerm event API stay as plain .lua files. They are deployed
#   unchanged by wez-lua.nix and loaded from `extraConfig`.
# =====================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.ven.features.terminal.wezterm;

  # ------------------------------------------------------------
  # ------ STATIC CONFIGURATION MODULES ------ #
  #
  # Each module returns a plain attribute set that is merged into
  # `programs.wezterm.settings`. The merge is shallow, so the modules
  # must not define overlapping top-level keys.
  # ------------------------------------------------------------

  appearance = import ./wez-appearance.nix {
    inherit lib;
  };

  keybindings = import ./wez-keybindings.nix {
    inherit lib pkgs;
  };

  mouse = import ./wez-mouse.nix {
    inherit lib;
  };

  ssh = import ./wez-ssh.nix {
    inherit lib;
  };
in
{
  # ------------------------------------------------------------
  # ------ SUBMODULES ------ #
  #
  # Modules that deploy files or add options rather than contribute
  # settings.
  # ------------------------------------------------------------

  imports = [
    ./wez-lua.nix
    ./wez-plugins.nix
    ./wez-catppuccin.nix
    ./wez-themes.nix
  ];

  # ------------------------------------------------------------
  # ------ FEATURE TOGGLE ------ #
  # ------------------------------------------------------------

  options.ven.features.terminal.wezterm.enable =
    lib.mkEnableOption "WezTerm terminal emulator";

  config = lib.mkIf cfg.enable {
    programs.wezterm = {
      enable = true;

      # Use the package supplied by the selected nixpkgs package set
      package = pkgs.wezterm;

      # ------------------------------------------------------------
      # ------ WEZTERM SETTINGS ------ #
      #
      # Home Manager renders these Nix values into wezterm.lua with
      # lib.generators.toLua. Values wrapped in mkLuaInline are
      # emitted as raw Lua expressions.
      # ------------------------------------------------------------

      settings =
        appearance
        // keybindings
        // mouse
        // ssh
        // {
          # Scrollback
          scrollback_lines = 100000;

          # Debug
          debug_key_events = true;

          # Notifications
          notification_handling = "AlwaysShow";
        };

      # ------------------------------------------------------------
      # ------ WEZTERM EXTRA CONFIG ------ #
      #
      # Home Manager wraps this block in an immediately invoked Lua
      # function with the generated `config` table in scope, so the
      # runtime modules can mutate `config` directly.
      #
      # Nothing is returned from this block, so the settings above are
      # never replaced wholesale.
      # ------------------------------------------------------------

      extraConfig = ''
        -- Runtime Lua modules
        -- Deployed by wez-lua.nix.

        -- Appearance themes
        -- At most one of these is ever enabled; wez-themes.nix fails
        -- the build if more than one toggle is on. With all of them
        -- off the Gruvbox colours from wez-appearance.nix stand.

        ${lib.optionalString cfg.catppuccin.appearance.enable ''
          -- Catppuccin appearance
          local catppuccin_appearance = dofile(
              wezterm.config_dir .. "/catppuccin-config/appearance.lua"
          )

          catppuccin_appearance.apply(config)
        ''}

        ${lib.optionalString cfg.themes.nord.enable ''
          -- Nord appearance
          local nord = dofile(
              wezterm.config_dir .. "/themes/nord.lua"
          )

          nord.apply(config)
        ''}

        ${lib.optionalString cfg.themes.nordOtto.enable ''
          -- Nord Otto appearance
          local nord_otto = dofile(
              wezterm.config_dir .. "/themes/nord-otto.lua"
          )

          nord_otto.apply(config)
        ''}

        ${lib.optionalString cfg.themes.otto.enable ''
          -- Otto appearance
          local otto = dofile(
              wezterm.config_dir .. "/themes/otto.lua"
          )

          otto.apply(config)
        ''}

        -- Plugins
        -- Loads the wrappers in plugins/, which in turn require the
        -- upstream plugins pinned by wez-plugins.nix.
        local plugins = dofile(
            wezterm.config_dir .. "/plugins/plugins.lua"
        )

        plugins.apply(config)

        ${lib.optionalString cfg.catppuccin.tabline.enable ''
          -- Catppuccin tabline
          -- Runs after plugins.apply so that it replaces the Gruvbox
          -- tabline styling from plugins/tabline.lua.
          local catppuccin_tabline = dofile(
              wezterm.config_dir .. "/catppuccin-config/tabline.lua"
          )

          catppuccin_tabline.apply(config)
        ''}

        -- Overlays
        -- Registers the quick commands entry in the command palette.
        -- This module only installs an event handler, so it takes no
        -- config argument.
        dofile(wezterm.config_dir .. "/overlays/overlays.lua")

        -- Personal modules
        -- Each one appends its own key bindings to the list that was
        -- generated from wez-keybindings.nix.
        local save_scrollback = dofile(
            wezterm.config_dir .. "/personal/save_scrollback.lua"
        )

        save_scrollback.apply(config)

        local replace_tab = dofile(
            wezterm.config_dir .. "/personal/replace_tab.lua"
        )

        replace_tab.apply(config)

        -- Context palette
        -- Binds Command/Super + Shift + P to the built in command
        -- palette and sets its row count.
        local context_palette = dofile(
            wezterm.config_dir .. "/personal/context_palette.lua"
        )

        context_palette.apply(config)

        -- Deliberately dropped:
        --
        --   personal/command_palette.lua
      '';
    };
  };
}
