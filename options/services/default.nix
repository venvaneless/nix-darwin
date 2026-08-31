# options/services/default.nix
#
# =====================================================================
# OPTIONS: SERVICES
#
# Glue for service-related options.
#
# Individual files declare available options and built-in defaults.
# Values set here with lib.mkDefault become global defaults while still
# allowing individual machines to override them.
# =====================================================================

{ lib, ... }:

{
  imports = [
   ./unison.nix
   ./obsidian-sync.nix
   ./documents-sync.nix
   ./startpage-logic.nix
  ];

  # ------------------------------------------------------------
  # Global defaults
  # ------------------------------------------------------------

  ven.services.unison = {
    enable = lib.mkDefault false;
    auto = lib.mkDefault true;
    batch = lib.mkDefault true;
    fastCheck = lib.mkDefault true;
    confirmBigDeletes = lib.mkDefault true;
  };

  ven.services.obsidianSync = {
    enable = lib.mkDefault false;
    runAtLoad = lib.mkDefault true;

    excludes = lib.mkDefault [
      ".git"
      ".githooks"
      ".gitignore"
    ];
  };

  ven.services.documentsSync = {
    enable = lib.mkDefault false;
    runAtLoad = lib.mkDefault true;
    watchPaths = lib.mkDefault true;
    createRemoteDirectory = lib.mkDefault true;
  };

  ven.services.startpage = {
    enable = lib.mkDefault false;
    runAtLoad = lib.mkDefault true;
    keepAlive = lib.mkDefault true;
    throttleInterval = lib.mkDefault 10;
  };
}
