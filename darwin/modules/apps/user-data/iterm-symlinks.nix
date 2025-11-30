# /Users/ven/dotfiles/nix/darwin/modules/apps/user-data/iterm-symlinks.nix
#
# ITERM2: USER-DATA MIDDLE-MAN
# ============================================================
# Source of truth: /Users/ven/dotfiles/apps/iterm2
# Runtime paths: ~/Library/Application Support/iTerm2
#                 ~/Library/Preferences/com.googlecode.iterm2.plist
# ============================================================

{ config, lib, pkgs, ... }:

let
  home     = config.home.homeDirectory;
  dotIterm = "/Users/ven/dotfiles/apps/iterm2";
  asIterm  = "${home}/Library/Application Support/iTerm2";
  plist    = "${home}/Library/Preferences/com.googlecode.iterm2.plist";
  dotPlist = "${dotIterm}/com.googlecode.iterm2.plist";
in
{
  home.activation.iterm2UserData = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail
    echo "Managing iTerm2 user‑data..."

    # 1. Initialise dotfiles directory from existing system files if it doesn't exist.
    if [ ! -d "${dotIterm}" ]; then
      mkdir -p "${dotIterm}"
      [ -d "${asIterm}" ] && cp -a "${asIterm}/." "${dotIterm}/" || true
      [ -f "${plist}" ]   && cp -a "${plist}" "${dotPlist}" || true
    fi

    # 2. Ensure Application Support/iTerm2 is a real directory.
    [ -L "${asIterm}" ] && rm -f "${asIterm}"
    mkdir -p "${asIterm}"

    # 3. Symlink every file in dotfiles back into Application Support (skip plist).
    for item in "${dotIterm}"/*; do
      name="$(basename "$item")"
      [ "$name" = "com.googlecode.iterm2.plist" ] && continue
      ln -sfn "$item" "${asIterm}/$name"
    done

    # 4. Move any new files or directories created by iTerm2 back into the dotfiles dir.
    #    Replace them with symlinks so future writes hit the dotfiles copy.
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

    # 5. Move the real plist into dotfiles (if present) and symlink it back.
    mkdir -p "${dotIterm}"
    if [ -f "${plist}" ] && [ ! -L "${plist}" ]; then
      mv "${plist}" "${dotPlist}"
    fi
    [ -f "${dotPlist}" ] || : > "${dotPlist}"
    ln -sfn "${dotPlist}" "${plist}"

    echo "iTerm2 user‑data sync complete."
  '';
}
