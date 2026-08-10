# shared/terminal/cli-tuis/eza/themes/white.nix
#
# =====================================================================
# EZA: WHITE THEME
#
# - Declares the White theme entirely in Nix
# - Toggle with ven.features.terminal.cliTuis.eza.themes.white.enable
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
  cfg = ezaCfg.themes.white;
in
{
  options.ven.features.terminal.cliTuis.eza.themes.white.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Use the White theme for eza.";
  };

  # Only applies when eza itself is enabled.
  config = lib.mkIf (ezaCfg.enable && cfg.enable) {
    programs.eza.theme = {
      colourful = false;
      filekinds = {
        normal = { foreground = "#fff"; };
        directory = { foreground = "#fff"; };
        symlink = { foreground = "#fff"; };
        pipe = { foreground = "#fff"; };
        block_device = { foreground = "#fff"; };
        char_device = { foreground = "#fff"; };
        socket = { foreground = "#fff"; };
        special = { foreground = "#fff"; };
        executable = { foreground = "#fff"; };
        mount_point = { foreground = "#fff"; };
      };
      perms = {
        user_read = { foreground = "#fff"; };
        user_write = { foreground = "#fff"; };
        user_execute_file = { foreground = "#fff"; };
        user_execute_other = { foreground = "#fff"; };
        group_read = { foreground = "#fff"; };
        group_write = { foreground = "#fff"; };
        group_execute = { foreground = "#fff"; };
        other_read = { foreground = "#fff"; };
        other_write = { foreground = "#fff"; };
        other_execute = { foreground = "#fff"; };
        special_user_file = { foreground = "#fff"; };
        special_other = { foreground = "#fff"; };
        attribute = { foreground = "#fff"; };
      };
      size = {
        major = { foreground = "#fff"; };
        minor = { foreground = "#fff"; };
        number_byte = { foreground = "#fff"; };
        number_kilo = { foreground = "#fff"; };
        number_mega = { foreground = "#fff"; };
        number_giga = { foreground = "#fff"; };
        number_huge = { foreground = "#fff"; };
        unit_byte = { foreground = "#fff"; };
        unit_kilo = { foreground = "#fff"; };
        unit_mega = { foreground = "#fff"; };
        unit_giga = { foreground = "#fff"; };
        unit_huge = { foreground = "#fff"; };
      };
      users = {
        user_you = { foreground = "#fff"; };
        user_root = { foreground = "#fff"; };
        user_other = { foreground = "#fff"; };
        group_yours = { foreground = "#fff"; };
        group_other = { foreground = "#fff"; };
        group_root = { foreground = "#fff"; };
      };
      links = {
        normal = { foreground = "#fff"; };
        multi_link_file = { foreground = "#fff"; };
      };
      git = {
        new = { foreground = "#fff"; };
        modified = { foreground = "#fff"; };
        deleted = { foreground = "#fff"; };
        renamed = { foreground = "#fff"; };
        typechange = { foreground = "#fff"; };
        ignored = { foreground = "#fff"; };
        conflicted = { foreground = "#fff"; };
      };
      git_repo = {
        branch_main = { foreground = "#fff"; };
        branch_other = { foreground = "#fff"; };
        git_clean = { foreground = "#fff"; };
        git_dirty = { foreground = "#fff"; };
      };
      security_context = {
        colon = { foreground = "#fff"; };
        user = { foreground = "#fff"; };
        role = { foreground = "#fff"; };
        typ = { foreground = "#fff"; };
        range = { foreground = "#fff"; };
      };
      file_type = {
        image = { foreground = "#fff"; };
        video = { foreground = "#fff"; };
        music = { foreground = "#fff"; };
        lossless = { foreground = "#fff"; };
        crypto = { foreground = "#fff"; };
        document = { foreground = "#fff"; };
        compressed = { foreground = "#fff"; };
        temp = { foreground = "#fff"; };
        compiled = { foreground = "#fff"; };
        build = { foreground = "#fff"; };
        source = { foreground = "#fff"; };
      };
      punctuation = { foreground = "#fff"; };
      date = { foreground = "#fff"; };
      inode = { foreground = "#fff"; };
      blocks = { foreground = "#fff"; };
      header = { foreground = "#fff"; };
      octal = { foreground = "#fff"; };
      flags = { foreground = "#fff"; };
      symlink_path = { foreground = "#fff"; };
      control_char = { foreground = "#fff"; };
      broken_symlink = { foreground = "#fff"; };
      broken_path_overlay = { foreground = "#fff"; };
      filenames = { };
      extensions = { };
    };
  };
}
