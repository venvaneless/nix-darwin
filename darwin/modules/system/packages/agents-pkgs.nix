{ pkgs, ... }:

{
  imports = [
    ./codex/codex.nix
  ];

  environment.systemPackages = with pkgs; [
  	chatgpt
  	codex
    codex-profile
  ];
}