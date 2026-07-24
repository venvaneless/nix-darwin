# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/agents-pkgs.nix

{ pkgs, inputs, ... }:

let
  unstablePkgs = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;

    config = {
      allowUnfree = true;
    };
  };

  claudeEnvironment = {
    CLAUDE_CONFIG_DIR = "/Users/ven/.config/.claude";
    CLAUDE_MEM_DATA_DIR = "/Users/ven/.config/.claude-mem";
    CLAUDE_CODE_PATH = "/run/current-system/sw/bin/claude";

    # Claude Code is updated through nix-darwin.
    DISABLE_AUTOUPDATER = "1";
  };
in
{
  imports = [
    ./codex/codex.nix
  ];

  environment.variables = claudeEnvironment;
  launchd.user.envVariables = claudeEnvironment;

  environment.systemPackages = [
    unstablePkgs.codex
    pkgs.claude-code
    pkgs.codex-profile
  ];
}
