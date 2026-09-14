# darwin/packages/hammerspoon.nix

{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "hammerspoon";
  version = "1.1.1";

  src = fetchurl {
    url = "https://github.com/Hammerspoon/hammerspoon/releases/download/${finalAttrs.version}/Hammerspoon-${finalAttrs.version}.zip";
    hash = "sha256-EbsckPr1Qn83x71P5+q5d0rkPh1csCDFswiNrDKEnvo=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    unzip
  ];

  installPhase = ''
    runHook preInstall

    if [ ! -d "Hammerspoon.app" ]; then
      echo "ERROR: Hammerspoon.app was not found." >&2
      find . -maxdepth 3 -print >&2
      exit 1
    fi

    mkdir -p \
      "$out/Applications" \
      "$out/bin"

    cp -R \
      "Hammerspoon.app" \
      "$out/Applications/Hammerspoon.app"

    ln -s \
      "$out/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs" \
      "$out/bin/hs"

    runHook postInstall
  '';

  meta = {
    description = "Desktop automation application for macOS";
    homepage = "https://www.hammerspoon.org/";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;

    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
    ];

    mainProgram = "hs";
  };
})
