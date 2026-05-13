# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/eza.nix
#
# =====================================================================
# EZA
# 
# Modern, maintained replacement for ls
# =====================================================================

{ ... }:

{
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;

    colors = "always";
    icons = "auto";

    extraOptions = [
      "--group-directories-first"
      "--header"
      "--all"
    ];

    theme = {
      filekinds = {
        normal = { foreground = "#e0def4"; };
        directory = { foreground = "#9ccfd8"; };
        symlink = { foreground = "#c4a7e7"; };
        pipe = { foreground = "#908caa"; };
        block_device = { foreground = "#ea9a97"; };
        char_device = { foreground = "#f6c177"; };
        socket = { foreground = "#2a283e"; };
        special = { foreground = "#c4a7e7"; };
        executable = { foreground = "#e0def4"; };
        mount_point = { foreground = "#44415a"; };
      };

      perms = {
        user_read = { foreground = "#908caa"; };
        user_write = { foreground = "#44415a"; };
        user_execute_file = { foreground = "#c4a7e7"; };
        user_execute_other = { foreground = "#c4a7e7"; };
        group_read = { foreground = "#908caa"; };
        group_write = { foreground = "#44415a"; };
        group_execute = { foreground = "#c4a7e7"; };
        other_read = { foreground = "#908caa"; };
        other_write = { foreground = "#44415a"; };
        other_execute = { foreground = "#c4a7e7"; };
        special_user_file = { foreground = "#c4a7e7"; };
        special_other = { foreground = "#44415a"; };
        attribute = { foreground = "#908caa"; };
      };

      size = {
        major = { foreground = "#908caa"; };
        minor = { foreground = "#9ccfd8"; };
        number_byte = { foreground = "#908caa"; };
        number_kilo = { foreground = "#56526e"; };
        number_mega = { foreground = "#3e8fb0"; };
        number_giga = { foreground = "#c4a7e7"; };
        number_huge = { foreground = "#c4a7e7"; };
        unit_byte = { foreground = "#908caa"; };
        unit_kilo = { foreground = "#3e8fb0"; };
        unit_mega = { foreground = "#c4a7e7"; };
        unit_giga = { foreground = "#c4a7e7"; };
        unit_huge = { foreground = "#9ccfd8"; };
      };

      users = {
        user_you = { foreground = "#f6c177"; };
        user_root = { foreground = "#eb6f92"; };
        user_other = { foreground = "#c4a7e7"; };
        group_yours = { foreground = "#56526e"; };
        group_other = { foreground = "#6e6a86"; };
        group_root = { foreground = "#eb6f92"; };
      };

      links = {
        normal = { foreground = "#9ccfd8"; };
        multi_link_file = { foreground = "#3e8fb0"; };
      };

      git = {
        new = { foreground = "#9ccfd8"; };
        modified = { foreground = "#f6c177"; };
        deleted = { foreground = "#eb6f92"; };
        renamed = { foreground = "#3e8fb0"; };
        typechange = { foreground = "#c4a7e7"; };
        ignored = { foreground = "#6e6a86"; };
        conflicted = { foreground = "#ea9a97"; };
      };

      git_repo = {
        branch_main = { foreground = "#908caa"; };
        branch_other = { foreground = "#c4a7e7"; };
        git_clean = { foreground = "#9ccfd8"; };
        git_dirty = { foreground = "#eb6f92"; };
      };

      security_context = {
        colon = { foreground = "#908caa"; };
        user = { foreground = "#9ccfd8"; };
        role = { foreground = "#c4a7e7"; };
        typ = { foreground = "#6e6a86"; };
        range = { foreground = "#c4a7e7"; };
      };

      file_type = {
        image = { foreground = "#f6c177"; };
        video = { foreground = "#eb6f92"; };
        music = { foreground = "#9ccfd8"; };
        lossless = { foreground = "#6e6a86"; };
        crypto = { foreground = "#44415a"; };
        document = { foreground = "#908caa"; };
        compressed = { foreground = "#c4a7e7"; };
        temp = { foreground = "#ea9a97"; };
        compiled = { foreground = "#3e8fb0"; };
        build = { foreground = "#6e6a86"; };
        source = { foreground = "#ea9a97"; };
      };

      extensions = {
        "cpp" = { filename = { foreground = "#ea9a97"; }; };
        "rs" = { filename = { foreground = "#ea9a97"; }; };
        "mp4" = { filename = { foreground = "#eb6f92"; }; };
        "png" = { filename = { foreground = "#f6c177"; }; };
        "tar.gz" = { filename = { foreground = "#c4a7e7"; }; };
        "gz" = { filename = { foreground = "#c4a7e7"; }; };
        "zip" = { filename = { foreground = "#c4a7e7"; }; };
        "pdf" = { filename = { foreground = "#908caa"; }; };
        "docx" = { filename = { foreground = "#908caa"; }; };
        "pem" = { filename = { foreground = "#56526e"; }; };
        "toml" = { filename = { foreground = "#908caa"; }; };
        "yml" = { filename = { foreground = "#908caa"; }; };
        "yaml" = { filename = { foreground = "#908caa"; }; };
        "ini" = { filename = { foreground = "#e0def4"; }; };
        "conf" = { filename = { foreground = "#e0def4"; }; };
        "iso" = { filename = { foreground = "#c4a7e7"; }; };
        "mp3" = { filename = { foreground = "#9ccfd8"; }; };
        "flac" = { filename = { foreground = "#6e6a86"; }; };
        "sh" = { filename = { foreground = "#c4a7e7"; }; };
      };

      filenames = {
        "Cargo.lock" = { filename = { foreground = "#908caa"; }; };
        "Cargo.toml" = { filename = { foreground = "#908caa"; }; };
        ".pre-commit.yaml" = { filename = { foreground = "#908caa"; }; };
        "README.md" = { filename = { foreground = "#908caa"; }; };
        "Makefile" = { filename = { foreground = "#56526e"; }; };
        "justfile" = { filename = { foreground = "#56526e"; }; };
        "nginx.conf" = { filename = { foreground = "#e0def4"; }; };
      };

      punctuation = { foreground = "#56526e"; };
      date = { foreground = "#3e8fb0"; };
      inode = { foreground = "#908caa"; };
      blocks = { foreground = "#9399B2"; };
      header = { foreground = "#908caa"; };
      octal = { foreground = "#9ccfd8"; };
      flags = { foreground = "#c4a7e7"; };
      symlink_path = { foreground = "#9ccfd8"; };
      control_char = { foreground = "#3e8fb0"; };
      broken_symlink = { foreground = "#eb6f92"; };
      broken_path_overlay = { foreground = "#56526e"; };
    };
  };
}
