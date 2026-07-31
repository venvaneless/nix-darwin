# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/agents-pkgs.nix

{ pkgs, inputs, ... }:

let
  unstablePkgs = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;

    config = {
      allowUnfree = true;
    };
  };
in
{
  imports = [
    # ./claude
    ./codex/codex.nix
  ];

  environment.systemPackages = [
    unstablePkgs.codex
    pkgs.codex-profile
  ];
}