# darwin/system-commands/fmove.nix
#
# =====================================================================
# FMOVE
#
# Copy one or more files and folders into one destination.
#
# Modes:
# - fmove
#     Opens an interactive FZF picker.
#
# - fmove [--trash-source] source1 source2 --to destination
#     Uses paths directly from the command line.
#
# Features:
# - Supports files, folders and symbolic links
# - Supports paths containing spaces without quoting
# - Supports multiple source paths
# - Copies through a destination-local staging path
# - Verifies every copy before publishing it
# - Keeps sources by default
# - Sends sources to macOS Trash only with --trash-source
# - Refuses to overwrite existing destination items
# =====================================================================

{ pkgs, ... }:

let
  fmove = pkgs.writeShellApplication {
    name = "fmove";

    runtimeInputs = with pkgs; [
      coreutils
      fd
      findutils
      fzf
      rsync
    ];

    text = ''
      set -Eeuo pipefail


      selected_sources=()
      destination=""
      search_root="$PWD"
      in_progress_paths=()
      trash_source=0


      usage() {
        cat <<'USAGE'
Usage:
  fmove
  fmove [--trash-source] SOURCE [SOURCE ...] --to DESTINATION

Behavior:
  fmove copies and verifies every selected source, then keeps the original.

  --trash-source sends a verified source to macOS Trash only when the
  destination is outside iCloud. If the destination is in iCloud, fmove
  keeps the source so you can wait for Finder to show that the upload is done.

Interactive controls:

Source picker:
  Type         Filter the displayed files and folders
  TAB          Select or unselect multiple items
  RIGHT/ENTER  Continue with the selected items
  CTRL-P       Paste or drag an exact source path
  CTRL-R       Change the recursive search root
  ESC          Cancel

Destination picker:
  Type         Filter the displayed folders
  RIGHT        Open the highlighted folder
  LEFT         Go to the parent folder
  ENTER        Use the highlighted folder
  CTRL-P       Paste or drag an exact destination path
  ESC          Cancel

Examples:
  fmove

  fmove file1 folder2 folder3 --to destination

  fmove --trash-source file1 folder2 --to destination

Paths containing spaces can be entered without quotes:

  fmove /Users/ven/Library/Mobile Documents/example --to /Users/ven/Desktop/New Folder
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


      join_words() {
        local joined=""
        local word

        for word in "$@"; do
          if test -z "$joined"; then
            joined="$word"
          else
            joined="$joined $word"
          fi
        done

        printf "%s\n" "$joined"
      }


      cleanup() {
        local exit_status=$?
        local temporary_path

        for temporary_path in "''${in_progress_paths[@]}"; do
          if path_exists "$temporary_path"; then
            rm -rf -- "$temporary_path" 2>/dev/null || true
          fi
        done

        exit "$exit_status"
      }


      add_source() {
        local requested_source="$1"
        local normalized_source
        local existing_source

        path_exists "$requested_source" || begin_error=1

        if test "''${begin_error:-0}" -eq 1; then
          unset begin_error
          printf "Source does not exist:\n%s\n" "$requested_source" >&2
          return 1
        fi

        normalized_source=$(normalize_existing_path "$requested_source") || begin_error=1

        if test "''${begin_error:-0}" -eq 1; then
          unset begin_error
          printf "Could not resolve source:\n%s\n" "$requested_source" >&2
          return 1
        fi

        for existing_source in "''${selected_sources[@]}"; do
          if test "$existing_source" = "$normalized_source"; then
            return 0
          fi
        done

        selected_sources+=("$normalized_source")
      }


      parse_command_line() {
        local argument_mode="sources"
        local source_words=()
        local destination_words=()

        local start_index
        local end_index
        local part_index
        local word_count

        local candidate
        local found_source

        while test $# -gt 0; do
          case "$1" in
            --trash-source)
              trash_source=1
              shift
              ;;

            --keep-source)
              trash_source=0
              shift
              ;;

            --to)
              if test "$argument_mode" = "destinations"; then
                fail "--to may only be used once."
              fi

              argument_mode="destinations"
              shift
              ;;

            --help|-h)
              usage
              exit 0
              ;;

            *)
              if test "$argument_mode" = "sources"; then
                source_words+=("$1")
              else
                destination_words+=("$1")
              fi

              shift
              ;;
          esac
        done

        if test "''${#source_words[@]}" -eq 0; then
          fail "No source paths were provided."
        fi

        if test "''${#destination_words[@]}" -eq 0; then
          fail "No destination was provided. Put --to before the destination."
        fi

        start_index=0
        word_count="''${#source_words[@]}"

        while test "$start_index" -lt "$word_count"; do
          found_source=0

          for ((end_index = word_count - 1; end_index >= start_index; end_index--)); do
            candidate=""

            for ((part_index = start_index; part_index <= end_index; part_index++)); do
              if test -z "$candidate"; then
                candidate="''${source_words[part_index]}"
              else
                candidate="$candidate ''${source_words[part_index]}"
              fi
            done

            if path_exists "$candidate"; then
              add_source "$candidate" || exit 1

              start_index=$((end_index + 1))
              found_source=1
              break
            fi
          done

          if test "$found_source" -eq 0; then
            printf "Could not reconstruct a valid source path beginning with:\n" >&2
            printf "%s\n" "''${source_words[start_index]}" >&2
            exit 1
          fi
        done

        destination=$(join_words "''${destination_words[@]}")

        if ! test -d "$destination"; then
          fail "Destination folder does not exist: $destination"
        fi
      }


      choose_sources_with_fzf() {
        local candidates=()
        local result=()

        local key
        local typed_path
        local item
        local index

        while true; do
          candidates=()
          result=()

          mapfile -d "" candidates < <(
            fd \
              --hidden \
              --no-ignore \
              --absolute-path \
              --print0 \
              . \
              "$search_root" 2>/dev/null
          )

          mapfile -t result < <(
            printf "%s\n" "''${candidates[@]}" |
            fzf \
              --multi \
              --height="90%" \
              --layout="reverse-list" \
              --border \
              --prompt="Move from $(basename "$search_root") > " \
              --header="TAB select | RIGHT/ENTER continue | CTRL-P paste path | CTRL-R change root" \
              --expect="right,enter,ctrl-p,ctrl-r" \
              --bind="tab:toggle" || true
          )

          if test "''${#result[@]}" -eq 0; then
            exit 130
          fi

          key="''${result[0]:-}"

          case "$key" in
            ctrl-p)
              printf "Paste or drag the source path:\n> "
              IFS= read -r typed_path

              if test -n "$typed_path"; then
                add_source "$typed_path" || true
              fi
              ;;

            ctrl-r)
              printf "Paste or drag the folder to search recursively:\n> "
              IFS= read -r typed_path

              if test -d "$typed_path"; then
                search_root=$(
                  cd -- "$typed_path"
                  pwd -P
                )
              else
                printf "Not a folder:\n%s\n" "$typed_path" >&2
              fi
              ;;

            right|enter)
              for ((index = 1; index < ''${#result[@]}; index++)); do
                item="''${result[index]}"

                if test -n "$item"; then
                  add_source "$item" || true
                fi
              done

              if test "''${#selected_sources[@]}" -eq 0; then
                echo "Nothing was selected."
                continue
              fi

              return 0
              ;;
          esac
        done
      }


      choose_destination_with_fzf() {
        local current_directory="$PWD"
        local rows=()
        local result=()

        local key
        local row
        local label
        local chosen_path
        local typed_path
        local folder

        while true; do
          rows=()
          result=()

          rows+=(
            "[Use this folder]"$'\t'"$current_directory"
          )

          while IFS= read -r -d "" folder; do
            if test -d "$folder"; then
              rows+=(
                "$(basename "$folder")/"$'\t'"$folder"
              )
            fi
          done < <(
            find -P "$current_directory" \
              -mindepth 1 \
              -maxdepth 1 \
              -print0 2>/dev/null |
            sort -z
          )

          mapfile -t result < <(
            printf "%s\n" "''${rows[@]}" |
            fzf \
              --height="90%" \
              --layout="reverse-list" \
              --border \
              --delimiter=$'\t' \
              --with-nth="1" \
              --prompt="Destination $(basename "$current_directory") > " \
              --header="RIGHT open folder | LEFT parent | ENTER choose | CTRL-P paste path" \
              --expect="right,left,ctrl-h,enter,ctrl-p" || true
          )

          if test "''${#result[@]}" -eq 0; then
            exit 130
          fi

          key="''${result[0]:-}"
          row="''${result[1]:-}"

          case "$key" in
            left|ctrl-h)
              current_directory=$(dirname -- "$current_directory")
              ;;

            ctrl-p)
              printf "Paste or drag the destination folder:\n> "
              IFS= read -r typed_path

              if test -d "$typed_path"; then
                destination=$(
                  cd -- "$typed_path"
                  pwd -P
                )

                return 0
              fi

              printf "Destination folder does not exist:\n%s\n" "$typed_path" >&2
              ;;

            right)
              if test -z "$row"; then
                continue
              fi

              label=$(printf "%s\n" "$row" | cut -f1)
              chosen_path=$(printf "%s\n" "$row" | cut -f2-)

              if test "$label" = "[Use this folder]"; then
                destination="$current_directory"
                return 0
              fi

              if test -d "$chosen_path"; then
                current_directory="$chosen_path"
              fi
              ;;

            enter)
              if test -z "$row"; then
                continue
              fi

              chosen_path=$(printf "%s\n" "$row" | cut -f2-)

              if test -d "$chosen_path"; then
                destination="$chosen_path"
                return 0
              fi
              ;;
          esac
        done
      }


      validate_move() {
        local normalized_destination
        local source_count
        local first_index
        local second_index

        local source
        local other_source
        local source_name
        local other_name
        local source_parent
        local final_path

        test -d "$destination" || fail "Destination folder does not exist: $destination"

        normalized_destination=$(
          cd -- "$destination"
          pwd -P
        ) || fail "Could not resolve destination: $destination"

        destination="$normalized_destination"
        source_count="''${#selected_sources[@]}"

        for ((first_index = 0; first_index < source_count; first_index++)); do
          source="''${selected_sources[first_index]}"
          source_name=$(basename -- "$source")
          source_parent=$(dirname -- "$source")
          final_path="$destination/$source_name"

          case "$source" in
            /)
              fail "Refusing to move the filesystem root."
              ;;

            "$HOME")
              fail "Refusing to move the entire home folder."
              ;;

            "$HOME/Library")
              fail "Refusing to move the entire Library folder."
              ;;

            "$HOME/Library/Mobile Documents")
              fail "Refusing to move the entire Mobile Documents folder."
              ;;

            "$HOME/Library/Mobile Documents/com~apple~CloudDocs")
              fail "Refusing to move the entire iCloud Drive."
              ;;
          esac

          if test "$source_parent" = "$destination"; then
            fail "Source is already inside the destination: $source"
          fi

          if path_exists "$final_path"; then
            fail "Destination item already exists: $final_path"
          fi

          if test -d "$source" && ! test -L "$source"; then
            case "$destination" in
              "$source"/*)
                fail "Destination cannot be inside a selected source: $destination"
                ;;
            esac
          fi

          for ((second_index = first_index + 1; second_index < source_count; second_index++)); do
            other_source="''${selected_sources[second_index]}"
            other_name=$(basename -- "$other_source")

            if test "$source_name" = "$other_name"; then
              fail "Two selected sources have the same name: $source_name"
            fi

            case "$other_source" in
              "$source"/*)
                fail "A selected source is inside another selected source: $other_source"
                ;;
            esac

            case "$source" in
              "$other_source"/*)
                fail "A selected source is inside another selected source: $source"
                ;;
            esac
          done
        done
      }


      request_icloud_downloads() {
        local source="$1"
        local item

        if ! test -x /usr/bin/brctl; then
          return 0
        fi

        timeout 120 /usr/bin/brctl download "$source" >/dev/null 2>&1 || true

        if test -d "$source" && ! test -L "$source"; then
          while IFS= read -r -d "" item; do
            timeout 120 /usr/bin/brctl download "$item" >/dev/null 2>&1 || true
          done < <(
            find -P "$source" \
              -type f \
              -print0 2>/dev/null
          )
        fi
      }


      is_icloud_path() {
        case "$1" in
          "$HOME/Library/Mobile Documents"|"$HOME/Library/Mobile Documents"/*)
            return 0
            ;;
        esac

        return 1
      }


      copy_source_to_staging() {
        local source="$1"
        local temporary_path="$2"

        if test -d "$source" && ! test -L "$source"; then
          mkdir -p -- "$temporary_path"

          COPYFILE_DISABLE=1 rsync \
            -a \
            -- \
            "$source/" \
            "$temporary_path/"
        else
          COPYFILE_DISABLE=1 rsync \
            -a \
            -- \
            "$source" \
            "$temporary_path"
        fi
      }


      verify_staged_copy() {
        local source="$1"
        local temporary_path="$2"
        local differences
        local source_link
        local temporary_link

        if test -L "$source"; then
          source_link=$(readlink "$source")
          temporary_link=$(readlink "$temporary_path")

          if test "$source_link" = "$temporary_link"; then
            return 0
          fi

          printf "Symlink verification failed:\n%s\n" "$source" >&2
          return 1
        fi

        if test -d "$source"; then
          differences=$(COPYFILE_DISABLE=1 rsync \
            -a \
            --checksum \
            --dry-run \
            --itemize-changes \
            -- \
            "$source/" \
            "$temporary_path/") || return 1

          if test -z "$differences"; then
            return 0
          fi

          printf "Directory verification found differences:\n%s\n" "$differences" >&2
          return 1
        fi

        if cmp -s -- "$source" "$temporary_path"; then
          return 0
        fi

        printf "File verification failed:\n%s\n" "$source" >&2
        return 1
      }


      send_source_to_trash() {
        local source="$1"

        if /usr/bin/trash "$source"; then
          printf "Original moved to Trash:\n%s\n" "$source"
          return 0
        fi

        printf "Could not move the original to Trash; it was kept:\n%s\n" "$source" >&2
        return 1
      }


      transfer_source() {
        local source="$1"
        local source_name
        local final_path
        local temporary_path
        local confirmation

        source_name=$(basename -- "$source")
        final_path="$destination/$source_name"
        temporary_path="$destination/.fmove-in-progress-$$-$source_name"

        printf "\nCopying:\n%s\n" "$source"
        printf "To:\n%s\n" "$destination"

        if is_icloud_path "$source"; then
          echo "Requesting an iCloud download before copying..."
          request_icloud_downloads "$source"
        fi

        if path_exists "$temporary_path"; then
          fail "Staging path already exists; refusing to reuse it: $temporary_path"
        fi

        in_progress_paths+=("$temporary_path")

        if ! copy_source_to_staging "$source" "$temporary_path"; then
          fail "Could not copy the source into the destination: $source"
        fi

        echo "Verifying copied data..."
        if ! verify_staged_copy "$source" "$temporary_path"; then
          fail "The staged copy does not match the source: $source"
        fi

        if path_exists "$final_path"; then
          fail "Destination item appeared while copying: $final_path"
        fi

        /bin/mv "$temporary_path" "$final_path" || \
          fail "Could not finalize the destination item: $final_path"

        if path_exists "$temporary_path"; then
          fail "Could not finalize the staged copy: $temporary_path"
        fi

        printf "Copy verified:\n%s\n" "$final_path"

        if test "$trash_source" -eq 0; then
          printf "Original kept:\n%s\n" "$source"
          return 0
        fi

        if is_icloud_path "$final_path"; then
          printf "\nDestination is in iCloud, so the original was kept:\n%s\n" "$source"
          echo "Wait until Finder shows the destination is no longer Waiting to Upload,"
          echo "then verify it from another device before moving the original to Trash."
          return 0
        fi

        printf "Send the verified original to Trash? [y/N] "
        if ! IFS= read -r confirmation; then
          echo "No confirmation received; original kept."
          return 0
        fi

        case "$confirmation" in
          y|Y|yes|YES)
            send_source_to_trash "$source"
            ;;

          *)
            printf "Original kept:\n%s\n" "$source"
            ;;
        esac
      }


      trap cleanup EXIT


      if test $# -eq 0; then
        choose_sources_with_fzf
        choose_destination_with_fzf
      elif test $# -eq 1 && test "$1" = "--trash-source"; then
        trash_source=1
        choose_sources_with_fzf
        choose_destination_with_fzf
      else
        parse_command_line "$@"
      fi


      validate_move


      for source in "''${selected_sources[@]}"; do
        transfer_source "$source"
      done


      echo
      echo "Finished successfully."
      echo "Copied and verified ''${#selected_sources[@]} item(s) to:"
      echo "$destination"
    '';
  };
in
{
  environment.systemPackages = [
    fmove
  ];
}
