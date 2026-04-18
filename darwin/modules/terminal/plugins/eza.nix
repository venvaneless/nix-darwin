# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/eza.nix
#
# ZSH: EZA
# =========================
# Modern ls replacement with icons and Rose Pine Moon theme

{ ... }:

{
  programs.eza = {
    enable = true;
    enableZshIntegration = true;

    # Use colored output
    colors = "auto";

    # Use icons declaratively
    icons = "auto";

    # Optional nice defaults
    git = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];

    # Custom theme written to ~/.config/eza/theme.yml
    theme = {
      filekinds = {
        normal = { foreground = "#e0def4"; };
        directory = { foreground = "#9ccfd8"; font-style = "bold"; };
        symlink = { foreground = "#c4a7e7"; };
        executable = { foreground = "#3e8fb0"; font-style = "bold"; };
        pipe = { foreground = "#f6c177"; };
        socket = { foreground = "#ea9a97"; };
        block-device = { foreground = "#eb6f92"; };
        char-device = { foreground = "#eb6f92"; };
        special = { foreground = "#6e6a86"; };
      };

      perms = {
        user-read = { foreground = "#9ccfd8"; };
        user-write = { foreground = "#f6c177"; };
        user-execute = { foreground = "#3e8fb0"; };
        group-read = { foreground = "#c4a7e7"; };
        group-write = { foreground = "#ea9a97"; };
        group-execute = { foreground = "#eb6f92"; };
        other-read = { foreground = "#6e6a86"; };
        other-write = { foreground = "#6e6a86"; };
        other-execute = { foreground = "#6e6a86"; };
        special-user-file = { foreground = "#eb6f92"; };
        special-other = { foreground = "#eb6f92"; };
        attribute = { foreground = "#6e6a86"; };
      };

      size = {
        number = { foreground = "#f6c177"; };
        unit = { foreground = "#6e6a86"; };
      };

      users = {
        user-you = { foreground = "#c4a7e7"; font-style = "bold"; };
        user-root = { foreground = "#eb6f92"; font-style = "bold"; };
        user-other = { foreground = "#e0def4"; };
        group-your = { foreground = "#9ccfd8"; };
        group-other = { foreground = "#6e6a86"; };
        group-root = { foreground = "#eb6f92"; };
      };

      dates = {
        hour-old = { foreground = "#3e8fb0"; };
        day-old = { foreground = "#9ccfd8"; };
        older = { foreground = "#6e6a86"; };
      };

      git = {
        new = { foreground = "#3e8fb0"; };
        modified = { foreground = "#f6c177"; };
        deleted = { foreground = "#eb6f92"; };
        renamed = { foreground = "#c4a7e7"; };
        typechange = { foreground = "#ea9a97"; };
        ignored = { foreground = "#6e6a86"; };
        conflicted = { foreground = "#eb6f92"; font-style = "bold"; };
      };
    };
  };
}