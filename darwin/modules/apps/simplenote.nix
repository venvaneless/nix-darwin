# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/simplenote.nix
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
