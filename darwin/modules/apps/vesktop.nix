# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/vesktop.nix
#
# =============================================================
# VESKTOP
# Custom Discord app.
# =============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Vesktop.app";
	caskName  = "vesktop";
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
  system.activationScripts.ensureVesktopAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
