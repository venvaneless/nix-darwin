# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/syncthing.nix
# 
# =========================================	===================
# PASTE
# 
# Your clipboard, supercharged and secure Paste keeps everything
# you copy organized and searchable. Lightweight, intuitive,
# packed with smart features, and private by design.
# ============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Syncthing.app";
	caskName  = "syncthing";
  targetDir = "/Applications/Tools";
in
{

# Homebrew cask install
# ------------------------------------------------------------
  homebrew.casks = [
    {
      name = caskName;
      args = { appdir = targetDir; };
    }
  ];

  # Ensure application directory exists
  # ------------------------------------------------------------
  system.activationScripts.ensureSyncthingAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
