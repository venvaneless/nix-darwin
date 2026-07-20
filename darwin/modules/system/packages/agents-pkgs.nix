{ pkgs, ... }:

{
  imports = [
    ./codex/codex.nix
  ];

  environment.systemPackages = with pkgs; [
  	codex
    codex-profile
  ];
}