# shared/terminal/cli-tuis/television/config.nix
#
# =====================================================================
# TELEVISION: CORE CONFIGURATION
#
# The global Television options are intentionally separate from channel
# recipes so each channel remains simple to extend or replace.
# =====================================================================

{ selectedThemeConfig }:

''
  # Managed by shared/terminal/cli-tuis/television/default.nix.
  # Custom Nix channels are installed declaratively under cable/.

  [ui]
  theme = "${selectedThemeConfig.name}"

  [ui.preview_panel]
  size = 55
  scrollbar = true

  [ui.help_panel]
  hidden = true

  [ui.remote_control]
  show_channel_descriptions = true
  sort_alphabetically = true
''
