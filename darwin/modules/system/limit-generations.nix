# /Users/ven/dotfiles/nix/darwin/modules/system/limit-generations.nix
#
# SYSTEM: AUTO GARBAGE COLLECTION + GENERATION LIMIT
# ============================================================

{ pkgs, ... }:

{
  # --- Automatic nix store GC ---
  nix.gc = {
    automatic = true;
    interval = { Weekday = 1; Hour = 3; Minute = 0; };  # Monday 03:00
    options = "--delete-older-than 30d";
  };

  # --- LaunchDaemon: prune old nix-darwin generations ---
  launchd.daemons."nix-prune-generations" = {
    serviceConfig = {
      Program = "${pkgs.writeShellApplication {
        name = "nix-prune-generations";
        # no sudo from nixpkgs here — use system one
        runtimeInputs = [ pkgs.nix ];
        text = ''
          echo "🧹 Pruning old nix-darwin generations (keeping 5 most recent)..."
          /usr/bin/sudo nix-env --delete-generations +5 --profile /nix/var/nix/profiles/system
        '';
      }}/bin/nix-prune-generations";

      StartInterval = 60 * 60 * 24 * 7;  # run every 7 days
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/var/log/nix-prune-generations.log";
      StandardErrorPath = "/var/log/nix-prune-generations.err";
    };
  };
}
