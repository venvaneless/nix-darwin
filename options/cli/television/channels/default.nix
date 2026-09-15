# options/cli/television/channels/default.nix
#
# =====================================================================
# TELEVISION: NIX CHANNEL REGISTRY
#
# One registry keeps every available Nix channel visible without placing
# channel implementation in the Television module or global config file.
# =====================================================================

{ lib, televisionLib, channels }:

lib.optionalAttrs channels.nix.enable { nix = import ./nix.nix { inherit televisionLib; }; }
// lib.optionalAttrs channels.nixFiles.enable { nix-files = import ./nix-files.nix { inherit televisionLib; }; }
// lib.optionalAttrs channels.nixSymbols.enable { nix-symbols = import ./nix-symbols.nix { inherit televisionLib; }; }
// lib.optionalAttrs channels.nixImports.enable { nix-imports = import ./nix-imports.nix { inherit televisionLib; }; }
// lib.optionalAttrs channels.nixRecent.enable { nix-recent = import ./nix-recent.nix { inherit televisionLib; }; }
// lib.optionalAttrs channels.nixGit.enable { nix-git = import ./nix-git.nix { inherit televisionLib; }; }
// lib.optionalAttrs channels.nixDarwin.enable { nix-darwin = import ./nix-darwin.nix { inherit televisionLib; }; }
