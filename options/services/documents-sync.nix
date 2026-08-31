# options/services/documents-sync.nix
#
# =====================================================================
# OPTIONS: DOCUMENTS SYNC
#
# Defines a portable, Unison-backed synchronization service for a local
# Documents folder and a separately selected remote copy.
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.services.documentsSync;
  unison = config.ven.services.unison;

  # A disabled service has no remote target. Keep runner rendering safe
  # while the assertion below gives a clear error if it is enabled
  # without selecting one.
  remoteDirectory = if cfg.remoteDirectory == null then "/nonexistent" else cfg.remoteDirectory;

  # Each exclusion is relative to both synchronized roots.
  excludeArguments = lib.concatMap (path: [
    "-ignore"
    "Path ${path}"
  ]) cfg.excludes;

  # The runner writes only to its configurable local log directory.
  # It never creates the local Documents source, and it only creates the
  # exact remote directory when that behavior is enabled explicitly.
  runner = pkgs.writeShellScript "documents-sync" ''
    set -euo pipefail

    ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg cfg.logDirectory}
    exec >>${lib.escapeShellArg "${cfg.logDirectory}/documents-sync.out.log"} 2>>${lib.escapeShellArg "${cfg.logDirectory}/documents-sync.err.log"}

    if [ ! -d ${lib.escapeShellArg cfg.localDirectory} ]; then
      echo "Local Documents directory is unavailable: ${cfg.localDirectory}"
      exit 1
    fi

    remote_parent=$(${pkgs.coreutils}/bin/dirname ${lib.escapeShellArg remoteDirectory})

    if [ ! -d "$remote_parent" ]; then
      echo "Remote Documents parent is unavailable: $remote_parent"
      exit 1
    fi

    if [ -e ${lib.escapeShellArg remoteDirectory} ] && [ ! -d ${lib.escapeShellArg remoteDirectory} ]; then
      echo "Remote Documents path is not a directory: ${remoteDirectory}"
      exit 1
    fi

    if [ ! -d ${lib.escapeShellArg remoteDirectory} ]; then
      if ${lib.boolToString cfg.createRemoteDirectory}; then
        ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg remoteDirectory}
      else
        echo "Remote Documents directory is unavailable: ${remoteDirectory}"
        exit 1
      fi
    fi

    exec ${lib.escapeShellArgs (
      [
        "${pkgs.unison}/bin/unison"
        "-root"
        cfg.localDirectory
        "-root"
        remoteDirectory
      ]
      ++ lib.optionals unison.auto [ "-auto" ]
      ++ lib.optionals unison.batch [ "-batch" ]
      ++ [ "-silent" ]
      ++ lib.optionals unison.fastCheck [ "-fastcheck" ]
      ++ lib.optionals unison.confirmBigDeletes [ "-confirmbigdel" ]
      ++ excludeArguments
    )}
  '';
in
{
  options.ven.services.documentsSync = lib.mkOption {
    type = lib.types.submodule {
      options = {
        enable = lib.mkEnableOption "Documents synchronization";

        localDirectory = lib.mkOption {
          type = lib.types.str;
          default = "${config.home.homeDirectory}/Documents";
          description = "Local Documents directory synchronized by Unison.";
        };

        remoteDirectory = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Remote Documents directory. Set this on every host that enables the service.";
        };

        runAtLoad = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Run synchronization when the user service starts.";
        };

        watchPaths = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Synchronize again after either configured Documents directory changes.";
        };

        createRemoteDirectory = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Create the exact configured remote Documents directory when its parent exists.";
        };

        logDirectory = lib.mkOption {
          type = lib.types.str;
          default = "${config.home.homeDirectory}/.local/state/documents-sync";
          description = "Directory used for Documents synchronization logs.";
        };

        excludes = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Documents-relative paths excluded from synchronization.";
        };
      };
    };

    default = { };
    description = "Per-machine settings for portable Documents synchronization.";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = unison.enable;
          message = "ven.services.documentsSync requires ven.services.unison.enable = true.";
        }
        {
          assertion = cfg.remoteDirectory != null;
          message = "ven.services.documentsSync.remoteDirectory must be set when synchronization is enabled.";
        }
        {
          assertion = cfg.remoteDirectory == null || cfg.remoteDirectory != cfg.localDirectory;
          message = "ven.services.documentsSync remoteDirectory must differ from localDirectory.";
        }
      ];
    }

    (lib.mkIf (pkgs.stdenv.isDarwin && unison.enable) {
      launchd.agents.documents-sync = {
        enable = true;

        config = {
          Label = "com.ven.documents-sync";
          ProgramArguments = [ "${runner}" ];
          RunAtLoad = cfg.runAtLoad;
          WatchPaths = lib.optionals cfg.watchPaths [
            cfg.localDirectory
            remoteDirectory
          ];
        };
      };
    })

    (lib.mkIf (pkgs.stdenv.isLinux && unison.enable) {
      systemd.user.services.documents-sync = {
        Unit = {
          Description = "Synchronize Documents with Unison";
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${runner}";
        };

        Install = lib.optionalAttrs cfg.runAtLoad {
          WantedBy = [ "default.target" ];
        };
      };

      systemd.user.paths.documents-sync = lib.mkIf cfg.watchPaths {
        Unit = {
          Description = "Watch Documents synchronization roots";
        };

        Path = {
          PathChanged = [
            cfg.localDirectory
            remoteDirectory
          ];
          Unit = "documents-sync.service";
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    })
  ]);
}
