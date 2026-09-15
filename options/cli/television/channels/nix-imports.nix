# shared/terminal/cli-tuis/television/channels/nix-imports.nix
#
# Import-focused content search, including imports blocks and relative paths.

{ televisionLib }:

''
  [metadata]
  name = "nix-imports"
  description = "Search Nix import declarations and relative module paths"
  requirements = ["rg", "bat", "nvim", "zed"]

  [source]
  command = "${televisionLib.match.importsSource}"
  display = "{split:\\t:0}\t{split:\\t:3}"
  shell = "fish"

  [preview]
  command = "${televisionLib.match.preview} '{}'"
  shell = "fish"

  [keybindings]
  enter = "actions:nvim"

  [actions.nvim]
  description = "Open import in nvim"
  command = "${televisionLib.match.nvim} '{}'"
  shell = "fish"
  mode = "execute"

  [actions.zed]
  description = "Open import in Zed"
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
