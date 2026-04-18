# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/simplenote.nix
# 
# =============================================================
# SIMPLENOTE
# Simple note-taking app written in React
# =============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Simplenote.app";
	caskName  = "simplenote";
  targetDir = "/Applications/Productivity";
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
  system.activationScripts.ensureSimplenoteAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
