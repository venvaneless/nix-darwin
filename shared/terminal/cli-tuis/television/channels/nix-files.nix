# shared/terminal/cli-tuis/television/channels/nix-files.nix
#
# Content search across Nix files. The Fish `tv` wrapper supplies a bare
# phrase as `--input`, while explicit Television flags pass through intact.

{ televisionLib }:

''
  [metadata]
  name = "nix-files"
  description = "Search lines inside Nix files"
  requirements = ["rg", "bat", "nvim", "zed"]

  [source]
  command = "${televisionLib.match.filesSource}"
  display = "{split:\\t:0}\t{split:\\t:3}"
  shell = "fish"

  [preview]
  command = "${televisionLib.match.preview} '{}'"
  shell = "fish"

  [keybindings]
  enter = "actions:nvim"

  [actions.nvim]
  description = "Open match in nvim"
  command = "${televisionLib.match.nvim} '{}'"
  shell = "fish"
  mode = "execute"

  [actions.zed]
  description = "Open match in Zed"
  command = "${televisionLib.match.zed} '{}'"
  shell = "fish"
  mode = "fork"

  [actions.copy-path]
  description = "Copy absolute path"
  command = "${televisionLib.match.copyAbsolute} '{}'"
  shell = "fish"

  [actions.copy-relative-path]
  description = "Copy relative path"
  command = "${televisionLib.match.copyRelative} '{}'"
  shell = "fish"
''
