# shared/terminal/cli-tuis/bat/themes/gruvbox-dark.nix
#
# =====================================================================
# BAT THEME: GRUVBOX DARK
#
# bat ships this theme, so only its name is needed. It matches the
# theme Delta uses for Git output.
# =====================================================================

{ ... }:

{
  home.shared.cli.bat.themes.gruvboxDark = {
    name = "gruvboxDark";
    batName = "gruvbox-dark";

    # Shipped with bat; nothing is generated for it.
    builtIn = true;
  };
}
