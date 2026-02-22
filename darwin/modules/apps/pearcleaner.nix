# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/pearcleaner.nix
#
# ============================================================
# PEARCLEANER
#
# Utility to uninstall apps and remove leftover files
# from old/uninstalled apps.
# ============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
  appName   = "Pearcleaner.app";
  caskName  = "pearcleaner";
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
  system.activationScripts.ensurePearcleanerAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
