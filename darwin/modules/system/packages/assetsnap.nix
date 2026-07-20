# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/assetsnap.nix
#
# =====================================================================
# ASSETSNAP
#
# Developer asset manager for the macOS menu bar.
# Distributed as an unsigned macOS application bundle.
# =====================================================================

{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "assetsnap";
  version = "0.0.7";

  src = fetchurl {
    url = "https://assetsnap.binarybeam.net/releases/AssetSnap-${finalAttrs.version}.dmg";
    hash = "sha256-rnuxF+5r+EKBDNLt7msc7bvs7lBBIMY+1IO7GpK5r7U=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    undmg
  ];

  installPhase = ''
    runHook preInstall

    if [ ! -d "AssetSnap.app" ]; then
      echo "ERROR: AssetSnap.app was not found in the mounted DMG." >&2
      echo "Extracted installer contents:" >&2
      find . -maxdepth 3 -print >&2
      exit 1
    fi

    mkdir -p "$out/Applications"

    cp -R \
      "AssetSnap.app" \
      "$out/Applications/AssetSnap.app"

    runHook postInstall
  '';

  meta = {
    description = "Developer assets from your menu bar";
    homepage = "https://assetsnap.binarybeam.net/";
    license = lib.licenses.unfree;
    platforms = lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
    ];
  };
})