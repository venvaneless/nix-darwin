# options/paths.nix
#
# =====================================================================
# OPTIONS: COMMON PATHS
#
# Defines frequently used user, XDG, macOS application, Library, and
# iCloud paths. This module only centralizes values; it does not change
# existing service, backup, alias, Fish, or iCloud behavior.
# =====================================================================

{ }:

let
  # ------------------------------------------------------------
  # ------ PRIMARY USER ------ #
  # ------------------------------------------------------------

  userName = "ven";
in
{
  # ------------------------------------------------------------
  # ------ CROSS-PLATFORM USER PATHS ------ #
  # ------------------------------------------------------------

  user = {
    name = userName;

    darwinHome = "/Users/${userName}";
    linuxHome = "/home/${userName}";

    darwin = {
      config = "/Users/${userName}/.config";
      state = "/Users/${userName}/.config/.state";
      data = "/Users/${userName}/.config/.local/share";
      cache = "/Users/${userName}/.config/.cache";
      downloads = "/Users/${userName}/Downloads";
      nixConfig = "/Users/${userName}/.config/nix/nix-config";
      containers = "/Users/${userName}/.config/containers";
      secrets = "/Users/${userName}/.config/secrets";
    };

    linux = {
      config = "/home/${userName}/.config";
      state = "/home/${userName}/.local/state";
      data = "/home/${userName}/.local/share";
      cache = "/home/${userName}/.cache";
      downloads = "/home/${userName}/Downloads";
      nixConfig = "/home/${userName}/.config/nix/nix-config";
      containers = "/home/${userName}/.config/containers";
      secrets = "/home/${userName}/.config/secrets";
    };
  };

  # ------------------------------------------------------------
  # ------ MACOS APPLICATION PATHS ------ #
  # ------------------------------------------------------------

  darwin.applications = rec {
    root = "/Applications";
    nixApps = "${root}/Nix Apps";
    programming = "${root}/Programming";
    productivity = "${root}/Productivity";
    tools = "${root}/Tools";
    multimedia = "${root}/Multimedia";
    system = "${root}/System";
  };

  # ------------------------------------------------------------
  # ------ MACOS LIBRARY AND ICLOUD PATHS ------ #
  # ------------------------------------------------------------

  darwin.library = rec {
    root = "/Users/${userName}/Library";
    applicationSupport = "${root}/Application Support";
    preferences = "${root}/Preferences";
    containers = "${root}/Containers";
    groupContainers = "${root}/Group Containers";
    logs = "${root}/Logs";
    mobileDocuments = "${root}/Mobile Documents";
    iCloudDrive = "${mobileDocuments}/com~apple~CloudDocs";
  };
}
