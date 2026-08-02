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
      -v ${lib.escapeShellArg "${cfg.dataDir}:/crawls"} \
      ${lib.escapeShellArg cfg.image} \
      crawl \
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
      default = "/Users/ven/.config/containers/browsertrix";
      description = "Persistent directory for Browsertrix crawl collections and WACZ files.";
    };

    image = lib.mkOption {
      type = lib.types.str;
      default = "webrecorder/browsertrix-crawler:1.12.4";
      description = "Pinned Browsertrix Crawler image used for manual crawls.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ crawler ];
  };
}
