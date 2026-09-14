# CODEX: SHARED EXTENSIONS
# =========================
# Share Codex skills and plugins between all configured profiles.
#
# ** Conversation storage is not handled here. Sessions and archives are not
# ** extensions, and their layout is what archiving depends on, so they are
# ** owned by codex.nix alongside the rest of the profile contract.
#
# ** Every branch below is a no-op once the links are correct, and nothing
# ** is rewritten, re-owned, or removed just to arrive at a state it is
# ** already in. A correct link is left alone rather than recreated, and a
# ** real directory where a link belongs is reported instead of deleted.

{ lib, options, pkgs, ... }:

let
  helpers = import ../../../../options { inherit lib options pkgs; };

  inherit (helpers) paths;

  codex = paths.darwin.agents.codex;

  owner = "${paths.user.name}:staff";

  # ---- Shared trees, and the per-profile link that points at each
  sharedLinks = [
    { name = "skills"; target = codex.sharedSkills; }
    { name = "plugins"; target = codex.sharedPlugins; }
  ];

  profileRoots = [ codex.api codex.chatgpt ];

  # Only the directories this module creates are given to the user. The
  # previous chown -R walked 5336 paths on every activation to change
  # nothing; ownership is set once, at creation.
  renderSharedRoot = link: ''
    if [ ! -d ${lib.escapeShellArg link.target} ]; then
      mkdir -p ${lib.escapeShellArg link.target}
      chown ${owner} ${lib.escapeShellArg link.target}
      echo "[nix-darwin][codex] Created shared ${link.name}: ${link.target}"
    fi
  '';

  renderProfileLink = root: link:
    let
      path = "${root}/${link.name}";
    in
    ''
      if [ -L ${lib.escapeShellArg path} ] \
        && [ "$(readlink ${lib.escapeShellArg path})" = ${lib.escapeShellArg link.target} ]; then
        : # Already correct.
      elif [ -e ${lib.escapeShellArg path} ] && [ ! -L ${lib.escapeShellArg path} ]; then
        echo "[nix-darwin][codex] Not a link, leaving it alone: ${path}" >&2
      else
        rm -f ${lib.escapeShellArg path}
        ln -s ${lib.escapeShellArg link.target} ${lib.escapeShellArg path}
        chown -h ${owner} ${lib.escapeShellArg path}
        echo "[nix-darwin][codex] Linked ${path}"
      fi
    '';

  renderProfile = root: ''
    if [ ! -d ${lib.escapeShellArg root} ]; then
      mkdir -p ${lib.escapeShellArg root}
      chown ${owner} ${lib.escapeShellArg root}
    fi

    ${lib.concatMapStringsSep "\n" (renderProfileLink root) sharedLinks}
  '';
in
{
  system.activationScripts.extraActivation.text = lib.mkBefore ''
    ${lib.concatMapStringsSep "\n" renderSharedRoot sharedLinks}

    ${lib.concatMapStringsSep "\n" renderProfile profileRoots}
  '';
}
