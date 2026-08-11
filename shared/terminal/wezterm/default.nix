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
# - Runtime Lua that relies on closures, callbacks or the WezTerm
#   event API is embedded in Nix modules through `extraConfig`.
#   Home Manager writes the combined result into wezterm.lua.
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
  # Modules that add options or embedded runtime configuration.
  # ------------------------------------------------------------

  imports = [
    ./wez-plugins.nix
    ./wez-themes.nix

    # ---- Embedded Lua modules
    ./plugins/wez-plugins.nix
    ./overlays/wez-overlays.nix
    ./personal/wez-platform.nix
    ./personal/wez-context_palette.nix
    ./personal/wez-replace_tab.nix
    ./personal/wez-save_scrollback.nix
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
        -- Dynamic WezTerm configuration is embedded by the imported
        -- Nix modules through programs.wezterm.extraConfig.
      '';
    };
  };
}
