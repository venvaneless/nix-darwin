# shared/terminal/cli-tuis/television/channels/default.nix
#
# =====================================================================
# TELEVISION: NIX CHANNEL REGISTRY
#
# One registry keeps every available Nix channel visible without placing
# channel implementation in the Television module or global config file.
# =====================================================================

{ televisionLib }:

{
  nix = import ./nix.nix { inherit televisionLib; };
  nix-files = import ./nix-files.nix { inherit televisionLib; };
  nix-symbols = import ./nix-symbols.nix { inherit televisionLib; };
  nix-imports = import ./nix-imports.nix { inherit televisionLib; };
  nix-recent = import ./nix-recent.nix { inherit televisionLib; };
  nix-git = import ./nix-git.nix { inherit televisionLib; };
  nix-darwin = import ./nix-darwin.nix { inherit televisionLib; };
}
