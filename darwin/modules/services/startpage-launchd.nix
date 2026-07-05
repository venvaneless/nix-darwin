# /Users/ven/.config/nix/nix-config/darwin/modules/services/startpage-launchd.nix
#
# =====================================================================
# TARTARUS STARTPAGE SERVICE
#
# - Serves Tartarus startpage locally
# - Uses Python's built-in HTTP server
# - Runs as a user LaunchAgent
# - Starts automatically at login
# - No Terminal window needed
# =====================================================================

{ config, pkgs, lib, ... }:

let
  appName = "tartarus-startpage";

  startpageDir =
    "/Users/ven/Library/Mobile Documents/com~apple~CloudDocs/my-system/system-assets/00-installation-files/tartarus-startpage";

  host = "127.0.0.1";
  port = 8787;

  runner = pkgs.writeShellScriptBin "run-${appName}" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [${appName}] Starting local startpage server"
    echo ">>> [${appName}] Directory: ${startpageDir}"
    echo ">>> [${appName}] URL: http://${host}:${toString port}/index.html"

    if [ ! -d "${startpageDir}" ]; then
      echo "!!! [${appName}] Directory does not exist: ${startpageDir}"
      exit 1
    fi

    if [ ! -f "${startpageDir}/index.html" ]; then
      echo "!!! [${appName}] index.html not found"
      exit 1
    fi

    cd "${startpageDir}"

    exec ${pkgs.python3}/bin/python3 -m http.server ${toString port} --bind ${host}
  '';
in
{
  environment.systemPackages = [
    runner
  ];

  launchd.agents.tartarus-startpage = {
    serviceConfig = {
      Label = "com.ven.tartarus-startpage";
      ProgramArguments = [ "${runner}/bin/run-${appName}" ];

      RunAtLoad = true;
      KeepAlive = true;

      StandardOutPath = "/tmp/com.ven.tartarus-startpage.out.log";
      StandardErrorPath = "/tmp/com.ven.tartarus-startpage.err.log";
    };
  };
}