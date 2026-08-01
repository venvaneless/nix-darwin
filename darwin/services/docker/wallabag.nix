# darwin/services/docker/wallabag.nix

{ config, pkgs, lib, ... }:

let
  # Main macOS user that owns the Wallabag data directories
  userName = "ven";

  # Home directory of the main macOS user
  userHome = "/Users/${userName}";

  # Root directory for persistent Docker container data
  containersDir = "${userHome}/.config/containers";

  # Persistent data directory used specifically by Wallabag
  wallabagDataDir = "${containersDir}/wallabag";

  cfg = config.services.wallabag;

  appName = "wallabag";

  # Unique launchd service label for Wallabag
  serviceLabel = "com.${userName}.${appName}";

  # Relative /etc path used for the stable Wallabag runner
  runnerEtcPath = "${userName}/services/run-${appName}";


  # Docker Compose file for Wallabag service
  composeFile = pkgs.writeText "wallabag-compose.yml" ''
    services:
      wallabag:
        image: wallabag/wallabag:latest
        container_name: wallabag
        restart: unless-stopped
        ports:
          - "${toString cfg.port}:80"
        environment:
          SYMFONY__ENV__DOMAIN_NAME: ${cfg.domainName}
        volumes:
          - ${cfg.dataDir}/data:/var/www/wallabag/data
          - ${cfg.dataDir}/images:/var/www/wallabag/web/assets/images
  '';

  # Runner script for Wallabag service
  runner = pkgs.writeShellScriptBin "run-${appName}" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Docker Desktop credential helpers are not included in launchd's
    # default PATH, so add Docker Desktop's executable directory.
    export PATH="/Applications/Programming/Docker.app/Contents/Resources/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin"

    # Ensure that the Wallabag data directory and its subdirectories exist
    mkdir -p "${cfg.dataDir}/data"
    mkdir -p "${cfg.dataDir}/images"
    mkdir -p "${cfg.dataDir}/logs"

    # Set the correct permissions
    # ** `chmod u+rwx,g+rwx,o+rx`: Grants read, write, and execute permissions to the owner (user) and group, while granting read and execute permissions to others for the specified directories.
    chmod u+rwx,g+rwx,o+rx \
      "${cfg.dataDir}" \
      "${cfg.dataDir}/data" \
      "${cfg.dataDir}/images" \
      "${cfg.dataDir}/logs"

    # This command ensures that the Wallabag data directory and its contents are accessible to Docker, allowing the Wallabag container to read and write data as needed.
    echo ">>> [${appName}] Waiting for Docker daemon"

    # ---- WAIT FOR DOCKER DAEMON
    # Attempt counter to track the number of attempts to check Docker daemon readiness
    docker_attempt=1

    # Set a limit for the number of attempts to check Docker daemon readiness
    docker_attempt_limit=60

    # Wait for Docker daemon to be ready
    until ${pkgs.docker_29}/bin/docker info >/dev/null 2>&1; do

      # Print a message indicating that Docker is not ready and the current attempt number
      if [ "$docker_attempt" -ge "$docker_attempt_limit" ]; then
        echo "!!! [${appName}] Docker daemon did not become ready"

        # Terminate the script with error, due to Docker daemon not being ready after a specified number of attempts
        exit 1
      fi

      # Pause the script for 2 seconds before the next attempt to check if Docker daemon is ready.
      # ** It prevents the script from continuously checking without any delay, preventing excessive CPU and Docker deamon to become overloaded.  
      sleep 2
      # Increment the attempt counter
      docker_attempt=$((docker_attempt + 1))
    done
    # Print a message indicating that Docker is ready
    echo ">>> [${appName}] Docker is ready"
    echo ">>> [${appName}] Starting Wallabag"
    echo ">>> [${appName}] URL: ${cfg.domainName}"

    # Run Docker Compose to start Wallabag

    # Set the project name for Docker Compose to avoid conflicts with other projects

    # Specify the Docker Compose file to use for the Wallabag service

    # Run Docker Compose in detached mode, allowing the service to run in the background

    # Run in "detached mode," to allow the Docker Compose command to run in the background
    # ** This is useful for services that need to run continuously without blocking the terminal session and allows for freeing up the terminal for other tasks

    # Remove any orphaned containers that are not defined in the current Docker Compose file, ensuring a clean environment
    ${pkgs.docker-compose}/bin/docker-compose \
      -p "${appName}" \
      -f "${composeFile}" \
      up \
      -d \
      --remove-orphans

    # Print a message indicating that Wallabag is running
    echo ">>> [${appName}] Wallabag is running"
  '';
  
in
{

  # ------------------------------------------------------------------------ #
  # ------ WALLABAG SERVICE OPTIONS ------ #
  options.services.wallabag = {
  	# Enable the Wallabag service
    enable = lib.mkEnableOption "Wallabag Docker service";

    # Local port for Wallabag service
    port = lib.mkOption {
      # Define the type of the option as a port number
      type = lib.types.port;

      # Set the default port number for the Wallabag service
      default = 8989;

      # Provide a description for the option, explaining its purpose
      description = "Local port for Wallabag.";
    };

    # Persistent data directory for Wallabag service
    dataDir = lib.mkOption {
      # Define the type of the option as a string
      type = lib.types.str;

      # Set the default path for the Wallabag data directory, where persistent data will be stored
      default = wallabagDataDir;

      # Provide a description for the option, explaining its purpose
      description = "Persistent Wallabag data directory.";
    };

    # Public URL for Wallabag service
    domainName = lib.mkOption {
      # Define the type of the option as a string
      type = lib.types.str;

      # Set the default public URL for the Wallabag service, which can be accessed externally
      default = "http://127.0.0.1:8989";

      # Provide a description for the option, explaining its purpose
      description = "Wallabag public URL.";
    };
  };

  # Enable the Wallabag service and configure its environment
  config = lib.mkIf cfg.enable {

  	# Add the Wallabag runner script to the system packages, making it available for execution
    environment.systemPackages = [ runner ];

    # Stable runner path for launchd.
    environment.etc."${runnerEtcPath}".source =
      "${runner}/bin/run-${appName}";

    # Activation script for setting up Wallabag data directories and correct permissions
    system.activationScripts.ensureWallabagDataDir.text = lib.mkAfter ''
      echo ">>> [wallabag] Ensuring data directories"

      # Create the Wallabag data directory and its subdirectories with the correct permissions
      # ** '-d': Create directories, including any necessary parent directories
      # ** '-m 0775': Set the permissions of the created directories to 0775, allowing the owner and group to read, write, and execute, while others can read and execute
      # ** '-o ven': Set the owner of the created directories to the user 'ven'
      # ** '-g staff': Set the group of the created directories to 'staff'

      # Path to the Wallabag data directory
      /usr/bin/install -d -m 0775 -o ${userName} -g staff "${cfg.dataDir}"

      # Wallabag's persistent data storage directory
      /usr/bin/install -d -m 0775 -o ${userName} -g staff "${cfg.dataDir}/data"

      # Wallabag's images storage directory
      /usr/bin/install -d -m 0775 -o ${userName} -g staff "${cfg.dataDir}/images"

      # Wallabag service logs directory
      /usr/bin/install -d -m 0775 -o ${userName} -g staff "${cfg.dataDir}/logs"

      # Set the correct permissions for the Wallabag data directory and its contents
      /usr/sbin/chown -R ${userName}:staff "${cfg.dataDir}" || true

      # ---- NOTE: FLAGS AND EXPLANATION OF THE `chown` COMMAND ---- #
      # ** `chown`: Change the ownership of the specified directory and its contents to the user 'ven' and group 'staff'
      
      # ** '-R': Apply the ownership change recursively to all files and subdirectories within the specified directory
      
      # ** '${userName}:staff': Specify the configured owner and the 'staff' group for the directory and its contents
      
      # "${cfg.dataDir}": The path to the Wallabag data directory, which is specified as variable in the configuration options and will be created if it does not already exist
      
      # ** `|| true`: Ensures that the script continues executing even if the `chown` command fails (e.g., if the user or group does not exist), preventing the script from terminating prematurely due to an error
      # ------------------------------------------------------------------------ #
    '';
    # ------------------------------------------------------------------------ #

    
    # ------------------------------------------------------------------------ #
    # ------ LAUNCHD SERVICE CONFIGURATION ------ #

    # Define the LaunchAgent for the Wallabag service
    # ** Manage the service's lifecycle and ensure it runs in the background
    launchd.agents.wallabag = {

      # Define the configuration for the Wallabag LaunchAgent
      serviceConfig = {

     	# Unique label for the LaunchAgent
     	# ** This label is used to identify the service in the system and can be used for managing the service (e.g., starting, stopping, or checking its status)
        Label = serviceLabel;

        # Command to execute the Wallabag runner script
        ProgramArguments = [ "/etc/${runnerEtcPath}" ];

        # Run service at load, start automatically on system boot or user login
        RunAtLoad = true;

        # Keep the service alive and automatically restart if it exits unexpectedly
        KeepAlive = {

          # Restart the service if it exits with a non-zero status code
          # ** 'nonzero' status code indicates an error or unexpected termination, after which the service will be restarted
          SuccessfulExit = false;
        };

        ThrottleInterval = 10; # Minimum time interval (in seconds) between restarts to prevent rapid restart loops

        # Paths to log files for standard output and error
        StandardOutPath = "${cfg.dataDir}/logs/wallabag.log";
        StandardErrorPath = "${cfg.dataDir}/logs/wallabag-error.log";
      };
    };
    # ------------------------------------------------------------------------ #
  };
}