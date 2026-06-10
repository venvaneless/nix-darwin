# /Users/ven/.config/nix/nix-config/darwin/modules/apps/a-better-finder-rename.nix
# 
# =============================================================
# A BETTER FINDER RENAME
# Renamer for files, music and photos
# =============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
  appName   = "A Better Finder Rename.app";
  caskName  = "a-better-finder-rename";
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
  system.activationScripts.ensureABFRAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
