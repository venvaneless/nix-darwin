# options/obsidian/default.nix
#
# =====================================================================
# OPTIONS: OBSIDIAN COMMAND
# =====================================================================
#
# Defines the portable, user-scoped `obsidian` command. The original
# gitdll, obsidian-missing, and obsidian-library commands are deliberately
# not configured here: they remain independent fallbacks.
# =====================================================================

{ lib, paths, ... }:

let
  # ---- Reusable mode switch ---- #
  # Every independent command mode can be enabled and installed on either
  # supported platform without hiding individual actions from the library TUI.
  mode = description: {
    enable = lib.mkEnableOption description;

    installOn = lib.mkOption {
      type = lib.types.submodule {
        options = {
          darwin = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Install ${description} on Darwin.";
          };

          linux = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Install ${description} on Linux.";
          };
        };
      };
      default = { };
      description = "Platforms on which ${description} is available.";
    };
  };

  # ---- Per-platform path ---- #
  # A host may keep the matching paths.nix default or override one platform
  # directly without changing the other platform's location.
  platformPath = darwinDefault: linuxDefault: description:
    lib.mkOption {
      type = lib.types.submodule {
        options = {
          darwin = lib.mkOption {
            type = lib.types.str;
            default = darwinDefault;
            description = "${description} on Darwin.";
          };

          linux = lib.mkOption {
            type = lib.types.str;
            default = linuxDefault;
            description = "${description} on Linux.";
          };
        };
      };
      default = { };
      description = "Per-platform ${description}.";
    };

  stringList = default: description: lib.mkOption {
    type = lib.types.listOf lib.types.str;
    inherit default description;
  };
in
{
  options.ven.features.obsidian = {
    # ---- Main command ---- #
    enable = lib.mkEnableOption "the independent Obsidian command";

    installOn = lib.mkOption {
      type = lib.types.submodule {
        options = {
          darwin = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Install the command on Darwin.";
          };

          linux = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Install the command on Linux.";
          };
        };
      };
      default = { };
      description = "Platforms on which the independent Obsidian command is installed.";
    };

    # ---- Command modes ---- #
    # The library mode owns its full, familiar TUI. These switches control
    # whole entry points rather than removing individual TUI actions.
    modes = {
      library = mode "the Obsidian library TUI";
      plugins = mode "the Obsidian plugin downloader mode";
      themes = mode "the Obsidian theme downloader mode";
      missing = mode "the Obsidian missing-file recovery mode";
    };

    # ---- Default and overridable paths ---- #
    # Download modes keep gitdll's destinations. Permanent library paths and
    # reports preserve obsidian-library and obsidian-missing defaults.
    paths = {
      pluginDownloads = platformPath
        "${paths.darwin.home.downloads}/gitdll-plugins"
        "${paths.linux.home.downloads}/gitdll-plugins"
        "Default plugin download destination";

      themeDownloads = platformPath
        "${paths.darwin.home.downloads}/gitdll-themes"
        "${paths.linux.home.downloads}/gitdll-themes"
        "Default theme download destination";

      pluginsLibrary = platformPath
        paths.darwin.backups.obsidianExtensions
        paths.linux.backups.obsidianExtensions
        "Permanent plugin-library root";

      themesLibrary = platformPath
        paths.darwin.backups.obsidianThemes
        paths.linux.backups.obsidianThemes
        "Permanent theme-library root";

      missingReport = platformPath
        "${paths.darwin.home.downloads}/obsidian-missing.txt"
        "${paths.linux.home.downloads}/obsidian-missing.txt"
        "Missing-file recovery report";

      libraryReports = platformPath
        paths.darwin.home.downloads
        paths.linux.home.downloads
        "Library audit-report directory";

      libraryErrorReport = platformPath
        "${paths.darwin.home.downloads}/obsidian-library-errors.log"
        "${paths.linux.home.downloads}/obsidian-library-errors.log"
        "Library error-report path";

      libraryFailureReport = platformPath
        paths.darwin.home.downloads
        paths.linux.home.downloads
        "Library batch-failure report directory";
    };

    # ---- Shared download and recovery policy ---- #
    # Both independent download entry points and the reimplemented library
    # manager render these values. They are deliberately not shared with the
    # legacy fallback commands.
    policy = {
      recovery = {
        preferReleaseAssets = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Prefer GitHub release assets before repository-file recovery.";
        };

        allowRepositoryFallback = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Recover an individually missing core file from its repository.";
        };

      };

      content = {
        pluginRequiredFiles = stringList [ "manifest.json" "main.js" ]
          "Required plugin payload files.";
        pluginOptionalFiles = stringList [ "styles.css" "README.md" ]
          "Optional plugin payload files.";
        themeRequiredFiles = stringList [ "manifest.json" "theme.css" ]
          "Required theme payload files.";
        themeOptionalFiles = stringList [ "obsidian.css" "README.md" ]
          "Optional theme payload files.";

        normalizeLayout = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Normalize safe documentation and image layouts after download.";
        };
        keepDocumentation = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Keep permitted documentation files.";
        };
        keepImages = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Keep permitted image assets.";
        };
        keepSnippets = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Keep permitted snippet assets.";
        };
        keepReadme = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Keep a permitted README file.";
        };
        keepNestedContent = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Keep permitted nested content.";
        };
      };

      exclusions = {
        basenameFamilies = stringList [
          "agents"
          "algorithm"
          "architecture"
          "claude"
          "license"
          "changelog"
          "contributing"
          "continent_design"
          "continent-design"
          "codex_task"
          "codex-task"
          "decisions"
          "design_system"
          "design-system"
          "implementation_plan"
          "implementation-plan"
          "manual_test_plan"
          "manual-test-plan"
          "policies"
          "policy"
          "security"
          "privacy"
          "release_checklist"
          "release-checklist"
          "usage_examples"
          "usage-examples"
          "validation"
        ] "Case-insensitive basename families excluded from downloaded content.";

        exactFiles = stringList [
          "agents.md"
          "claude.md"
          "changelog.md"
          "contributing.md"
          "list of urls.md"
          "main-debug.js"
          "publishing.md"
          "release.md"
          "third_party_notices.md"
          "wechat-渐读介绍.md"
          "readme_ko.md"
          "readme_jp.md"
          "readme.zh.md"
          "readme.zh-cn.md"
          "readme-zh_cn.md"
          "readme-zh_tw.md"
          "readme-zh.md"
          "readme-cn.md"
          "readme-tw.md"
        ] "Exact case-insensitive filenames excluded from downloaded content.";

        normalizedTitleStems = stringList [
          "aiassistance"
          "codeofconduct"
          "roadmap"
          "readmeakutagawaja"
          "readmeja"
          "readmesherlock"
          "thirdpartynotices"
        ] "Punctuation-normalized document title stems excluded from downloads.";

        hiddenPaths = stringList [ ".git" ".github" ]
          "Hidden path segments excluded from downloaded content.";
        pathSegments = stringList [ "node_modules" ]
          "Non-hidden path segments excluded from downloaded content.";
        localeMarkers = stringList [ "zh" "ko" "jp" ]
          "Case-insensitive locale path markers excluded from downloads.";
      };

      interaction = {
        promptForArchiveStatus = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Offer archived or abandoned manifest markers after remote checks.";
        };
        confirmSelectedUpdates = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Require confirmation before selected updates replace files.";
        };
        parallelChecks = lib.mkOption {
          type = lib.types.ints.between 1 32;
          default = 6;
          description = "Maximum parallel remote update checks.";
        };
        fzfHeight = lib.mkOption {
          type = lib.types.str;
          default = "80%";
          description = "Height passed to interactive fzf menus.";
        };
        useLinuxTrash = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Use trash-cli for confirmed Linux library removals.";
        };
      };
    };
  };
}
