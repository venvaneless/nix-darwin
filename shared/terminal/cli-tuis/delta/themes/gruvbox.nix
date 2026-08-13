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
# Structured after the community "gruvmax-fang" delta theme
# (https://github.com/maxfangx), which is the reference for what Gruvbox
# should look like in delta, with every colour swapped for the exact
# WezTerm values used elsewhere in this repository.
#
# ---- WHAT MAKES THIS READ AS GRUVBOX ---- #
# The recognisable Gruvbox look comes from warm grey furniture and cream
# text with sparing yellow, orange, and blue accents. The diff background
# tints must stay close to #282828 so the syntax colours sit in front of
# them. Saturated plus/minus backgrounds flood the screen instead, which
# turns an addition-heavy diff into a wash of a single hue.
#
# Therefore:
# - plus and minus backgrounds are only a few steps off the terminal
#   background, and clearly separated in hue (warm red vs olive green)
# - the emph variants carry the contrast, so word-level edits stand out
# - line number gutters, boxes, and rules use bg3/bg4 grey, never green
# - accents are cream for file paths, yellow for commits, orange for
#   hunk line numbers, and blue for hunk file paths
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
        # ---- MODE ---- #
        # Declaring dark here is what makes delta treat this feature as a
        # theme, so it appears in `delta --show-themes`.
        dark = true;

        # ---- SYNTAX HIGHLIGHTING ---- #
        # The same syntect theme bat uses, so both agree on token colours.
        # This carries most of the Gruvbox character: swap it and preview
        # with `git diff | delta --show-syntax-themes`.
        syntax-theme = "gruvbox-dark";

        # ---- DIFF BODY ---- #
        # Backgrounds sit just off #282828. The emph variants are the ones
        # meant to be noticed, marking the words that actually changed.
        minus-style = "syntax #3f2120";
        minus-emph-style = "syntax #7a3028";
        minus-non-emph-style = "syntax #2e1b1a";
        plus-style = "syntax #26301c";
        plus-emph-style = "syntax #46571f";
        plus-non-emph-style = "syntax #1e2616";
        zero-style = "syntax";

        # Markers for added and removed blank lines.
        minus-empty-line-marker-style = "normal #3f2120";
        plus-empty-line-marker-style = "normal #26301c";

        # Delta's own annotations, such as wrapped-line symbols. Grey keeps
        # them out of the way instead of delta's default blue.
        inline-hint-style = "#928374";
        whitespace-error-style = "#fb4934 reverse";

        # ---- LINE NUMBERS ---- #
        # Warm bg4 grey gutters. Only the changed-line numbers take colour,
        # and in the muted red and green rather than the bright pair.
        line-numbers-left-style = "#7c6f64";
        line-numbers-right-style = "#7c6f64";
        line-numbers-minus-style = "bold #cc241d";
        line-numbers-plus-style = "bold #98971a";
        line-numbers-zero-style = "#665c54";
        line-numbers-left-format = " {nm:>4} │";
        line-numbers-right-format = " {np:>4} │";

        # ---- FILE HEADERS ---- #
        # Cream is the brightest element on screen, so the eye lands on the
        # file path first.
        file-style = "bold #fbf1c7";
        file-decoration-style = "#7c6f64 ul";
        file-added-label = "[+]";
        file-copied-label = "[==]";
        file-modified-label = "[*]";
        file-removed-label = "[-]";
        file-renamed-label = "[->]";

        # ---- HUNK HEADERS ---- #
        hunk-header-style = "file line-number syntax";
        hunk-header-decoration-style = "#504945 box";
        hunk-header-file-style = "#83a598";
        hunk-header-line-number-style = "bold #fe8019";

        # ---- COMMITS ---- #
        commit-style = "bold #fabd2f";
        commit-decoration-style = "#7c6f64 box ul";

        # ---- BLAME ---- #
        blame-code-style = "syntax";
        blame-format = "{author:<18} ({commit:>8}) {timestamp:^16} ";

        # Four Gruvbox background steps cycled per commit in git blame.
        blame-palette = "#1d2021 #282828 #32302f #3c3836";

        # ---- MERGE CONFLICTS ---- #
        merge-conflict-begin-symbol = "▼";
        merge-conflict-end-symbol = "▲";
        merge-conflict-ours-diff-header-style = "bold #fabd2f";
        merge-conflict-ours-diff-header-decoration-style = "#504945 box";
        merge-conflict-theirs-diff-header-style = "bold #83a598";
        merge-conflict-theirs-diff-header-decoration-style = "#504945 box";

        # ---- GREP OUTPUT ---- #
        # Used when delta renders `git grep` or `rg --json` results.
        grep-file-style = "#83a598";
        grep-line-number-style = "#fe8019";
        grep-match-line-style = "syntax #32302f";
        grep-match-word-style = "bold #fabd2f";
      };
    };
  };
}
