# shared/terminal/cli-tuis/eza/themes/rose-pine-dawn.nix
#
# =====================================================================
# EZA: ROSÉ PINE DAWN THEME
#
# - Declares the Rosé Pine Dawn theme entirely in Nix
# - Toggle with ven.features.terminal.cliTuis.eza.themes.rosePineDawn.enable
# - Disabled by default; enable it after turning the active theme off
#
# Home Manager renders this attribute set to
# $XDG_CONFIG_HOME/eza/theme.yml. Only one eza theme may be enabled.
#
# Converted from the eza-community/eza-themes collection
# =====================================================================

{ config, lib, ... }:

let
  ezaCfg = config.ven.features.terminal.cliTuis.eza;
  cfg = ezaCfg.themes.rosePineDawn;
in
{
  options.ven.features.terminal.cliTuis.eza.themes.rosePineDawn.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Use the Rosé Pine Dawn theme for eza.";
  };

  # Only applies when eza itself is enabled.
  config = lib.mkIf (ezaCfg.enable && cfg.enable) {
    programs.eza.theme = {
      colourful = true;
      filekinds = {
        normal = { foreground = "#575279"; };
        directory = { foreground = "#56949f"; };
        symlink = { foreground = "#cecacd"; };
        pipe = { foreground = "#797593"; };
        block_device = { foreground = "#d7827e"; };
        char_device = { foreground = "#ea9d34"; };
        socket = { foreground = "#f4ede8"; };
        special = { foreground = "#907aa9"; };
        executable = { foreground = "#907aa9"; };
        mount_point = { foreground = "#dfdad9"; };
      };
      perms = {
        user_read = { foreground = "#797593"; };
        user_write = { foreground = "#d7827e"; };
        user_execute_file = { foreground = "#907aa9"; };
        user_execute_other = { foreground = "#907aa9"; };
        group_read = { foreground = "#797593"; };
        group_write = { foreground = "#d7827e"; };
        group_execute = { foreground = "#907aa9"; };
        other_read = { foreground = "#797593"; };
        other_write = { foreground = "#d7827e"; };
        other_execute = { foreground = "#907aa9"; };
        special_user_file = { foreground = "#907aa9"; };
        special_other = { foreground = "#d7827e"; };
        attribute = { foreground = "#797593"; };
      };
      size = {
        major = { foreground = "#797593"; };
        minor = { foreground = "#56949f"; };
        number_byte = { foreground = "#797593"; };
        number_kilo = { foreground = "#cecacd"; };
        number_mega = { foreground = "#286983"; };
        number_giga = { foreground = "#907aa9"; };
        number_huge = { foreground = "#907aa9"; };
        unit_byte = { foreground = "#797593"; };
        unit_kilo = { foreground = "#286983"; };
        unit_mega = { foreground = "#907aa9"; };
        unit_giga = { foreground = "#907aa9"; };
        unit_huge = { foreground = "#56949f"; };
      };
      users = {
        user_you = { foreground = "#ea9d34"; };
        user_root = { foreground = "#b4637a"; };
        user_other = { foreground = "#907aa9"; };
        group_yours = { foreground = "#cecacd"; };
        group_other = { foreground = "#9893a5"; };
        group_root = { foreground = "#b4637a"; };
      };
      links = {
        normal = { foreground = "#56949f"; };
        multi_link_file = { foreground = "#286983"; };
      };
      git = {
        new = { foreground = "#56949f"; };
        modified = { foreground = "#ea9d34"; };
        deleted = { foreground = "#b4637a"; };
        renamed = { foreground = "#286983"; };
        typechange = { foreground = "#907aa9"; };
        ignored = { foreground = "#9893a5"; };
        conflicted = { foreground = "#d7827e"; };
      };
      git_repo = {
        branch_main = { foreground = "#797593"; };
        branch_other = { foreground = "#907aa9"; };
        git_clean = { foreground = "#56949f"; };
        git_dirty = { foreground = "#b4637a"; };
      };
      security_context = {
        colon = { foreground = "#797593"; };
        user = { foreground = "#56949f"; };
        role = { foreground = "#907aa9"; };
        typ = { foreground = "#9893a5"; };
        range = { foreground = "#907aa9"; };
      };
      file_type = {
        image = { foreground = "#ea9d34"; };
        video = { foreground = "#b4637a"; };
        music = { foreground = "#56949f"; };
        lossless = { foreground = "#9893a5"; };
        crypto = { foreground = "#dfdad9"; };
        document = { foreground = "#797593"; };
        compressed = { foreground = "#907aa9"; };
        temp = { foreground = "#d7827e"; };
        compiled = { foreground = "#286983"; };
        build = { foreground = "#9893a5"; };
        source = { foreground = "#d7827e"; };
      };
      punctuation = { foreground = "#cecacd"; };
      date = { foreground = "#286983"; };
      inode = { foreground = "#797593"; };
      blocks = { foreground = "#9893a5"; };
      header = { foreground = "#797593"; };
      octal = { foreground = "#56949f"; };
      flags = { foreground = "#907aa9"; };
      symlink_path = { foreground = "#56949f"; };
      control_char = { foreground = "#286983"; };
      broken_symlink = { foreground = "#b4637a"; };
      broken_path_overlay = { foreground = "#cecacd"; };
    };
  };
}
