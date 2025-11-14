# /Users/ven/dotfiles/nix/darwin/modules/services/ven-proof.nix
#
# SYSTEM: FLAKE PROOF
# ============================================================
# Writes a proof file on every darwin-rebuild switch so we can
# see which Git revision the system was built from.
# ============================================================

{ config, lib, ... }:

let
  # If nix-darwin can't detect a revision (e.g. not a git repo),
  # configurationRevision will be null, so we default to "unknown".
  rev = config.system.configurationRevision or "unknown";
in
{
  # ----- Simple proof activation script -----
  system.activationScripts.venProof.text = ''
    echo "FLAKE IS ALIVE" > /etc/ven-flake-proof
    echo "COMMIT = ${rev}" >> /etc/ven-flake-proof
  '';
}
