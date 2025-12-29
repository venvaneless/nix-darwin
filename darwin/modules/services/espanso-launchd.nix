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
# Managed declaratively by Home Manager.
# ============================================================

{ lib, ... }:

{
  launchd.agents.espanso-env = {
    # IMPORTANT:
    # In Home Manager, the agent name does NOT have to match
    # the real Label. We override Label explicitly below.

    config = {
      Label = "com.federicoterzi.espanso";

      ProgramArguments = [
        "/Applications/Tools/Espanso.app/Contents/MacOS/espanso"
        "launcher"
      ];

      RunAtLoad = true;

      EnvironmentVariables = {
        ESPANSO_CONFIG_DIR = "/Users/ven/ven-dots/user-data/apps/espanso/config";
        ESPANSO_DATA_DIR   = "/Users/ven/ven-dots/user-data/apps/espanso/data";
      };

      StandardOutPath = "/tmp/espanso.out";
      StandardErrorPath = "/tmp/espanso.err";
    };
  };
}
