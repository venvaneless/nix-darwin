# shared/terminal/cli-tuis/television/channels/nix-darwin.nix
#
# Darwin-scoped file browser. Additional nix-linux and nix-shared channels
# can reuse this file-channel shape with only a different helper scope.

{ televisionLib }:

''
  [metadata]
  name = "nix-darwin"
  description = "Browse Darwin Nix configuration files"
  requirements = ["fd", "bat", "nvim", "zed"]

  [source]
  command = "${televisionLib.file.darwinSource}"
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
