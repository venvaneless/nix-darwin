# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/assetsnap.nix
#
# =============================================================
# ASSETSNAP
# Small dev tool living in the taskbar: color picker, sort
# text, etc.
# =============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Assetsnap.app";
	caskName  = "assetsnap";
  targetDir = "/Tools";
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
  system.activationScripts.ensureAssetSnapAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
