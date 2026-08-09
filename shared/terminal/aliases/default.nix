# shared/terminal/aliases/default.nix
#
# =====================================================================
# FISH: PORTABLE ALIASES
# =====================================================================

{ ... }:

{
  imports = [
    ./shell-aliases.nix
    ./git-aliases.nix
    ./gc-aliases.nix
    ./nix-aliases.nix
  ];
}
