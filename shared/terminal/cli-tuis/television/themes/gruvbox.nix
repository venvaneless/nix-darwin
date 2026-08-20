# shared/terminal/cli-tuis/television/themes/gruvbox.nix
#
# =====================================================================
# TELEVISION: GRUVBOX THEME
#
# - Installs the `ven-gruvbox` Television theme file
# - Selected directly in television/default.nix with selectedTheme = "gruvbox"
# - Uses the same Gruvbox Dark colours as the local WezTerm palette
# =====================================================================

{ config, lib, ... }:

let
  televisionCfg = config.ven.features.terminal.cliTuis.television;
  cfg = televisionCfg.gruvbox;

  # ---- Variables from paths.nix ---- #
  # Keep the generated theme under the shared XDG configuration root.
  paths = import ../../../../../options/paths.nix { };
  themeFile = "${paths.relative.config}/television/themes/ven-gruvbox.toml";
in
{
  options.ven.features.terminal.cliTuis.television.gruvbox.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Internal switch for the Gruvbox theme selected in television/default.nix.";
  };

  config = lib.mkIf (televisionCfg.enable && cfg.enable) {
    home.file."${themeFile}".text = ''
      # Matches the Gruvbox Dark colours configured for WezTerm.

      # General
      background = "#282828"
      border_fg = "#665c54"
      text_fg = "#ebdbb2"
      dimmed_text_fg = "#a89984"

      # Input
      input_text_fg = "#fb4934"
      result_count_fg = "#cc241d"

      # Results
      result_name_fg = "#83a598"
      result_line_number_fg = "#fabd2f"
      result_value_fg = "#ebdbb2"
      selection_fg = "#282828"
      selection_bg = "#d79921"
      match_fg = "#fb4934"

      # Preview
      preview_title_fg = "#b8bb26"

      # Modes
      channel_mode_fg = "#282828"
      channel_mode_bg = "#b16286"
      remote_control_mode_fg = "#282828"
      remote_control_mode_bg = "#8ec07c"
      action_picker_mode_fg = "#282828"
      action_picker_mode_bg = "#83a598"
    '';
  };
}
