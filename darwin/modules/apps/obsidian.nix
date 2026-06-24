# /Users/ven/.config/nix/nix-config/darwin/modules/apps/obsidian.nix
# 
# =====================================================================
# OBSIDIAN
# 
# Knowledge base that works on top of a local folder
# of plain text Markdown files
# =====================================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Obsidian.app";
	caskName  = "obsidian";
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
  system.activationScripts.ensureObsidianAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
