# /Users/ven/.config/nix/nix-config/darwin/modules/apps/syncthing.nix
# 
# =====================================================================
# SYNCTHING
# 
# Open source continuous file synchronization application
# =====================================================================

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
