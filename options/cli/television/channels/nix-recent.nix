# shared/terminal/cli-tuis/television/channels/nix-recent.nix
#
# Recently modified Nix files, ordered by the portable helper in lib.nix.

{ televisionLib }:

''
  [metadata]
  name = "nix-recent"
  description = "Browse recently modified Nix files"
  requirements = ["find", "sort", "bat", "nvim", "zed"]

  [source]
  command = "${televisionLib.recent.source}"
  display = "{split:\\t:0}"
  no_sort = true
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
