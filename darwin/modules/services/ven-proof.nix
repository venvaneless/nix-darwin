# /Users/ven/dotfiles/nix/darwin/modules/services/ven-proof.nix
{ config, lib, ... }:

let
  rev =
    if config.system.configurationRevision == null
    then "unknown"
    else config.system.configurationRevision;
in
{
  system.activationScripts.venProof.text = ''
    echo "FLAKE IS ALIVE" > /etc/ven-flake-proof
    echo "COMMIT = ${rev}" >> /etc/ven-flake-proof
  '';
}
