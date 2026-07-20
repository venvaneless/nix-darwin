# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/iterm2.nix

{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "iterm2";
  version = "3.6.11";

  src = fetchurl {
    url = "https://iterm2.com/downloads/stable/iTerm2-${
      lib.replaceStrings [ "." ] [ "_" ] finalAttrs.version
    }.zip";

    hash = "sha256-NueMUElWDqqOEiIk9mUutLIpxhzV5zMtbSW1w29zmOc=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    unzip
  ];

  installPhase = ''
    runHook preInstall

    if [ ! -d "iTerm.app" ]; then
      echo "ERROR: iTerm.app was not found." >&2
      find . -maxdepth 3 -print >&2
      exit 1
    fi

    mkdir -p "$out/Applications"

    cp -R \
      "iTerm.app" \
      "$out/Applications/iTerm.app"

    runHook postInstall
  '';

  meta = {
    description = "Terminal emulator for macOS";
    homepage = "https://iterm2.com/";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.darwin;

    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
    ];
  };
})