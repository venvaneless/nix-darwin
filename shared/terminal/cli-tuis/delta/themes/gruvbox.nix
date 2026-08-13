# shared/terminal/cli-tuis/delta/themes/gruvbox.nix
#
# =====================================================================
# DELTA: GRUVBOX DARK THEME
#
# - Selected directly in ../delta.nix with selectedTheme = "gruvbox"
# - Enabled only when delta.nix imports this theme module
#
# The palette matches ../../../wezterm/themes/wez-gruvbox.nix and the
# Gruvbox Dark themes already used by bat, btop, eza, fzf, and Atuin.
#
# Everything is declared as a named delta feature, so Home Manager writes
# it into a [delta "gruvbox"] section and selects it with `features`.
# Only colours belong here; layout options stay in delta.nix, because a
# value in delta's main section always overrides a feature.
# =====================================================================

{ config, lib, ... }:

let
  deltaCfg = config.ven.features.terminal.cliTuis.delta;
  cfg = deltaCfg.themes.gruvbox;
in
{
  options.ven.features.terminal.cliTuis.delta.themes.gruvbox.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Internal switch for the Gruvbox Dark theme selected in delta.nix.";
  };

  # Only applies when delta itself is enabled.
  config = lib.mkIf (deltaCfg.enable && cfg.enable) {
    programs.delta.options = {
      # Activate the feature declared below.
      features = "gruvbox";

      gruvbox = {
        # ---- SYNTAX HIGHLIGHTING ---- #
        # The same syntect theme bat uses, so both agree on token colours.
        syntax-theme = "gruvbox-dark";

        # ---- REMOVED AND ADDED LINES ---- #
        # Backgrounds are darkened Gruvbox red and green, dim enough to
        # keep the syntax colours in front of them readable.
        minus-style = "syntax #452b2b";
        minus-emph-style = "syntax #6f3f3f";
        minus-non-emph-style = "syntax #3a2626";
        plus-style = "syntax #2c3a26";
        plus-emph-style = "syntax #46603a";
        plus-non-emph-style = "syntax #26301f";
        zero-style = "syntax";

        # ---- LINE NUMBERS ---- #
        line-numbers-minus-style = "#fb4934";
        line-numbers-plus-style = "#b8bb26";
        line-numbers-zero-style = "#665c54";
        line-numbers-left-style = "#504945";
        line-numbers-right-style = "#504945";

        # ---- FILE HEADERS ---- #
        file-style = "bold #fabd2f";
        file-decoration-style = "#665c54 ul";
        file-added-label = "[+]";
        file-copied-label = "[C]";
        file-modified-label = "[M]";
        file-removed-label = "[-]";
        file-renamed-label = "[R]";

        # ---- HUNK HEADERS ---- #
        hunk-header-style = "file line-number syntax";
        hunk-header-decoration-style = "#665c54 box";
        hunk-header-file-style = "#83a598";
        hunk-header-line-number-style = "bold #fe8019";

        # ---- COMMITS AND BLAME ---- #
        commit-style = "bold #fabd2f";
        commit-decoration-style = "#665c54 box ul";
        blame-code-style = "syntax";

        # Four Gruvbox background steps cycled per commit in git blame.
        blame-palette = "#282828 #32302f #3c3836 #504945";

        # ---- MERGE CONFLICTS ---- #
        merge-conflict-begin-symbol = "▼";
        merge-conflict-end-symbol = "▲";
        merge-conflict-ours-diff-header-style = "bold #fabd2f";
        merge-conflict-ours-diff-header-decoration-style = "#665c54 box";
        merge-conflict-theirs-diff-header-style = "bold #83a598";
        merge-conflict-theirs-diff-header-decoration-style = "#665c54 box";

        # ---- MISCELLANEOUS ---- #
        whitespace-error-style = "#fb4934 reverse";
        grep-file-style = "#83a598";
        grep-line-number-style = "#fe8019";
      };
    };
  };
}
