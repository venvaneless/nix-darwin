# shared/terminal/cli-tuis/atuin/default.nix

# =====================================================================
# ATUIN: KNOBS
#
# Atuin's values and the theme it uses. Its implementation, platform
# selection, and theme rendering live in options/cli/atuin.
# =====================================================================

{ ... }:

{
  imports = [
    ./themes
  ];

  home.shared.cli.atuin = {
    enable = true;

    installOn = {
      darwin = true;
      linux = true;
    };

    # One of the themes declared under ./themes.
    theme = "gruvboxDark";

    settings = {
      enter_accept = true;

      sync = {
        # Keep Atuin sync-v2 records enabled for existing history data.
        records = true;
      };
    };

    fish = {
      # Prevent Atuin from automatically taking over keybindings.
      preventAutomaticKeybindings = true;

      # Bind Ctrl-R to Atuin search.
      searchBinding = "\\cr";
    };
  };
}
