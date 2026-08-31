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
  # Obsidian iCloud synchronization
  # ------------------------------------------------------------

  ven.services.unison = {
    enable = true;
    auto = true;
    batch = true;
    fastCheck = true;
    confirmBigDeletes = true;
  };

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
  # Documents iCloud synchronization
  # ------------------------------------------------------------

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

  # ------------------------------------------------------------
  # Tartarus startpage
  # ------------------------------------------------------------

  ven.services.startpage = {
    enable = true;
    directory = paths.darwin.icloud.services.tartarusStartpage;
    host = "127.0.0.1";
    port = 8787;
    runAtLoad = true;
    keepAlive = true;
    throttleInterval = 10;
    logDirectory = paths.darwin.services.tartarusStartpageLogs;
  };
}
