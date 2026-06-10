# /Users/ven/.config/nix/nix-config/darwin/modules/apps/devdocs.nix
#
#
# =============================================================
# DevTools
# API documentation viewer
# =============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "DevDocs.app";
	caskName  = "dteoh-devdocs";
  targetDir = "/Applications/Programming";
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
  system.activationScripts.ensureDevDocsAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
