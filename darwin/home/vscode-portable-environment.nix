# darwin/home/vscode-portable-environment.nix
#
# =====================================================================
# DARWIN HOME MANAGER: VS CODE PORTABLE ENVIRONMENT
# =====================================================================
#
# Keeps VS Code in the user-owned portable state tree for every GUI
# launch after login. It never migrates, removes, or otherwise touches
# VS Code settings, extensions, chat sessions, or workspace data.
# =====================================================================

{ paths, pkgs, ... }:

let
  vscodePaths = paths.darwin.home.vscode;

  setPortableEnvironment = pkgs.writeShellScript "set-vscode-portable-environment" ''
    set -euo pipefail

    if [ ! -d "${vscodePaths.root}" ]; then
      echo "[vscode] Portable root is missing; no GUI environment was changed: ${vscodePaths.root}" >&2
      exit 0
    fi

    /bin/launchctl setenv VSCODE_PORTABLE "${vscodePaths.root}"
    /bin/launchctl setenv VSCODE_CLI_DATA_DIR "${vscodePaths.cli}"
  '';
in
{
  launchd.agents.vscodePortableEnvironment = {
    config = {
      Label = "com.ven.vscode-portable-environment";
      ProgramArguments = [ "${setPortableEnvironment}" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };
}