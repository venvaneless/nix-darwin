# shared/terminal/cli-tuis/television/channels/nix.nix
#
# Nix file browser for the active portable configuration root.

{ televisionLib }:

''
  [metadata]
  name = "nix"
  description = "Browse files in the active Nix configuration"
  requirements = ["fd", "bat", "nvim", "zed"]

  [source]
  command = "${televisionLib.file.source}"
  display = "{split:\\t:0}"
  shell = "fish"

  [preview]
  command = "${televisionLib.file.preview} '{}'"
  shell = "fish"

  [keybindings]
  enter = "actions:nvim"

  [actions.nvim]
  description = "Open selected file in nvim"
  command = "${televisionLib.file.nvim} '{}'"
  shell = "fish"
  mode = "execute"

  [actions.zed]
  description = "Open selected file in Zed"
  command = "${televisionLib.file.zed} '{}'"
  shell = "fish"
  mode = "fork"

  [actions.copy-path]
  description = "Copy absolute path"
  command = "${televisionLib.file.copyAbsolute} '{}'"
  shell = "fish"

  [actions.copy-relative-path]
  description = "Copy relative path"
  command = "${televisionLib.file.copyRelative} '{}'"
  shell = "fish"
''
