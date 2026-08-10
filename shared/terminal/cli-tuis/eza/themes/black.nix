# shared/terminal/cli-tuis/eza/themes/black.nix
#
# =====================================================================
# EZA: BLACK THEME
#
# - Declares the Black theme entirely in Nix
# - Toggle with ven.features.terminal.cliTuis.eza.themes.black.enable
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
  cfg = ezaCfg.themes.black;
in
{
  options.ven.features.terminal.cliTuis.eza.themes.black.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Use the Black theme for eza.";
  };

  # Only applies when eza itself is enabled.
  config = lib.mkIf (ezaCfg.enable && cfg.enable) {
    programs.eza.theme = {
      colourful = false;
      filekinds = {
        normal = { foreground = "#000"; };
        directory = { foreground = "#000"; };
        symlink = { foreground = "#000"; };
        pipe = { foreground = "#000"; };
        block_device = { foreground = "#000"; };
        char_device = { foreground = "#000"; };
        socket = { foreground = "#000"; };
        special = { foreground = "#000"; };
        executable = { foreground = "#000"; };
        mount_point = { foreground = "#000"; };
      };
      perms = {
        user_read = { foreground = "#000"; };
        user_write = { foreground = "#000"; };
        user_execute_file = { foreground = "#000"; };
        user_execute_other = { foreground = "#000"; };
        group_read = { foreground = "#000"; };
        group_write = { foreground = "#000"; };
        group_execute = { foreground = "#000"; };
        other_read = { foreground = "#000"; };
        other_write = { foreground = "#000"; };
        other_execute = { foreground = "#000"; };
        special_user_file = { foreground = "#000"; };
        special_other = { foreground = "#000"; };
        attribute = { foreground = "#000"; };
      };
      size = {
        major = { foreground = "#000"; };
        minor = { foreground = "#000"; };
        number_byte = { foreground = "#000"; };
        number_kilo = { foreground = "#000"; };
        number_mega = { foreground = "#000"; };
        number_giga = { foreground = "#000"; };
        number_huge = { foreground = "#000"; };
        unit_byte = { foreground = "#000"; };
        unit_kilo = { foreground = "#000"; };
        unit_mega = { foreground = "#000"; };
        unit_giga = { foreground = "#000"; };
        unit_huge = { foreground = "#000"; };
      };
      users = {
        user_you = { foreground = "#000"; };
        user_root = { foreground = "#000"; };
        user_other = { foreground = "#000"; };
        group_yours = { foreground = "#000"; };
        group_other = { foreground = "#000"; };
        group_root = { foreground = "#000"; };
      };
      links = {
        normal = { foreground = "#000"; };
        multi_link_file = { foreground = "#000"; };
      };
      git = {
        new = { foreground = "#000"; };
        modified = { foreground = "#000"; };
        deleted = { foreground = "#000"; };
        renamed = { foreground = "#000"; };
        typechange = { foreground = "#000"; };
        ignored = { foreground = "#000"; };
        conflicted = { foreground = "#000"; };
      };
      git_repo = {
        branch_main = { foreground = "#000"; };
        branch_other = { foreground = "#000"; };
        git_clean = { foreground = "#000"; };
        git_dirty = { foreground = "#000"; };
      };
      security_context = {
        colon = { foreground = "#000"; };
        user = { foreground = "#000"; };
        role = { foreground = "#000"; };
        typ = { foreground = "#000"; };
        range = { foreground = "#000"; };
      };
      file_type = {
        image = { foreground = "#000"; };
        video = { foreground = "#000"; };
        music = { foreground = "#000"; };
        lossless = { foreground = "#000"; };
        crypto = { foreground = "#000"; };
        document = { foreground = "#000"; };
        compressed = { foreground = "#000"; };
        temp = { foreground = "#000"; };
        compiled = { foreground = "#000"; };
        build = { foreground = "#000"; };
        source = { foreground = "#000"; };
      };
      punctuation = { foreground = "#000"; };
      date = { foreground = "#000"; };
      inode = { foreground = "#000"; };
      blocks = { foreground = "#000"; };
      header = { foreground = "#000"; };
      octal = { foreground = "#000"; };
      flags = { foreground = "#000"; };
      symlink_path = { foreground = "#000"; };
      control_char = { foreground = "#000"; };
      broken_symlink = { foreground = "#000"; };
      broken_path_overlay = { foreground = "#000"; };
      filenames = { };
      extensions = { };
    };
  };
}
