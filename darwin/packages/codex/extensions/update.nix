# CODEX: EXTENSION UPDATER
# =========================
# Discover and update all installed Codex extensions

{ pkgs, ... }:

let
  updateCodexExtensions = pkgs.writeShellApplication {
    name = "update-codex-extensions";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
    ];

    text = ''
      set -Eeuo pipefail


      # PATHS
      # =========================
      # nix-darwin exposes extension installers here
      system_bin="/run/current-system/sw/bin"


      # DISCOVER
      # =========================
      # Find every declaratively installed Codex extension installer
      installers="$(
        ${pkgs.findutils}/bin/find \
          "$system_bin" \
          -maxdepth 1 \
          -type l \
          -name 'install-codex-*' \
          -print \
          | sort
      )"


      # VERIFY
      # =========================
      if test -z "$installers"; then
        printf 'No Codex extension installers were found.\n'
        exit 0
      fi


      # UPDATE
      # =========================
      # Each installer independently checks/downloads its upstream extension
      while IFS= read -r installer; do
        test -n "$installer" || continue

        name="$(${pkgs.coreutils}/bin/basename "$installer")"

        printf '\n'
        printf 'Updating: %s\n' "$name"
        printf '%s\n' '----------------------------------------'

        "$installer"
      done <<< "$installers"


      # COMPLETE
      # =========================
      printf '\n'
      printf 'All Codex extensions are current.\n'
    '';
  };
in
{
  environment.systemPackages = [
    updateCodexExtensions
  ];
}