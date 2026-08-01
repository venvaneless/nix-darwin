# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/iterm2/iterm-browser-plugin.nix

{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "iterm-browser-plugin";
  version = "1.0";

  src = fetchurl {
    url = "https://raw.githubusercontent.com/gnachman/iterm2-website/refs/heads/master/downloads/browser-plugin/iTermBrowserPlugin-${finalAttrs.version}.zip";

    # Replace this after the first build reports the correct hash.
    hash = "sha256-bUG9Mv0QIs+TXT/fkrxTD5DE0XZmuYETfv38/kISj70=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    unzip
  ];

  installPhase = ''
    runHook preInstall

    if [ ! -d "iTermBrowserPlugin.app" ]; then
      echo "ERROR: iTermBrowserPlugin.app was not found in the extracted archive." >&2
      echo "Extracted archive contents:" >&2
      find . -maxdepth 3 -print >&2
      exit 1
    fi

    mkdir -p "$out/Applications"

    cp -R \
      "iTermBrowserPlugin.app" \
      "$out/Applications/iTermBrowserPlugin.app"

    runHook postInstall
  '';

  meta = {
    description = "Optional browser functionality plugin for iTerm2";
    homepage = "https://iterm2.com/browser-plugin.html";
    platforms = lib.platforms.darwin;

    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
    ];
  };
})