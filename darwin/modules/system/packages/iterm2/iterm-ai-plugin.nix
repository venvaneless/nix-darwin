# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/iterm2/iterm-ai-plugin.nix

{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "iterm-ai-plugin";
  version = "1.1";

  src = fetchurl {
    url = "https://raw.githubusercontent.com/gnachman/iterm2-website/refs/heads/master/downloads/ai-plugin/iTermAI-${finalAttrs.version}.zip";

    # Replace this after the first build reports the correct hash.
    hash = "sha256-blVHUFkJ3xsek1XmH5fE3cV1Nz2O8kB0wyB4hCb5n0I=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    unzip
  ];

  installPhase = ''
    runHook preInstall

    if [ ! -d "iTermAI.app" ]; then
      echo "ERROR: iTermAI.app was not found in the extracted archive." >&2
      echo "Extracted archive contents:" >&2
      find . -maxdepth 3 -print >&2
      exit 1
    fi

    mkdir -p "$out/Applications"

    cp -R \
      "iTermAI.app" \
      "$out/Applications/iTermAI.app"

    runHook postInstall
  '';

  meta = {
    description = "Optional AI network provider plugin for iTerm2";
    homepage = "https://iterm2.com/ai-plugin.html";
    platforms = lib.platforms.darwin;

    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
    ];
  };
})