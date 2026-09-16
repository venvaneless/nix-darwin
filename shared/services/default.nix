# shared/services/default.nix
#
# =====================================================================
# SHARED: SERVICE KNOBS
# =====================================================================

{ paths, pkgs, ... }:

{
  # ------------------------------------------------------------
  # ------ RESTIC ------ #
  # Encrypted, deduplicated snapshot backups.
  # ------------------------------------------------------------

  system.shared.services.restic = {
    enable = true;
    installOn = {
      darwin = false;
      linux = false;
    };
    package = pkgs.restic;

    # Also names the restic-home wrapper command
    name = "home";
    # Account the backup runs as
    user = paths.user.name;

    # ---- Schedule
    # systemd calendar expression
    schedule = "daily";
    randomizedDelay = "1h";
    # Runs a missed backup at next boot
    persistent = true;

    # ---- Repository
    repository = "/path/to/backup";
    # Creates the repository on first run when missing
    initialize = true;
    # SOPS secret holding the repository password
    passwordSecret = "restic/password";

    # ---- Contents
    paths = [
      paths.user.linuxHome
    ];
    exclude = [
      "${paths.user.linuxHome}/.cache"
      "${paths.user.linuxHome}/Downloads"
    ];

    # ---- Retention
    retention = {
      daily = 7;
      weekly = 4;
      monthly = 6;
    };
  };
}
