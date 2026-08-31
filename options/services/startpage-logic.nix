# options/services/startpage-logic.nix
#
# =====================================================================
# OPTIONS: STARTPAGE
#
# Defines a portable local HTTP service for a user-selected startpage
# directory. Platform modules provide the appropriate user-service host.
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.services.startpage;

  # A trailing slash is accepted in the configured directory, while the
  # runner always addresses one normalized index-file path.
  directory = lib.removeSuffix "/" cfg.directory;
  indexPath = "${directory}/${cfg.indexFile}";

  # The runner creates only its local log directory. The startpage
  # directory is read-only from the service's point of view.
  runner = pkgs.writeShellScript "tartarus-startpage" ''
    set -euo pipefail

    ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg cfg.logDirectory}
    exec >>${lib.escapeShellArg "${cfg.logDirectory}/tartarus-startpage.out.log"} 2>>${lib.escapeShellArg "${cfg.logDirectory}/tartarus-startpage.err.log"}

    echo ">>> [tartarus-startpage] Starting local startpage server"
    echo ">>> [tartarus-startpage] Directory: ${directory}"
    echo ">>> [tartarus-startpage] URL: http://${cfg.host}:${toString cfg.port}/${cfg.indexFile}"

    if [ ! -d ${lib.escapeShellArg directory} ]; then
      echo "!!! [tartarus-startpage] Directory does not exist: ${directory}"
      exit 1
    fi

    if [ ! -f ${lib.escapeShellArg indexPath} ]; then
      echo "!!! [tartarus-startpage] ${cfg.indexFile} not found: ${indexPath}"
      exit 1
    fi

    cd ${lib.escapeShellArg directory}
    exec ${pkgs.python3}/bin/python3 -m http.server ${toString cfg.port} --bind ${lib.escapeShellArg cfg.host}
  '';
in
{
  options.ven.services.startpage = lib.mkOption {
    type = lib.types.submodule {
      options = {
        enable = lib.mkEnableOption "local Tartarus startpage service";

        directory = lib.mkOption {
          type = lib.types.str;
          default = "${config.home.homeDirectory}/Documents/system/services/tartarus-startpage";
          description = "Directory containing the startpage index file.";
        };

        indexFile = lib.mkOption {
          type = lib.types.str;
          default = "index.html";
          description = "Startpage file served at the local root URL.";
        };

        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "Address on which the local startpage server listens.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 8787;
          description = "Local TCP port for the startpage server.";
        };

        runAtLoad = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Start the local startpage service when the user session starts.";
        };

        keepAlive = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Restart the startpage service after it exits unexpectedly.";
        };

        throttleInterval = lib.mkOption {
          type = lib.types.ints.positive;
          default = 10;
          description = "Seconds launchd waits before restarting a failed startpage service.";
        };

        logDirectory = lib.mkOption {
          type = lib.types.str;
          default = "${config.home.homeDirectory}/.local/state/tartarus-startpage";
          description = "Directory used for startpage service logs.";
        };
      };
    };

    default = { };
    description = "Per-machine settings for the local Tartarus startpage service.";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf pkgs.stdenv.isDarwin {
      launchd.agents.tartarus-startpage = {
        enable = true;

        config = {
          Label = "com.ven.tartarus-startpage";
          ProgramArguments = [ "${runner}" ];
          RunAtLoad = cfg.runAtLoad;
          KeepAlive = cfg.keepAlive;
          ThrottleInterval = cfg.throttleInterval;
        };
      };
    })

    (lib.mkIf pkgs.stdenv.isLinux {
      systemd.user.services.tartarus-startpage = {
        Unit = {
          Description = "Serve the Tartarus startpage";
        };

        Service = {
          ExecStart = "${runner}";
          Restart = if cfg.keepAlive then "on-failure" else "no";
          RestartSec = cfg.throttleInterval;
        };

        Install = lib.optionalAttrs cfg.runAtLoad {
          WantedBy = [ "default.target" ];
        };
      };
    })
  ]);
}
