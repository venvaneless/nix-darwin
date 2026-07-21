# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/better-finder-rename.nix
#
# ============================================================
# PACKAGE: A BETTER FINDER RENAME
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
  pname = "better-finder-rename";
  version = "12.31";

  src = fetchurl {
    url = "https://www.publicspace.net/download/ABFRX12.dmg";
    hash = "sha256-HHLf+Csb6iYFe+o3sOARbb3wFIqJbXjCjMkTLLxfwF0=";
  };

  nativeBuildInputs = [
    undmg
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    if [ ! -d "A Better Finder Rename 12.app" ]; then
      echo "ERROR: A Better Finder Rename 12.app was not found." >&2
      find . -maxdepth 3 -print >&2
      exit 1
    fi

    mkdir -p "$out/Applications"

    cp -R \
      "A Better Finder Rename 12.app" \
      "$out/Applications/A Better Finder Rename 12.app"

    runHook postInstall
  '';

  meta = {
    description = "Advanced batch file and folder renaming utility for macOS";
    homepage = "https://www.publicspace.net/ABetterFinderRename/";
    license = lib.licenses.unfree;
    platforms = lib.platforms.darwin;

    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
    ];
  };
}