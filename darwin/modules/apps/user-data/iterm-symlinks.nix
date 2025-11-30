# darwin/modules/apps/user-data/iterm-symlinks.nix
{ config, lib, pkgs, ... }:

let
  home     = config.home.homeDirectory;
  dotIterm = "/Users/ven/dotfiles/apps/iterm";  # source of truth
  asIterm  = "${home}/Library/Application Support/iTerm2";
  plist    = "${home}/Library/Preferences/com.googlecode.iterm2.plist";
  dotPlist = "${dotIterm}/com.googlecode.iterm2.plist";
in
{
  home.activation.itermUserData =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -euo pipefail
      echo "Managing iTerm2 user-data…"

      # Initialise dotfiles dir if missing
      # Copy existing app support files and plist
      if [ ! -d "${dotIterm}" ]; then
        mkdir -p "${dotIterm}"
        [ -d "${asIterm}" ] && cp -a "${asIterm}/." "${dotIterm}/" 2>/dev/null || true
        [ -f "${plist}" ]   && cp -a "${plist}" "${dotPlist}"   2>/dev/null || true
      fi

      # Ensure Application Support/iTerm2 is a real directory.
      if [ -L "${asIterm}" ]; then
        rm -f "${asIterm}"
      fi
      mkdir -p "${asIterm}"

      # Symlinks all dotfiles (except .plist file) back into the Application Support folder
      for item in "${dotIterm}"/*; do
        name="$(basename "$item")"
        [ "$name" = "com.googlecode.iterm2.plist" ] && continue
        ln -sfn "$item" "${asIterm}/$name"
      done

      # Move any new files/directories created by iTerm2 into dotfiles and replace with symlinks
      #    Do directories first.
      while IFS= read -r item; do
        name="$(basename "$item")"
        [ "$name" = "." ] || [ "$name" = ".." ] || [ "$name" = "com.googlecode.iterm2.plist" ] && continue

        if [ -e "${dotIterm}/$name" ]; then
          rm -rf "$item"
          ln -sfn "${dotIterm}/$name" "${asIterm}/$name"
          continue
        fi

        mv "$item" "${dotIterm}/$name"
        ln -sfn "${dotIterm}/$name" "${asIterm}/$name"
      done < <(find "${asIterm}" -maxdepth 1 -mindepth 1 -type d)

      # Move any new files created by iTerm2 back into dotfiles.
      while IFS= read -r item; do
        name="$(basename "$item")"
        [ "$name" = "com.googlecode.iterm2.plist" ] && continue

        if [ -e "${dotIterm}/$name" ]; then
          rm -f "$item"
          ln -sfn "${dotIterm}/$name" "${asIterm}/$name"
          continue
        fi

        mv "$item" "${dotIterm}/$name"
        ln -sfn "${dotIterm}/$name" "${asIterm}/$name"
      done < <(find "${asIterm}" -maxdepth 1 -mindepth 1 -type f)

      # 5. Handle the plist: move real plist into dotfiles and symlink back.
      mkdir -p "${dotIterm}"
      if [ -f "${plist}" ] && [ ! -L "${plist}" ]; then
        mv "${plist}" "${dotPlist}"
      fi
      [ -f "${dotPlist}" ] || : > "${dotPlist}"
      ln -sfn "${dotPlist}" "${plist}"

      echo "iTerm2 user-data sync complete."
    '';
}
