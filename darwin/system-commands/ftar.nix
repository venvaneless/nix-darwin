# darwin/system-commands/ftar.nix
#
# =====================================================================
# FTAR AND FTARD
#
# - ftar archives files and folders and keeps the originals
# - ftard archives files and folders and deletes the originals
# - Supports multiple sources and destinations
# - Preserves symbolic links
# - Excludes macOS and filesystem junk
# - Creates and verifies archives outside iCloud
# =====================================================================

{ pkgs, ... }:

let
  makeFtarCommand =
    {
      name,
      deleteOriginals,
    }:

    pkgs.writeShellApplication {
      inherit name;

      runtimeInputs = with pkgs; [
        coreutils
        findutils
        gzip
        gnutar
        rsync
      ];

      text = ''
        set -Eeuo pipefail


        delete_originals=${if deleteOriginals then "1" else "0"}

        archive_name=""
        argument_mode="sources"

        sources=()
        destinations=()
        normalized_sources=()
        normalized_destinations=()
        source_names=()
        in_progress_archives=()
        deletion_failures=()

        work_dir=""
        delete_root=""


        usage() {
          cat <<'USAGE'
Usage:
  ftar [--name ARCHIVE_NAME] SOURCE [SOURCE ...] --to DESTINATION [DESTINATION ...]
  ftard [--name ARCHIVE_NAME] SOURCE [SOURCE ...] --to DESTINATION [DESTINATION ...]

Examples:
  ftar "/path/to/source" --to "/path/to/destination"

  ftard \
    "/path/to/source-one" \
    "/path/to/source-two" \
    --to \
    "/path/to/destination-one" \
    "/path/to/destination-two"

  ftar \
    --name "my-backup" \
    "/path/to/source-one" \
    "/path/to/source-two" \
    --to \
    "/path/to/destination"

Behavior:
  ftar   keeps the original sources.
  ftard  permanently deletes the original sources after every
         destination copy has been verified.
USAGE
        }


        fail() {
          printf "Error: %s\n" "$*" >&2
          exit 1
        }


        path_exists() {
          test -e "$1" || test -L "$1"
        }


        normalize_existing_path() {
          local input="$1"
          local parent
          local base

          if test "$input" = "/"; then
            printf "/\n"
            return 0
          fi

          while test "$input" != "/" && test "''${input: -1}" = "/"; do
            input="''${input%/}"
          done

          parent=$(dirname -- "$input")
          base=$(basename -- "$input")

          (
            cd -- "$parent" 2>/dev/null
            printf "%s/%s\n" "$(pwd -P)" "$base"
          )
        }


        cleanup() {
          local exit_status=$?

          for unfinished_archive in "''${in_progress_archives[@]}"; do
            if path_exists "$unfinished_archive"; then
              rm -f -- "$unfinished_archive" 2>/dev/null || true
            fi
          done

          if test -n "$work_dir" && test -d "$work_dir"; then
            rm -rf -- "$work_dir" 2>/dev/null || true
          fi

          if test $exit_status -ne 0; then
            printf "\nThe original sources were not deleted unless the output explicitly says otherwise.\n" >&2
          fi
        }


        request_icloud_downloads() {
          local source="$1"

          if not test -x /usr/bin/brctl; then
            return 0
          fi

          /usr/bin/brctl download "$source" >/dev/null 2>&1 || true

          if test -d "$source" && not test -L "$source"; then
            while IFS= read -r -d "" item; do
              /usr/bin/brctl download "$item" >/dev/null 2>&1 || true
            done < <(
              find -P "$source" \
                \( -type f -o -type l \) \
                -print0 2>/dev/null
            )
          fi
        }


        stage_source() {
          local source="$1"
          local attempt

          request_icloud_downloads "$source"

          for attempt in 1 2 3; do
            if COPYFILE_DISABLE=1 rsync \
                -a \
                --exclude=".DS_Store" \
                --exclude="._*" \
                --exclude=".localized" \
                --exclude=".LSOverride" \
                --exclude=$'Icon\r' \
                --exclude="__MACOSX" \
                --exclude=".AppleDouble" \
                --exclude=".Spotlight-V100" \
                --exclude=".Trashes" \
                --exclude=".Trash" \
                --exclude=".Trash-*" \
                --exclude=".fseventsd" \
                --exclude=".TemporaryItems" \
                --exclude=".DocumentRevisions-V100" \
                --exclude=".com.apple.timemachine.donotpresent" \
                --exclude=".VolumeIcon.icns" \
                --exclude="Thumbs.db" \
                --exclude="ehthumbs.db" \
                --exclude="desktop.ini" \
                -- \
                "$source" \
                "$staging_dir/"

              return 0
            fi

            printf "Read attempt %s failed for:\n%s\n" "$attempt" "$source"

            request_icloud_downloads "$source"
            sleep $((attempt * 2))
          done

          return 1
        }


        force_remove_path() {
          local target="$1"

          if not path_exists "$target"; then
            return 0
          fi

          /bin/chflags -R nouchg,noschg "$target" 2>/dev/null || true
          /bin/chmod -RN "$target" 2>/dev/null || true

          timeout 180 /bin/rm -rf -- "$target" 2>/dev/null || true

          if not path_exists "$target"; then
            return 0
          fi

          if string_match=$(printf "%s" "$target" | grep -F "/Library/Mobile Documents/" || true); test -n "$string_match"; then
            /usr/bin/killall fileproviderd 2>/dev/null || true
            /usr/bin/killall bird 2>/dev/null || true
            /usr/bin/killall cloudd 2>/dev/null || true

            sleep 2

            timeout 180 /bin/rm -rf -- "$target" 2>/dev/null || true
          fi

          if not path_exists "$target"; then
            return 0
          fi

          /usr/bin/sudo /bin/chflags -R nouchg,noschg "$target" 2>/dev/null || true
          /usr/bin/sudo /bin/chmod -RN "$target" 2>/dev/null || true

          timeout 300 \
            /usr/bin/sudo \
            /bin/rm \
            -rf \
            -- \
            "$target" 2>/dev/null || true

          if path_exists "$target"; then
            return 1
          fi

          return 0
        }


        force_delete_source() {
          local source="$1"
          local source_number="$2"
          local source_name
          local quarantine_path

          source_name=$(basename -- "$source")

          quarantine_path="$delete_root/$(printf "%04d" "$source_number")-$source_name"

          printf "Deleting original:\n%s\n" "$source"

          if timeout 180 /bin/mv "$source" "$quarantine_path" 2>/dev/null; then
            if force_remove_path "$quarantine_path"; then
              return 0
            fi

            deletion_failures+=("$quarantine_path")
            return 1
          fi

          if path_exists "$quarantine_path"; then
            if not force_remove_path "$quarantine_path"; then
              deletion_failures+=("$quarantine_path")
            fi
          fi

          if not force_remove_path "$source"; then
            deletion_failures+=("$source")
            return 1
          fi

          return 0
        }


        trap cleanup EXIT


        while test $# -gt 0; do
          case "$1" in
            --name)
              test $# -ge 2 || fail "--name requires an archive name."
              test -n "$2" || fail "--name cannot be empty."

              archive_name="$2"
              shift 2
              ;;

            --to)
              argument_mode="destinations"
              shift
              ;;

            --help|-h)
              usage
              exit 0
              ;;

            --)
              shift
              ;;

            *)
              if test "$argument_mode" = "sources"; then
                sources+=("$1")
              else
                destinations+=("$1")
              fi

              shift
              ;;
          esac
        done


        if test "''${#sources[@]}" -eq 0; then
          usage
          fail "No source files or folders were provided."
        fi


        if test "''${#destinations[@]}" -eq 0; then
          usage
          fail "No destination folders were provided."
        fi


        for source in "''${sources[@]}"; do
          path_exists "$source" || fail "Source does not exist: $source"

          normalized_source=$(normalize_existing_path "$source") || \
            fail "Could not resolve source path: $source"

          source_name=$(basename -- "$normalized_source")

          case "$normalized_source" in
            /)
              fail "Refusing to archive the filesystem root."
              ;;

            "$HOME")
              fail "Refusing to archive the entire home folder."
              ;;

            "$HOME/Library")
              fail "Refusing to archive the entire Library folder."
              ;;

            "$HOME/Library/Mobile Documents")
              fail "Refusing to archive the entire Mobile Documents folder."
              ;;

            "$HOME/Library/Mobile Documents/com~apple~CloudDocs")
              fail "Refusing to archive the entire iCloud Drive."
              ;;
          esac

          for existing_source in "''${normalized_sources[@]}"; do
            if test "$normalized_source" = "$existing_source"; then
              fail "Source was provided more than once: $normalized_source"
            fi

            case "$normalized_source" in
              "$existing_source"/*)
                fail "A source is nested inside another source: $normalized_source"
                ;;
            esac

            case "$existing_source" in
              "$normalized_source"/*)
                fail "A source contains another selected source: $normalized_source"
                ;;
            esac
          done

          for existing_name in "''${source_names[@]}"; do
            if test "$source_name" = "$existing_name"; then
              fail "Two sources have the same top-level name: $source_name"
            fi
          done

          normalized_sources+=("$normalized_source")
          source_names+=("$source_name")
        done

        sources=("''${normalized_sources[@]}")


        for destination in "''${destinations[@]}"; do
          mkdir -p -- "$destination" || \
            fail "Could not create destination: $destination"

          normalized_destination=$(
            cd -- "$destination" 2>/dev/null
            pwd -P
          ) || fail "Could not resolve destination: $destination"

          for source in "''${sources[@]}"; do
            if test -d "$source" && not test -L "$source"; then
              case "$normalized_destination" in
                "$source"/*)
                  fail "A destination cannot be inside a source folder: $normalized_destination"
                  ;;
              esac
            fi
          done

          duplicate_destination=0

          for existing_destination in "''${normalized_destinations[@]}"; do
            if test "$normalized_destination" = "$existing_destination"; then
              duplicate_destination=1
              break
            fi
          done

          if test $duplicate_destination -eq 0; then
            normalized_destinations+=("$normalized_destination")
          fi
        done

        destinations=("''${normalized_destinations[@]}")


        if test -z "$archive_name"; then
          if test "''${#sources[@]}" -eq 1; then
            archive_name=$(basename -- "''${sources[0]}")
          else
            archive_name="archive-$(date +%Y%m%d-%H%M%S)"
          fi
        fi


        case "$archive_name" in
          */*)
            fail "--name must be a filename, not a path."
            ;;

          *.tar.gz|*.tgz)
            ;;

          *)
            archive_name="$archive_name.tar.gz"
            ;;
        esac


        for destination in "''${destinations[@]}"; do
          final_archive="$destination/$archive_name"

          if path_exists "$final_archive"; then
            fail "Archive already exists: $final_archive"
          fi
        done


        work_dir=$(mktemp -d "/private/tmp/ftar.XXXXXX") || \
          fail "Could not create a temporary working directory."

        staging_dir="$work_dir/staging"
        local_archive="$work_dir/$archive_name"

        mkdir -p -- "$staging_dir"


        printf "Preparing %s source(s)...\n" "''${#sources[@]}"

        for source in "''${sources[@]}"; do
          printf "\nStaging:\n%s\n" "$source"

          if not stage_source "$source"; then
            fail "Could not copy the source outside iCloud: $source"
          fi
        done


        find "$staging_dir" -depth \( \
          -name ".DS_Store" -o \
          -name "._*" -o \
          -name ".localized" -o \
          -name ".LSOverride" -o \
          -name $'Icon\r' -o \
          -name "__MACOSX" -o \
          -name ".AppleDouble" -o \
          -name ".Spotlight-V100" -o \
          -name ".Trashes" -o \
          -name ".Trash" -o \
          -name ".Trash-*" -o \
          -name ".fseventsd" -o \
          -name ".TemporaryItems" -o \
          -name ".DocumentRevisions-V100" -o \
          -name ".com.apple.timemachine.donotpresent" -o \
          -name ".VolumeIcon.icns" -o \
          -name "Thumbs.db" -o \
          -name "ehthumbs.db" -o \
          -name "desktop.ini" \
        \) -exec rm -rf -- {} +


        if test -z "$(find "$staging_dir" -mindepth 1 -print -quit)"; then
          fail "Nothing remained after macOS junk was excluded."
        fi


        printf "\nCreating archive outside iCloud:\n%s\n" "$local_archive"

        COPYFILE_DISABLE=1 tar \
          -czf "$local_archive" \
          -C "$staging_dir" \
          . || fail "Archive creation failed."


        tar -tzf "$local_archive" >/dev/null || \
          fail "Local archive verification failed."


        read -r local_hash _ < <(sha256sum "$local_archive")
        local_size=$(stat -c "%s" "$local_archive")


        printf "\nCopying to %s destination(s)...\n" "''${#destinations[@]}"

        for destination in "''${destinations[@]}"; do
          final_archive="$destination/$archive_name"
          in_progress_archive="$destination/.$archive_name.in-progress.$$"

          in_progress_archives+=("$in_progress_archive")

          cp -- "$local_archive" "$in_progress_archive" || \
            fail "Could not copy archive to: $destination"

          copied_size=$(stat -c "%s" "$in_progress_archive")

          if test "$copied_size" != "$local_size"; then
            fail "Copied archive has the wrong size: $in_progress_archive"
          fi

          read -r copied_hash _ < <(sha256sum "$in_progress_archive")

          if test "$copied_hash" != "$local_hash"; then
            fail "Copied archive failed checksum verification: $in_progress_archive"
          fi

          mv -- "$in_progress_archive" "$final_archive" || \
            fail "Could not finalize archive: $final_archive"

          printf "Verified:\n%s\n" "$final_archive"
        done


        in_progress_archives=()


        if test $delete_originals -eq 0; then
          printf "\nFinished successfully. Original sources were kept.\n"
          exit 0
        fi


        delete_root="$HOME/.ftard-delete-$(date +%Y%m%d-%H%M%S)-$$"

        mkdir -p -- "$delete_root" || \
          fail "Could not create the deletion folder: $delete_root"


        printf "\nEvery destination copy passed verification.\n"
        printf "Deleting original sources...\n\n"

        source_number=0

        for source in "''${sources[@]}"; do
          source_number=$((source_number + 1))

          force_delete_source "$source" "$source_number" || true
        done


        if path_exists "$delete_root"; then
          if not force_remove_path "$delete_root"; then
            deletion_failures+=("$delete_root")
          fi
        fi


        remaining_failures=()

        for failed_path in "''${deletion_failures[@]}"; do
          if path_exists "$failed_path"; then
            remaining_failures+=("$failed_path")
          fi
        done


        if test "''${#remaining_failures[@]}" -gt 0; then
          printf "\nThe archives are valid, but these paths could not be deleted:\n" >&2

          for failed_path in "''${remaining_failures[@]}"; do
            printf "  %s\n" "$failed_path" >&2
          done

          exit 1
        fi


        for source in "''${sources[@]}"; do
          if path_exists "$source"; then
            fail "Source still exists after deletion: $source"
          fi
        done


        printf "\nFinished successfully.\n"
        printf "Every archive copy was verified.\n"
        printf "Every original source was permanently deleted.\n"
      '';
    };


  ftar = makeFtarCommand {
    name = "ftar";
    deleteOriginals = false;
  };


  ftard = makeFtarCommand {
    name = "ftard";
    deleteOriginals = true;
  };
in
{
  environment.systemPackages = [
    ftar
    ftard
  ];
}