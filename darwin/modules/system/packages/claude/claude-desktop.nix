# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/claude/claude-desktop.nix

{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  writeShellApplication,
  coreutils,
  curl,
  git,
  jq,
  nix,

  version ? "1.24012.9",
  releaseId ? "03c61d06f8e01a4db2273b9514e225f21d2ba62e",
  sourceHash ? "sha256-Oa0tGB4rGwF8VQb2bAg5nCNXXIAti2OSf0ASjncQOps=",
  downloadUrl ? "https://downloads.claude.ai/releases/darwin/universal/${version}/Claude-${releaseId}.zip",

  applicationName ? "Claude.app",
}:

let
  # ------------------------------------------------------------
  # ------ CLAUDE DESKTOP UPDATE SCRIPT ------ #
  #
  # Provides all commands required by update-claude-desktop.sh
  # and exposes the resulting executable through:
  #
  # passthru.updateScript
  # ------------------------------------------------------------

  updateClaudeDesktop =
    writeShellApplication {
      name = "update-claude-desktop";

      runtimeInputs = [
        coreutils
        curl
        git
        jq
        nix
      ];

      text =
        builtins.readFile ./update-claude-desktop.sh;
    };
in

stdenvNoCC.mkDerivation {
  pname = "claude-desktop";
  inherit version;

  src = fetchurl {
    url = downloadUrl;
    hash = sourceHash;
  };

  nativeBuildInputs = [
    unzip
  ];

  dontConfigure = true;
  dontBuild = true;

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    application_source="$PWD/${applicationName}"
    application_destination="$out/Applications/${applicationName}"

    if [ ! -d "$application_source" ]; then
      echo "ERROR: Claude application bundle was not found." >&2
      echo "Expected: $application_source" >&2
      exit 1
    fi

    mkdir -p "$out/Applications"

    cp \
      -R \
      -- \
      "$application_source" \
      "$application_destination"

    if [ ! -d "$application_destination" ]; then
      echo "ERROR: Claude application bundle was not installed." >&2
      exit 1
    fi

    runHook postInstall
  '';

  passthru = {
    updateScript =
      "${updateClaudeDesktop}/bin/update-claude-desktop";

    updateScriptPackage =
      updateClaudeDesktop;
  };

  meta = {
    description = "Anthropic's official Claude AI desktop application";
    homepage = "https://claude.com/download";
    license = lib.licenses.unfree;

    sourceProvenance = [
      lib.sourceTypes.binaryNativeCode
    ];

    platforms = lib.platforms.darwin;
    mainProgram = "Claude";
  };
}