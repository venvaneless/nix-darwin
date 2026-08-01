# darwin/services/startpage-launchd.nix
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
  # Define the application name for the Tartarus startpage service
  appName = "tartarus-startpage";
  # Tartarus is a personal startpage that provides quick access to frequently used links, tools, and information. It is designed to be lightweight and customizable, allowing users to create a personalized dashboard for their daily tasks and activities.

  # Path to the local startpage directory (must contain index.html)
  startpageDir =
    "/Users/ven/Library/Mobile Documents/com~apple~CloudDocs/Documents/system/services/tartarus-startpage/";

  # Network settings for the local server
  host = "127.0.0.1";
  port = 8787;

  # Create a shell script to run the local startpage server
  runner = pkgs.writeShellScriptBin "run-${appName}" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Print information about the service startup
    echo ">>> [${appName}] Starting local startpage server"
    echo ">>> [${appName}] Directory: ${startpageDir}"
    echo ">>> [${appName}] URL: http://${host}:${toString port}/index.html"

    # Check if the startpage directory exists and contains index.html
    if [ ! -d "${startpageDir}" ]; then
      echo "!!! [${appName}] Directory does not exist: ${startpageDir}"
      # If the directory is not found and the script cannot proceed, it will terminate the execution with an error code, signaling that the required directory is missing and preventing further execution of the script
      exit 1
    fi

    # Check if index.html exists in the startpage directory
    if [ ! -f "${startpageDir}/index.html" ]; then

      # If 'index.html' missing in the specified directory, print an error
      echo "!!! [${appName}] index.html not found"

      # If file is missing, the script will terminate with an error code
      exit 1
    fi

    # Change to the startpage directory
    cd "${startpageDir}"
    
    # Start the Python HTTP server
    exec ${pkgs.python3}/bin/python3 -m http.server ${toString port} --bind ${host}
  '';
in
{
  environment.systemPackages = [
    # Add the runner script to the system packages so it can be executed
    # ** 'runner' is a shell script that starts the local Tartarus startpage server using Python's built-in HTTP server. It checks for the existence of the specified directory and index.html file before starting the server, ensuring that the necessary files are in place.
    runner
  ];

  # Create a stable path for the runner script so the LaunchAgent does not point directly to a changing Nix store path
  environment.etc."ven/services/run-tartarus-startpage".source =
    "${runner}/bin/run-${appName}";

  # Define the LaunchAgent for the Tartarus startpage service
  launchd.agents.tartarus-startpage = {
    serviceConfig = {
      # Unique label for the LaunchAgent
      Label = "com.ven.tartarus-startpage";

      # Command to execute the runner script through its stable path
      ProgramArguments = [ "/etc/ven/services/run-tartarus-startpage" ];

      # Run the service at load and keep it alive
      RunAtLoad = true;
      KeepAlive = true;

      # Wait before restarting the service if the iCloud startpage directory is temporarily unavailable
      ThrottleInterval = 10;

      # Paths to log files for standard output and error
      StandardOutPath = "/tmp/com.ven.tartarus-startpage.out.log";
      StandardErrorPath = "/tmp/com.ven.tartarus-startpage.err.log";
    };
  };
}