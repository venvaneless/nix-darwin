# options/obsidian/dispatcher.nix
#
# =====================================================================
# OBSIDIAN: COMMAND DISPATCHER
# =====================================================================
#
# This command deliberately owns a separate implementation. The existing
# gitdll, obsidian-missing, and obsidian-library commands stay untouched as
# recovery fallbacks.
# =====================================================================

{
  config,
  lib,
  platforms,
  ...
}:

let
  cfg = config.ven.features.obsidian;

  libraryEnabled = platforms.valueForCurrentPlatform cfg.modes.library;
  pluginsEnabled = platforms.valueForCurrentPlatform cfg.modes.plugins;
  themesEnabled = platforms.valueForCurrentPlatform cfg.modes.themes;
  missingEnabled = platforms.valueForCurrentPlatform cfg.modes.missing;
  checkAllEnabled = platforms.valueForCurrentPlatform cfg.modes.checkAll;
  auditEnabled = platforms.valueForCurrentPlatform cfg.modes.audit;

in
{
  # The private download and library functions are supplied by sibling
  # option modules. This module owns only the public command dispatcher.
  config = lib.mkIf (platforms.enabledForCurrentPlatform cfg) {
    programs.fish.functions = {
      # ---- Shared disabled-mode message ---- #
      # Kept as a private installed function so `obsidian-dll` can reject a
      # disabled mode even when the main `obsidian` command has not run yet.
      __obsidian_command_mode_disabled = {
        description = "Report a disabled independent Obsidian command mode";

        body = ''
          echo "Error: the Obsidian $argv[1] mode is disabled for this platform."
          return 1
        '';
      };

      # ---- Shared plugin/theme entry point ---- #
      # Both public names call the independent downloader core; neither calls
      # the legacy gitdll functions.
      __obsidian_command_download = {
        description = "Dispatch independent Obsidian plugin and theme downloads";

        body = ''
          switch "$argv[1]"
            case --plugins --plugin
              ${lib.optionalString pluginsEnabled ''
                __obsidian_command_gitdll --plugins $argv[2..]
                return $status
              ''}${lib.optionalString (!pluginsEnabled) ''
                __obsidian_command_mode_disabled "plugin downloader"
                return $status
              ''}

            case --themes --theme
              ${lib.optionalString themesEnabled ''
                __obsidian_command_gitdll --themes $argv[2..]
                return $status
              ''}${lib.optionalString (!themesEnabled) ''
                __obsidian_command_mode_disabled "theme downloader"
                return $status
              ''}

            case '*'
              echo "Error: choose --plugins/--plugin or --themes/--theme."
              return 1
          end
        '';
      };

      # ---- Main command ---- #
      obsidian = {
      description = "Manage an independent Obsidian plugin and theme library";

      body = ''
        function __obsidian_command_run_tui
          set --local missing_request_file (command mktemp -t obsidian-missing.XXXXXXXXXX)
          if test -z "$missing_request_file"
            echo "Error: could not prepare the missing-file repair request."
            return 1
          end

          while true
            set --erase OBSIDIAN_LIBRARY_MISSING_REQUEST_FILE
            set --erase OBSIDIAN_LIBRARY_MISSING_ENABLED
            set --local --export OBSIDIAN_LIBRARY_MISSING_REQUEST_FILE "$missing_request_file"
            set --local --export OBSIDIAN_LIBRARY_MISSING_ENABLED ${if missingEnabled then "1" else "0"}
            __obsidian_command_library
            set --local library_status $status

            if test "$library_status" -ne 42
              command rm -f -- "$missing_request_file"
              return "$library_status"
            end

            if not test -s "$missing_request_file"
              command rm -f -- "$missing_request_file"
              echo "Error: the library TUI did not provide a repair path."
              return 1
            end

            set --local repair_path (string trim -- (string collect <"$missing_request_file"))
            command rm -f -- "$missing_request_file"
            __obsidian_command_missing "$repair_path"
            set --local repair_status $status
            if test "$repair_status" -ne 0
              return "$repair_status"
            end

            set missing_request_file (command mktemp -t obsidian-missing.XXXXXXXXXX)
            if test -z "$missing_request_file"
              echo "Error: could not prepare another missing-file repair request."
              return 1
            end
          end
        end

        if test (count $argv) -eq 0
          ${lib.optionalString libraryEnabled ''
            __obsidian_command_run_tui
            return $status
          ''}${lib.optionalString (!libraryEnabled) ''
            __obsidian_command_mode_disabled "library"
            return $status
          ''}
        end

        switch "$argv[1]"
          case --plugins --plugin
            __obsidian_command_download $argv
            return $status

          case --themes --theme
            __obsidian_command_download $argv
            return $status

          case --missing
            ${lib.optionalString missingEnabled ''
              __obsidian_command_missing $argv[2..]
              return $status
            ''}${lib.optionalString (!missingEnabled) ''
              __obsidian_command_mode_disabled "missing-file recovery"
              return $status
            ''}

          case --check-all
            ${lib.optionalString (libraryEnabled && checkAllEnabled) ''
              __obsidian_command_library $argv
              return $status
            ''}${lib.optionalString (!libraryEnabled) ''
              __obsidian_command_mode_disabled "library"
              return $status
            ''}${lib.optionalString (libraryEnabled && !checkAllEnabled) ''
              __obsidian_command_mode_disabled "full-library update check"
              return $status
            ''}

          case --audit
            ${lib.optionalString (libraryEnabled && auditEnabled) ''
              __obsidian_command_library $argv
              return $status
            ''}${lib.optionalString (!libraryEnabled) ''
              __obsidian_command_mode_disabled "library"
              return $status
            ''}${lib.optionalString (libraryEnabled && !auditEnabled) ''
              __obsidian_command_mode_disabled "library audit"
              return $status
            ''}

          case --download-plugin
            ${lib.optionalString (libraryEnabled && pluginsEnabled) ''
              __obsidian_command_library $argv
              return $status
            ''}${lib.optionalString (!libraryEnabled) ''
              __obsidian_command_mode_disabled "library"
              return $status
            ''}${lib.optionalString (libraryEnabled && !pluginsEnabled) ''
              __obsidian_command_mode_disabled "plugin downloader"
              return $status
            ''}

          case --download-theme
            ${lib.optionalString (libraryEnabled && themesEnabled) ''
              __obsidian_command_library $argv
              return $status
            ''}${lib.optionalString (!libraryEnabled) ''
              __obsidian_command_mode_disabled "library"
              return $status
            ''}${lib.optionalString (libraryEnabled && !themesEnabled) ''
              __obsidian_command_mode_disabled "theme downloader"
              return $status
            ''}

          case --help -h help
            echo "Usage:"
            echo "  obsidian"
            echo "  obsidian --plugins SOURCE... [--to DESTINATION] [--include PATH] [--include-file FILE]"
            echo "  obsidian --themes SOURCE... [--to DESTINATION] [--include PATH] [--include-file FILE]"
            echo "  obsidian --missing LIBRARY_PATH"
            echo "  obsidian --check-all"
            echo "  obsidian --audit local|remote"
            echo "  obsidian --download-plugin SOURCE"
            echo "  obsidian --download-theme SOURCE"
            echo "  obsidian-dll --plugins|--plugin SOURCE... [--to DESTINATION] [--include PATH] [--include-file FILE]"
            echo "  obsidian-dll --themes|--theme SOURCE... [--to DESTINATION] [--include PATH] [--include-file FILE]"
            return 0

          case '*'
            echo "Error: unknown Obsidian command option: $argv[1]"
            echo "Run 'obsidian --help' for the independent command interface."
            return 1
        end
      '';
      };

      # ---- Familiar downloader-only name ---- #
      # Keeps the TUI at `obsidian` while exposing gitdll-compatible plugin
      # and theme entry points under a clear, independent name.
      obsidian-dll = {
        description = "Download Obsidian plugins and themes independently";

        body = ''
          if test (count $argv) -eq 0; or contains -- "$argv[1]" --help -h help
            echo "Usage:"
            echo "  obsidian-dll --plugins|--plugin SOURCE... [--to DESTINATION] [--include PATH] [--include-file FILE]"
            echo "  obsidian-dll --themes|--theme SOURCE... [--to DESTINATION] [--include PATH] [--include-file FILE]"
            return 0
          end

          __obsidian_command_download $argv
        '';
      };
    };
  };
}
