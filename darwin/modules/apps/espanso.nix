# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/espanso.nix
# 
# ============================================================
# ESPANSO
# 
# Cross-platform Text Expander written in Rust.
# ============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Espanso.app";
	caskName  = "espanso";
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
  system.activationScripts.ensureEspansoAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
