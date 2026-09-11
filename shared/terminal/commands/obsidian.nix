# shared/terminal/commands/obsidian.nix
#
# =====================================================================
# FISH COMMAND: INDEPENDENT OBSIDIAN
# =====================================================================
#
# This is the one editable configuration surface for the independent
# `obsidian` and `obsidian-dll` commands. Option types and command semantics
# are supplied through the Home Manager special-argument flow from
# options/obsidian/; this module only chooses values and installs the rendered
# result. Existing gitdll, obsidian-missing, and obsidian-library commands
# are intentionally untouched fallbacks.
# =====================================================================

{ paths, ... }:

{
  config = {
    ven.features.obsidian = {
      # ---- Main command ---- #
      # Keep this disabled until the independent implementation has completed
      # its requested validation. Legacy commands continue to be available.
      # Installs neither `obsidian` nor `obsidian-dll` while false.
      enable = false;

      # Selects platforms where the independent command may be installed.
      installOn = {
        darwin = true;
        linux = true;
      };

      # ---- Command entry points ---- #
      # `library` is the complete familiar TUI at `obsidian`; plugin and theme
      # modes additionally power `obsidian --plugins|--themes` and
      # `obsidian-dll --plugins|--themes`.
      modes = {
        # Enables the complete interactive library manager at `obsidian`.
        library = { darwin = true; linux = true; };

        # Enables `--plugin` and `--plugins` direct-download entry points.
        plugins = { darwin = true; linux = true; };

        # Enables `--theme` and `--themes` direct-download entry points.
        themes = { darwin = true; linux = true; };

        # Enables missing-file recovery, including the TUI repair handoff.
        missing = { darwin = true; linux = true; };

        # Enables non-interactive `obsidian --check-all`.
        checkAll = { darwin = true; linux = true; };

        # Enables non-interactive `obsidian --audit local|remote`.
        audit = { darwin = true; linux = true; };
      };

      # ---- Direct downloader reports ---- #
      # These affect `obsidian --plugins|--themes` and `obsidian-dll`, not
      # the TUI's own audit, error, or batch-failure reports.
      downloads = {
        plugins = {
          # Saves failed plugin sources and download errors when true.
          saveFailureReport = true;
          # File written when a direct plugin download has failures.
          failureReport = {
            darwin = "${paths.darwin.home.downloads}/obsidian-plugin-download-failures.txt";
            linux = "${paths.linux.home.downloads}/obsidian-plugin-download-failures.txt";
          };
        };

        themes = {
          # Saves failed theme sources and download errors when true.
          saveFailureReport = true;
          # File written when a direct theme download has failures.
          failureReport = {
            darwin = "${paths.darwin.home.downloads}/obsidian-theme-download-failures.txt";
            linux = "${paths.linux.home.downloads}/obsidian-theme-download-failures.txt";
          };
        };
      };

      # ---- Library TUI actions ---- #
      # These are menu capabilities, not command-line flags. Set a platform
      # value to false to hide only that action from the independent TUI.
      actions = {
        # Shows the installed-plugin browser and its actions.
        browsePlugins = { darwin = true; linux = true; };

        # Shows the installed-theme browser and its actions.
        browseThemes = { darwin = true; linux = true; };

        # Shows update checks and selected/all update choices.
        checkUpdates = { darwin = true; linux = true; };

        # Allows choosing and installing a different release version.
        alternateVersion = { darwin = true; linux = true; };

        # Allows typed-confirmation removal to the platform Trash.
        remove = { darwin = true; linux = true; };

        # Allows remote archive/abandonment status checks and markers.
        archiveStatus = { darwin = true; linux = true; };

        # Shows the local-library audit report action.
        auditLocal = { darwin = true; linux = true; };

        # Shows the remote-library audit report action.
        auditRemote = { darwin = true; linux = true; };

        # Shows full plugin downloads into the configured plugin library.
        downloadPlugin = { darwin = true; linux = true; };

        # Shows full theme downloads into the configured theme library.
        downloadTheme = { darwin = true; linux = true; };

        # Shows per-repository plugin file/folder selection downloads.
        downloadPluginPaths = { darwin = true; linux = true; };

        # Shows per-repository theme file/folder selection downloads.
        downloadThemePaths = { darwin = true; linux = true; };
      };

      # ---- Paths ---- #
      # Each path retains its current platform default while allowing a host
      # to replace either platform directly. This keeps external-drive Linux
      # roots independent from Darwin paths.
      paths = {
        # Destination for direct plugin downloads without `--to`.
        pluginDownloads = {
          darwin = "${paths.darwin.home.downloads}/gitdll-plugins";
          linux = "${paths.linux.home.downloads}/gitdll-plugins";
        };

        # Destination for direct theme downloads without `--to`.
        themeDownloads = {
          darwin = "${paths.darwin.home.downloads}/gitdll-themes";
          linux = "${paths.linux.home.downloads}/gitdll-themes";
        };

        # Permanent plugin-library root managed by the TUI.
        pluginsLibrary = {
          darwin = paths.darwin.backups.obsidianExtensions;
          linux = paths.linux.backups.obsidianExtensions;
        };

        # Permanent theme-library root managed by the TUI.
        themesLibrary = {
          darwin = paths.darwin.backups.obsidianThemes;
          linux = paths.linux.backups.obsidianThemes;
        };

        # Report written after missing-file recovery scans.
        missingReport = {
          darwin = "${paths.darwin.home.downloads}/obsidian-missing.txt";
          linux = "${paths.linux.home.downloads}/obsidian-missing.txt";
        };

        # Directory where dated audit reports are written.
        libraryReports = {
          darwin = paths.darwin.home.downloads;
          linux = paths.linux.home.downloads;
        };

        # Destination for TUI-selected repository files and folders.
        partialDownloads = {
          darwin = "${paths.darwin.home.downloads}/obsidian-partial-downloads";
          linux = "${paths.linux.home.downloads}/obsidian-partial-downloads";
        };

        # Log file for recoverable library-manager errors.
        libraryErrorReport = {
          darwin = "${paths.darwin.home.downloads}/obsidian-library-errors.log";
          linux = "${paths.linux.home.downloads}/obsidian-library-errors.log";
        };

        # Directory for batch download failure reports.
        libraryFailureReport = {
          darwin = paths.darwin.home.downloads;
          linux = paths.linux.home.downloads;
        };
      };

      # ---- Recovery policy ---- #
      policy.recovery = {
        # Uses GitHub release assets before repository-file recovery.
        preferReleaseAssets = true;

        # Recovers missing required files from the repository when permitted.
        allowRepositoryFallback = true;
      };

      # ---- Content policy ---- #
      # The same allowed-content and normalization policy is rendered into
      # both the TUI and the compatible direct plugin/theme downloader.
      policy.content = {
        # Files every plugin payload must contain to be considered valid.
        pluginRequiredFiles = [
          "manifest.json"
          "main.js"
        ];
        # Extra plugin files retained when their content is permitted.
        pluginOptionalFiles = [
          "styles.css"
          "README.md"
        ];
        # Files every theme payload must contain to be considered valid.
        themeRequiredFiles = [
          "manifest.json"
          "theme.css"
        ];
        # Extra theme files retained when their content is permitted.
        themeOptionalFiles = [
          "obsidian.css"
          "README.md"
        ];

        # Normalizes safe downloaded documentation and image layout.
        normalizeLayout = true;
        # Retains allowed documentation files and folders.
        keepDocumentation = true;
        # Retains allowed image assets.
        keepImages = true;
        # Retains allowed snippet files and folders.
        keepSnippets = true;
        # Retains an allowed README.
        keepReadme = true;
        # Retains allowed content below the repository root.
        keepNestedContent = true;
      };

      # ---- Exclusion policy ---- #
      # exactFiles matches an exact basename anywhere, case-insensitively.
      # basenameFamilies matches a basename regardless of extension or case.
      # The option-owned helper applies this one policy to TUI and CLI paths.
      policy.exclusions = {
        # Excludes these exact basenames anywhere, case-insensitively.
        exactFiles = [
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
        ];

        # Excludes these basename families with any extension or capitalization.
        basenameFamilies = [
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
        ];

        # Excludes punctuation-normalized document-title variants.
        normalizedTitleStems = [
          "aiassistance"
          "codeofconduct"
          "roadmap"
          "readmeakutagawaja"
          "readmeja"
          "readmesherlock"
          "thirdpartynotices"
        ];
        # Excludes these hidden repository path segments.
        hiddenPaths = [ ".git" ".github" ];
        # Excludes these ordinary repository path segments.
        pathSegments = [ "node_modules" ];
        # Excludes files and folders carrying these locale markers.
        localeMarkers = [ "zh" "ko" "jp" ];
      };

      # ---- Library update policy ---- #
      policy.updates = {
        # Tracks, reuses, and updates optional files moved or renamed inside a library entry.
        reuseMovedOptionalFiles = { darwin = true; linux = true; };

        # Offers a staged repair when a required payload is incomplete.
        repairIncomplete = true;

        # Reports a healthy, unchanged canonical repository as already current.
        skipCurrent = true;
      };

      # ---- TUI and update interaction ---- #
      policy.interaction = {
        # Offers manifest archive/abandoned status marking after checks.
        promptForArchiveStatus = true;
        # Requires confirmation before selected updates replace files.
        confirmSelectedUpdates = true;
        # Limits concurrent remote checks.
        parallelChecks = 6;
        # Sets the height of fzf selection menus.
        fzfHeight = "80%";
        # Uses trash-cli rather than deletion for Linux removals.
        useLinuxTrash = true;
      };
    };
  };
}
