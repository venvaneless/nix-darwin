# /Users/ven/dotfiles/nix/darwin/modules/services/ven-proof.nix

{ config, lib, ... }:

let
  rev =
    if config.system.configurationRevision == null
    then "unknown"
    else config.system.configurationRevision;
in
{
  # Append to the global extraActivation script
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo "FLAKE IS ALIVE" > /etc/ven-flake-proof
    echo "COMMIT = ${rev}" >> /etc/ven-flake-proof
  '';
}
