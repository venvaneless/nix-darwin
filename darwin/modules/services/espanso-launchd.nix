# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/espanso-launchd.nix
#
# ESPANSO: LAUNCHD ENV OVERRIDE
# ============================================================
# Purpose:
#   - Inject ESPANSO_* environment variables into the
#     Espanso launchd user agent
#
# This is the ONLY way Espanso respects custom paths on macOS
# without relying on filesystem symlinks.
#
# Managed declaratively by nix-darwin / Home Manager.
# ============================================================

{ lib, ... }:

{
  launchd.user.agents.espanso-env = {
    enable = true;

    config = {
      Label = "com.federicoterzi.espanso";

      EnvironmentVariables = {
        ESPANSO_CONFIG_DIR = "/Users/ven/ven-dots/user-data/apps/espanso/config";
        ESPANSO_DATA_DIR   = "/Users/ven/ven-dots/user-data/apps/espanso/data";
      };
    };
  };
}
