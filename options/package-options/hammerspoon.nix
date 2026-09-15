# options/package-options/hammerspoon.nix
#
# =====================================================================
# PACKAGE: HAMMERSPOON
#
# Packages the Hammerspoon macOS application and provides its source
# updater from one definition, so the updater always targets this file.
# =====================================================================

{
  curl,
  fetchurl,
  gnused,
  jq,
  lib,
  nix,
  paths,
  stdenvNoCC,
  unzip,
  writeShellApplication,
}:

let
  # The updater changes this declared package source, never an installed app.
  packageFile = "${paths.darwin.home.nixConfig}/options/package-options/hammerspoon.nix";

  # ------------------------------------------------------------
  # ------ HAMMERSPOON APPLICATION ------ #
  # ------------------------------------------------------------

  hammerspoon = stdenvNoCC.mkDerivation (finalAttrs: {
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
  });

  # ------------------------------------------------------------
  # ------ HAMMERSPOON SOURCE UPDATER ------ #
  # Updates version, release URL, and hash together without building
  # or activating the nix-darwin configuration.
  # ------------------------------------------------------------

  updateHammerspoon = writeShellApplication {
    name = "update-hammerspoon";

    runtimeInputs = [
      curl
      jq
      nix
      gnused
    ];

    text = ''
      set -euo pipefail

      package_file=${lib.escapeShellArg packageFile}
      metadata_url="https://api.github.com/repos/Hammerspoon/hammerspoon/releases/latest"

      if [ ! -f "$package_file" ]; then
        echo "ERROR: Package file was not found:" >&2
        echo "$package_file" >&2
        exit 1
      fi

      metadata="$(
        curl \
          --fail \
          --location \
          --silent \
          --show-error \
          "$metadata_url"
      )"

      version="$(
        printf '%s' "$metadata" |
          jq \
            --exit-status \
            --raw-output \
            '.tag_name'
      )"

      asset_name="Hammerspoon-$version.zip"

      url="$(
        printf '%s' "$metadata" |
          jq \
            --exit-status \
            --raw-output \
            --arg asset_name "$asset_name" \
            '[.assets[] | select(.name == $asset_name and .content_type == "application/zip")][0].browser_download_url'
      )"

      if [ -z "$url" ] || [ "$url" = "null" ]; then
        echo "ERROR: The GitHub release did not contain $asset_name." >&2
        exit 1
      fi

      temporary_source_file="$(mktemp)"
      temporary_package_file="$(mktemp "$package_file.XXXXXX")"

      cleanup() {
        rm \
          -f \
          -- \
          "$temporary_source_file" \
          "$temporary_package_file"
      }

      trap cleanup EXIT

      curl \
        --fail \
        --location \
        --silent \
        --show-error \
        --output "$temporary_source_file" \
        "$url"

      sri_hash="$(
        nix \
          hash \
          file \
          --sri \
          --type sha256 \
          "$temporary_source_file"
      )"

      current_version="$(
        ${gnused}/bin/sed \
          -n \
          's/^[[:space:]]*version = "\([^"]*\)";$/\1/p' \
          "$package_file"
      )"

      current_url="$(
        ${gnused}/bin/sed \
          -n \
          's/^[[:space:]]*url = "\([^"]*\)";$/\1/p' \
          "$package_file"
      )"

      current_hash="$(
        ${gnused}/bin/sed \
          -n \
          's/^[[:space:]]*hash = "\([^"]*\)";$/\1/p' \
          "$package_file"
      )"

      if \
        [ "$current_version" = "$version" ] \
        && [ "$current_url" = "$url" ] \
        && [ "$current_hash" = "$sri_hash" ]
      then
        echo "Hammerspoon is already current: $version"
        exit 0
      fi

      ${gnused}/bin/sed \
        -e 's|^[[:space:]]*version = "[^"]*";|    version = "'"$version"'";|' \
        -e 's|^[[:space:]]*url = "[^"]*";|      url = "'"$url"'";|' \
        -e 's|^[[:space:]]*hash = "[^"]*";|      hash = "'"$sri_hash"'";|' \
        "$package_file" \
        > "$temporary_package_file"

      if ! grep \
        -F \
        -q \
        "version = \"$version\";" \
        "$temporary_package_file"
      then
        echo "ERROR: Failed to update the package version." >&2
        exit 1
      fi

      if ! grep \
        -F \
        -q \
        "url = \"$url\";" \
        "$temporary_package_file"
      then
        echo "ERROR: Failed to update the download URL." >&2
        exit 1
      fi

      if ! grep \
        -F \
        -q \
        "hash = \"$sri_hash\";" \
        "$temporary_package_file"
      then
        echo "ERROR: Failed to update the source hash." >&2
        exit 1
      fi

      chmod \
        --reference="$package_file" \
        "$temporary_package_file"

      mv \
        -- \
        "$temporary_package_file" \
        "$package_file"

      trap - EXIT

      echo "The Hammerspoon package definition was updated."
      echo
      echo "Version: $version"
      echo "URL: $url"
      echo "Hash: $sri_hash"
      echo
      echo "The application has not been built or installed yet."
    '';

    meta = {
      description = "Updates the local Hammerspoon Nix package";
      platforms = lib.platforms.darwin;
    };
  };
in
{
  inherit hammerspoon updateHammerspoon;
}
