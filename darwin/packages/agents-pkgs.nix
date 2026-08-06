# darwin/packages/agents-pkgs.nix

{ pkgs, unstablePkgs, ... }:

{
  imports = [
    ./claude

    # Codex configuration and environment variables
    ./codex/codex.nix

    # Declarative shared Codex plugins and MCP synchronization command
    ./codex/extensions.nix

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
