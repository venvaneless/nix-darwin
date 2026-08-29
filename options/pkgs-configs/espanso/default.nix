# options/pkgs-configs/espanso/default.nix
#
# =====================================================================
# ESPANSO: FEATURE DEFINITION
#
# Defines Espanso's reusable parent feature schema. Shared Home Manager
# modules select and apply these options; this file depends only on other
# definitions in options/.
# =====================================================================

{ lib, ... }:

{
  # ------------------------------------------------------------
  # ------ ESPANSO FEATURE DEFINITIONS ------ #
  # Markdown is an independent Espanso subfeature with its own option
  # schema in this same options directory.

  imports = [
    ./markdown.nix
  ];

  options.ven.espanso = {
    enable = lib.mkEnableOption "Espanso configuration";

    showNotifications = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show Espanso expansion notifications.";
    };

    base.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Create Espanso's base match file.";
    };
  };
}
