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
    syncInterval = 300;
    runAtLoad = true;
    logDirectory = paths.darwin.obsidian.logs;

    excludes = [
      ".git"
      ".githooks"
      ".gitignore"
    ];
  };
}
