# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/a-better-finder-attributes.nix
# 
# ============================================================
# A BETTER FINDER ATTRIBUTES
# 
# File and photo tweaking tool.
# ============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
  appName   = "A Better Finder Attributes.app";
  caskName  = "a-better-finder-attributes";
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
  system.activationScripts.ensureABFAttributesAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
