# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/raycast.nix
# 
# ============================================================
# RAYCAST
# 
# A collection of powerful productivity tools all within
# an extendable macOS launcher.
# 
# Raycast is a blazingly fast macOS launcher that replaces
# the clutter of menus, buried apps, and slow search with
# a single command bar. Everything on your computer becomes
# instantly accessible from your keyboard.
# ============================================================

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