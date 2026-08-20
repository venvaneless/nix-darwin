# CODEX: SHARED EXTENSIONS
# =========================
# Share Codex skills, plugins, and conversation storage between all configured
# profiles. Session and archive storage must share one root because archiving
# moves a session between them.
#
# Activation never migrates existing conversations or rewrites the state
# database. When either is still needed the profile is reported here and
# `codex-repair` performs the migration with ChatGPT closed.

{ lib, options, pkgs, ... }:

let
  helpers = import ../../../../options { inherit lib options pkgs; };

  inherit (helpers) paths;

  codex = paths.darwin.agents.codex;
  sharedRoot = codex.shared;

  profiles = [
    {
      name = "api";
      root = codex.api;
    }
    {
      name = "chatgpt";
      root = codex.chatgpt;
    }
  ];
in
{
  system.activationScripts.extraActivation.text = lib.mkBefore ''
    echo "[nix-darwin][codex] Configuring shared Codex resources..."

    mkdir -p \
      "${codex.sharedSkills}" \
      "${codex.sharedPlugins}" \
      "${codex.sharedSessions}" \
      "${codex.sharedArchivedSessions}"

    ${lib.concatMapStringsSep "\n" (profile: ''
      profile_root="${profile.root}"
      session_root="$profile_root/sessions"
      archive_root="$profile_root/archived_sessions"

      mkdir -p "$profile_root"

      rm -rf "$profile_root/skills"
      rm -rf "$profile_root/plugins"

      ln -s \
        "${codex.sharedSkills}" \
        "$profile_root/skills"

      ln -s \
        "${codex.sharedPlugins}" \
        "$profile_root/plugins"

      # Existing session directories are never replaced during activation.
      if [ -L "$session_root" ]; then
        session_target="$(readlink "$session_root")"

        if [ "$session_target" != "${codex.sharedSessions}" ]; then
          echo "[nix-darwin][codex] Existing session link is unmanaged: $session_root" >&2
        fi
      elif [ -e "$session_root" ]; then
        echo "[nix-darwin][codex] Session migration is pending: $session_root" >&2
        echo "[nix-darwin][codex] Quit ChatGPT and run: codex-repair --apply" >&2
      else
        ln -s \
          "${codex.sharedSessions}" \
          "$session_root"
      fi

      # Existing archive directories contain user conversations, so they are
      # migrated by codex-repair while ChatGPT is closed. Never replace one
      # here: archiving is what moves a conversation between the two roots,
      # and a half-migrated tree is what breaks it.
      if [ -L "$archive_root" ]; then
        archive_target="$(readlink "$archive_root")"

        if [ "$archive_target" != "${codex.sharedArchivedSessions}" ]; then
          echo "[nix-darwin][codex] Existing archive link is unmanaged: $archive_root" >&2
        fi
      elif [ -e "$archive_root" ]; then
        echo "[nix-darwin][codex] Archive migration is pending: $archive_root" >&2
        echo "[nix-darwin][codex] Quit ChatGPT and run: codex-repair --apply" >&2
      else
        ln -s \
          "${codex.sharedArchivedSessions}" \
          "$archive_root"
      fi
    '') profiles}

    chown -R ${paths.user.name}:staff "${sharedRoot}"
  '';
}
