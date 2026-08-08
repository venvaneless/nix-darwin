# CODEX: SHARED EXTENSIONS
# =========================
# Shared Codex plugin infrastructure

{ lib, ... }:

let
  userName = "ven";
  homeDir = "/Users/${userName}";

  codexRoot = "${homeDir}/.config/codex";
  sharedRoot = "${codexRoot}/shared";

  profiles = [
    "api"
    "chatgpt"
  ];
in
{
  # CODEX: EXTENSION OPTIONS
  # =========================
  # Individual extension files append their update logic here

  options.codex.extensionUpdaters = lib.mkOption {
    type = lib.types.listOf lib.types.lines;
    default = [ ];
    internal = true;
  };


  # CODEX: SHARED DIRECTORIES
  # =========================
  # Both profiles use the same skills and plugin directories

  system.activationScripts.codexSharedExtensions.text = lib.mkBefore ''
    echo "[nix-darwin][codex] Configuring shared extensions..."

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

    chown -R \
      ${userName}:staff \
      "${sharedRoot}"
  '';
}