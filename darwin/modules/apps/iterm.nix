# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/iterm.nix
# 
# =============================================================
# ITERM2
# Terminal emulator as alternative to Apple's Terminal app
# =============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "iTerm.app";
	caskName  = "iterm2";
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
  system.activationScripts.ensureItermAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}