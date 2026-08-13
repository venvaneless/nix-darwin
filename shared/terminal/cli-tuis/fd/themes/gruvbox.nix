# shared/terminal/cli-tuis/fd/themes/gruvbox.nix
#
# =====================================================================
# FD: GRUVBOX DARK THEME
#
# - Selected directly in ../fd.nix with selectedTheme = "gruvbox"
# - Enabled only when fd.nix imports this theme module
#
# fd has no theme file of its own. It colours its output from LS_COLORS,
# so this module exports one instead of writing a config file.
#
# LS_COLORS is a shared variable: ls, tree, and fzf previews read it too,
# and eza layers it over its own theme.yml. Every colour below is taken
# from the same Gruvbox Dark palette used by ../../eza/themes/gruvbox-dark.nix
# and ../../../wezterm/themes/wez-gruvbox.nix, so the tools stay consistent.
# =====================================================================

{ config, lib, ... }:

let
  fdCfg = config.ven.features.terminal.cliTuis.fd;
  cfg = fdCfg.themes.gruvbox;

  # ---- PALETTE ---- #
  # Truecolor foreground escapes for the WezTerm Gruvbox Dark colours.
  fg = "38;2;235;219;178"; # #ebdbb2 light0  - regular files
  gray = "38;2;146;131;116"; # #928374 gray    - pipes and muted entries
  darkGray = "38;2;102;92;84"; # #665c54 bg3     - sockets
  red = "38;2;251;73;52"; # #fb4934 red     - devices and broken links
  darkRed = "38;2;204;36;29"; # #cc241d dark red - temporary files
  green = "38;2;184;187;38"; # #b8bb26 green   - executables and audio
  yellow = "38;2;250;189;47"; # #fabd2f yellow  - images
  blue = "38;2;131;165;152"; # #83a598 blue    - directories and sources
  purple = "38;2;211;134;155"; # #d3869b purple - archives and special files
  aqua = "38;2;142;192;124"; # #8ec07c aqua    - symlinks and lossless audio
  orange = "38;2;254;128;25"; # #fe8019 orange  - mount points
  cream = "38;2;251;241;199"; # #fbf1c7 light0h - setuid foreground
  bgHard = "38;2;40;40;40"; # #282828 bg      - foreground on coloured dirs

  # ---- BACKGROUNDS ---- #
  onRed = "48;2;251;73;52"; # #fb4934 - setuid and setgid entries
  onBlue = "48;2;131;165;152"; # #83a598 - sticky and other-writable dirs

  # ---- HELPER ---- #
  # Renders one "pattern=escape" pair for every listed pattern.
  entriesFor = escape: patterns: map (pattern: "${pattern}=${escape}") patterns;

  # ---- FILE KINDS ---- #
  fileKinds = [
    "no=${fg}" # default text
    "fi=${fg}" # regular file
    "di=${blue};1" # directory
    "ln=${aqua}" # symbolic link
    "or=${red};1" # broken symbolic link
    "mi=${darkRed}" # missing link target
    "pi=${gray}" # named pipe
    "so=${darkGray}" # socket
    "do=${darkGray}" # door
    "bd=${red}" # block device
    "cd=${red}" # character device
    "ex=${green};1" # executable file
    "su=${cream};${onRed}" # setuid
    "sg=${cream};${onRed}" # setgid
    "tw=${bgHard};${onBlue}" # sticky and other-writable directory
    "ow=${bgHard};${onBlue}" # other-writable directory
    "st=${bgHard};${onBlue}" # sticky directory
    "mh=${orange}" # multiple hard links
    "ca=${purple}" # file with capability
  ];

  # ---- FILE TYPES ---- #
  # Grouped the same way as eza's file_type section so both agree.
  fileTypes =
    entriesFor purple [
      "*.zip" "*.tar" "*.tgz" "*.gz" "*.bz2" "*.xz" "*.zst" "*.7z" "*.rar"
      "*.dmg" "*.pkg"
    ]
    ++ entriesFor yellow [
      "*.png" "*.jpg" "*.jpeg" "*.gif" "*.webp" "*.svg" "*.heic" "*.bmp" "*.tiff"
    ]
    ++ entriesFor red [
      "*.mp4" "*.mkv" "*.mov" "*.avi" "*.webm"
    ]
    ++ entriesFor green [
      "*.mp3" "*.m4a" "*.ogg" "*.opus" "*.aac"
    ]
    ++ entriesFor aqua [
      "*.flac" "*.wav" "*.alac"
    ]
    ++ entriesFor fg [
      "*.pdf" "*.epub" "*.md" "*.txt" "*.docx" "*.odt"
    ]
    ++ entriesFor blue [
      "*.nix" "*.lua" "*.fish" "*.sh" "*.py" "*.rs" "*.go" "*.ts" "*.tsx"
      "*.js" "*.jsx" "*.json" "*.jsonc" "*.toml" "*.yml" "*.yaml"
    ]
    ++ entriesFor gray [
      "*.gpg" "*.asc" "*.pem" "*.key" "*.lock"
    ]
    ++ entriesFor darkRed [
      "*.tmp" "*.swp" "*.bak" "*.log" "*.orig"
    ];
in
{
  options.ven.features.terminal.cliTuis.fd.themes.gruvbox.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Internal switch for the Gruvbox Dark colours selected in fd.nix.";
  };

  # Only applies when fd itself is enabled.
  config = lib.mkIf (fdCfg.enable && cfg.enable) {
    home.sessionVariables.LS_COLORS =
      lib.concatStringsSep ":" (fileKinds ++ fileTypes);
  };
}
