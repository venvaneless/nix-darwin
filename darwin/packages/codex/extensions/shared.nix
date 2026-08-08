# CODEX: SHARED EXTENSIONS
# =========================
# Share Codex skills and plugins between all configured profiles

{ lib, ... }:

let
  codexRoot = "/Users/ven/.config/codex";
  sharedRoot = "${codexRoot}/shared";

  profiles = [
    "api"
    "chatgpt"
  ];
in
{
  system.activationScripts.codexSharedExtensions.text = lib.mkBefore ''
    echo "[nix-darwin][codex] Configuring shared skills and plugins..."

    mkdir -p \
      "${sharedRoot}/skills" \
      "${sharedRoot}/plugins"

    ${lib.concatMapStringsSep "\n" (profile: ''
      profile_root="${codexRoot}/${profile}"

      mkdir -p "$profile_root"

      rm -rf "$profile_root/skills"
      rm -rf "$profile_root/plugins"

      ln -s \
        "${sharedRoot}/skills" \
        "$profile_root/skills"

      ln -s \
        "${sharedRoot}/plugins" \
        "$profile_root/plugins"
    '') profiles}

    chown -R ven:staff "${sharedRoot}"
  '';
}