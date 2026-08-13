# darwin/services/docker/browsertrix.nix
#
# BROWSERTRIX CRAWLER
# =====================================================================
# - Runs explicit, one-shot web-archiving crawls through Docker Desktop.
# - Stores generated WACZ collections outside the container.
# - Does not create a launchd job: crawling must be started deliberately.
# =====================================================================

{ config, pkgs, lib, ... }:

let
  cfg = config.services.browsertrix;

  appName = "browsertrix";

  # ---- SHARED PATHS ---- #
  # The persistent crawl collection directory comes from the
  # centralized path definitions.
  paths = import ../../../options/paths.nix { };

  dockerBin = "${pkgs.docker}/bin/docker";

  dockerWait = ''
    docker_attempt=1
    docker_attempt_limit=60

    until "${dockerBin}" info >/dev/null 2>&1; do
      if [ "$docker_attempt" -ge "$docker_attempt_limit" ]; then
        echo "!!! [${appName}] Docker engine did not become ready"
        exit 1
      fi

      sleep 2
      docker_attempt=$((docker_attempt + 1))
    done
  '';

  crawler = pkgs.writeShellScriptBin "${appName}-crawl" ''
    set -euo pipefail

    if [ "$#" -eq 0 ]; then
      echo "Usage: ${appName}-crawl --url <URL> [Browsertrix crawler options]"
      exit 64
    fi

    mkdir -p ${lib.escapeShellArg cfg.dataDir}
    chmod 700 ${lib.escapeShellArg cfg.dataDir}

    echo ">>> [${appName}] Waiting for Docker engine"
    ${dockerWait}

    exec "${dockerBin}" run --rm -it \
      --cpus ${lib.escapeShellArg cfg.cpuLimit} \
      --memory ${lib.escapeShellArg cfg.memoryLimit} \
      -v ${lib.escapeShellArg "${cfg.dataDir}:/crawls"} \
      ${lib.escapeShellArg cfg.image} \
      crawl \
      --workers ${toString cfg.workers} \
      --generateWACZ \
      --text \
      "$@"
  '';
in
{
  options.services.browsertrix = {
    enable = lib.mkEnableOption "Browsertrix Docker crawler";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = paths.darwin.docker.data.browsertrix;
      description = "Persistent directory for Browsertrix crawl collections and WACZ files.";
    };

    image = lib.mkOption {
      type = lib.types.str;
      default = "webrecorder/browsertrix-crawler:1.12.4";
      description = "Pinned Browsertrix Crawler image used for manual crawls.";
    };

    cpuLimit = lib.mkOption {
      type = lib.types.str;
      default = "2";
      description = "Maximum CPU cores Browsertrix may use while crawling.";
    };

    memoryLimit = lib.mkOption {
      type = lib.types.str;
      default = "1536m";
      description = "Maximum memory Browsertrix may use while crawling.";
    };

    workers = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Number of Browsertrix browser workers to run in parallel.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ crawler ];
  };
}
