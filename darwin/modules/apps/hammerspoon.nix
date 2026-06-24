# /Users/ven/.config/nix/nix-config/darwin/modules/apps/hammerspoon.nix
# 
# =====================================================================
# HAMMERSPOOON
# 
# Tool for powerful automation of macOS
# At its core, Hammerspoon is just a bridge between
# the operating system and a Lua scripting engine
# =====================================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Hammerspoon.app";
	caskName  = "hammerspoon";
  targetDir = "/Applications/System";
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
  system.activationScripts.ensureHammerspoonAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
