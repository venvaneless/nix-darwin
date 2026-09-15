# shared/terminal/cli-tuis/television/channels/nix-git.nix
#
# Git-aware Nix configuration browser with status and cyclable file/diff views.

{ televisionLib }:

''
  [metadata]
  name = "nix-git"
  description = "Browse Git changes in the active Nix configuration"
  requirements = ["git", "bat", "nvim", "zed"]

  [source]
  command = "${televisionLib.git.source}"
  display = "[{split:\\t:0}] {split:\\t:1}"
  shell = "fish"

  [preview]
  command = [
    "${televisionLib.git.previewDiff} '{}'",
    "${televisionLib.git.previewFile} '{}'",
  ]
  shell = "fish"

  [keybindings]
  enter = "actions:nvim"

  [actions.nvim]
  description = "Open changed file in nvim"
  command = "${televisionLib.git.nvim} '{}'"
  shell = "fish"
  mode = "execute"

  [actions.zed]
  description = "Open changed file in Zed"
  command = "${televisionLib.git.zed} '{}'"
  shell = "fish"
  mode = "fork"

  [actions.copy-path]
  description = "Copy absolute path"
  command = "${televisionLib.git.copyAbsolute} '{}'"
  shell = "fish"

  [actions.copy-relative-path]
  description = "Copy relative path"
  command = "${televisionLib.git.copyRelative} '{}'"
  shell = "fish"
''
