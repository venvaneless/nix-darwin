# darwin/services/docker/vaultwarden/vaultwarden.nix
#
# =====================================================================
# VAULTWARDEN: CONTAINER DEFINITION
#
# - Defines Vaultwarden ports, environment variables and data path
# - Service and launchd wiring is in vaultwarden-service.nix
# =====================================================================

{ lib, ... }:

let
  # Shared paths for Vaultwarden
  dataDir = "/Users/ven/.config/containers/vaultwarden";

  # Internal container port
  internalPort = 80;

  # Host port used by nginx
  hostPort = 8080;

  # Container environment variables
  envVars = [
  	# Set the domain for Vaultwarden (used for generating links, etc.)
    "DOMAIN=https://vaultwarden.local"

    # Enable WebSocket support for real-time updates
    "WEBSOCKET_ENABLED=true"

    # Disable database write-ahead logging (WAL) for performance
    "ENABLE_DB_WAL=false"

    # Set the maximum size for uploaded files
    "ROCKET_LIMITS={forms=\"64KiB\"}"

    # Set the number of iterations for password hashing
    "PASSWORD_ITERATIONS=100000"

    # Enable password hints for users
    "PASSWORD_HINTS=true"
  ];
in
{
  #------ EXPORT CONFIG SUBTREE FOR REUSE
  # ** Allows for other modules to reuse these paths and settings if needed in the future
  options.ven.vaultwarden = {
  	# Define the Vaultwarden configuration options
    dataDir = lib.mkOption {

      # Data directory for Vaultwarden container
      type = lib.types.str;

      # Default value for the data directory
      default = dataDir;

      # Description for the data directory option
      description = "Data directory for Vaultwarden.";
    };

    # ---- PORT CONFIGURATION
    hostPort = lib.mkOption {
      # Host port for the Vaultwarden container
      type = lib.types.port;

      # Default host port for Vaultwarden container
      default = hostPort;

      # Description for the host port option
      description = "Host port where the Vaultwarden container listens.";
    };

    # ---- INTERNAL PORT
    internalPort = lib.mkOption {

      # Internal port for the Vaultwarden container
      type = lib.types.port;

      # Default internal port for the Vaultwarden container
      default = internalPort;

      # Description for the internal port option
      description = "Internal port used by the Vaultwarden container.";
    };

	# ---- ENVIRONMENT VARIABLES    
    envVars = lib.mkOption {

      # Environment variable list for Vaultwarden container
      type = lib.types.listOf lib.types.str;

      # Default environment variable list for Vaultwarden container
      default = envVars;

      # Description for the environment variable list option
      description = "Environment variables passed to the Vaultwarden container.";
    };
  };

  # Export a config subtree for the Vaultwarden container definition
  config = { };
}