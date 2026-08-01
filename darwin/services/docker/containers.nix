# darwin/services/docker/containers.nix
#
# =====================================================================
# DOCKER CONTAINERS (DARWIN-ONLY HELPER)
# - Provides mkContainer helper for future use.
# - Only defines launchd services (no systemd here).
# =====================================================================

{ config, pkgs, lib, ... }:

let
  # Root directory for container data
  containersRoot = "/Users/ven/.config/containers";

  # Docker binary for Docker Desktop on macOS
  dockerBin =
    "/Applications/Programming/Docker.app/Contents/Resources/bin/docker";

  # Helper function to declare a Docker container
  mkContainer =
  	# Use named arguments for clarity
    { name
    # Image Docker to run
    , image
    # Ports to expose
    , ports ? []
    # Additional volumes to mount
    , extraVolumes ? []

    # Additional arguments to pass to the docker run command
    , extraArgs ? []

    # Whether to run the container at load (default: true)
    , runAtLoad ? true

    # Whether to keep the container alive (default: true)
    , keepAlive ? true
    }:
    let
      # Lowercase container name for consistency
      cName   = lib.toLower name;

      # Data directory for the container
      dataDir = "${containersRoot}/${cName}";

      # Construct port arguments for docker run
      portArgs =
      	# Map each port to a "-p" argument and concatenate them with spaces
        lib.concatStringsSep " "
          (map (p: "-p ${p}") ports);

	  # Construct volume arguments for docker run          
      volumeArgs =
        "-v ${dataDir}:/data "
        + lib.concatStringsSep " "
            (map (v: "-v ${v}") extraVolumes);

      # Construct additional arguments for docker run
      args = lib.concatStringsSep " " extraArgs;

	  # Script to ensure the data directory exists with correct permissions      
      ensureDirScript = pkgs.writeShellScriptBin "ensure-${cName}-data" ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Ensure the data directory exists with correct permissions
        echo ">>> [container:${cName}] Ensuring data dir: ${dataDir}"
        mkdir -p "${dataDir}"
        chmod 700 "${dataDir}"
      '';

	  # Runner script to start or run the Docker container      
      runner = pkgs.writeShellScriptBin "run-${cName}" ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Print a message indicating the container is starting
        echo ">>> [container:${cName}] Starting..."
        "${ensureDirScript}/bin/ensure-${cName}-data"

        # Check if the Docker binary exists
        if ! command -v "${dockerBin}" >/dev/null 2>&1; then
          # If Docker binary is not found, print an error message and exit
          echo "!!! [container:${cName}] docker not found at ${dockerBin}"
          exit 1
        fi

		# Attempt to start the container; if it doesn't exist, run it        
        "${dockerBin}" start ${cName} || \
        "${dockerBin}" run -d \
          --name ${cName} \
          ${portArgs} \
          ${volumeArgs} \
          ${args} \
          ${image}
      '';
    in
    {
      # Ensure data dir exists at activation time
      system.activationScripts."ensure-${cName}-data".text = ''
        "${ensureDirScript}/bin/ensure-${cName}-data"
      '';

      # Expose runner
      environment.systemPackages = [ runner ];

      # launchd only (Darwin)
      launchd.daemons."docker-${cName}" = {
        serviceConfig = {
          Label            = "com.ven.docker.${cName}";
          ProgramArguments = [ "${runner}/bin/run-${cName}" ];
          RunAtLoad        = runAtLoad;
          KeepAlive        = keepAlive;
        };
      };
    };

in
{
  # Provide mkContainer helper function to the user
  options.ven.docker.mkContainer = lib.mkOption {
    # Set the type to anything to allow for flexible usage
    type = lib.types.anything;

    # Set the default value to the mkContainer function defined above
    default = mkContainer;

    # Set a description for the option
    description = "Helper function to declare Docker containers (Darwin only).";
  };

  config = { };
}
