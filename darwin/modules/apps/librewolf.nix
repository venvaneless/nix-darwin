# /Users/ven/.config/nix/nix-config/darwin/modules/apps/librewolf.nix
# 
# ====================================================================
# KIWIX
# A fork of the Firefox web browser
# ====================================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Librewolf.app";
	caskName  = "librewolf";
  targetDir = "/Applications";
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
  system.activationScripts.ensureLibrewolfAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
