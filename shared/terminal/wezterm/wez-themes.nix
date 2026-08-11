# shared/terminal/wezterm/wez-themes.nix
#
# =====================================================================
# WEZTERM: THEME TEMPLATES
#
# Alternative colour schemes kept next to the active Gruvbox
# configuration. They are always deployed, but only loaded when their
# toggle is enabled, so switching themes is a one line change instead
# of a file move.
#
# Each theme replaces the colours set in wez-appearance.nix, so only
# one of them can be active at a time. The assertion below rejects a
# configuration that enables more than one, rather than letting load
# order decide silently.
#
# All toggles default to false, because the active theme is Gruvbox.
# =====================================================================

{
  config,
  lib,
  ...
}:

let
  cfg = config.ven.features.terminal.wezterm;

  # ------------------------------------------------------------
  # ------ MUTUALLY EXCLUSIVE APPEARANCE THEMES ------ #
  #
  # Every entry here fully replaces the colour scheme.
  # ------------------------------------------------------------

  appearanceThemes = {
    "nord" = cfg.themes.nord.enable;
    "nord-otto" = cfg.themes.nordOtto.enable;
    "otto" = cfg.themes.otto.enable;
  };

  enabledThemeNames =
    lib.attrNames
      (lib.filterAttrs (_: enabled: enabled) appearanceThemes);
in

{
  imports = [
    ./themes/wez-nord.nix
    ./themes/wez-nord-otto.nix
    ./themes/wez-otto.nix
  ];

  options.ven.features.terminal.wezterm.themes = {
    # ---- Nord
    # Cool blue palette based on the Nord colour scheme.
    nord.enable =
      lib.mkEnableOption "Nord appearance for WezTerm";

    # ---- Nord Otto
    # Nord palette with the Otto adjustments applied.
    nordOtto.enable =
      lib.mkEnableOption "Nord Otto appearance for WezTerm";

    # ---- Otto
    # Standalone Otto palette.
    otto.enable =
      lib.mkEnableOption "Otto appearance for WezTerm";
  };

  config = lib.mkIf cfg.enable {
    # ------------------------------------------------------------
    # ------ EXCLUSIVITY CHECK ------ #
    #
    # Enabling two themes would apply both, with the one loaded last
    # winning and no warning. Fail the build instead.
    # ------------------------------------------------------------

    assertions = [
      {
        assertion = lib.length enabledThemeNames <= 1;

        message = ''
          Only one WezTerm appearance theme can be enabled at a time.

          Currently enabled: ${lib.concatStringsSep ", " enabledThemeNames}

          Disable all but one of:
            ven.features.terminal.wezterm.themes.nord.enable
            ven.features.terminal.wezterm.themes.nordOtto.enable
            ven.features.terminal.wezterm.themes.otto.enable

          Leaving every toggle off keeps the Gruvbox colours defined
          in wez-appearance.nix.
        '';
      }
    ];
  };
}
