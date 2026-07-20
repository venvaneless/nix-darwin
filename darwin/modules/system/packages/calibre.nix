# /Users/ven/.config/nix/nix-config/darwin/modules/system/packages/calibre.nix

{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "calibre-bin";
  version = "9.11.0";

  src = fetchurl {
    url = "https://github.com/kovidgoyal/calibre/releases/download/v${finalAttrs.version}/calibre-${finalAttrs.version}.dmg";
    hash = "sha256-MAwazx+LlB4mXQ+MOfxgjDz+qGWjFwLghGQ9U2t4yVE=";
  };

  __noChroot = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mountPoint="$TMPDIR/calibre-dmg-$$"
    mounted="false"

    cleanup() {
      case "$mountPoint" in
        "$TMPDIR"/calibre-dmg-*)
          ;;
        *)
          echo "ERROR: Refusing cleanup of unsafe path: $mountPoint" >&2
          return 1
          ;;
      esac

      if [ "$mounted" = "true" ]; then
        echo "Detaching Calibre DMG from: $mountPoint"

        if /usr/bin/hdiutil detach "$mountPoint" -quiet; then
          mounted="false"
        elif /usr/bin/hdiutil detach "$mountPoint" -force -quiet; then
          mounted="false"
        else
          echo "ERROR: Failed to detach Calibre DMG." >&2
          echo "ERROR: Preserving mount directory rather than deleting mounted contents." >&2
          return 1
        fi
      fi

      if [ -d "$mountPoint" ]; then
        /bin/rmdir "$mountPoint" 2>/dev/null || {
          echo "ERROR: Mount directory is not empty after detachment: $mountPoint" >&2
          return 1
        }
      fi
    }

    trap cleanup EXIT INT TERM

    /bin/mkdir -p "$mountPoint"

    /usr/bin/hdiutil attach \
      "$src" \
      -nobrowse \
      -readonly \
      -mountpoint "$mountPoint"

    mounted="true"

    if [ ! -d "$mountPoint/calibre.app" ]; then
      echo "ERROR: calibre.app was not found in the mounted DMG." >&2
      /usr/bin/find "$mountPoint" -maxdepth 2 -print >&2
      exit 1
    fi

    /bin/mkdir -p "$out/Applications"

    /usr/bin/ditto \
      "$mountPoint/calibre.app" \
      "$out/Applications/calibre.app"

    if [ ! -d "$out/Applications/calibre.app" ]; then
      echo "ERROR: calibre.app was not copied successfully." >&2
      exit 1
    fi

    cleanup
    trap - EXIT INT TERM

    runHook postInstall
  '';

  meta = {
    description = "Comprehensive e-book management application";
    homepage = "https://calibre-ebook.com/";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.darwin;

    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
    ];
  };
})