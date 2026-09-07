# options/terminal-aliases.nix
#
# =====================================================================
# OPTIONS: TERMINAL ALIASES
# =====================================================================
#
# Defines the shared Fish alias entry contract, platform selection, and
# Nix command values. Alias modules provide command entries; paths stay
# centralized in paths.nix and platform checks stay in platforms.nix.
# =====================================================================

{ config, lib, paths, platforms, ... }:

let
  # ------------------------------------------------------------
  # ------ TERMINAL ENTRY CONTRACT ------ #
  # A command may be shared by every platform or provide distinct
  # Darwin and Linux forms. A path can use paths.nix or a literal.
  # ------------------------------------------------------------

  platformStringType = lib.types.submodule {
    options = {
      darwin = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Value used on macOS.";
      };

      linux = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Value used on Linux.";
      };
    };
  };

  # ------------------------------------------------------------
  # ------ NVALIDATE COMMAND SETTINGS ------ #
  # nvalidate has configurable command parts. The alias declaration
  # provides those defaults; this module owns the Fish rendering.
  # ------------------------------------------------------------

  validationCommandType = lib.types.submodule {
    options = {
      flake = {
        path = lib.mkOption {
          type = platformStringType;
          default = { };
          description = "Flake path used by this command on each platform.";
        };

        host = lib.mkOption {
          type = platformStringType;
          default = { };
          description = "Flake host used by this command on each platform.";
        };
      };

      date.format = lib.mkOption {
        type = lib.types.str;
        default = "+%Y-%m-%d-%H%M%S";
        description = "Timestamp format used by this command.";
      };

      log = {
        directory = lib.mkOption {
          type = platformStringType;
          default = { };
          description = "Directory where this command writes its log on each platform.";
        };

        file = lib.mkOption {
          type = lib.types.str;
          default = "$timestamp-nix-eval.log";
          description = "Log filename pattern used by this command.";
        };
      };

      system = {
        configurations = lib.mkOption {
          type = platformStringType;
          default = { };
          description = "Flake configuration namespace used by this command.";
        };

        buildTarget = lib.mkOption {
          type = platformStringType;
          default = { };
          description = "Flake build target used by this command.";
        };

        derivationTarget = lib.mkOption {
          type = platformStringType;
          default = { };
          description = "Flake derivation target evaluated by this command.";
        };
      };
    };
  };

  # ------------------------------------------------------------
  # ------ PINFLAKE COMMAND SETTINGS ------ #
  # pinflake accepts another flake at runtime, while its default
  # flake, GC-root directory, and replacement behavior stay
  # declarative and can be overridden by a host.
  # ------------------------------------------------------------

  pinflakeCommandType = lib.types.submodule {
    options.pinflake = {
      flake.path = lib.mkOption {
        type = platformStringType;
        default = { };
        description = "Default flake path archived by this command on each platform.";
      };

      gcRoots.path = lib.mkOption {
        type = platformStringType;
        default = { };
        description = "Directory where this command creates indirect GC roots on each platform.";
      };

      store.path = lib.mkOption {
        type = lib.types.str;
        default = paths.nixPaths.store;
        description = "Nix store root accepted when this command reads archive output.";
      };

      replaceExistingRoots = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Replace an existing indirect GC root with the same store-path name.";
      };
    };
  };

  # ------------------------------------------------------------
  # ------ FILE AND FOLDER COMMAND SETTINGS ------ #
  # File and folder functions declare their portable defaults in the
  # alias module. This module owns the Fish implementation selected by
  # those settings.
  # ------------------------------------------------------------

  cdfCommandType = lib.types.submodule {
    options.cdf = {
      home.path = lib.mkOption {
        type = platformStringType;
        default = { };
        description = "Home directory where cdf starts on each platform.";
      };

      mobileDocuments.path = lib.mkOption {
        type = platformStringType;
        default = { };
        description = "macOS Mobile Documents directory shown by cdf when it exists.";
      };

      iCloudDrive.path = lib.mkOption {
        type = platformStringType;
        default = { };
        description = "macOS iCloud Drive directory browsed by cdf when it exists.";
      };

      applicationSupport.path = lib.mkOption {
        type = platformStringType;
        default = { };
        description = "macOS Application Support directory shown by cdf when it exists.";
      };

      preferences.path = lib.mkOption {
        type = platformStringType;
        default = { };
        description = "macOS Preferences directory shown by cdf when it exists.";
      };

      rootDirectories = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "Desktop" "Documents" "Downloads" ];
        description = "Home-directory folders cdf offers from its root menu.";
      };

      showHidden = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Show hidden folders when cdf first opens.";
      };
    };
  };

  copyfCommandType = lib.types.submodule {
    options.copyf.command = lib.mkOption {
      type = platformStringType;
      default = { };
      description = "Platform-specific recursive copy command used by copyf.";
    };
  };

  copyfolderCommandType = lib.types.submodule {
    options.copyfolder = { };
  };

  zzCommandType = lib.types.submodule {
    options.zz = {
      path = lib.mkOption {
        type = platformStringType;
        default = { };
        description = "Directory used as zz's default zoxide query starting point on each platform.";
      };

      fzf = {
        height = lib.mkOption {
          type = lib.types.str;
          default = "60%";
          description = "Height passed to fzf by zz.";
        };

        prompt = lib.mkOption {
          type = lib.types.str;
          default = "zoxide cd> ";
          description = "Prompt displayed by zz's fzf picker.";
        };
      };
    };
  };

  unarchiveCommandType = lib.types.submodule {
    options.unarchive.deleteFiles = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Remove successfully extracted archives by default.";
    };
  };

  # ------------------------------------------------------------
  # ------ GIT COMMIT COMMAND SETTINGS ------ #
  # Commit aliases provide only their behavior switches. This module
  # renders the shared Fish implementation and its optional timestamp.
  # ------------------------------------------------------------

  commitCommandType = lib.types.submodule {
    options.commit = {
      date.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Append a timestamp to this commit message.";
      };

      date.format = lib.mkOption {
        type = lib.types.str;
        default = "+%Y-%m-%d-%H:%M";
        description = "Timestamp format appended to this commit message.";
      };

      rebuild = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run drs after a successful commit.";
      };
    };
  };

  # A structured command can be a per-platform command or one of the
  # named implementations below. Keeping the attribute branch unified
  # prevents lib.types.either from selecting the generic platform shape
  # before it reaches a named implementation such as cdf.
  commandType = lib.types.either lib.types.str lib.types.attrs;

  entryType = lib.types.submodule {
    options = {
      command = lib.mkOption {
        type = commandType;
        description = "Fish command or function body provided by this terminal entry.";
      };

      enable = lib.mkEnableOption "terminal entry";

      installOn = {
        darwin = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Make this terminal entry available on macOS.";
        };

        linux = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Make this terminal entry available on Linux.";
        };
      };

      path = lib.mkOption {
        type = platformStringType;
        default = { };
        description = "Per-platform path consumed by this terminal entry.";
      };

      pathSuffix = lib.mkOption {
        type = platformStringType;
        default = { };
        description = "Per-platform text appended directly after this entry's path.";
      };

      arguments = lib.mkOption {
        type = platformStringType;
        default = { };
        description = "Per-platform arguments appended after this entry's path.";
      };

      days = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.positive;
        default = null;
        description = "Default retention age in days for a terminal entry that accepts an age argument.";
      };

      deleteFiles = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Delete successfully processed files by default for this command.";
      };

    };
  };

  entryCollection = lib.mkOption {
    type = lib.types.attrsOf entryType;
    default = { };
    description = "Individually configurable terminal entries.";
  };

  # ------------------------------------------------------------
  # ------ TERMINAL ENTRY BEHAVIOR ------ #
  # Default settings and Fish rendering apply to every alias kind.
  # Platform eligibility and per-platform value selection delegate to
  # the shared helpers in options/platforms.nix.
  # ------------------------------------------------------------

  normalizeEntry = entry:
    if builtins.isString entry then
      { command = entry; }
    else
      entry;

  # Mark complete entry declarations as defaults. Applying mkDefault to a
  # nested command field leaked its override record into Fish rendering.
  mkDefaults = entries:
    lib.mapAttrs (_: entry: lib.mkDefault (normalizeEntry entry)) entries;

  renderValidationCommand = command:
    let
      flakePath = platforms.valueForCurrentPlatform command.flake.path;
      flakeHost = platforms.valueForCurrentPlatform command.flake.host;
      downloadsDirectory = platforms.valueForCurrentPlatform command.log.directory;
      configurationType = platforms.valueForCurrentPlatform command.system.configurations;
      buildTarget = platforms.valueForCurrentPlatform command.system.buildTarget;
      derivationTarget = platforms.valueForCurrentPlatform command.system.derivationTarget;
    in
    ''
      function nvalidate --description "Evaluate and build the Nix system configuration with a Downloads log"
        set -l flake_path "${flakePath}"
        set -l flake_host "${flakeHost}"
        set -l downloads_dir "${downloadsDirectory}"
        set -l timestamp (command date "${command.date.format}")
        set -l log_file "$downloads_dir/${command.log.file}"

        if not test -d "$downloads_dir"
          echo "Downloads folder does not exist: $downloads_dir" >&2
          return 1
        end

        set -l configuration_type "${configurationType}"
        set -l build_target "${buildTarget}"

        echo "Writing validation output to:"
        echo "$log_file"

        begin
          echo "Nix system validation"
          echo "Started: "(command date "+%Y-%m-%d %H:%M:%S %Z")
          echo "Flake: $flake_path#$flake_host"
          echo "Configuration: $configuration_type.$flake_host"
          echo
          echo "=== Evaluating the system configuration ==="

          if not nix eval "$flake_path#${derivationTarget}"
            echo "Evaluation failed. The system build was not started."
            false
          else
            echo
            echo "=== Building the system configuration without activation ==="
            sudo -H nix build "$flake_path#$build_target" --no-link
          end
        end 2>&1 | command tee "$log_file"

        set -l pipeline_status $pipestatus

        if test $pipeline_status[2] -ne 0
          echo "Could not save the validation output to: $log_file" >&2
          return 1
        end

        return $pipeline_status[1]
      end
    '';

  renderPinflakeCommand = command:
    let
      flakePath = platforms.valueForCurrentPlatform command.pinflake.flake.path;
      gcRootsPath = platforms.valueForCurrentPlatform command.pinflake.gcRoots.path;
      removeExistingRoot = lib.optionalString command.pinflake.replaceExistingRoots ''
        # Remove an existing root before recreating it for this store path
        command rm -f "$root_path"
      '';
    in
    ''
      # Set the flake path to the configured default directory
      set -l flake_path "${flakePath}"

      # If an argument was supplied, use it instead
      if test (count $argv) -gt 0

        # Use the first argument as the flake path
        set flake_path "$argv[1]"
      end

      # Check if the specified directory contains a flake
      if not test -f "$flake_path/flake.nix"
        echo "Not a flake directory: $flake_path"

        # Return 1 to indicate an error occurred
        return 1
      end

      # Create a directory for the flake input GC roots
      set -l root_dir "${gcRootsPath}"

      # Use command to bypass the global mkdir alias
      command mkdir -p "$root_dir"

      # Print the flake being archived
      echo "Archiving flake inputs from:"
      echo "$flake_path"

      # Archive the flake and return its input information as JSON
      set -l archive_json (
        nix flake archive --json "$flake_path"
      )

      # Stop if nix flake archive fails
      or begin
        echo "Failed to archive flake inputs."
        return 1
      end

      # Extract all Nix store paths from the archive output
      set -l store_paths (

        printf "%s" "$archive_json" |

        jq -r '
          [
            .path?,
            .storePath?,
            (
              .inputs? // {}

              | ..
              | objects

              | .path?, .storePath?
            )
          ]

          | flatten

          | map(
              select(
                type == "string"
                and startswith("${command.pinflake.store.path}/")
              )
            )

          | unique
          | .[]
        '
      )

      # Make sure at least one input store path was returned
      if test (count $store_paths) -eq 0
        echo "No flake input store paths were returned."
        return 1
      end

      # Create a GC root for every input store path
      for store_path in $store_paths

        # Extract the store path name
        set -l store_name (basename "$store_path")

        # Build the GC root path
        set -l root_path "$root_dir/$store_name"

        ${removeExistingRoot}

        # Realise the store path and create an indirect GC root
        nix-store \
          --realise "$store_path" \
          --add-root "$root_path" \
          --indirect >/dev/null

        # Stop if the input could not be pinned
        or begin
          echo "Failed to pin: $store_path"
          return 1
        end

        # Print the successfully pinned path
        echo "Pinned: $store_path"
      end

      # Print completion information
      echo
      echo "Flake inputs protected from garbage collection."
      echo "GC roots: $root_dir"
    '';

  renderCdfCommand = command:
    let
      cdf = command.cdf;
      homePath = platforms.valueForCurrentPlatform cdf.home.path;
      mobileDocumentsPath = platforms.valueForCurrentPlatform cdf.mobileDocuments.path;
      iCloudDrivePath = platforms.valueForCurrentPlatform cdf.iCloudDrive.path;
      applicationSupportPath = platforms.valueForCurrentPlatform cdf.applicationSupport.path;
      preferencesPath = platforms.valueForCurrentPlatform cdf.preferences.path;
      rootDirectories = lib.concatMapStringsSep " " lib.escapeShellArg cdf.rootDirectories;
      showHidden = if cdf.showHidden then "yes" else "no";
    in
    ''
      set home_path "${homePath}"
      set mobile_docs "${if mobileDocumentsPath == null then "" else mobileDocumentsPath}"
      set icloud_drive "${if iCloudDrivePath == null then "" else iCloudDrivePath}"
      set app_support "${if applicationSupportPath == null then "" else applicationSupportPath}"
      set preferences "${if preferencesPath == null then "" else preferencesPath}"

      set show_hidden "${showHidden}"

      set current_kind "root"
      set current_path "$home_path"

      set stack_kind
      set stack_path

      function __cdf_pretty_container_name
        set raw (basename "$argv[1]")
        set clean "$raw"

        set clean (string replace -r '^iCloud~' "" "$clean")
        set clean (string replace -r '^[A-Z0-9]+~' "" "$clean")
        set clean (string replace -r '^com~apple~' "" "$clean")

        set parts (string split "~" "$clean")
        set label "$parts[-1]"

        echo "$label"
      end

      function __cdf_add_row
        printf "%s\t%s\t%s\n" "$argv[1]" "$argv[2]" "$argv[3]"
      end

      function __cdf_should_skip_hidden
        set base (basename "$argv[1]")

        if test "$show_hidden" = "no"
          if string match -q ".*" "$base"
            return 0
          end
        end

        return 1
      end

      while true
        set rows

        switch "$current_kind"
          case root
            set -a rows (__cdf_add_row "Home" "$home_path" "folder")

            for directory_name in ${rootDirectories}
              set directory_path "$home_path/$directory_name"

              if test -d "$directory_path"
                set -a rows (__cdf_add_row "$directory_name" "$directory_path" "folder")
              end
            end

            if test -d "$mobile_docs"
              set -a rows (__cdf_add_row "iCloud" "$mobile_docs" "icloud-menu")
            end

            if test -d "$app_support"
              set -a rows (__cdf_add_row "Application Support" "$app_support" "folder")
            end

            if test -d "$preferences"
              set -a rows (__cdf_add_row "Preferences" "$preferences" "folder")
            end

            set -a rows (__cdf_add_row "Show Hidden Files: $show_hidden" "$current_path" "toggle-hidden")

          case icloud-menu
            set -a rows (__cdf_add_row "All Folders" "$mobile_docs" "icloud-all")
            set -a rows (__cdf_add_row "App Containers" "$mobile_docs" "icloud-containers")

          case icloud-all
            if test -d "$icloud_drive"
              for dir in (find "$icloud_drive" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
                if __cdf_should_skip_hidden "$dir"
                  continue
                end

                set name (basename "$dir")
                set -a rows (__cdf_add_row "$name" "$dir" "folder")
              end
            end

            if test -d "$mobile_docs"
              for dir in (find "$mobile_docs" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
                if __cdf_should_skip_hidden "$dir"
                  continue
                end

                set base (basename "$dir")

                if test "$base" = "com~apple~CloudDocs"
                  continue
                end

                set name (__cdf_pretty_container_name "$dir")
                set -a rows (__cdf_add_row "$name" "$dir" "folder")
              end
            end

          case icloud-containers
            if test -d "$mobile_docs"
              for dir in (find "$mobile_docs" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
                if __cdf_should_skip_hidden "$dir"
                  continue
                end

                set base (basename "$dir")

                if test "$base" = "com~apple~CloudDocs"
                  continue
                end

                set name (__cdf_pretty_container_name "$dir")
                set -a rows (__cdf_add_row "$name" "$dir" "folder")
              end
            end

          case folder
            if test -d "$current_path"
              for dir in (find "$current_path" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
                if __cdf_should_skip_hidden "$dir"
                  continue
                end

                set name (basename "$dir")
                set -a rows (__cdf_add_row "$name" "$dir" "folder")
              end
            end
        end

        set prompt_name (basename "$current_path")

        set result (
          printf "%s\n" $rows |
          fzf \
            --header="cdf: $current_path" \
            --height=80% \
            --layout=reverse-list \
            --prompt="$prompt_name > " \
            --delimiter=(printf "\t") \
            --with-nth=1 \
            --expect=enter,right,left,ctrl-l,ctrl-h \
            --preview='test -d {2:q} && eza -la --icons=always {2:q} 2>/dev/null || true'
        )

        if test (count $result) -eq 0
          return 0
        end

        set key $result[1]
        set row $result[2]

        if test -z "$row"
          continue
        end

        set fields (string split (printf "\t") "$row")
        set selected_name "$fields[1]"
        set selected_path "$fields[2]"
        set selected_kind "$fields[3]"

        if test "$selected_kind" = "toggle-hidden"
          read -l -P "Show hidden files? [y/N]: " answer

          if string match -qi "y" "$answer"; or string match -qi "yes" "$answer"
            set show_hidden "yes"
          else
            set show_hidden "no"
          end

          continue
        end

        switch "$key"
          case enter
            if test "$selected_kind" = "folder"
              builtin cd "$selected_path"
              return 0
            else
              set -a stack_kind "$current_kind"
              set -a stack_path "$current_path"

              set current_kind "$selected_kind"
              set current_path "$selected_path"
            end

          case right ctrl-l
            set -a stack_kind "$current_kind"
            set -a stack_path "$current_path"

            set current_kind "$selected_kind"
            set current_path "$selected_path"

          case left ctrl-h
            if test (count $stack_kind) -gt 0
              set current_kind "$stack_kind[-1]"
              set current_path "$stack_path[-1]"

              set -e stack_kind[-1]
              set -e stack_path[-1]
            else
              set current_kind "root"
              set current_path "$home_path"
            end
        end
      end
    '';

  renderCopyfCommand = command:
    let
      copyCommand = platforms.valueForCurrentPlatform command.copyf.command;
    in
    ''
      set -l src (string replace -r '/+$' "" -- "$argv[1]")
      set -l dest (string replace -r '/+$' "" -- "$argv[2]")

      if test -z "$src"; or test -z "$dest"; or not test -e "$src"
        echo "Usage: copyf <path/to/file/or/folder> <destination/path>"
        return 1
      end

      if test -e "$dest"
        echo "Destination already exists: $dest"
        return 1
      end

      command mkdir -p (dirname "$dest"); or begin
        echo "Could not create destination parent:"
        echo (dirname "$dest")
        return 1
      end

      ${copyCommand} "$src" "$dest"; or begin
        echo "Copy failed: $src"
        return 1
      end

      echo "Copied: $src -> $dest"
    '';

  renderCopyfolderCommand = ''
    copyf $argv
  '';

  renderZzCommand = command:
    let
      zz = command.zz;
      startPath = platforms.valueForCurrentPlatform zz.path;
    in
    ''
      set -l start_path "${startPath}"

      if not test -d "$start_path"
        echo "zz starting path does not exist: $start_path" >&2
        return 1
      end

      set selected_path (
        zoxide query -l "$start_path" |
        fzf --height=${zz.fzf.height} --reverse --prompt=${lib.escapeShellArg zz.fzf.prompt}
      )

      if test -z "$selected_path"
        return 0
      end

      builtin cd "$selected_path"
    '';

  renderUnarchiveCommand = command:
    let
      deleteFiles = if command.unarchive.deleteFiles then "1" else "0";
    in
    ''
      set -l delete_files ${deleteFiles}

      if test "$argv[1]" = "--delete"
        set delete_files 1
        set -e argv[1]
      end

      if test (count $argv) -eq 0
        echo "Usage: unarchive [--delete] <archive> [archive ...]"
        return 1
      end

      set -l failed_archives

      for input in $argv
        set -l archive (realpath "$input")

        if not test -f "$archive"
          echo "Archive not found: $input"
          set -a failed_archives "$input"
          continue
        end

        set -l parent (dirname "$archive")
        set -l filename (basename "$archive")
        set -l folder_name "$filename"

        switch "$folder_name"
          case '*.tar.gz'
            set folder_name (string replace -r '\.tar\.gz$' "" "$folder_name")
          case '*.tar.bz2'
            set folder_name (string replace -r '\.tar\.bz2$' "" "$folder_name")
          case '*.tar.xz'
            set folder_name (string replace -r '\.tar\.xz$' "" "$folder_name")
          case '*.tar.zst'
            set folder_name (string replace -r '\.tar\.zst$' "" "$folder_name")
          case '*.tgz'
            set folder_name (string replace -r '\.tgz$' "" "$folder_name")
          case '*.tbz2'
            set folder_name (string replace -r '\.tbz2$' "" "$folder_name")
          case '*.tbz'
            set folder_name (string replace -r '\.tbz$' "" "$folder_name")
          case '*.txz'
            set folder_name (string replace -r '\.txz$' "" "$folder_name")
          case '*.tzst'
            set folder_name (string replace -r '\.tzst$' "" "$folder_name")
          case '*.tar'
            set folder_name (string replace -r '\.tar$' "" "$folder_name")
          case '*.gz'
            set folder_name (string replace -r '\.gz$' "" "$folder_name")
          case '*.bz2'
            set folder_name (string replace -r '\.bz2$' "" "$folder_name")
          case '*.xz'
            set folder_name (string replace -r '\.xz$' "" "$folder_name")
          case '*.zst'
            set folder_name (string replace -r '\.zst$' "" "$folder_name")
          case '*.zip'
            set folder_name (string replace -r '\.zip$' "" "$folder_name")
          case '*.rar'
            set folder_name (string replace -r '\.rar$' "" "$folder_name")
          case '*.7z'
            set folder_name (string replace -r '\.7z$' "" "$folder_name")
          case '*.7zip'
            set folder_name (string replace -r '\.7zip$' "" "$folder_name")
        end

        set -l destination "$parent/$folder_name"
        set -l temp_dir (mktemp -d "$parent/.unarchive.XXXXXX")

        if test $status -ne 0
          echo "Could not create temporary extraction folder:"
          echo "$archive"
          set -a failed_archives "$archive"
          continue
        end

        set -l extract_status 1

        switch "$archive"
          case '*.tar.gz' '*.tgz' \
               '*.tar.bz2' '*.tbz2' '*.tbz' \
               '*.tar.xz' '*.txz' \
               '*.tar.zst' '*.tzst' \
               '*.tar'

            tar -xf "$archive" -C "$temp_dir"
            set extract_status $status

          case '*.rar'
            unar -q -o "$temp_dir" "$archive"
            set extract_status $status

          case '*.zip' '*.7z' '*.7zip' '*.gz' '*.bz2' '*.xz' '*.zst'
            7z x -y -o"$temp_dir" "$archive"
            set extract_status $status

          case '*'
            echo "Unsupported archive format: $archive"
            rm -rf "$temp_dir"
            set -a failed_archives "$archive"
            continue
        end

        if test $extract_status -ne 0
          echo "Extraction failed. Archive kept:"
          echo "$archive"

          rm -rf "$temp_dir"
          set -a failed_archives "$archive"
          continue
        end

        # Some .tar.gz-style archives contain one uncompressed .tar.
        # Unpack that inner archive before choosing the final destination.
        set -l nested_tars "$temp_dir"/*.tar

        if test (count $nested_tars) -eq 1; and test -f "$nested_tars[1]"
          tar -xf "$nested_tars[1]" -C "$temp_dir"

          if test $status -ne 0
            echo "Nested tar extraction failed. Archive kept:"
            echo "$archive"

            rm -rf "$temp_dir"
            set -a failed_archives "$archive"
            continue
          end

          rm -f "$nested_tars[1]"
        end

        set -l extracted_items "$temp_dir"/*

        if test (count $extracted_items) -eq 1
          if test -d "$extracted_items[1]"
            if test (basename "$extracted_items[1]") = "$folder_name"
              if test -e "$destination"
                echo "Destination already exists. Archive kept:"
                echo "$destination"

                rm -rf "$temp_dir"
                set -a failed_archives "$archive"
                continue
              end

              mv "$extracted_items[1]" "$destination"
              set -l move_status $status

              rm -rf "$temp_dir"

              if test $move_status -ne 0
                echo "Could not move extracted folder. Archive kept:"
                echo "$archive"

                set -a failed_archives "$archive"
                continue
              end
            else
              if test -e "$destination"
                echo "Destination already exists. Archive kept:"
                echo "$destination"

                rm -rf "$temp_dir"
                set -a failed_archives "$archive"
                continue
              end

              mv "$temp_dir" "$destination"

              if test $status -ne 0
                echo "Could not place extracted contents. Archive kept:"
                echo "$archive"

                rm -rf "$temp_dir"
                set -a failed_archives "$archive"
                continue
              end
            end
          else
            if test -e "$destination"
              echo "Destination already exists. Archive kept:"
              echo "$destination"

              rm -rf "$temp_dir"
              set -a failed_archives "$archive"
              continue
            end

            mv "$temp_dir" "$destination"

            if test $status -ne 0
              echo "Could not place extracted contents. Archive kept:"
              echo "$archive"

              rm -rf "$temp_dir"
              set -a failed_archives "$archive"
              continue
            end
          end
        else
          if test -e "$destination"
            echo "Destination already exists. Archive kept:"
            echo "$destination"

            rm -rf "$temp_dir"
            set -a failed_archives "$archive"
            continue
          end

          mv "$temp_dir" "$destination"

          if test $status -ne 0
            echo "Could not place extracted contents. Archive kept:"
            echo "$archive"

            rm -rf "$temp_dir"
            set -a failed_archives "$archive"
            continue
          end
        end

        if test "$delete_files" -eq 1
          rm -f "$archive"; or begin
            echo "Archive extracted, but could not be deleted:"
            echo "$archive"

            set -a failed_archives "$archive"
            continue
          end

          echo "Removed:   $archive"
        else
          echo "Preserved: $archive"
        end

        echo "Extracted: $destination"
      end

      if test (count $failed_archives) -gt 0
        echo
        echo "Failed archives:"

        for archive in $failed_archives
          echo "$archive"
        end

        return 1
      end
    '';

  renderRetentionCommand = entry:
    let
      command = platforms.valueForCurrentPlatform entry.command;
    in
    ''
      set -l days "$argv[1]"

      if test -z "$days"
        set days ${toString entry.days}
      end

      ${command}
    '';

  renderCommitCommand = name: command:
    let
      dateCommand = if command.commit.date.enable then ''
        set -l timestamp (command date "${command.commit.date.format}")
        set message "$message $timestamp"
      '' else "";
      rebuildCommand = if command.commit.rebuild then "and drs" else "";
    in
    ''
      function ${name}
        set -l message (string join " " $argv)

        if test -z "$message"
          echo "Usage: ${name} <commit-message>"
          return 1
        end

        ${dateCommand}
        git add -A

        if git diff --cached --quiet
          echo "Nothing to commit."
          return 0
        end

        git commit -m "$message"
        ${rebuildCommand}
      end
    '';

  commandForCurrentPlatform = name: entry:
    let
      commandValue =
        if entry.days != null then
          renderRetentionCommand entry
        else if builtins.isAttrs entry.command && entry.command ? flake then
          renderValidationCommand entry.command
        else if builtins.isAttrs entry.command && entry.command ? pinflake then
          renderPinflakeCommand entry.command
        else if builtins.isAttrs entry.command && entry.command ? cdf then
          renderCdfCommand entry.command
        else if builtins.isAttrs entry.command && entry.command ? copyf then
          renderCopyfCommand entry.command
        else if builtins.isAttrs entry.command && entry.command ? copyfolder then
          renderCopyfolderCommand
        else if builtins.isAttrs entry.command && entry.command ? zz then
          renderZzCommand entry.command
        else if builtins.isAttrs entry.command && entry.command ? unarchive then
          renderUnarchiveCommand entry.command
        else if builtins.isAttrs entry.command && entry.command ? commit then
          renderCommitCommand name entry.command
        else
          entry.command;
      command =
        if builtins.isString commandValue then
          commandValue
        else
          platforms.valueForCurrentPlatform commandValue;
      path = platforms.valueForCurrentPlatform entry.path;
      pathSuffix = platforms.valueForCurrentPlatform entry.pathSuffix;
      arguments = platforms.valueForCurrentPlatform entry.arguments;
    in
    if command == null then
      throw "Terminal entry has no command for the current platform"
    else if path == null then
      command
    else
      "${command} ${path}${if pathSuffix == null then "" else pathSuffix}${if arguments == null then "" else arguments}";

  enabledCommands = entries:
    lib.mapAttrs (name: entry: commandForCurrentPlatform name entry) (lib.filterAttrs
      (_: entry: platforms.enabledForCurrentPlatform entry)
      entries);

  # ------------------------------------------------------------
  # ------ NIX ALIAS VALUES ------ #
  # Host values remain directly overridable. Defaults compose values
  # from paths.nix, while platform-specific Nix targets resolve here.
  # ------------------------------------------------------------

  nixCfg = config.ven.features.terminal.fish.nixProfile;
in
{
  options = {
    ven.features.terminal.aliases = {
      shell = entryCollection;
      functions = entryCollection;
      abbreviations = entryCollection;
    };

    ven.features.terminal.commands = entryCollection;


    ven.features.terminal.fish.nixProfile = {
      flakeHost = lib.mkOption {
        type = lib.types.str;
        description = "Flake configuration name for this machine, such as macbook.";
      };

      flakePath = lib.mkOption {
        type = platformStringType;
        default = {
          darwin = "${config.home.homeDirectory}/${paths.relative.nixConfig}";
          linux = "${config.home.homeDirectory}/${paths.relative.nixConfig}";
        };
        description = "Path to this machine's Nix flake checkout on each platform.";
      };

      scriptsPath = lib.mkOption {
        type = platformStringType;
        default = {
          darwin = "${config.home.homeDirectory}/${paths.relative.nixScripts}";
          linux = "${config.home.homeDirectory}/${paths.relative.nixScripts}";
        };
        description = "Path to this machine's Nix helper scripts on each platform.";
      };

      validationLogDirectory = lib.mkOption {
        type = platformStringType;
        default = {
          darwin = "${config.home.homeDirectory}/${paths.relative.downloads}";
          linux = "${config.home.homeDirectory}/${paths.relative.downloads}";
        };
        description = "Directory where nvalidate writes its timestamped log on each platform.";
      };

      flakeInputGCRoots = lib.mkOption {
        type = platformStringType;
        default = {
          darwin = "${config.home.homeDirectory}/${paths.relative.nixFlakeInputGCRoots}";
          linux = "${config.home.homeDirectory}/${paths.relative.nixFlakeInputGCRoots}";
        };
        description = "Directory holding pinflake's indirect Nix GC roots on each platform.";
      };

      storePath = lib.mkOption {
        type = lib.types.str;
        default = paths.nixPaths.store;
        description = "Nix store root used when pinflake reads archive output.";
      };

      systemProfile = lib.mkOption {
        type = platformStringType;
        default = {
          darwin = paths.nixPaths.systemProfile;
          linux = paths.nixPaths.systemProfile;
        };
        description = "Nix system profile managed by generation aliases on each platform.";
      };
    };
  };

  config = {
    programs.fish = {
      shellAliases = enabledCommands config.ven.features.terminal.aliases.shell;
      functions =
        enabledCommands config.ven.features.terminal.aliases.functions
        // enabledCommands config.ven.features.terminal.commands;
      shellAbbrs = enabledCommands config.ven.features.terminal.aliases.abbreviations;
    };

    _module.args = {
      terminalAliasEntries = {
        inherit mkDefaults;

        valueForCurrentPlatform = platforms.valueForCurrentPlatform;

        pathForCurrentPlatform = entry:
          platforms.valueForCurrentPlatform entry.path;
      };

      terminalCommandEntries = {
        inherit mkDefaults;
      };

      nixAliasValues = {
        inherit (nixCfg)
          flakeHost
          flakePath
          scriptsPath
          validationLogDirectory
          flakeInputGCRoots
          storePath
          systemProfile
          ;

        rebuildCommand =
          if platforms.isDarwin then
            "darwin-rebuild"
          else
            "nixos-rebuild";

        systemConfigurations =
          if platforms.isDarwin then
            "darwinConfigurations"
          else
            "nixosConfigurations";

        systemBuildTarget =
          if platforms.isDarwin then
            "darwinConfigurations.${nixCfg.flakeHost}.system"
          else
            "nixosConfigurations.${nixCfg.flakeHost}.config.system.build.toplevel";

        systemDerivationTarget =
          if platforms.isDarwin then
            "darwinConfigurations.${nixCfg.flakeHost}.system.drvPath"
          else
            "nixosConfigurations.${nixCfg.flakeHost}.config.system.build.toplevel.drvPath";
      };
    };
  };
}
