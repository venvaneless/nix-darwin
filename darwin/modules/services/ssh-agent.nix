# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/ssh-agent.nix
#
# DARWIN: SSH AGENT
# =========================
# Starts a user-level ssh-agent through launchd
# and exposes a fixed SSH_AUTH_SOCK path for
# shells and GUI apps like WezTerm.

{ ... }:

{
  # Fixed socket path visible to shells and GUI apps
  environment.variables.SSH_AUTH_SOCK = "/tmp/ssh-agent.sock";

  launchd.user.agents.ssh-agent = {
    serviceConfig = {
      Label = "local.ssh-agent";

      ProgramArguments = [
        "/usr/bin/ssh-agent"
        "-D"
        "-a"
        "/tmp/ssh-agent.sock"
      ];

      RunAtLoad = true;
      KeepAlive = true;

      StandardOutPath = "/tmp/ssh-agent.log";
      StandardErrorPath = "/tmp/ssh-agent.err";
    };
  };
}