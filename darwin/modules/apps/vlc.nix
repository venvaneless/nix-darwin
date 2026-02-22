# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/vlc.nix
#
# ============================================================
# VLC
# 
# Multimedia player
# ============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "VLC.app";
	caskName  = "vlc";
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
  system.activationScripts.ensureVLCAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
