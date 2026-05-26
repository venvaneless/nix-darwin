# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/vaultwarden/vaultwarden.nix
#
# VAULTWARDEN: CONTAINER DEFINITION
# =================================
# - Defines Vaultwarden image, ports, env vars, and data path.
# - Service/launchd wiring is in vaultwarden-service.nix.
# =================================

{ config, pkgs, lib, ... }:

let
  # Shared paths for Vaultwarden
  dataDir = "/Users/ven/.config/containers/vaultwarden";

  # Internal container port (Vaultwarden default HTTP)
  internalPort = 80;

  # Host port (nginx will talk to this)
  hostPort = 8080;

  envVars = [
    "WEBSOCKET_ENABLED=true"
    "ENABLE_DB_WAL=false"
    "ROCKET_LIMITS={forms=\"64KiB\"}"
    "PASSWORD_ITERATIONS=100000"
    "PASSWORD_HINTS=true"
  ];
in
{
  # Export a config subtree so other modules (service/nginx/mkcert) can reuse
  # these paths and settings if needed in the future.
  options.ven.vaultwarden = {
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = dataDir;
      description = "Data directory for Vaultwarden";
    };

    hostPort = lib.mkOption {
      type = lib.types.int;
      default = hostPort;
      description = "Host port where Vaultwarden container listens";
    };

    internalPort = lib.mkOption {
      type = lib.types.int;
      default = internalPort;
      description = "Internal container port for Vaultwarden";
    };

    envVars = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = envVars;
      description = "Environment variable list for Vaultwarden container";
    };
  };

  config = { };
}
