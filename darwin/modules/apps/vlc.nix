# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/vlc.nix
#
# VLC: INSTALL APP
# ============================================================
# Installs "VLC" for macOS via Homebrew cask and places it
# into a custom Applications directory.
# ============================================================

{ ... }:

let
  # APP METADATA
  # ------------------------------------------------------------
  appName   = "VLC.app";
  caskName  = "vlc";
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
  system.activationScripts.ensureVLCAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
