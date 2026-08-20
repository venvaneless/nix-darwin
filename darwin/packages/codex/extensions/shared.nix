# CODEX: SHARED EXTENSIONS
# =========================
# Share Codex skills and plugins between all configured profiles.
#
# ** Conversation storage is not handled here. Sessions and archives are not
# ** extensions, and their layout is what archiving depends on, so they are
# ** owned by codex.nix alongside the rest of the profile contract.

{ lib, options, pkgs, ... }:

let
  helpers = import ../../../../options { inherit lib options pkgs; };

  inherit (helpers) paths;

  codex = paths.darwin.agents.codex;
  sharedRoot = codex.shared;

  profileRoots = [ codex.api codex.chatgpt ];

  renderProfile = root: ''
    mkdir -p ${lib.escapeShellArg root}

    rm -rf ${lib.escapeShellArg "${root}/skills"}
    rm -rf ${lib.escapeShellArg "${root}/plugins"}

    ln -s \
      ${lib.escapeShellArg codex.sharedSkills} \
      ${lib.escapeShellArg "${root}/skills"}

    ln -s \
      ${lib.escapeShellArg codex.sharedPlugins} \
      ${lib.escapeShellArg "${root}/plugins"}
  '';
in
{
  system.activationScripts.extraActivation.text = lib.mkBefore ''
    echo "[nix-darwin][codex] Configuring shared Codex skills and plugins..."

    mkdir -p \
      ${lib.escapeShellArg codex.sharedSkills} \
      ${lib.escapeShellArg codex.sharedPlugins}

    ${lib.concatMapStringsSep "\n" renderProfile profileRoots}

    chown -R ${paths.user.name}:staff ${lib.escapeShellArg sharedRoot}
  '';
}
