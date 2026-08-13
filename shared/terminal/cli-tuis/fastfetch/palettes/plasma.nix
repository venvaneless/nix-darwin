# shared/terminal/cli-tuis/fastfetch/palettes/plasma.nix
#
# =====================================================================
# FASTFETCH: PLASMA PALETTE
#
# - Selected in fastfetch.nix with selectedPalette.<platform> = "plasma"
# - Preserves the colours the Linux profile used before the layouts and
#   palettes were separated
#
# Platform independent: either layout may use it, despite the name
# describing the desktop it was originally written for.
#
# The original profile coloured its system section with the terminal's
# ANSI cyan (escape 36). Palettes are truecolor, so that one value is
# pinned to the hex equivalent below rather than following the theme.
# =====================================================================

{
  name = "plasma";

  # ---- TITLE LINE ---- #
  # Kept as ANSI colour names, exactly as the original profile had them.
  title = {
    user = "cyan";
    at = "white";
    host = "cyan";
  };

  # ---- SECTIONS ---- #
  sections = {
    # Cyan: operating system, host, kernel, uptime, packages.
    system = {
      accent = "#00cdcd";
      label = "#66ffff";
    };

    # Amber: processor, graphics, memory, swap, disks.
    hardware = {
      accent = "#f7c068";
      label = "#ffd88a";
    };

    # Slate: desktop environment, theme, icons, fonts, cursor.
    desktop = {
      accent = "#919cab";
      label = "#b1bbc8";
    };

    # Coral: shell, editor, terminal, and the working directory.
    terminal = {
      accent = "#f77067";
      label = "#ff928a";
    };

    # Violet: load average, processes, date, locale.
    state = {
      accent = "#c381dc";
      label = "#d6a1ed";
    };
  };
}
