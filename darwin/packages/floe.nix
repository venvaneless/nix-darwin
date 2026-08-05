# darwin/packages/floe.nix
#
# =====================================================================
# PACKAGE: FLOE
#
# Packages the signed and notarized Floe macOS application from its
# official GitHub release archive.
# =====================================================================

{
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
}:

stdenvNoCC.mkDerivation rec {
  pname = "floe";
  version = "0.1.5";

  src = fetchurl {
    url = "https://github.com/ovidijusr/floe/releases/download/v${version}/Floe-v${version}-macos-arm64.app.zip";

    hash = "sha256-eARSKpS+aKqrkysSE3EDiPPXtqpX6vbdL8y769mhCzc=";
  };

  dontUnpack = true;

  # Prevent Nix fixups from modifying the signed application bundle
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"

    ${unzip}/bin/unzip \
      -q \
      "$src" \
      "Floe.app/*" \
      -d "$out/Applications"

    if [ ! -d "$out/Applications/Floe.app" ]; then
      echo "Floe.app was not found in the release archive" >&2
      exit 1
    fi

    runHook postInstall
  '';

  meta = {
    description = "Minimal menu bar icon hider for macOS 27";
    homepage = "https://github.com/ovidijusr/floe";
    changelog = "https://github.com/ovidijusr/floe/releases/tag/v${version}";
    license = lib.licenses.gpl3Only;

    platforms = [
      "aarch64-darwin"
    ];
  };
}