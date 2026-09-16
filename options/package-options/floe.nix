# options/package-options/floe.nix
#
# =====================================================================
# PACKAGE: FLOE
#
# Packages Floe's macOS application from its official GitHub release archive.
# The upstream 0.1.5 bundle has an invalid code-signature seal, so this
# derivation creates a locally ad-hoc-signed copy before installing it.
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

  # Do not run generic Nix fixups on the application bundle. It is re-signed
  # explicitly below after every file has been installed.
  dontFixup = true;

  # codesign is supplied by the macOS host rather than nixpkgs. Declare it so
  # Darwin's sandbox can make the explicit local signing step available.
  __impureHostDeps = [
    "/usr/bin/codesign"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"

    ${unzip}/bin/unzip \
      -q \
      "$src" \
      "Floe.app/*" \
      -x "*/._*" \
      -d "$out/Applications"

    if [ ! -d "$out/Applications/Floe.app" ]; then
      echo "Floe.app was not found in the release archive" >&2
      exit 1
    fi

    runHook postInstall

    # Floe 0.1.5's upstream signature fails strict verification because its
    # Info.plist is not sealed. Re-sign the immutable Nix output ad hoc; this
    # does not claim the release retains its Developer ID or notarization.
    /usr/bin/codesign \
      --force \
      --deep \
      --sign - \
      --timestamp=none \
      "$out/Applications/Floe.app"

    /usr/bin/codesign \
      --verify \
      --deep \
      --strict \
      "$out/Applications/Floe.app"
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
