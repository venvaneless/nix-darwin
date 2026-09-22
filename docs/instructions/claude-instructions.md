# Claude: Instructions


I want Claude and its cli to be completely owned by and configured through Nix. This below is a plan and instructions how we will do it.


## Configuration Directory

- This is where all Claude configuration files will be stored:

```text
/Users/ven/.config/claude/
```

- Plugins I want to have installed from the  very beginning:

```text
https://github.com/kepano/obsidian-skills
https://github.com/thedotmack/claude-mem
```

claude-mem configuration should be here:
```text
/Users/ven/.config/claude-mem/
```

## All Nix Options for Claude Code

Upstream home-manager options are assigned directly in `shared/home/agents.nix`, and `options/agents/claude/` will hold custom features, which upstream doesn't cover.

- Here are the nix options I want to have. None of them are optional; I want all of them existing and to be declared and managed through Nix.

#### settings
home-manager/option/programs.claude-code.settings

`programs.claude-code.settings`
JSON configuration for Claude Code settings.json.

**Declaration type**: JSON value
**Default**: {}
**Example**:
```nix
{
  hooks = {
    PostToolUse = [
      {
        hooks = [
          {
            command = "nix fmt $(jq -r '.tool_input.file_path' &lt;&lt;&lt; '$CLAUDE_TOOL_INPUT')";
            type = "command";
          }
        ];
        matcher = "Edit|MultiEdit|Write";
      }
    ];
    PreToolUse = [
      {
        hooks = [
          {
            command = "echo 'Running command: $CLAUDE_TOOL_INPUT'";
            type = "command";
          }
        ];
        matcher = "Bash";
      }
    ];
  };
  includeCoAuthoredBy = false;
  model = "claude-3-5-sonnet-20241022";
  permissions = {
    additionalDirectories = [
      "../docs/"
    ];
    allow = [
      "Bash(git diff:*)"
      "Edit"
    ];
    ask = [
      "Bash(git push:*)"
    ];
    defaultMode = "acceptEdits";
    deny = [
      "WebFetch"
      "Bash(curl:*)"
      "Read(./.env)"
      "Read(./secrets/**)"
    ];
    disableBypassPermissionsMode = "disable";
  };
  statusLine = {
    command = "input=$(cat); echo \"[$(echo \"$input\" | jq -r '.model.display_name')] 📁 $(basename \"$(echo \"$input\" | jq -r '.workspace.current_dir')\")\"";
    padding = 0;
    type = "command";
  };
  theme = "dark";
}
```



#### configDir
home-manager/option/programs.claude-code.configDir

`programs.claude-code.configDir`
Directory holding Claude Code's configuration files.

Defaults to `~/.claude`, matching the upstream `claude` CLI default. The `CLAUDE_CONFIG_DIR` environment variable is exported automatically whenever the directory differs from this default so the CLI reads configuration from the same location.

**Declarations type**: string
**Default**: "${config.home.homeDirectory}/.claude"
**Example**: "${config.xdg.configHome}/claude"


#### skills
home-manager/option/programs.claude-code.skills

`programs.claude-code.skills`
Custom skills for Claude Code.

This option can be either:
  • An attribute set defining skills
  • A path to a directory containing skill folders

If an attribute set is used, the attribute name becomes the skill directory name, and the value is either:
  • Inline content as a string (creates `skills/<name>/SKILL.md`)
  • A path to a file (creates `skills/<name»/SKILL.md`)
  • A path to a directory (creates (`skills/<name>/` with all files)

This also accepts Nix store paths, for example a skill directory from a package.

If a path is used, it is expected to contain one folder per skill name, each containing a `SKILL.md`. The directory is symlinked into the skills subdirectory of `programs.claude-code.configDir`.

**Declarations type**: (attribute set of (strings concatenated with "\n" or absolute path)) or absolute path
**Default**: {}
**Example**:
```nix

{
  xlsx = ./skills/xlsx/SKILL.md;
  data-analysis = ./skills/data-analysis;
  pdf-processing = ''
    ---
    name: pdf-processing
    description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
    ---

    # PDF Processing

    ## Quick start

    Use pdfplumber to extract text from PDFs:

    ```python
    import pdfplumber

    with pdfplumber.open("document.pdf") as pdf:
        text = pdf.pages[0].extract_text()
    ```
  '';

  # A skill can also be a subdirectory within a package source (store path)
  beads = "${pkgs.beads.src}/claude-plugin/skills/beads";
}
```

#### plugins
home-manager/option/programs.claude-code.plugins

`programs.claude-code.plugins`
Plugins to use when running Claude Code. The attribute name becomes the plugin directory name, and the value is either:
  • A path to the plugin directory
  • The plugin package, whether a nix package or the output of a fetcher. With Claude Code 2.1.157 or later, each plugin is symlinked into the `skills/` subdirectory of `programs.claude-code.configDir` and loaded as a personal plugin, exposing its skills, agents, commands, hooks, and MCP servers. Versions 2.1.76 through 2.1.156 fall back to a legacy `--plugin-dir` wrapper, as do packages without detectable version metadata. Strict-parser subcommands such as `claude rc` may reject arguments from that compatibility path.

A plugin that lives in a subdirectory of a larger repository can be referenced through a store path, in which case only that subdirectory is linked and the surrounding repository is
left out.

A plain list of plugins is still accepted but deprecated, since the directory name is then derived from each entry's base name and store paths produce unstable names such as `bxalsøm3h4sh-source-`

**Declarations type**: (attribute set of (package or absolute path)) or list of (package or absolute path)
**Default**: {}
**Example**:
```nix
{
  my-local-plugin = ./my-local-plugin;
  claude-plugin = fetchFromGitHub {
    owner = "some-github-org";
    repo = "claude-plugin";
    rev = "779a68ebc2a75e4a184d2c87e5a43a758e6458a1";
    sha256 = "228fdd7e5908ea1d2f65218ecd9c71e1eefa0834d200d55fbb8bf8b5563acec0";
  };

  # A plugin can also be a subdirectory within a package source
  # (store path).
  nested-plugin = "${pkgs.some-package.src}/claude-plugin";
}
```


#### commands
home-manager/option/programs.claude-code.commands

`programs.claude-code.commands`
Custom commands for Claude Code. The attribute name becomes the command filename, and the value is either:
  • Inline content as a string
  • A path to a file containing the command content Commands are stored in the `commands/` subdirectory of `programs.claude-code.configDir`.

**Declarations type**: attribute set of (strings concatenated with "\n" or absolute path)
**Default**: {}
**Example**:
```nix
{
  changelog = ''
    ---
    allowed-tools: Bash(git log:*), Bash(git diff:*)
    argument-hint: [version] [change-type] [message]
    description: Update CHANGELOG.md with new entry
    ---
    Parse the version, change type, and message from the input
    and update the CHANGELOG.md file accordingly.
  '';
  fix-issue = ./commands/fix-issue.md;
  commit = ''
    ---
    allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
    description: Create a git commit with proper message
    ---
    ## Context

    - Current git status: !`git status`
    - Current git diff: !`git diff HEAD`
    - Recent commits: !`git log --oneline -5`

    ## Task

    Based on the changes above, create a single atomic git commit with a descriptive message.
  '';
}
```


#### hooks
home-manager/option/programs.claude-code.hooks

`programs.claude-code.hooks`
Custom hooks for Claude Code. The attribute name becomes the hook filename, and the value is either:
  • Inline content as a string
  • A path to a file containing the hook script content. Hooks are stored in the `hooks/` subdirectory of `programs.claude-code.configDir` and made executable.

**Declarations type**: attribute set of (strings concatenated with "\n" or absolute path)
**Default**: {}
**Example**:
```nix
{
  pre-edit = ''
    #!/usr/bin/env bash
    echo "About to edit file: $1"
  '';
  post-commit = ./hooks/post-commit.sh;
}
```

#### hooksDir
home-manager/option/programs.claude-code.hooksDir

`programs.claude-code.hooksDir`
Path to a directory containing hook files for Claude Code. Hook files from this directory will be symlinked into the `hooks/` subdirectory of `programs.claude-code.configDir`.

**Declarations type**: null or absolute path
**Default**: null
**Example**:
```nix
{
  hooksDir = ./hooks;
}
```


#### agents
home-manager/option/programs.claude-code.agents

`programs.claude-code.agents`
Custom agents for Claude Code. The attribute name becomes the agent filename, and the value is either:
  • Inline content as a string with frontmatter
  • A path to a file containing the agent content with frontmatter.

Agents are stored in the `agents/` subdirectory of `programs.claude-code. configDir`

**Declarations type**: attribute set of (strings concatenated with "\n" or absolute path)
**Default**: {}
**Example**:
```nix
  code-reviewer = ''
    ---
    name: code-reviewer
    description: Specialized code review agent
    tools: Read, Edit, Grep
    ---

    You are a senior software engineer specializing in code reviews.
    Focus on code quality, security, and maintainability.
  '';
  documentation = ./agents/documentation.md;
```

#### agentsDir
home-manager/option/programs.claude-code.agentsDir

`programs.claude-code.agentsDir`
Path to a directory containing agent files for Claude Code. Agent files from this directory will be symlinked into the `agents/` subdirectory of `programs.claude-code.configDir`.

**Declarations type**: null or absolute path
**Default**: null
**Example**:
```nix
{
  agentsDir = ./agents;
}
```


#### rules
home-manager/option/programs.claude-code.rules

`programs.claude-code.rules`
Modular rule files for Claude Code. The attribute name becomes the rule filename, and the value is either:
  • Inline content as a string
  • A path to a file containing the rule content Rules are stored in the `rules` subdirectory of `programs.claude-code.configDir`. All markdown files in that directory are automatically loaded as project memory.

**Declarations type**: attribute set of (strings concatenated with "\n" or absolute path)
**Default**: {}
**Example**:
```nix
  my-rule = ''
    # Rule content here
  '';
  another-rule = ./rules/another-rule.md;
```

#### rulesDir
home-manager/option/programs.claude-code.rulesDir

`programs.claude-code.rulesDir`
Path to a directory containing rule files for Claude Code. Rule files from this directory will be symlinked into the `rules/` subdirectory of `programs.claude-code.configDir`. All markdown files in this directory are automatically loaded as project memory.

**Declarations type**: null or absolute path
**Default**: null or absolute path
**Example**:
```nix
{
  rulesDir = ./rules;
}
```


#### commands
home-manager/option/programs.claude-code.commands

`programs.claude-code.commands`
Custom commands for Claude Code. The attribute name becomes the command filename, and the value is either:
  • Inline content as a string
  • A path to a file containing the command content Commands are stored in the `commands/` subdirectory of `programs.claude-code.configDir`
**Declarations type**: attribute set of (strings concatenated with "\n" or absolute path)
**Default**: {}
**Example**:
```nix

{
  changelog = ''
    ---
    allowed-tools: Bash(git log:*), Bash(git diff:*)
    argument-hint: [version] [change-type] [message]
    description: Update CHANGELOG.md with new entry
    ---
    Parse the version, change type, and message from the input
    and update the CHANGELOG.md file accordingly.
  '';
  fix-issue = ./commands/fix-issue.md;
  commit = ''
    ---
    allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
    description: Create a git commit with proper message
    ---
    ## Context

    - Current git status: !`git status`
    - Current git diff: !`git diff HEAD`
    - Recent commits: !`git log --oneline -5`

    ## Task

    Based on the changes above, create a single atomic git commit with a descriptive message.
  '';
}
```

#### commandsDir
home-manager/option/programs.claude-code.commandsDir

`programs.claude-code.commandsDir`
Path to a directory containing command files for Claude Code. Command files from this directory will be symlinked into the `commands/` subdirectory of `programs.claude-code.configDir`. All markdown files in this directory are automatically loaded as project memory.

**Declarations type**: null or absolute path
**Default**: null or absolute path
**Example**:
```nix
{
  commandsDir = ./commands;
}
```


#### lspServers
home-manager/option/programs.claude-code.lspServers

`programs.claude-code.lspServers`
LSP (Language Server Protocol) servers configuration.

**Declarations type**: attribute set of (JSON value)
**Default**: {}
**Example**:
```nix

{
  go = {
    args = [
      "serve"
    ];
    command = "gopls";
    extensionToLanguage = {
      ".go" = "go";
    };
  };
  typescript = {
    args = [
      "--stdio"
    ];
    command = "typescript-language-server";
    extensionToLanguage = {
      ".js" = "javascript";
      ".jsx" = "javascriptreact";
      ".ts" = "typescript";
      ".tsx" = "typescriptreact";
    };
  };
}
```


#### mcp1Servers
home-manager/option/programs.claude-code.mcpServers

`programs.claude-code.mcpServers`
MCP (Model Context Protocol) servers configuration.

**Declarations type**: attribute set of (JSON value)
**Default**: {}
**Example**:
```nix

{
  customTransport = {
    customOption = "value";
    timeout = 5000;
    type = "websocket";
    url = "wss://example.com/mcp";
  };
  database = {
    args = [
      "-y"
      "@bytebase/dbhub"
      "--dsn"
      "postgresql://user:pass@localhost:5432/db"
    ];
    command = "npx";
    env = {
      DATABASE_URL = "postgresql://user:pass@localhost:5432/db";
    };
    type = "stdio";
  };
  filesystem = {
    args = [
      "-y"
      "@modelcontextprotocol/server-filesystem"
      "/tmp"
    ];
    command = "npx";
    type = "stdio";
  };
  github = {
    type = "http";
    url = "https://api.githubcopilot.com/mcp/";
  };
}
```


#### outputStyles
home-manager/option/programs.claude-code.outputStyles

`programs.claude-code.outputStyles`
Custom output styles for Claude Code. The attribute name becomes the base of the output style filename. The value is either:
  • Inline content as a string
  • A path to a file In both cases, the contents will be written to `output-styles/<name>.md` inside `programs.claude-code.configDir`.

**Declarations type**: attribute set of (package or absolute path)
**Default**: {}
**Example**:
```nix

{
  local-marketplace = ./my-local-marketplace;
  gh-marketplace = fetchFromGitHub {
    owner = "some-github-org";
    repo = "claude-marketplace";
    rev = "8a873a220b8427b25b03ce1a821593a24e098c34";
    sha256 = "5c2dce95122b5bb73fa547edabbb6c3061c2d193d11e51faecd4d22659e67279";
  };
}
```


#### marketplaces
home-manager/option/programs.claude-code.marketplaces

`programs.claude-code.marketplaces`
  • A path to the marketplace directory
  • The marketplace package, whether a nix package or the output of a fetcher.

**Declarations type**: attribute set of (JSON value)
**Default**: {}
**Example**:
```nix
{
  marketplace1 = {
    url = "https://example.com/marketplace1";
    apiKey = "your-api-key";
  };
  marketplace2 = {
    url = "https://example.com/marketplace2";
    apiKey = "your-api-key";
  };
}
```


#### context
home-manager/option/programs.claude-code.context

`programs.claude-code.context`
Global context for Claude Code.

The value is either:
  • Inline content as a string
  • A path to a file containing the content
  The configured content is written to `CLAUDE.md` inside `programs.claude-code.configDir` (default `~/.claude/CLAUDE.md`).

**Declarations type**: strings concatenated with "\n" or absolute path
**Default**: ""
**Example**:
```nix
{
  context = ./claude-memory.md;
}
```


#### claude-powerline
home-manager/option/programs.claude-code.claude-powerline

For CLI I also want to have this installed
`programs.claude-code.claude-powerline`
Beautiful vim-style powerline for Claude Code.

**Declarations type**: boolean
**Default**: false
**Example**:
```nix
{
  programs.claude-code.claude-powerline = true;
}
```


---

## Architecture

As with every other configuration in Nix, claude will also be split between logic and knobs.

Logic goes to:
```text
options/agents/claude/default.nix
```

Obviously, if there's more settings for different purposes like mcp, lsp, etc. they would go into separate files within the same directory structure.

The knobs will be in:
```text
shared/home/agents.nix
```

Let me know if anything will be installed via system and not HM so we think about restructuring the architecture accordingly.

Also let me know what else should I think about adding or not adding.

Remember that I won't need the Claude app anymore, only the CLI, since using the extension for Claude in VSCode as GUI is enough. The important thing is though that I still want to be able to use my skills, plugins and when needed, allow Claude access to my local files and environment and allow it to manipulate the system, launch apps for me, etc.

Existing settings for Claude should be incorporated into the change.

I want to keep the memories and chats I already have. Just let me know how we back them up and restore if it needs restoring in the first place.

---

# Plan (agreed 2026-09-17)

## Findings that change the request above
- **The pinned home-manager (26.05) doesn't match the docs above.** Its `plugins` option is a list that only adds `--plugin-dir` flags through a wrapper script, so only the terminal CLI sees those plugins. The attrset form above comes from home-manager master. We use `marketplaces` instead, which works in VS Code too.
- **The claude-mem memory database isn't in any backup.**
- **Claude Code deletes chats older than 30 days by default.**

## 1. What goes where

| Piece                                                      | Where                                                                             | Why                                                                         |
| ---------------------------------------------------------- | --------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| Claude Code CLI (`unstablePkgs.claude-code`)               | home-manager                                                                      | `programs.claude-code.package`                                              |
| `settings.json` (permissions, hook entries, `env`, model…) | home-manager                                                                      | `programs.claude-code.settings`                                             |
| Hook scripts (`guard.py`)                                  | home-manager                                                                      | `programs.claude-code.hooksDir`                                             |
| Rules                                                      | home-manager                                                                      | `programs.claude-code.rulesDir`                                             |
| Agents                                                     | home-manager                                                                      | `programs.claude-code.agentsDir`                                            |
| Commands                                                   | home-manager                                                                      | `programs.claude-code.commandsDir`                                          |
| Global `CLAUDE.md`                                         | home-manager                                                                      | `programs.claude-code.context`                                              |
| obsidian-skills, claude-mem, later marketplaces            | home-manager                                                                      | `programs.claude-code.marketplaces` + `settings.enabledPlugins` (section 2) |
| MCP and LSP servers                                        | home-manager                                                                      | `programs.claude-code.mcpServers` / `lspServers`, **but see section 9**     |
| claude-powerline                                           | home-manager (`home.packages` + `settings.statusLine`)                            | Only in `nixpkgs-unstable` (1.30.3), not in 26.05                           |
| `CLAUDE_CONFIG_DIR`                                        | home-manager: `home.sessionVariables` (fish) + Claude extension setting (VS Code) | See section 8 B                                                             |
| `CLAUDE_MEM_DATA_DIR`, npm paths, `DISABLE_AUTOUPDATER`    | home-manager: `settings.json` `env` block                                         | Applies to every Claude session and its hooks, however started              |
| `claude-backup` command                                    | nix-darwin, stays where it is                                                     | Uses the darwin backup helpers                                              |
| macOS permissions for computer use                         | **Can't be declared**                                                             | Toggled once in System Settings                                             |

Nothing has to be installed at system level, so the architecture doesn't need to change.

## 2. Plugins and marketplaces
- **Why not `plugins`:** the VS Code extension runs its own bundled `claude`, so it never sees wrapper flags. claude-mem also can't run from the read-only Nix store, because it installs its own `node_modules` next to its scripts.
- **How:** same pattern as the Codex setup. A marketplace points at a pinned flake input, and Claude Code installs its own writable copy into `plugins/cache`:
  - `marketplaces.claude-mem = inputs.claude-mem;` (already a flake input)
  - `marketplaces.obsidian-skills = inputs.obsidian-skills;` (**new flake input**, `github:kepano/obsidian-skills`, `flake = false`)
  - `settings.enabledPlugins = { "claude-mem@claude-mem" = true; "obsidian@obsidian-skills" = true; };` (confirm exact plugin names from each repo's `marketplace.json`)
- **Updates** come from `nix flake update`, not from Claude's auto-update.
- **The plugin ID changes** from `claude-mem@thedotmack` to the local one. Observations aren't affected, because `CLAUDE_MEM_DATA_DIR` stays at `~/.config/claude-mem`.
- **Restructure:** claude-mem's settings move from `darwin/packages/codex/extensions/claude-mem/` to `options/agents/claude-mem/`, since Claude and Codex both use them.
- **Existing marketplaces:** home-manager generates `plugins/known_marketplaces.json`, which drops `thedotmack` and `claude-plugins-official`. No plugin from either is in use, so they're left out.
- **Adding marketplaces later goes through Nix.** That file is read-only, so `/plugin marketplace add` won't work at runtime. Adding one takes two edits:
  1. A flake input in `flake.nix` (flake inputs can't be declared from a knob, and a bare `"anthropics/skills"` string has no hash, so pure evaluation can't fetch it):
     ```nix
     anthropic-skills = { url = "github:anthropics/skills"; flake = false; };
     ```
  2. The knob in `shared/home/agents.nix`, naming the input and the plugins to enable:
     ```nix
     claude.marketplaces = [ "claude-mem" "obsidian-skills" "anthropic-skills" ];
     claude.plugins = [ "claude-mem@claude-mem" "obsidian@obsidian-skills" ];
     ```
     The logic maps each name to `inputs.${name}` for `programs.claude-code.marketplaces`, and each plugin to `settings.enabledPlugins`.
- **Why flake inputs and not a rev + hash knob:** a knob with `rev` and `hash` works, but stays on that commit until both are edited by hand. `nix flake update` only moves flake inputs, fetching the newest commit and writing its hash to `flake.lock`.
- **Updating everything:** `nix flake update` in the repo, then rebuild. That moves nixpkgs (Claude Code CLI, claude-powerline, other packages), home-manager, and every GitHub input (claude-mem, obsidian-skills, added marketplaces). A single one: `nix flake update claude-mem`.
- **To verify while building:** after a marketplace input moves, check that Claude Code actually installs the new plugin version into `plugins/cache` (the Codex sync script does this explicitly), or whether it needs a `/plugin update` or a follow-up command.

## 3. File layout
home-manager already declares every option Claude needs, so no custom knob layer wraps them. `shared/home/agents.nix` sets `programs.claude-code.*` directly, and `options/agents/claude/` holds only what upstream doesn't do.

```
shared/home/agents.nix       # programs.claude-code.* set directly:
                             #   package, configDir, settings (permissions,
                             #   env, hooks, enabledPlugins, model…),
                             #   marketplaces (inputs.* are in scope here),
                             #   mcpServers, lspServers, hooksDir,
                             #   context / rules / agents / commands
  hooks/guard.py             # moved from ~/.config/claude/hooks → hooksDir
options/agents/claude/
  default.nix        # swaps in home-manager master's claude-code module (section 9)
  vscode.nix         # writes CLAUDE_CONFIG_DIR into the VS Code extension's settings
options/agents/claude-mem/   # shared by Claude + Codex
```
- **MCP and LSP servers, settings and marketplaces** are plain values, so they live in `agents.nix`. `inputs` is already in scope for shared home modules, as the WezTerm plugins show.
- **Rules, agents, commands, `CLAUDE.md`: open choice.** Each can be inline text in `agents.nix` (`rules`, `agents`, `commands`, `context`) or a folder of `.md` files (`rulesDir`, `agentsDir`, `commandsDir`). The module refuses both forms for the same type. None exist yet, so nothing needs a folder until one is written.
- **A `ven.*` option is added only if** Claude needs per-platform gating (`installOn`) later; today each host decides by importing the module.
- **`hooks` vs `settings.hooks`:** `hooksDir` only places the script files; the `PreToolUse` entry that runs `guard.py` still goes in `settings.hooks`.
Everything in the current `settings.json` moves over as-is: permissions, `additionalDirectories`, the hook, `disableClaudeAiConnectors`, `effortLevel`, `model`, `theme` and the notification settings. The `env` block gets `DISABLE_AUTOUPDATER=1`, `CLAUDE_MEM_DATA_DIR`, `NPM_CONFIG_USERCONFIG` and `NPM_CONFIG_CACHE` (moved from the old launchd export). `CLAUDE_CODE_PATH` is dropped unless something still reads it (check claude-mem and Codex before removing).

## 4. Removed
- **Code:** `darwin/packages/claude/{default.nix, claude-desktop.nix, claude-desktop-release.nix, update-claude-desktop.sh}` and the `./claude` import in `agents-pkgs.nix`.
- **In `claude-backup.nix`:** the Desktop Application Support and preferences entries.
- **One-time commands for the user** (not activation): remove the `/Applications/Claude.app` link and `~/Library/Application Support/Claude`, run `tccutil reset All com.anthropic.claudefordesktop`, delete the stray `~/.claude.json`, and delete old claude-mem versions from `plugins/cache`.
- **The launchd export** (`launchd.user.envVariables`) goes with the old module. The values stay in launchd until logout, so after the rebuild run `launchctl unsetenv` for `CLAUDE_CONFIG_DIR`, `CLAUDE_MEM_DATA_DIR`, `CLAUDE_CODE_PATH`, `NPM_CONFIG_USERCONFIG`, `NPM_CONFIG_CACHE` and `DISABLE_AUTOUPDATER`, then restart VS Code to confirm the extension setting alone is enough.

## 5. Also added
- **`cleanupPeriodDays = 36500`.** Without it Claude Code deletes chats older than 30 days, and `.last-cleanup` shows that cleanup is already running.
- **claude-mem in `claude-backup`:** `claude-mem.db` (with its `-wal` file), `chroma/` and `settings.json`.
- **Letting Claude act on the Mac:**
  - Computer use: enable once in `/mcp`. That state lives in `.claude.json`, which stays editable.
  - Grant Accessibility and Screen Recording to VS Code and WezTerm by hand.
  - Add `Bash(open -a:*)` to the allow list; keep `osascript` on the ask list.
- **Global `CLAUDE.md`** through `context`, and `rulesDir` for repo conventions.
- **`mcpServers` and `lspServers`** are wired up (claude-mem brings its own MCP server, so none is needed for it). See section 9 for how they reach VS Code.
- **Not needed:** `outputStyles`. `syncClaudeAiSkills` stays on (it provides pdf, docx, skill-creator).
- **claude-powerline caveat:** the status line likely shows only in the terminal CLI, not the VS Code panel.

## 6. Backing up chats and memory
Restoring probably won't be needed. The folder location doesn't change, and home-manager only replaces `settings.json`, `plugins/known_marketplaces.json` and `hooks/guard.py`. With `backupFileExtension = "bak"` it renames those to `.bak` instead of overwriting. Chats, history, `.claude.json`, login and the claude-mem database aren't touched.

Before switching, quit all Claude sessions and back up anyway:
1. Run `claude-backup` (chats, history, login, `.claude.json`, `settings.json`, encrypted).
2. Copy claude-mem by hand, since it's in no backup yet: `cp -a /Users/ven/.config/claude-mem /Users/ven/Downloads/claude-mem-2026-09-17`
3. Delete any leftover `settings.json.bak`. If one exists, home-manager stops the rebuild instead of overwriting it.

**If something goes wrong:** copy `projects/`, `history.jsonl` and `.claude.json` from the backup into `/Users/ven/.config/claude/`, and the claude-mem folder back to `/Users/ven/.config/claude-mem/`.

## 7. Follow-up (after the Claude setup works): split `inputs` with flake-file
Build the Claude setup with plain inputs in `flake.nix` first. Then, as a separate change to the whole repo:
- **Why:** `inputs` in `flake.nix` must be a literal attrset, since Nix reads it before evaluating any code. flake-parts, haumea and den only split `outputs`. flake-file (by den's author) makes `flake.nix` a generated file instead.
- **How:** each flake-parts module declares its own inputs (e.g. `flake-file.inputs.claude-mem = { url = "github:thedotmack/claude-mem"; flake = false; };`), and `nix run .#write-flake` regenerates `flake.nix`. `flake.lock` and `nix flake update` work as before.
- **Claude marketplaces:** the Claude logic reads the marketplace knob and declares the inputs, so adding one becomes a single knob entry (`anthropic-skills = "github:anthropics/skills";`), then `nix run .#write-flake` and a rebuild.
- **Also move:** the Codex extension sources and WezTerm plugins next to their modules.
- **Trade-offs:** `flake.nix` is no longer edited by hand; forgetting `write-flake` after a knob change fails the rebuild with a missing input.
- **Before starting:** check flake-file's current option names and commands against its docs.

## 8. Decisions

### A. Read-only `settings.json`: Nix owns it
home-manager links `settings.json` into the Nix store, so Claude Code can't write to it (`/model`, `/config`, enabling plugins from `/plugin`, user-level "don't ask again"). All of those go through Nix.

- **Trial permissions go in the project file.** Claude Code merges permissions from every settings file, and "Yes, don't ask again" saves to the project's `.claude/settings.local.json`, which stays writable. New rules are collected and tested there (approved or edited by hand). Once they work, they move into the permissions knob and are deleted from the local file. While being tested, they apply only in that project.
- **Rejected:** `mkOutOfStoreSymlink` (settings.json becomes a hand-kept JSON file instead of generated from knobs), and an extra user-level `.json` (Claude Code has none; `--settings` would need a wrapper the VS Code extension doesn't use).

### B. `CLAUDE_CONFIG_DIR`: home-manager only, no launchd
Claude is used only through the CLI (always from a terminal) and the official VS Code extension. No Claude desktop app, and no other GUI app runs Claude.

- **Terminals:** `programs.claude-code.configDir` adds `CLAUDE_CONFIG_DIR` to `home.sessionVariables`. home-manager's generated `config.fish` loads those on every fish start (login or not), so WezTerm and every tool started from fish get it.
- **VS Code:** the Claude extension's environment-variables setting (`claudeCode.environmentVariables`; confirm the exact name) sets `CLAUDE_CONFIG_DIR`, written by the home-manager VS Code module from the same path.
- **Everything else** (`CLAUDE_MEM_DATA_DIR`, npm paths, `DISABLE_AUTOUPDATER`) goes in the `settings.json` `env` block, which Claude Code applies to every session and its hooks. Only `CLAUDE_CONFIG_DIR` needs outside help, because Claude needs it to find `settings.json`.
- **Adding a GUI app later that runs Claude:** give it the path through its own env setting from Nix, or a Nix wrapper that sets the variable. A launchd agent gets it in its own `EnvironmentVariables`. A missed app fails quietly by using `~/.claude`.
- **To check while building:** whether the Codex VS Code extension runs claude-mem hooks that need `CLAUDE_MEM_DATA_DIR`. If so, set it through Codex's own setting or have claude-mem's settings name the data path.

## 9. `mcpServers` / `lspServers`: use the home-manager master module
All options stay available in every version; what differs is **how** the servers reach Claude Code.

- **26.05 (pinned):** the servers go into a generated plugin passed with `--plugin-dir` through the `claude` wrapper script. Only the terminal `claude` uses that wrapper; the VS Code extension runs its own bundled `claude`, so it would not see them.
- **master (checked 2026-09-17, `modules/programs/claude-code/default.nix`):** for Claude Code 2.1.157 or later (installed: 2.1.268), the same generated plugin is linked into `configDir/skills/claude-code-home-manager` as a personal plugin, with no wrapper. Anything reading `CLAUDE_CONFIG_DIR` loads it, VS Code included. `plugins` (now an attrset) is linked the same way.
- **Plan:** import only the master `claude-code` module and keep the rest of home-manager on 26.05:
  - New flake input `home-manager-master` (`github:nix-community/home-manager`, `flake = false`).
  - In `options/agents/claude/default.nix`: `disabledModules = [ "programs/claude-code.nix" ];` and `imports = [ "${inputs.home-manager-master}/modules/programs/claude-code" ];`.
  - `mcpServers` / `lspServers` then stay plain knobs in `shared/home/agents.nix`, no custom plugin code.
  - When home-manager 26.11 ships with this module, drop the extra input and the two lines.
- **To verify while building:** that the master module evaluates against 26.05's `lib.hm` helpers (e.g. `lib.hm.mcp.transformMcpServer` with `exclude`), and that a test MCP server shows up in `/mcp` in both the CLI and VS Code.
- **Plugins still via `marketplaces`:** master's `plugins` links from the read-only store, which claude-mem can't run from (it installs `node_modules`). obsidian-skills could use `plugins` instead if it has no install step; check during the build.
