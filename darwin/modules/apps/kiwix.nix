# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/kiwix.nix
# 
# ====================================================================
# KIWIX
# App providing offline access to Wikipedia and many other web sites
# ====================================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Kiwix.app";
	caskName  = "kiwix";
  targetDir = "/Applications";
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
  system.activationScripts.ensureKiwixAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
