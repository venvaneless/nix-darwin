# darwin/packages/unarchiver/default.nix
#
# =====================================================================
# THE UNARCHIVER
#
# macOS archive extraction application.
# Distributed as a prebuilt application bundle inside a ZIP archive.
# =====================================================================

{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

stdenvNoCC.mkDerivation {
  pname = "the-unarchiver";
  version = "4.3.9";

  src = fetchurl {
    url = "https://dl.devmate.com/com.macpaw.site.theunarchiver/147/1742287964/TheUnarchiver-147.zip";
    hash = "sha256-0NjdLgKFGezl7rDwGLM5L2fhyFBTRyzLuu5k6H8XOig=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    unzip
  ];

  unpackPhase = ''
    runHook preUnpack

    unzip \
      -q \
      "$src"

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    if [ ! -d "The Unarchiver.app" ]; then
      echo "ERROR: The Unarchiver.app was not found in the extracted ZIP archive." >&2
      echo "Extracted archive contents:" >&2
      find . -maxdepth 3 -print >&2
      exit 1
    fi

    mkdir -p "$out/Applications"

    cp -R \
      "The Unarchiver.app" \
      "$out/Applications/The Unarchiver.app"

    runHook postInstall
  '';

  meta = {
    description = "Unpacks archive files on macOS";
    homepage = "https://theunarchiver.com/";
    license = lib.licenses.unfree;
    platforms = lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
    ];
  };
}