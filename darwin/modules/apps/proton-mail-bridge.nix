# /Users/ven/.config/nix/nix-darwin/darwin/modules/apps/proton-mail-bridge.nix
# 
# ============================================================
# OBSIDIAN
# 
# Bridges Proton Mail to email clients supporting IMAP and SMTP protocols
# ============================================================

{ ... }:

let
# App metadata
# ------------------------------------------------------------
	appName   = "Proton Mail Bridge.app";
	caskName  = "proton-mail-bridge";
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
  system.activationScripts.ensureProtonBridgeDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      echo "[${appName}] Creating application directory: ${targetDir}"
      mkdir -p "${targetDir}"
    else
      echo "[${appName}] Application directory already exists: ${targetDir}"
    fi
  '';
}
