# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/jdownloader.nix
# 
# =============================================================
# JDownloader
# Multiplayer code editor written in Rust
# =============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "JDownloader.app";
	caskName  = "jdownloader";
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
  system.activationScripts.ensureJDownloaderAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}