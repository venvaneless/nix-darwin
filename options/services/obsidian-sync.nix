# options/services/obsidian-sync.nix
#
# =====================================================================
# OPTIONS: OBSIDIAN SYNC
#
# Defines the toggle and settings for the Obsidian/iCloud
# synchronization service.
# =====================================================================

{ config, lib, paths, pkgs, ... }:

let
  cfg = config.ven.services.obsidianSync;
  unison = config.ven.services.unison;

  # Each exclusion is a vault-relative Unison Path preference.
  excludeArguments = lib.concatMap (path: [
    "-ignore"
    "Path ${path}"
  ]) cfg.excludes;

  # The runner owns its mutable logs. This avoids an activation hook and
  # ensures a machine-specific log directory exists before Unison starts.
  runner = pkgs.writeShellScript "obsidian-sync" ''
    set -euo pipefail

    ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg cfg.logDirectory}
    exec >>${lib.escapeShellArg "${cfg.logDirectory}/obsidian-sync.out.log"} 2>>${lib.escapeShellArg "${cfg.logDirectory}/obsidian-sync.err.log"}

    if [ ! -d ${lib.escapeShellArg cfg.localVault} ]; then
      echo "Local vault is unavailable: ${cfg.localVault}"
      exit 1
    fi

    remoteParent=$(${pkgs.coreutils}/bin/dirname ${lib.escapeShellArg cfg.remoteVault})

    if [ ! -d "$remoteParent" ]; then
      echo "iCloud container is unavailable: $remoteParent"
      exit 1
    fi

    if [ ! -d ${lib.escapeShellArg cfg.remoteVault} ]; then
      ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg cfg.remoteVault}
    fi

    exec ${lib.escapeShellArgs (
      [
        "${pkgs.unison}/bin/unison"
        "-root"
        cfg.localVault
        "-root"
        cfg.remoteVault
      ]
      ++ lib.optionals unison.auto [ "-auto" ]
      ++ lib.optionals unison.batch [ "-batch" ]
      ++ [
        # Keep the mutable logs limited to errors and failed checks.
        "-silent"
      ]
      ++ lib.optionals unison.fastCheck [ "-fastcheck" ]
      ++ lib.optionals unison.confirmBigDeletes [ "-confirmbigdel" ]
      ++ excludeArguments
    )}
  '';
in

{
  options.ven.services.obsidianSync = lib.mkOption {
    type = lib.types.submodule {
      options = {
        enable = lib.mkEnableOption "Obsidian iCloud synchronization";

        localVault = lib.mkOption {
          type = lib.types.str;
          default = paths.darwin.obsidian.vault;
          description = "Local Obsidian vault path.";
        };

        remoteVault = lib.mkOption {
          type = lib.types.str;
          default = paths.darwin.obsidian.iCloudVault;
          description = "iCloud copy of the Obsidian vault.";
        };

        syncInterval = lib.mkOption {
          type = lib.types.ints.positive;
          default = 300;
          description = "Interval between Unison synchronization cycles, in seconds.";
        };

        runAtLoad = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Start the repeating Unison process when the LaunchAgent loads at login.";
        };

        logDirectory = lib.mkOption {
          type = lib.types.str;
          default = paths.darwin.obsidian.logs;
          description = "Directory used for synchronization logs.";
        };

        excludes = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            ".git"
            ".githooks"
            ".gitignore"
          ];
          description = "Vault-relative paths excluded from Obsidian synchronization.";
        };
      };
    };

    default = { };
    description = "Per-machine settings for Obsidian iCloud synchronization.";
  };

  config = lib.mkIf (pkgs.stdenv.isDarwin && cfg.enable && unison.enable) {
    # The LaunchAgent runs in the logged-in user's session, where both
    # the local vault and the iCloud container are available.
    launchd.agents.obsidian-sync = {
      enable = true;

      config = {
        Label = "com.ven.obsidian-sync";
        ProgramArguments = [ "${runner}" ];
        RunAtLoad = cfg.runAtLoad;
      };
    };
  };
}
