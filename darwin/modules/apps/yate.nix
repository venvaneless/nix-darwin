# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/yate.nix
#
# ============================================================
# YATE
# 
# macOS Media file tag editor
# ============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Yate.app";
	caskName  = "yate";
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
  system.activationScripts.ensureYateAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}