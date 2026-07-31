# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/claude/claude.nix

{ pkgs, ... }:

let
  claudeEnvironment = {
    CLAUDE_CONFIG_DIR = "/Users/ven/.config/.claude";
    CLAUDE_MEM_DATA_DIR = "/Users/ven/.config/.claude-mem";
    CLAUDE_CODE_PATH = "/run/current-system/sw/bin/claude";

    # Claude Code is updated through nix-darwin.
    DISABLE_AUTOUPDATER = "1";

    # Keep npx/npm files out of your home-folder root.
    NPM_CONFIG_USERCONFIG = "/Users/ven/.config/npm/npmrc";
    NPM_CONFIG_CACHE = "/Users/ven/.config/npm/cache";
  };
in
{
  environment.variables = claudeEnvironment;
  launchd.user.envVariables = claudeEnvironment;

  environment.systemPackages = [
    pkgs.claude-code
  ];
}