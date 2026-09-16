# darwin/packages/agents-pkgs.nix

{ packageOptions, paths, pkgs, symlinks, unstablePkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ SHARED SETTINGS ------ #
  # ------------------------------------------------------------

  # The host passes these values from options/default.nix through
  # specialArgs, so package modules do not evaluate option helpers directly.

  # ------------------------------------------------------------
  # ------ AGENT PACKAGE DEFINITIONS ------ #
  # ------------------------------------------------------------

  agentPackages = {
    # Official Codex CLI from unstable nixpkgs.
    codex = {
      enable = true;
      installOn = { darwin = true; linux = false; };
      package = unstablePkgs.codex;
    };

    # Patched codex-profile package provided by the local overlay.
    codexProfile = {
      enable = true;
      installOn = { darwin = true; linux = false; };
      package = pkgs.codex-profile;
    };
  };
in
{
  imports = [
    ./claude

    # Codex configuration and environment variables
    ./codex/codex.nix

    # Declarative shared Codex plugins and MCP synchronization command
    ./codex/extensions

    # Codex backup command
    ./codex/codex-backup.nix
  ];
}
// packageOptions.mkPackageModule {
  name = "darwin-agents";
  packages = agentPackages;
  inherit symlinks;
}
