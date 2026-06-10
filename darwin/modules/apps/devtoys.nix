# /Users/ven/.config/nix/nix-config/darwin/modules/apps/devtoys.nix
#
# =============================================================
# DevToys
# Utilities designed to make common development tasks easier
# =============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "DevToys.app";
	caskName  = "devtoys";
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
  system.activationScripts.ensureDevToysAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
