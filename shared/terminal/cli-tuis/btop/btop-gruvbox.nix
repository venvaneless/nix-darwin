# shared/terminal/cli-tuis/btop/btop-gruvbox.nix
#
# =====================================================================
# BTOP: GRUVBOX DARK THEME
#
# - Ships the `ven-gruvbox` theme file and selects it in btop
# - Toggle with ven.features.terminal.cliTuis.btop.gruvbox.enable
# - Turning it off leaves btop on its built-in Default theme
# =====================================================================

{ config, lib, ... }:

let
  btopCfg = config.ven.features.terminal.cliTuis.btop;
  cfg = btopCfg.gruvbox;
in
{
  options.ven.features.terminal.cliTuis.btop.gruvbox.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Use the declarative Gruvbox Dark theme for btop.";
  };

  # Only applies when btop itself is enabled.
  config = lib.mkIf (btopCfg.enable && cfg.enable) {
    programs.btop = {
      # ---- THEME SELECTION ---- #
      settings.color_theme = "btop-gruvbox";

      # ---- THEME DEFINITION ---- #
      themes.btop-gruvbox = ''
        # Main background.
        # Empty allows terminal transparency when theme_background is false.
        theme[main_bg]="#282828"

        # Main foreground.
        theme[main_fg]="#EBDBB2"

        # Panel titles.
        theme[title]="#EBDBB2"

        # Shortcut and accent text.
        theme[hi_fg]="#FABD2F"

        # Selected rows.
        theme[selected_bg]="#504945"
        theme[selected_fg]="#FBF1C7"

        # Disabled and inactive text.
        theme[inactive_fg]="#665C54"

        # Text drawn over graphs.
        theme[graph_text]="#A89984"

        # Empty portions of meters.
        theme[meter_bg]="#3C3836"

        # Process details and miniature process graphs.
        theme[proc_misc]="#B8BB26"

        # Panel borders.
        theme[cpu_box]="#FABD2F"
        theme[mem_box]="#B8BB26"
        theme[net_box]="#83A598"
        theme[proc_box]="#D3869B"

        # Divider lines.
        theme[div_line]="#504945"

        # Temperature gradient.
        theme[temp_start]="#83A598"
        theme[temp_mid]="#FABD2F"
        theme[temp_end]="#FB4934"

        # CPU graph gradient.
        theme[cpu_start]="#B8BB26"
        theme[cpu_mid]="#FABD2F"
        theme[cpu_end]="#FB4934"

        # Free-memory gradient.
        theme[free_start]="#83A598"
        theme[free_mid]="#8EC07C"
        theme[free_end]="#B8BB26"

        # Cached-memory gradient.
        theme[cached_start]="#689D6A"
        theme[cached_mid]="#8EC07C"
        theme[cached_end]="#B8BB26"

        # Available-memory gradient.
        theme[available_start]="#458588"
        theme[available_mid]="#83A598"
        theme[available_end]="#8EC07C"

        # Used-memory and disk gradient.
        theme[used_start]="#FABD2F"
        theme[used_mid]="#FE8019"
        theme[used_end]="#FB4934"

        # Network download gradient.
        theme[download_start]="#458588"
        theme[download_mid]="#83A598"
        theme[download_end]="#8EC07C"

        # Network upload gradient.
        theme[upload_start]="#B16286"
        theme[upload_mid]="#D3869B"
        theme[upload_end]="#FB4934"

        # Process CPU/RAM usage gradient.
        theme[process_start]="#B8BB26"
        theme[process_mid]="#FABD2F"
        theme[process_end]="#FB4934"
      '';
    };
  };
}
