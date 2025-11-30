# /Users/ven/dotfiles/nix/darwin/modules/apps/user-data/chromium-symlinks.nix
#
# Chromium: USER‑DATA MIDDLE‑MAN
# ============================================================
# Source of truth:
#     /Users/ven/dotfiles/apps/chromium
#
# Runtime paths:
#     ~/Library/Application Support/Chromium
#     ~/Library/Preferences/org.chromium.Chromium.plist
#
# Responsibilities:
#   - Ensure dotfiles path exists (initialize from system if needed)
#   - Ensure Application Support/Chromium is a folder (not a symlink)
#   - Ensure all files inside are symlinks pointing to dotfiles
#   - Move new system‑created files back into dotfiles
#   - Ensure plist is symlinked
#   - Never overwrite dotfiles
#   - Never interact with iCloud
#   - Never install or update anything
#   - Never launch Chromium
#
# This file mirrors the iTerm2 user‑data module but is tailored for
# ungoogled Chromium.  The authoritative copy of your browser
# settings resides under your dotfiles directory and changes are
# synchronized so that Chromium continues to function normally.
# When Chromium writes new files into its Application Support
# directory they are moved into `dotfiles/apps/chromium` and
# replaced with symlinks.  Similarly, your preferences plist is
# stored alongside the other files and symlinked back into
# `~/Library/Preferences`:contentReference[oaicite:1]{index=1}.
# ============================================================

{ config, lib, pkgs, ... }:

let
  home        = config.home.homeDirectory;
  # The location of the authoritative user‑data files.
  dotChromium = "/Users/ven/dotfiles/apps/chromium";

  # Paths to runtime data.
  asChromium  = "${home}/Library/Application Support/Chromium";
  plist       = "${home}/Library/Preferences/org.chromium.Chromium.plist";
  dotPlist    = "${dotChromium}/org.chromium.Chromium.plist";
in
{
  home.activation.chromiumUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing Chromium user‑data..."

      # Initialise dotfiles dir if missing
      # Copy existing app support files and plist
      if [ ! -d "${dotChromium}" ]; then
        echo "Chromium dotfiles missing → creating."
        mkdir -p "${dotChromium}"
        [ -d "${asChromium}" ] && cp -a "${asChromium}/." "${dotChromium}/" || true
        [ -f "${plist}" ] && cp -a "${plist}" "${dotPlist}" || true
      fi

      # Ensure Application Support/Chromium is a real directory.
      [ -L "${asChromium}" ] && rm -f "${asChromium}"
      mkdir -p "${asChromium}"

      # Symlinks all dotfiles (except .plist file) back into the Application Support folder
      for item in "${dotChromium}"/*; do
        name="$(basename "$item")"
        [ "$name" = "org.chromium.Chromium.plist" ] && continue
        ln -sfn "$item" "${asChromium}/$name"
      done

      # Move any new files/directories created by Chromium into dotfiles and replace with symlinks
      while IFS= read -r item; do
        name="$(basename "$item")"
        [ "$name" = "." ] || [ "$name" = ".." ] || [ "$name" = "org.chromium.Chromium.plist" ] && continue
        
        if [ -e "${dotChromium}/$name" ]; then
          rm -rf "$item"
          ln -sfn "${dotChromium}/$name" "${asChromium}/$name"
          continue
        fi
        
        mv "$item" "${dotChromium}/$name"
        ln -sfn "${dotChromium}/$name" "${asChromium}/$name"
      done < <(find "${asChromium}" -maxdepth 1 -mindepth 1 -type d)

      # Move any new files created by Chromium back into dotfiles.
      while IFS= read -r item; do
        name="$(basename "$item")"
        [ "$name" = "org.chromium.Chromium.plist" ] && continue
        
        if [ -e "${dotChromium}/$name" ]; then
          rm -f "$item"
          ln -sfn "${dotChromium}/$name" "${asChromium}/$name"
          continue
        fi
        
        mv "$item" "${dotChromium}/$name"
        ln -sfn "${dotChromium}/$name" "${asChromium}/$name"
      done < <(find "${asChromium}" -maxdepth 1 -mindepth 1 -type f)

      # Handle the plist: move real plist into dotfiles and symlink back.
      mkdir -p "${dotChromium}"
      if [ -f "${plist}" ] && [ ! -L "${plist}" ]; then
        mv "${plist}" "${dotPlist}"
      fi
      [ -f "${dotPlist}" ] || : > "${dotPlist}"
      ln -sfn "${dotPlist}" "${plist}"

      echo "Chromium user‑data sync complete."
    '';
}
