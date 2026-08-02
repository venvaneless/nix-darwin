# darwin/packages/unarchiver/unarchiver-update.nix
#
# =====================================================================
# UPDATER: THE UNARCHIVER
#
# Reads current Homebrew cask metadata and updates default.nix.
#
# This updater changes only the package definition. It does not build
# or switch the nix-darwin configuration.
# =====================================================================

{
  lib,
  writeShellApplication,
  curl,
  jq,
  nix,
  gnused,
  coreutils,
}:

writeShellApplication {
  name = "update-unarchiver";

  runtimeInputs = [
    curl
    jq
    nix
    gnused
    coreutils
  ];

  text = ''
    set -euo pipefail

    package_file="$HOME/.config/nix/nix-config/darwin/packages/unarchiver/default.nix"
    metadata_url="https://formulae.brew.sh/api/cask/the-unarchiver.json"

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

    token="$(
      printf '%s' "$metadata" |
        jq \
          --exit-status \
          --raw-output \
          '.token'
    )"

    if [ "$token" != "the-unarchiver" ]; then
      echo "ERROR: Unexpected Homebrew cask token: $token" >&2
      exit 1
    fi

    complete_version="$(
      printf '%s' "$metadata" |
        jq \
          --exit-status \
          --raw-output \
          '.version'
    )"

    version="$(
      printf '%s\n' "$complete_version" |
        ${coreutils}/bin/cut \
          -d ',' \
          -f 1
    )"

    url="$(
      printf '%s' "$metadata" |
        jq \
          --exit-status \
          --raw-output \
          '.url'
    )"

    hexadecimal_hash="$(
      printf '%s' "$metadata" |
        jq \
          --exit-status \
          --raw-output \
          '.sha256'
    )"

    sri_hash="$(
      nix-hash \
        --type sha256 \
        --to-sri \
        "$hexadecimal_hash"
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
      echo "The Unarchiver is already current: $version"
      exit 0
    fi

    temporary_file="$(
      mktemp \
        "$package_file.XXXXXX"
    )"

    cleanup() {
      rm \
        -f \
        -- \
        "$temporary_file"
    }

    trap cleanup EXIT

    ${gnused}/bin/sed \
      -e 's|^[[:space:]]*version = "[^"]*";|  version = "'"$version"'";|' \
      -e 's|^[[:space:]]*url = "[^"]*";|    url = "'"$url"'";|' \
      -e 's|^[[:space:]]*hash = "[^"]*";|    hash = "'"$sri_hash"'";|' \
      "$package_file" \
      > "$temporary_file"

    if ! grep \
      -F \
      -q \
      "version = \"$version\";" \
      "$temporary_file"
    then
      echo "ERROR: Failed to update the package version." >&2
      exit 1
    fi

    if ! grep \
      -F \
      -q \
      "url = \"$url\";" \
      "$temporary_file"
    then
      echo "ERROR: Failed to update the download URL." >&2
      exit 1
    fi

    if ! grep \
      -F \
      -q \
      "hash = \"$sri_hash\";" \
      "$temporary_file"
    then
      echo "ERROR: Failed to update the source hash." >&2
      exit 1
    fi

    chmod \
      --reference="$package_file" \
      "$temporary_file"

    mv \
      -- \
      "$temporary_file" \
      "$package_file"

    trap - EXIT

    echo "The Unarchiver package definition was updated."
    echo
    echo "Version: $version"
    echo "Homebrew metadata version: $complete_version"
    echo "URL: $url"
    echo "Hash: $sri_hash"
    echo
    echo "The application has not been built or installed yet."
  '';

  meta = {
    description = "Updates the local The Unarchiver Nix package";
    platforms = lib.platforms.darwin;
  };
}