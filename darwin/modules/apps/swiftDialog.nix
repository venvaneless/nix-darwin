# /Users/ven/.config/nix/nix-config/darwin/modules/apps/assetsnap.nix
#
# =====================================================================
# SWIFTDIALOG
# 
# Admin utility that presents custom dialogs or messages from shell scripts
# =====================================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Assetsnap.app";
	caskName  = "assetsnap";
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
  system.activationScripts.ensureAssetSnapAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
