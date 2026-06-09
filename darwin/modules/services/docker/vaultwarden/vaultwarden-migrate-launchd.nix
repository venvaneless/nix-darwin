# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/vaultwarden/vaultwarden-migrate-launchd.nix
#
# VAULTWARDEN: LAUNCHD MIGRATION CLEANUP
# ======================================
# Removes stale system LaunchDaemons left from older Vaultwarden/nginx configs.
# Keep temporarily, rebuild once, reboot once, then remove this file.

{ lib, ... }:

{
  system.activationScripts.vaultwardenLaunchdMigration.text = lib.mkBefore ''
    echo ">>> [vaultwarden-migrate] Removing stale system launchd jobs"

    launchctl bootout system/com.ven.vaultwarden 2>/dev/null || true
    rm -f /Library/LaunchDaemons/com.ven.vaultwarden.plist

    launchctl bootout system/com.ven.nginx-custom 2>/dev/null || true
    rm -f /Library/LaunchDaemons/com.ven.nginx-custom.plist
  '';
}