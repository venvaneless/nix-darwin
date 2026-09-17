# darwin/packages/claude/claude-backup.nix
# Claude backup command: `claude-backup`.
#
# Values only. Every knob below is declared in
# options/backups/app-backup-helper.nix, which owns what each one means
# and how the backup is carried out.

{ paths, ... }:

{
  services.backups.apps.claude = {
    # ---- BACKUP TOGGLE
    # Overrides the global services.appBackups.enabled for this app.
    enable = true;

    # ---- IDENTITY
    appName = "Claude";
    commandName = "claude-backup";

    # ---- PATHS ---- #

    # -- Application Support
    applicationSupportRoot = paths.darwin.library.applicationSupport;

    # -- Preferences
    preferencesRoot = paths.darwin.library.preferences;

    # -- Config
    configRoot = paths.darwin.home.config;

    # -- Destination
    destinationRoot = paths.darwin.backups.apps;
    destinationSegments = [ "claude" ];

    # -- iCloud
    # Backups go to <iCloudRoot>/<appName in lowercase>.
    iCloudRoot = paths.darwin.backups.icloud;

    # ---- EDITABLE BACKUP CONTENTS
    # Entries resolve from the roots above; additionalSources are absolute.

    # ** Claude Desktop. Downloaded Claude Code builds, VM images and
    # ** Electron caches are left out; they come back on the next start.
    applicationSupportEntries = {
      applicationSupportPaths = [
        {
          # Login token cache, theme, locale, extension allowlist
          sourcePath = "Claude/config.json";
          destinationPath = "app-support/Claude/config.json";
        }
        {
          # MCP servers, preferences, Cowork folder access
          sourcePath = "Claude/claude_desktop_config.json";
          destinationPath = "app-support/Claude/claude_desktop_config.json";
        }
        {
          sourcePath = "Claude/Claude Extensions";
          destinationPath = "app-support/Claude/Claude Extensions";
        }
        {
          # Per-extension settings, including allowed folders
          sourcePath = "Claude/Claude Extensions Settings";
          destinationPath = "app-support/Claude/Claude Extensions Settings";
        }
        {
          sourcePath = "Claude/extensions-installations.json";
          destinationPath = "app-support/Claude/extensions-installations.json";
        }
        {
          sourcePath = "Claude/mcp-user-tool-toggles.json";
          destinationPath = "app-support/Claude/mcp-user-tool-toggles.json";
        }
        {
          sourcePath = "Claude/cowork-enabled-cli-ops.json";
          destinationPath = "app-support/Claude/cowork-enabled-cli-ops.json";
        }
        {
          sourcePath = "Claude/git-worktrees.json";
          destinationPath = "app-support/Claude/git-worktrees.json";
        }
        {
          # Cowork sessions and their skills
          sourcePath = "Claude/local-agent-mode-sessions";
          destinationPath = "app-support/Claude/local-agent-mode-sessions";
        }
        {
          # Code tab sessions
          sourcePath = "Claude/claude-code-sessions";
          destinationPath = "app-support/Claude/claude-code-sessions";
        }
        {
          # claude.ai web login
          sourcePath = "Claude/Cookies";
          destinationPath = "app-support/Claude/Cookies";
        }
        {
          sourcePath = "Claude/Local State";
          destinationPath = "app-support/Claude/Local State";
        }
        {
          sourcePath = "Claude/Local Storage";
          destinationPath = "app-support/Claude/Local Storage";
        }
        {
          sourcePath = "Claude/IndexedDB";
          destinationPath = "app-support/Claude/IndexedDB";
        }
      ];

      # Rewritten constantly while the app runs.
      excludePatterns = [
        "LOCK"
        "*-journal"
      ];
    };

    preferenceEntries = {
      preferencePaths = [
        {
          sourcePath = "com.anthropic.claudefordesktop.plist";
          destinationPath = "pref/com.anthropic.claudefordesktop.plist";
        }
      ];

      excludePatterns = [ ];
    };

    # ** Claude Code (CLAUDE_CONFIG_DIR). Plugin code and marketplaces are
    # ** downloaded again from installed_plugins.json and
    # ** known_marketplaces.json, so only those files and plugin data are kept.
    configEntries = {
      configPaths = [
        {
          # Account, trusted folders, per-project MCP servers and tool approvals
          sourcePath = "claude/.claude.json";
          destinationPath = "config/claude/.claude.json";
        }
        {
          # Login
          sourcePath = "claude/.credentials.json";
          destinationPath = "config/claude/.credentials.json";
        }
        {
          # Permissions, additional directories, hooks, model
          sourcePath = "claude/settings.json";
          destinationPath = "config/claude/settings.json";
        }
        {
          # Global memory
          sourcePath = "claude/CLAUDE.md";
          destinationPath = "config/claude/CLAUDE.md";
        }
        {
          # Chat transcripts and per-project memory
          sourcePath = "claude/projects";
          destinationPath = "config/claude/projects";
          excludePatterns = [
            # claude-mem's own observer transcripts
            "-Users-ven--config-claude-mem-observer-sessions/"
          ];
        }
        {
          # Prompt history
          sourcePath = "claude/history.jsonl";
          destinationPath = "config/claude/history.jsonl";
        }
        {
          # Checkpoints used to rewind chats
          sourcePath = "claude/file-history";
          destinationPath = "config/claude/file-history";
        }
        {
          sourcePath = "claude/skills";
          destinationPath = "config/claude/skills";
        }
        {
          sourcePath = "claude/agents";
          destinationPath = "config/claude/agents";
        }
        {
          sourcePath = "claude/commands";
          destinationPath = "config/claude/commands";
        }
        {
          sourcePath = "claude/output-styles";
          destinationPath = "config/claude/output-styles";
        }
        {
          sourcePath = "claude/plugins/installed_plugins.json";
          destinationPath = "config/claude/plugins/installed_plugins.json";
        }
        {
          sourcePath = "claude/plugins/known_marketplaces.json";
          destinationPath = "config/claude/plugins/known_marketplaces.json";
        }
        {
          # Data plugins keep between runs
          sourcePath = "claude/plugins/data";
          destinationPath = "config/claude/plugins/data";
        }
      ];

      excludePatterns = [ ];
    };

    # Absolute paths for data outside the roots above. Uncomment to add one.
    additionalSources = {
      additionalPaths = [
        # {
        #   sourcePath = "${paths.darwin.home.root}/Library/Somewhere/App";
        #   destinationPath = "";
        # }
      ];

      excludePatterns = [ ];
    };

    requiredAny = [ ];

    # ---- INDIVIDUAL ARCHIVE CONTROLS
    archive = true;
    stageInDownloads = true;
    archiveFilenameTemplate = "{timestamp}-{prefix}.tar";
    archiveTimestampFormat = "%Y-%m-%d-%H%M%S";
    archivePrefix = "claude";

    /* iCloud */
    storeiCloud = false;
    cleanOldestiCloud = true;
    iCloudBackupsToKeep = 3;

    # ---- BACKUP CONTROLS
    automatic = false;
    notifyOnAutomatic = true;
    automaticIntervalSeconds = 86400;
    minimumIntervalSeconds = 28800;
    cpuLimitPercent = 25;
    transferLimitKiBps = 4096;

    /* Encryption */
    encrypt = true;
    encryptionIdentityFile = paths.darwin.home.sopsAgeKeys;
    # The public key comes from the identity file on every run

    # ---- BACKUP ARCHITECTURE
    preserveSymlinks = true;

    /* Backup Process */
    showProgress = true;
    processType = "Background";
    niceLevel = 20;
    lowPriorityIO = true;

    /* Logs */
    logDirectory = paths.darwin.backups.logs;
    logFilenameTemplate = "{appSlug}-{timestamp}.log";
    errorLogFilenameTemplate = "{appSlug}-{timestamp}-error.log";
    logTimestampFormat = "%Y-%m-%d-%H-%M-%S";
    logOnlyOnErrors = true;
  };
}
