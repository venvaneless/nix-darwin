# darwin/packages/better-finder-attributes.nix
#
# ============================================================
# PACKAGE: A BETTER FINDER ATTRIBUTES
#
# Packages the official macOS application bundle for use through
# the Darwin tools package manager.
# ============================================================

{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
}:

stdenvNoCC.mkDerivation {
  pname = "better-finder-attributes";
  version = "7.47";

  src = fetchurl {
    url = "https://www.publicspace.net/download/ABFAX.dmg";
    hash = "sha256-wtk0NfJ0viMmg9FoY1Iv/P1OpfgwE4xn8egOTcLMbOk=";
  };

  nativeBuildInputs = [
    undmg
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    if [ ! -d "A Better Finder Attributes 7.app" ]; then
      echo "ERROR: A Better Finder Attributes 7.app was not found." >&2
      find . -maxdepth 3 -print >&2
      exit 1
    fi

    mkdir -p "$out/Applications"

    cp -R \
      "A Better Finder Attributes 7.app" \
      "$out/Applications/A Better Finder Attributes 7.app"

    runHook postInstall
  '';

  meta = {
    description = "File and photo attribute manipulation utility for macOS";
    homepage = "https://www.publicspace.net/ABetterFinderAttributes/";
    license = lib.licenses.unfree;
    platforms = lib.platforms.darwin;

    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
    ];
  };
}