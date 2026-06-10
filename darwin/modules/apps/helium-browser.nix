# /Users/ven/.config/nix/nix-config/darwin/modules/apps/helium-browser.nix
# 
# =============================================================
# HELIUM BROWSER
# Open-source Chromium-based web browser.
# =============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Helium.app";
	caskName  = "helium-browser";
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
  system.activationScripts.ensureHeliumAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
