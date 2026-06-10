# /Users/ven/.config/nix/nix-config/darwin/modules/apps/vscode.nix
#
# ============================================================
# CALIBRE
#
# Open-source code editor
# ============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Visual Studio Code.app";
	caskName  = "visual-studio-code";
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
  system.activationScripts.ensureVisualStudioCodeAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
