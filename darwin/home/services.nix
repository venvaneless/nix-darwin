# darwin/home/services.nix
#
# =====================================================================
# DARWIN HOME MANAGER: SERVICES
#
# Enables and customizes user services for this Mac.
# =====================================================================

{ paths, ... }:

{
  # ------------------------------------------------------------
  # ICLOUD SYNCHRONISATION
  # ------------------------------------------------------------

  # ---- UNISON ---- #  
  ven.services.unison = {
    enable = true;
    auto = true;
    batch = true;
    fastCheck = true;
    confirmBigDeletes = true;
  };

  # ---- DOCUMENTS ---- #
  ven.services.documentsSync = {
    enable = true;
    localDirectory = paths.darwin.home.documents;
    remoteDirectory = paths.darwin.icloud.documents;
    runAtLoad = true;
    watchPaths = true;
    createRemoteDirectory = true;
    logDirectory = paths.darwin.services.documentsSyncLogs;

    excludes = [ ];
  };

  # ---- OBSIDIAN ---- #
  ven.services.obsidianSync = {
    enable = true;
    localVault = paths.darwin.obsidian.vault;
    remoteVault = paths.darwin.obsidian.iCloudVault;
    runAtLoad = true;
    logDirectory = paths.darwin.obsidian.logs;

    excludes = [
      ".git"
      ".githooks"
      ".gitignore"
    ];
  };

  # ------------------------------------------------------------
  # OTHER SERVICES
  # ------------------------------------------------------------

  # ---- BROWSER STARTPAGE ---- #
  ven.services.startpage = {
    enable = true;
    directory = paths.darwin.documents.tartarusStartpage;
    host = "127.0.0.1";
    port = 8787;
    runAtLoad = true;
    keepAlive = true;
    throttleInterval = 10;
    logDirectory = paths.darwin.services.tartarusStartpageLogs;
  };
}
