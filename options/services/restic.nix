# options/services/restic.nix
#
# =====================================================================
# OPTIONS: RESTIC
#
# Scheduled restic backups as a NixOS system service running as one user.
# =====================================================================

{
  config,
  options,
  lib,
  platforms,
  ...
}:

let
  cfg = config.system.shared.services.restic;

  retentionFlags = lib.mapAttrsToList (period: count: "--keep-${period} ${toString count}") cfg.retention;
in
{
  options.system.shared.services.restic = {
    enable = lib.mkEnableOption "scheduled restic backups";

    installOn = lib.mkOption {
      type = lib.types.attrsOf lib.types.bool;
      default = { };
      description = "Platforms on which the backup service runs.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      description = "restic package used by the backup service.";
    };

    name = lib.mkOption {
      type = lib.types.str;
      description = "Backup name; also names the restic-<name> wrapper command.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      description = "Account the backup runs as.";
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      description = "systemd OnCalendar expression.";
    };

    randomizedDelay = lib.mkOption {
      type = lib.types.str;
      description = "Random delay added to each scheduled run.";
    };

    persistent = lib.mkOption {
      type = lib.types.bool;
      description = "Run a missed backup at next boot.";
    };

    repository = lib.mkOption {
      type = lib.types.str;
      description = "restic repository location.";
    };

    initialize = lib.mkOption {
      type = lib.types.bool;
      description = "Create the repository when it does not exist.";
    };

    passwordSecret = lib.mkOption {
      type = lib.types.str;
      description = "SOPS secret holding the repository password.";
    };

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Paths included in the backup.";
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Paths excluded from the backup.";
    };

    retention = lib.mkOption {
      type = lib.types.attrsOf lib.types.ints.positive;
      default = { };
      description = "Snapshots kept per period, e.g. { daily = 7; }.";
    };
  };

  config = platforms.onlyInSystem options (lib.mkMerge [
    {
      assertions = [
        {
          assertion = !(platforms.isDarwin && platforms.enabledForCurrentPlatform cfg);
          message = "system.shared.services.restic is a NixOS system service and cannot be enabled on Darwin.";
        }
      ];
    }

    # services.restic and systemd only exist on NixOS.
    (platforms.onlyOnLinux (
      lib.mkIf (platforms.enabledForCurrentPlatform cfg) {
        sops.secrets.${cfg.passwordSecret}.owner = cfg.user;

        services.restic.backups.${cfg.name} = {
          inherit (cfg)
            package
            user
            repository
            initialize
            paths
            exclude
            ;

          passwordFile = config.sops.secrets.${cfg.passwordSecret}.path;
          pruneOpts = retentionFlags;

          timerConfig = {
            OnCalendar = cfg.schedule;
            RandomizedDelaySec = cfg.randomizedDelay;
            Persistent = cfg.persistent;
          };
        };
      }
    ))
  ]);
}
