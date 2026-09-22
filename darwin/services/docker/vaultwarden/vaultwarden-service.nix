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
  paths,
  pkgs,
  lib,
  ...
}:

let
  # ---- SHARED PATHS ---- #
  # Container data root, the Docker Desktop CLI, and the launchd log
  # location come from the centralized path definitions.

  # Application name for the Vaultwarden container
  appName = "vaultwarden";

  dataDir = config.ven.vaultwarden.dataDir or paths.darwin.docker.data.vaultwarden;
  # Host port for Vaultwarden container (nginx will talk to this)
  hostPort = config.ven.vaultwarden.hostPort or 8080;

  # Internal container port for Vaultwarden (default HTTP)
  internalPort = config.ven.vaultwarden.internalPort or 80;

  # Environment variables for Vaultwarden container
  envVars = config.ven.vaultwarden.envVars or [ ];

  # Pinned image for the Vaultwarden container
  image = config.ven.vaultwarden.image or "vaultwarden/server:1.37.3";

  # Recreate marker
  # ** Docker cannot change the image or environment of an existing
  # ** container. The spec is hashed into a label so the runner can tell
  # ** a stale container apart from a current one and rebuild it.
  specHash = builtins.hashString "sha256" (lib.concatStringsSep "\n" ([
    image
    (toString hostPort)
    (toString internalPort)
    dataDir
  ] ++ envVars));

  # User-specific directory for container data
  containersRoot = paths.darwin.docker.data.root;

  # Docker binary path for Docker Desktop on macOS
  dockerBin = paths.darwin.docker.cli;

  # Stable /etc location of the generated runner
  # ** environment.etc keys are relative to /etc; launchd needs the
  # ** absolute form of the same file.
  runnerEtcPath = "${paths.darwin.system.venServicesTarget}/run-${appName}";
  runnerAbsolutePath = "${paths.darwin.system.venServices}/run-${appName}";

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

        # Pull the pinned image when it is not present locally
        if ! "${dockerBin}" image inspect ${lib.escapeShellArg image} >/dev/null 2>&1; then
          echo ">>> [vaultwarden] Pulling ${image}"
          "${dockerBin}" pull ${lib.escapeShellArg image}
        fi

        # Drop the container when its recorded spec no longer matches.
        # ** Without this the container keeps its original image and
        # ** environment forever, and config changes never take effect.
        if "${dockerBin}" ps -a --format '{{.Names}}' | grep -qx "${appName}"; then
          running_spec=$("${dockerBin}" inspect "${appName}" \
            --format '{{index .Config.Labels "com.ven.spec"}}' 2>/dev/null || echo "")

          if [ "$running_spec" != "${specHash}" ]; then
            echo ">>> [vaultwarden] Image or settings changed; recreating container"
            "${dockerBin}" rm -f "${appName}" >/dev/null
          fi
        fi

        # Create the container when it does not exist.
        if ! "${dockerBin}" ps -a --format '{{.Names}}' | grep -qx "${appName}"; then
          echo ">>> [vaultwarden] Creating container"

          "${dockerBin}" run -d \
            --name "${appName}" \
            --label "com.ven.spec=${specHash}" \
            --restart unless-stopped \
            -p "${toString hostPort}:${toString internalPort}" \
            -v "${dataDir}:/data" \
            ${envArgs} \
            ${lib.escapeShellArg image}
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
  # ** environment.etc targets are resolved below /etc, so the relative
  # ** form of the shared services directory is used here.
  environment.etc."${runnerEtcPath}".source = "${runner}/bin/run-${appName}";

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
        runnerAbsolutePath
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

      StandardOutPath = "${paths.darwin.system.tmp}/com.ven.vaultwarden.out.log";
      StandardErrorPath = "${paths.darwin.system.tmp}/com.ven.vaultwarden.err.log";
    };
  };
}
