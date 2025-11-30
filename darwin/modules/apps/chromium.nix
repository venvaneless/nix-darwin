# /Users/ven/dotfiles/nix/darwin/modules/apps/chromium.nix
#
# Ungoogled Chromium: INSTALL APP
# ============================================================
# Installs the ungoogled Chromium browser via Homebrew so that
# it lives in a defined location.  By default the application
# bundle is placed directly in `/Applications` so that it matches
# your existing installation of `Chromium.app`.  Adjust
# `targetDir` if you prefer to keep development tools in a
# subfolder like `/Applications/Programming`.
# ============================================================

{ ... }:

let
  appName   = "Chromium.app";
  # Name of the Homebrew cask providing ungoogled Chromium.
  caskName  = "ungoogled-chromium";
  # Destination directory for the app bundle.  Use "/Applications"
  # because the app is already installed there.  Change this if
  # you prefer a different location (e.g. "/Applications/Programming").
  targetDir = "/Applications";
in
{
  # Request installation of the Chromium cask via Homebrew.  The
  # `args.appdir` attribute ensures the application bundle ends
  # up in the desired directory instead of the default.
  homebrew.casks = [
    { name = caskName; args = { appdir = targetDir; }; }
  ];

  # Ensure that the target directory exists before Homebrew
  # installs anything.  Without this the Homebrew cask may fail
  # because the parent directory doesn't exist.
  system.activationScripts.ensureChromiumAppDir.text = ''
    mkdir -p "${targetDir}"
  '';
}
