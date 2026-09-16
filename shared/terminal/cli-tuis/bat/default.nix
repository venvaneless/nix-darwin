# shared/terminal/cli-tuis/bat/default.nix

# =====================================================================
# BAT: KNOBS
#
# Bat's values and the theme it uses. Its implementation, platform
# selection, and theme rendering live in options/cli/bat.
# =====================================================================

{ ... }:

{
  imports = [
    ./themes
  ];

  home.shared.cli.bat = {
    enable = true;

    installOn = {
      darwin = true;
      linux = true;
    };

    # One of the themes declared under ./themes.
    theme = "gruvboxDark";

    settings = {
      # Line numbers, Git change markers, and the file header.
      style = "numbers,changes,header";

      # Wrap long lines at the terminal width.
      wrap = "auto";

      # Keep bat's output plain when it is piped into another command.
      paging = "auto";
    };

    rebuildCache = true;
  };
}
