# shared/terminal/cli-tuis/fastfetch/palettes/gruvbox.nix
#
# =====================================================================
# FASTFETCH: GRUVBOX DARK PALETTE
#
# - Selected in fastfetch.nix with selectedPalette.<platform> = "gruvbox"
# - The default palette on every machine
#
# Platform independent: either layout may use it. Colours match
# ../../../wezterm/themes/wez-gruvbox.nix and the Gruvbox Dark themes
# used by bat, btop, delta, eza, fzf, and Atuin.
#
# accent colours the section rule, its icons, and its values.
# label colours only the " : " between a key and its value.
# =====================================================================

{
  name = "gruvbox";

  # ---- TITLE LINE ---- #
  # Passed straight to fastfetch, which accepts hex and colour names.
  title = {
    user = "#fabd2f";
    at = "#ebdbb2";
    host = "#fabd2f";
  };

  # ---- SECTIONS ---- #
  sections = {
    # Yellow: operating system, host, kernel, uptime, packages.
    system = {
      accent = "#fabd2f";
      label = "#ebdbb2";
    };

    # Orange: processor, graphics, memory, swap, disks.
    hardware = {
      accent = "#fe8019";
      label = "#ebdbb2";
    };

    # Purple: desktop environment, theme, icons, fonts, cursor.
    desktop = {
      accent = "#d3869b";
      label = "#ebdbb2";
    };

    # Blue: shell, editor, terminal, and the working directory.
    terminal = {
      accent = "#83a598";
      label = "#ebdbb2";
    };

    # Green: load average, processes, date, locale.
    state = {
      accent = "#b8bb26";
      label = "#ebdbb2";
    };
  };
}
