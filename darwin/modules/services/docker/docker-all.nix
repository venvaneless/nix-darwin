# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/docker-all.nix
#
# DOCKER: AGGREGATOR MODULE
# ============================================================
# - Declares the containerDefs option that docker.nix will use
# - Sets the containerDefs list (empty for now)
# - Imports docker.nix and vaultwarden.nix cleanly as modules
# ============================================================

{ config, pkgs, lib, ... }:

{
  # ----- Declare option -----
  options.containerDefs = lib.mkOption {
    type = lib.types.listOf lib.types.attrs;
    default = [ ];
    description = "List of mkContainer container definitions.";
  };

  # ----- Set Value -----
  config.containerDefs = [
    # Add your extra generic containers here
    # (import ./browsertrix.nix)
  ];

  # ----- Import docker + vaultwarden -----
  imports = [
    ./docker.nix
    ./vaultwarden.nix
  ];
}
