# /Users/ven/.config/nix/nix-config/darwin/modules/apps/wezterm.nix
# 
# ===================================================================
# WEZTERM
# GPU-accelerated cross-platform terminal emulator and multiplexer
# ===================================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Wezterm.app";
	caskName  = "wezterm";
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
  system.activationScripts.ensureWeztermAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}