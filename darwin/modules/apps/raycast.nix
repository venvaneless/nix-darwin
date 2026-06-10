# /Users/ven/.config/nix/nix-config/darwin/modules/apps/raycast.nix
# 
# =============================================================
# RAYCAST
# A collection of powerful productivity tools all within
# an extendable macOS launcher
# =============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Raycast.app";
	caskName  = "raycast";
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
  system.activationScripts.ensureRaycastAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}