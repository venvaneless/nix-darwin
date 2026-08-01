# /Users/ven/.config/nix/nix-config/darwin/modules/apps/paste.nix
# 
# =====================================================================
# PASTE
# 
# Your clipboard, supercharged and secure Paste keeps everything
# you copy organized and searchable. Lightweight, intuitive,
# packed with smart features, and private by design
# =====================================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Paste.app";
	caskName  = "paste";
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
  system.activationScripts.ensurePasteAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
