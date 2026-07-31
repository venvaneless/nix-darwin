# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/agents-pkgs.nix

{ pkgs, unstablePkgs, ... }:

{
  imports = [
    ./claude

    # Codex configuration and environment variables
    ./codex/codex.nix

    # Codex backup command and LaunchAgent
    ./codex/codex-backup.nix
  ];

  environment.systemPackages = [
    # Official Codex CLI from unstable nixpkgs
    unstablePkgs.codex

    # Patched codex-profile package provided by the local overlay
    pkgs.codex-profile
  ];
}