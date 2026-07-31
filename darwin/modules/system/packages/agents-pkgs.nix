# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/agents-pkgs.nix

{ pkgs, inputs, ... }:

let
  unstablePkgs = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;

    config = {
      allowUnfree = true;
    };
  };

  codexProfilePackage =
    pkgs.callPackage ./codex { };
in
{
  imports = [
    ./claude
  ];

  environment.systemPackages = [
    unstablePkgs.codex
    codexProfilePackage
  ];
}