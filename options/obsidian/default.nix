# options/obsidian/default.nix
#
# =====================================================================
# OPTIONS: OBSIDIAN COMMAND
# =====================================================================
#
# Defines the typed vocabulary and semantics for the independent portable
# `obsidian` command. Concrete settings belong in
# shared/terminal/commands/obsidian.nix, so hosts have one visible place to
# adjust every knob. The original gitdll, obsidian-missing, and
# obsidian-library commands remain independent fallbacks.
# =====================================================================

{ lib, ... }:

let
  # ---- Reusable feature switch ---- #
  # The independent command has one feature switch and platform selection.
  feature = description: {
    enable = lib.mkEnableOption description;

    installOn = lib.mkOption {
      type = lib.types.submodule {
        options = {
          darwin = lib.mkOption {
            type = lib.types.bool;
            description = "Install ${description} on Darwin.";
          };

          linux = lib.mkOption {
            type = lib.types.bool;
            description = "Install ${description} on Linux.";
          };
        };
      };
      description = "Platforms on which ${description} is available.";
    };
  };

  # ---- Per-platform path ---- #
  # Values are selected by the option-owned command semantics for the host
  # that renders the Fish functions.
  platformPath = description: lib.mkOption {
    type = lib.types.submodule {
      options = {
        darwin = lib.mkOption {
          type = lib.types.str;
          description = "${description} on Darwin.";
        };

        linux = lib.mkOption {
          type = lib.types.str;
          description = "${description} on Linux.";
        };
      };
    };
    description = "Per-platform ${description}.";
  };

  # ---- Per-platform setting ---- #
  # TUI actions are behavior settings, not installable features. A host can
  # make a menu action available on one platform without an `enable` or
  # `installOn` wrapper.
  platformBool = description: lib.mkOption {
    type = lib.types.submodule {
      options = {
        darwin = lib.mkOption {
          type = lib.types.bool;
          description = "${description} on Darwin.";
        };

        linux = lib.mkOption {
          type = lib.types.bool;
          description = "${description} on Linux.";
        };
      };
    };
    description = "Per-platform ${description}.";
  };

  stringList = description: lib.mkOption {
    type = lib.types.listOf lib.types.str;
    inherit description;
  };

  bool = description: lib.mkOption {
    type = lib.types.bool;
    inherit description;
  };
in
{
  # ---- Obsidian implementation modules ---- #
  # This is the sole option-owned entry point. The module graph supplies
  # shared arguments to each concern; no helper is called through `import`.
  imports = [
    ./download.nix
    ./library.nix
    ./dispatcher.nix
  ];

  options.home.shared.terminal.obsidian = feature "the independent Obsidian command" // {
    # ---- Command modes ---- #
    # The library mode owns its full familiar TUI. These are per-platform
    # command settings; only the root command itself has installOn.
    modes = {
      library = platformBool "Enable the Obsidian library TUI";
      plugins = platformBool "Enable the Obsidian plugin downloader mode";
      themes = platformBool "Enable the Obsidian theme downloader mode";
      missing = platformBool "Enable Obsidian missing-file recovery";
      checkAll = platformBool "Enable the Obsidian full-library update check";
      audit = platformBool "Enable the Obsidian library audit mode";
    };

    # ---- Direct downloader reporting ---- #
    # These settings belong to `obsidian --plugins|--themes` and
    # `obsidian-dll`, not the library TUI.
    downloads = {
      plugins = {
        saveFailureReport = bool "Save a plugin direct-download failure report.";
        failureReport = platformPath "Plugin direct-download failure-report path";
      };
      themes = {
        saveFailureReport = bool "Save a theme direct-download failure report.";
        failureReport = platformPath "Theme direct-download failure-report path";
      };
    };

    # ---- Library TUI actions ---- #
    # Each setting controls one action in the independent TUI. It leaves the
    # separate legacy obsidian-library fallback unchanged.
    actions = {
      browsePlugins = platformBool "Browse installed plugins in the Obsidian TUI";
      browseThemes = platformBool "Browse installed themes in the Obsidian TUI";
      checkUpdates = platformBool "Check and update entries in the Obsidian TUI";
      alternateVersion = platformBool "Download alternate versions in the Obsidian TUI";
      remove = platformBool "Remove an entry through the Obsidian TUI";
      archiveStatus = platformBool "Check archive status in the Obsidian TUI";
      auditLocal = platformBool "Write local audits from the Obsidian TUI";
      auditRemote = platformBool "Write remote audits from the Obsidian TUI";
      downloadPlugin = platformBool "Download a plugin from the Obsidian TUI";
      downloadTheme = platformBool "Download a theme from the Obsidian TUI";
      downloadPluginPaths = platformBool "Download selected plugin files and folders from the Obsidian TUI";
      downloadThemePaths = platformBool "Download selected theme files and folders from the Obsidian TUI";
    };

    # ---- Default and overridable paths ---- #
    paths = {
      pluginDownloads = platformPath "Default plugin download destination";
      themeDownloads = platformPath "Default theme download destination";
      pluginsLibrary = platformPath "Permanent plugin-library root";
      themesLibrary = platformPath "Permanent theme-library root";
      missingReport = platformPath "Missing-file recovery report";
      libraryReports = platformPath "Library audit-report directory";
      partialDownloads = platformPath "TUI-selected repository file and folder download directory";
      libraryErrorReport = platformPath "Library error-report path";
      libraryFailureReport = platformPath "Library batch-failure report directory";
    };

    # ---- Shared download and recovery policy ---- #
    # The option-owned core renders these settings identically for the TUI,
    # `obsidian --plugins|--themes`, and `obsidian-dll`.
    policy = {
      recovery = {
        preferReleaseAssets = bool "Prefer GitHub release assets before repository-file recovery.";
        allowRepositoryFallback = bool "Recover an individually missing core file from its repository.";
      };

      content = {
        pluginRequiredFiles = stringList "Required plugin payload files.";
        pluginOptionalFiles = stringList "Optional plugin payload files.";
        themeRequiredFiles = stringList "Required theme payload files.";
        themeOptionalFiles = stringList "Optional theme payload files.";
        normalizeLayout = bool "Normalize safe documentation and image layouts after download.";
        keepDocumentation = bool "Keep permitted documentation files.";
        keepImages = bool "Keep permitted image assets.";
        keepSnippets = bool "Keep permitted snippet assets.";
        keepReadme = bool "Keep a permitted README file.";
        keepNestedContent = bool "Keep permitted nested content.";
      };

      exclusions = {
        basenameFamilies = stringList "Case-insensitive basename families excluded from downloaded content.";
        exactFiles = stringList "Exact case-insensitive filenames excluded from downloaded content.";
        normalizedTitleStems = stringList "Punctuation-normalized document title stems excluded from downloads.";
        hiddenPaths = stringList "Hidden path segments excluded from downloaded content.";
        pathSegments = stringList "Non-hidden path segments excluded from downloaded content.";
        localeMarkers = stringList "Case-insensitive locale path markers excluded from downloads.";
      };

      # ---- Library update policy ---- #
      # These values govern only the independent library TUI's update and
      # repair workflow. They do not alter legacy fallback commands.
      updates = {
        reuseMovedOptionalFiles = platformBool "Track and update moved or renamed optional files during a library update";
        repairIncomplete = bool "Offer repair when a required library payload is incomplete";
        skipCurrent = bool "Skip a healthy entry whose canonical repository is already current";
      };

      interaction = {
        promptForArchiveStatus = bool "Offer archived or abandoned manifest markers after remote checks.";
        confirmSelectedUpdates = bool "Require confirmation before selected updates replace files.";
        parallelChecks = lib.mkOption {
          type = lib.types.ints.between 1 32;
          description = "Maximum parallel remote update checks.";
        };
        fzfHeight = lib.mkOption {
          type = lib.types.str;
          description = "Height passed to interactive fzf menus.";
        };
        useLinuxTrash = bool "Use trash-cli for confirmed Linux library removals.";
      };
    };
  };
}
