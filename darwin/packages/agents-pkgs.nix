# darwin/packages/agents-pkgs.nix

{ inputs, lib, options, packageOptions, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ SHARED SETTINGS ------ #
  # ------------------------------------------------------------

  # ---- Variables from options/default.nix
  # The unstable package set is built once there, under the same
  # nixpkgs policy as the stable set.
  helpers = import ../../options { inherit inputs lib options pkgs; };
  inherit (helpers) unstablePkgs paths;

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
}
// packageOptions.mkPackageModule {
  name = "darwin-agents";
  packages = agentPackages;
}
