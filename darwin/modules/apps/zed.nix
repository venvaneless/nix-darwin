# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/zed.nix
# 
# ============================================================
# ZED
# 
# Multiplayer code editor written in Rust
# ============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Zed.app";
	caskName  = "zed";
  targetDir = "/Applications/Productivity";
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
  system.activationScripts.ensureZedAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}