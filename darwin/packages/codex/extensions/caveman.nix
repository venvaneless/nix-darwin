# CODEX: CAVEMAN
# =========================
# Install Caveman using the developer's official Codex installer

{ lib, pkgs, ... }:

let
  installCaveman = pkgs.writeShellApplication {
    name = "install-codex-caveman";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.nodejs
    ];

    text = ''
      set -Eeuo pipefail


      # PATHS
      # =========================
      # Shared skill directory used by both Codex profiles
      shared_skills="/Users/ven/.config/codex/shared/skills"

      # Temporary project used by the official skills installer
      temporary_dir="$(${pkgs.coreutils}/bin/mktemp -d)"


      # CLEANUP
      # =========================
      # Remove the temporary installer directory when finished
      cleanup() {
        rm -rf -- "$temporary_dir"
      }

      trap cleanup EXIT


      # INSTALL
      # =========================
      # Run Caveman's official Codex installation command
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
      # The Codex project installation must contain the Caveman skill
      installed_skill="$temporary_dir/.agents/skills/caveman"

      if ! test -d "$installed_skill"; then
        printf 'Caveman installer did not create: %s\n' "$installed_skill" >&2
        exit 1
      fi


      # SHARED INSTALL
      # =========================
      # Replace the shared copy with the newly installed version
      mkdir -p -- "$shared_skills"

      rm -rf -- "$shared_skills/caveman"

      cp -R \
        "$installed_skill" \
        "$shared_skills/caveman"

      printf 'Caveman installed: %s\n' "$shared_skills/caveman"
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
    echo "[nix-darwin][codex] Installing Caveman..."

    /usr/bin/sudo \
      -u ven \
      /usr/bin/env \
      HOME=/Users/ven \
      ${installCaveman}/bin/install-codex-caveman
  '';
}