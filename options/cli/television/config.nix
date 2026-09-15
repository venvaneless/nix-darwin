# shared/terminal/cli-tuis/television/config.nix
#
# =====================================================================
# TELEVISION: CORE CONFIGURATION
#
# The global Television options are intentionally separate from channel
# recipes so each channel remains simple to extend or replace.
# =====================================================================

{ themeName, ui }:

''
  # Managed by options/cli/television/default.nix.
  # Custom Nix channels are installed declaratively under cable/.

  [ui]
  theme = "${themeName}"

  [ui.preview_panel]
  size = ${toString ui.previewPanel.size}
  scrollbar = ${if ui.previewPanel.scrollbar then "true" else "false"}

  [ui.help_panel]
  hidden = ${if ui.helpPanel.hidden then "true" else "false"}

  [ui.remote_control]
  show_channel_descriptions = ${if ui.remoteControl.showChannelDescriptions then "true" else "false"}
  sort_alphabetically = ${if ui.remoteControl.sortAlphabetically then "true" else "false"}
''
