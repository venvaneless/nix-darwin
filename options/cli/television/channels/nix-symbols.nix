# shared/terminal/cli-tuis/television/channels/nix-symbols.nix
#
# Semi-structured search for common Nix module definitions and namespaces.

{ televisionLib }:

''
  [metadata]
  name = "nix-symbols"
  description = "Search common Nix symbols and module definitions"
  requirements = ["rg", "bat", "nvim", "zed"]

  [source]
  command = "${televisionLib.match.symbolsSource}"
  display = "{split:\\t:0}\t{split:\\t:3}"
  shell = "fish"

  [preview]
  command = "${televisionLib.match.preview} '{}'"
  shell = "fish"

  [keybindings]
  enter = "actions:nvim"

  [actions.nvim]
  description = "Open symbol in nvim"
  command = "${televisionLib.match.nvim} '{}'"
  shell = "fish"
  mode = "execute"

  [actions.zed]
  description = "Open symbol in Zed"
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
