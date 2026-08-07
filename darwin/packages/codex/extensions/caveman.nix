# CODEX: CAVEMAN
# =========================
# Install or update Caveman using the developer's official Codex installer

{ lib, pkgs, ... }:

let
  installCaveman = pkgs.writeShellApplication {
    name = "install-codex-caveman";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.nodejs
    ];

    text = ''
      set -Eeuo pipefail


      # PATHS
      # =========================
      # Shared skills used by both Codex profiles
      shared_skills="/Users/ven/.config/codex/shared/skills"

      # Temporary project for the upstream skills installer
      temporary_dir="$(${pkgs.coreutils}/bin/mktemp -d)"


      # CLEANUP
      # =========================
      # Remove temporary files after installation
      cleanup() {
        rm -rf -- "$temporary_dir"
      }

      trap cleanup EXIT


      # INSTALL
      # =========================
      # Use Caveman's official Codex installation method
      cd -- "$temporary_dir"

      ${pkgs.nodejs}/bin/npx \
        --yes \
        skills \
        add JuliusBrussee/caveman \
        --agent codex \
        --copy \
        --yes


      # VERIFY
      # =========================
      # Codex project skills are installed here by the upstream installer
      installed_skills="$temporary_dir/.agents/skills"

      if ! test -d "$installed_skills"; then
        printf 'Caveman installer did not create a Codex skills directory.\n' >&2
        printf 'Expected: %s\n' "$installed_skills" >&2
        exit 1
      fi

      if ! ${pkgs.findutils}/bin/find \
          "$installed_skills" \
          -mindepth 1 \
          -maxdepth 1 \
          -type d \
          -print \
          -quit \
          | grep -q .; then

        printf 'Caveman installer created no skills.\n' >&2
        exit 1
      fi


      # SHARED INSTALL
      # =========================
      # Copy every Caveman skill produced by the official installer
      mkdir -p -- "$shared_skills"

      for skill in "$installed_skills"/*; do
        test -d "$skill" || continue

        skill_name="$(${pkgs.coreutils}/bin/basename "$skill")"

        printf 'Installing Caveman skill: %s\n' "$skill_name"

        rm -rf -- "''${shared_skills:?}/''${skill_name:?}"

        cp -R \
          "$skill" \
          "''${shared_skills:?}/''${skill_name:?}"
      done
      

      # COMPLETE
      # =========================
      printf 'Caveman skills installed into: %s\n' "$shared_skills"
    '';
  };
in
{
  environment.systemPackages = [
    installCaveman
  ];


  # CODEX: ACTIVATION
  # =========================
  # Install or refresh Caveman after nix-darwin switches
  system.activationScripts.codexCaveman.text = lib.mkAfter ''
    echo "[nix-darwin][codex] Installing/updating Caveman..."

    /usr/bin/sudo \
      -u ven \
      /usr/bin/env \
      HOME=/Users/ven \
      PATH=/run/current-system/sw/bin:/usr/bin:/bin \
      ${installCaveman}/bin/install-codex-caveman
  '';
}