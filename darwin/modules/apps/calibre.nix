# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/calibre.nix
#
# =============================================================
# CALIBRE
# E-books management software
# =============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Calibre.app";
	caskName  = "calibre";
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
  system.activationScripts.ensureCalibreAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
