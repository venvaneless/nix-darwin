# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/docker-all.nix
#
# DOCKER: AGGREGATOR MODULE
# ============================================================
# - Imports:
#       docker.nix          → Docker Desktop + mkContainer system
#       vaultwarden.nix     → Vaultwarden container + nginx + certs
#
# - Exports:
#       containerDefs        → list of mkContainer containers (empty for now)
#
# docker.nix will import this file to read containerDefs.
# index.nix should import ONLY THIS FILE.
# ============================================================

{ pkgs, lib, ... }:

{
  # ----- This file only provides the container list -----
  containerDefs = [
    # Add your extra containers here later:
    # (import ./redis.nix)
    # (import ./browsertrix.nix)
  ];

  # ----- And it imports the two real modules -----
  imports = [
    ./docker.nix
    ./vaultwarden.nix
  ];
}
