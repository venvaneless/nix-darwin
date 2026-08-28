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

  # ven.services.unison = {
  #   enable = false;
  #   auto = true;
  #   batch = true;
  #   fastCheck = true;
  #   confirmBigDeletes = true;
  # };

  # ven.services.obsidianSync = {
  #   enable = false;
  #   localVault = paths.darwin.obsidian.vault;
  #   remoteVault = paths.darwin.obsidian.iCloudVault;
  #   syncInterval = 300;
  #   runAtLoad = false;
  #   logDirectory = paths.darwin.obsidian.logs;
  #
  #   excludes = [
  #     ".git"
  #     ".githooks"
  #     ".gitignore"
  #   ];
  # };
}
