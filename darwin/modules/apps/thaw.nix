# /Users/ven/.config/nix/nix-config/darwin/modules/apps/thaw.nix
#
# =====================================================================
# THAW
# 
# macOS Menu bar manager
# =====================================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Thaw.app";
	caskName  = "thaw";
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
  system.activationScripts.ensureThawAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
