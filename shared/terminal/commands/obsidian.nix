# shared/terminal/commands/obsidian.nix
#
# =====================================================================
# FISH COMMAND: INDEPENDENT OBSIDIAN DISPATCHER
# =====================================================================
#
# This command deliberately owns a separate implementation. The existing
# gitdll, obsidian-missing, and obsidian-library commands stay untouched as
# recovery fallbacks.
# =====================================================================

{ config, lib, platforms, ... }:

let
  cfg = config.ven.features.obsidian;

  commandEnabled = platforms.enabledForCurrentPlatform cfg;
  libraryEnabled = platforms.enabledForCurrentPlatform cfg.modes.library;
  pluginsEnabled = platforms.enabledForCurrentPlatform cfg.modes.plugins;
  themesEnabled = platforms.enabledForCurrentPlatform cfg.modes.themes;
  missingEnabled = platforms.enabledForCurrentPlatform cfg.modes.missing;
in
{
  config = lib.mkIf commandEnabled {
    programs.fish.functions.obsidian = {
      description = "Manage an independent Obsidian plugin and theme library";

      body = ''
        function __obsidian_command_mode_disabled --argument-names mode
          echo "Error: the Obsidian $mode mode is disabled for this platform."
          return 1
        end

        if test (count $argv) -eq 0
          ${lib.optionalString libraryEnabled ''
            __obsidian_command_library
            return $status
          ''}${lib.optionalString (!libraryEnabled) ''
            __obsidian_command_mode_disabled "library"
            return $status
          ''}
        end

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

          case --missing
            ${lib.optionalString missingEnabled ''
              __obsidian_command_missing $argv[2..]
              return $status
            ''}${lib.optionalString (!missingEnabled) ''
              __obsidian_command_mode_disabled "missing-file recovery"
              return $status
            ''}

          case --check-all --audit --download-plugin --download-theme
            ${lib.optionalString libraryEnabled ''
              __obsidian_command_library $argv
              return $status
            ''}${lib.optionalString (!libraryEnabled) ''
              __obsidian_command_mode_disabled "library"
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
            return 0

          case '*'
            echo "Error: unknown Obsidian command option: $argv[1]"
            echo "Run 'obsidian --help' for the independent command interface."
            return 1
        end
      '';
    };
  };
}
