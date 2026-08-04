# darwin/services/docker/vaultwarden/vaultwarden-service.nix
#
# =====================================================================
# VAULTWARDEN SERVICE
#
# - Ensures data dir exists
# - Starts Vaultwarden through Docker Desktop
# - Uses Docker restart policy for container persistence
# - Creates a user LaunchAgent, not a system daemon
# =====================================================================

{
  config,
  pkgs,
  lib,
  ...
}:

let

  # Application name for the Vaultwarden container
  appName = "vaultwarden";

  dataDir = config.ven.vaultwarden.dataDir or "/Users/ven/.config/containers/vaultwarden";
  # Host port for Vaultwarden container (nginx will talk to this)
  hostPort = config.ven.vaultwarden.hostPort or 8080;

  # Internal container port for Vaultwarden (default HTTP)
  internalPort = config.ven.vaultwarden.internalPort or 80;

  # Environment variables for Vaultwarden container
  envVars = config.ven.vaultwarden.envVars or [ ];

  # User-specific directory for container data
  containersRoot = "/Users/ven/.config/containers";

  # Docker binary path for Docker Desktop on macOS
  dockerBin = "/Applications/Programming/Docker.app/Contents/Resources/bin/docker";

  # Concatenate environment variables into Docker run arguments
  envArgs = lib.concatStringsSep " " (map (v: "-e ${lib.escapeShellArg v}") envVars);

  # Ensure the data directory exists and has the correct permissions
  ensureDirScript = pkgs.writeShellScriptBin "ensure-${appName}-data" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo ">>> [vaultwarden] Ensuring data directory: ${dataDir}"
    mkdir -p "${containersRoot}"
    mkdir -p "${dataDir}"

    # Set permissions to 700 to restrict access to the owner only
    # ** '700' flag sets permissions to allowing only the owner to read, write and execute. This is important for sensitive data like Vaultwarden's database and configuration files.
    chmod 700 "${dataDir}"
  '';

  # Runner script to start Vaultwarden container
  runner = pkgs.writeShellScriptBin "run-${appName}" ''
        #!/usr/bin/env bash
        set -euo pipefail

        echo ">>> [vaultwarden] Starting Vaultwarden runner"

    	# Ensure the data directory exists before starting the container
        "${ensureDirScript}/bin/ensure-${appName}-data"

        # Check if Docker binary exists and is executable
        if [ ! -x "${dockerBin}" ]; then
          echo "!!! [vaultwarden] docker not found at ${dockerBin}"
          exit 1
        fi

        # Check if Docker is running by attempting to get Docker info
        echo ">>> [vaultwarden] Waiting for Docker engine..."
        # Check if Docker is ready, retrying up to 60 times with a 2-second interval
        docker_attempt=1

        # Limit the number of attempts to avoid infinite loops
        docker_attempt_limit=60

        # Wait for Docker to become ready
        until "${dockerBin}" info >/dev/null 2>&1; do

          # Set what happens if Docker is not ready after the maximum number of attempts
          if [ "$docker_attempt" -ge "$docker_attempt_limit" ]; then

          	# If Docker is not ready after the maximum number of attempts, print an error message and exit with a non-zero status
            echo "!!! [vaultwarden] Docker engine did not become ready"
            exit 1
          fi
          sleep 2
          # Increment the attempt counter
          docker_attempt=$((docker_attempt + 1))
        done

        # Docker is ready; proceed with starting the Vaultwarden container
        echo ">>> [vaultwarden] Docker engine ready"

        # Check if the Vaultwarden image is present; if not, pull it
        if ! "${dockerBin}" image inspect vaultwarden/server:latest >/dev/null 2>&1; then
          echo ">>> [vaultwarden] Pulling image"
          # Pull the latest Vaultwarden image from Docker Hub
          "${dockerBin}" pull vaultwarden/server:latest
        fi

        # Create the container when it does not exist.
        if ! "${dockerBin}" ps -a --format '{{.Names}}' | grep -qx "${appName}"; then
          echo ">>> [vaultwarden] Creating container"

          "${dockerBin}" run -d \
            --name "${appName}" \
            --restart unless-stopped \
            -p "${toString hostPort}:${toString internalPort}" \
            -v "${dataDir}:/data" \
            ${envArgs} \
            vaultwarden/server:latest
        else
          echo ">>> [vaultwarden] Container exists; updating restart policy"

          "${dockerBin}" update \
            --restart unless-stopped \
            "${appName}" \
            >/dev/null
        fi

        # Start the existing container. Do not hide failures such as
        # an occupied host port.
        echo ">>> [vaultwarden] Starting container"
        "${dockerBin}" start "${appName}" >/dev/null

        echo ">>> [vaultwarden] Done"
  '';
in
{
  # Set runner and ensureDirScript as system packages so they are available in PATH
  environment.systemPackages = [

    # runner is a helper script to start the Vaultwarden container; it is included in systemPackages for availability
    runner

    # ensureDirScript is a helper script to ensure the data directory exists; it is included in systemPackages for availability
    ensureDirScript

    # They both need to be in systemPackages so that they can be available in PATH for launchd to execute them, and also for manual execution if needed.
  ];

  # Stable runner path for launchd.
  environment.etc."ven/services/run-vaultwarden".source = "${runner}/bin/run-${appName}";

  # Activation script to ensure data directory exists before starting the service
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo ">>> [vaultwarden] Ensuring data dir via activation"
    ${ensureDirScript}/bin/ensure-${appName}-data || echo "!!! [vaultwarden] ensure data dir failed"
  '';

  # LaunchAgent configuration for Vaultwarden service
  launchd.agents.vaultwarden = {
    serviceConfig = {
      Label = "com.ven.vaultwarden";

      ProgramArguments = [
        "/etc/ven/services/run-vaultwarden"
      ];

      # Try once when the user logs in.
      RunAtLoad = true;

      # Retry only when the runner fails.
      #
      # When Vaultwarden starts successfully, the runner exits with status 0
      # and launchd leaves it stopped because Docker manages the container.
      #
      # When Docker is not ready or the container cannot start, the runner
      # exits non-zero and launchd tries again.
      KeepAlive = {
        SuccessfulExit = false;
      };

      # Avoid retrying too aggressively while Docker Desktop starts.
      ThrottleInterval = 30;

      ProcessType = "Background";

      StandardOutPath = "/tmp/com.ven.vaultwarden.out.log";
      StandardErrorPath = "/tmp/com.ven.vaultwarden.err.log";
    };
  };
}
