# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/yate.nix
#
# YATE: INSTALL APP
# ============================================================
# Installs "Yate" for macOS via Homebrew cask and places it
# into a custom Applications directory.
# ============================================================

{ ... }:

let
  # APP METADATA
  # ------------------------------------------------------------
  appName   = "Yate.app";
  caskName  = "yate";
  targetDir = "/Applications/Multimedia";
in
{
  # HOMEBREW CASK INSTALL
  # ------------------------------------------------------------
  homebrew.casks = [
    {
      name = caskName;
      args = { appdir = targetDir; };
    }
  ];

  # DARWIN: ENSURE APPLICATION DIRECTORY EXISTS
  # ------------------------------------------------------------
  system.activationScripts.ensureYateAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
