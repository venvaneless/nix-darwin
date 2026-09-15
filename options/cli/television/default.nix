# options/cli/television/default.nix
#
# =====================================================================
# OPTIONS: TELEVISION
#
# Owns Television's option shape, platform selection, TOML rendering,
# custom Nix-navigation channels, generated Fish helpers, and themes.
# shared/terminal/cli-tuis/default.nix assigns every user-facing knob.
# =====================================================================

{ config, paths, platforms, lib, pkgs, ... }:

let
  cfg = config.cli.television;

  # ------------------------------------------------------------
  # ------ PLATFORM SELECTION ------ #
  # ------------------------------------------------------------

  enabledForCurrentPlatform = platforms.enabledForCurrentPlatform cfg;

  # The active Nix configuration root is configured by the shared terminal
  # module. Television searches that root; it does not own the path.
  nixConfigDir = config.ven.features.terminal.nixConfigDir;
  televisionCable = "${paths.relative.config}/television/cable";

  # Television's default palette needs no managed theme file. Named themes
  # are rendered only when the matching theme is selected.
  themeName = if cfg.theme == "default" then "television" else "ven-${cfg.theme}";
  themeFile = "${paths.relative.config}/television/themes/ven-gruvbox.toml";

  televisionLib = import ./lib.nix {
    inherit lib pkgs nixConfigDir;
    inherit (cfg) actions channels search;
    isDarwin = platforms.isDarwin;
  };

  channels = import ./channels {
    inherit lib televisionLib;
    inherit (cfg) channels;
  };
in
{
  options.cli.television = {
    enable = lib.mkEnableOption "Television terminal navigator";

    installOn = {
      darwin = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install and configure Television on macOS.";
      };

      linux = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install and configure Television on Linux.";
      };
    };

    enabledForCurrentPlatform = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether Television is enabled for the Home Manager host currently being built.";
    };

    theme = lib.mkOption {
      type = lib.types.enum [ "default" "gruvbox" ];
      default = "default";
      description = "Built-in Television theme. Choose default or gruvbox.";
    };

    ui = {
      previewPanel.size = lib.mkOption {
        type = lib.types.ints.between 0 100;
        default = 55;
        description = "Percentage of the Television window reserved for file previews.";
      };

      previewPanel.scrollbar = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Show a scrollbar in Television's preview pane.";
      };

      helpPanel.hidden = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Hide Television's built-in help pane.";
      };

      remoteControl.showChannelDescriptions = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Show descriptions for custom Television channels.";
      };

      remoteControl.sortAlphabetically = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Sort Television channel names alphabetically.";
      };
    };

    search.excludedDirectories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ".git" "result" "result-*" ".cache" ];
      description = "Directory-name globs omitted from every custom Nix search channel.";
    };

    actions = {
      default = lib.mkOption {
        type = lib.types.enum [ "nvim" "zed" ];
        default = "nvim";
        description = "Enabled editor action run when Enter is pressed on a Television result.";
      };

      nvim.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Offer an action that opens the selected result with the nvim command from PATH.";
      };

      zed.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Offer an action that opens the selected result with the zed command from PATH.";
      };

      copyAbsolutePath = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Offer an action that copies a result's absolute path.";
      };

      copyRelativePath = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Offer an action that copies a result's path relative to the Nix configuration root.";
      };
    };

    channels = {
      nix = {
        enable = lib.mkEnableOption "the channel that browses the main Nix configuration directory";
        fileGlobs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "File-name globs included by the main Nix configuration browser. An empty list includes every file.";
        };
      };

      nixFiles = {
        enable = lib.mkEnableOption "the channel that searches text inside Nix files";
        fileGlobs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "*.nix" ];
          description = "File-name globs searched by the Nix text-search channel.";
        };
      };

      nixSymbols = {
        enable = lib.mkEnableOption "the channel that searches common Nix declarations";
        patterns = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "environment\\.systemPackages" "home\\.packages" "imports[[:space:]]*=" "programs\\." "services\\." "options\\." "config\\." ];
          description = "Ripgrep regular expressions used by the Nix-symbol search channel.";
        };
      };

      nixImports = {
        enable = lib.mkEnableOption "the channel that searches Nix import declarations";
        patterns = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "imports[[:space:]]*=" "^[[:space:]]*\\.?\\.?/.*\\.nix" "(^|[[:space:](])(builtins\\.)?import[[:space:]]+\\(?\\.?\\.?/.*\\.nix" ];
          description = "Ripgrep regular expressions used by the Nix-import search channel.";
        };
      };

      nixRecent = {
        enable = lib.mkEnableOption "the channel that lists recently modified Nix files";
        maxResults = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = null;
          description = "Maximum recent Nix files shown. Use null to show every matching file.";
        };
      };

      nixGit = {
        enable = lib.mkEnableOption "the channel that browses Git changes in the Nix configuration";
        includeUntracked = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Include untracked files in the Nix Git-status channel.";
        };
      };

      nixDarwin = {
        enable = lib.mkEnableOption "the channel that browses the darwin subdirectory";
        fileGlobs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "File-name globs included by the Darwin configuration browser. An empty list includes every file.";
        };
      };
    };
  };

  config = lib.mkMerge [
    {
      cli.television.enabledForCurrentPlatform = enabledForCurrentPlatform;

      assertions = [
        {
          assertion = cfg.actions.default != "nvim" || cfg.actions.nvim.enable;
          message = "cli.television.actions.default is nvim, but cli.television.actions.nvim.enable is false.";
        }
        {
          assertion = cfg.actions.default != "zed" || cfg.actions.zed.enable;
          message = "cli.television.actions.default is zed, but cli.television.actions.zed.enable is false.";
        }
      ];
    }
    (lib.mkIf enabledForCurrentPlatform {
      # Television owns only its own package. Channel actions use commands
      # already installed elsewhere and resolved from the user's PATH.
      home.packages = [ pkgs.television ];

      xdg.configFile."television/config.toml".text = import ./config.nix {
        inherit themeName;
        inherit (cfg) ui;
      };

      home.file =
        (lib.mapAttrs' (
          name: text:
          lib.nameValuePair "${televisionCable}/${name}.toml" { inherit text; }
        ) channels)
        // lib.optionalAttrs (cfg.theme == "gruvbox") {
          "${themeFile}".text = import ./themes/gruvbox.nix;
        };

      programs.fish.functions.tv = {
        description = "Television with Nix file-search input";
        wraps = "tv";
        body = ''
          if test (count $argv) -gt 1; and test "$argv[1]" = "nix-files"
            set -e argv[1]

            if test (count $argv) -gt 0; and not string match -q -- '-*' $argv
              command tv nix-files --input (string join " " -- $argv)
              return $status
            end

            command tv nix-files $argv
            return $status
          end

          command tv $argv
        '';
      };
    })
  ];
}
