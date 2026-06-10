# /Users/ven/.config/nix/nix-config/darwin/modules/apps/freetube.nix
#
# =============================================================
# CALIBRE
# E-books management software
# =============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Freetube.app";
	caskName  = "freetube";
  targetDir = "/Applications/Multimedia";
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
  system.activationScripts.ensureFreetubeAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
