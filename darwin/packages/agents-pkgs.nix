# darwin/packages/agents-pkgs.nix

{ lib, options, pkgs, unstablePkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ SHARED PACKAGE HELPERS ------ #
  # ------------------------------------------------------------

  helpers = import ../../options { inherit lib options pkgs; };
  inherit (helpers) paths;

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

    # Dock launcher that always opens the ChatGPT Codex profile.
    codexChatgptLauncher = {
      enable = true;
      installOn = { darwin = true; linux = false; };
      package = pkgs.callPackage ./codex/chatgpt-launcher.nix {
        inherit paths;
      };
      appName = "Codex ChatGPT.app";
      symlinkApplications = true;
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

    # Codex backup command and LaunchAgent
    ./codex/codex-backup.nix
  ];

  config = helpers.packageOptions.mkPackageModule {
    name = "darwin-agents";
    packages = agentPackages;
  };
}
