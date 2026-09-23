# Codex: Instructions

This file also describes how Codex is set up today and what should change moving forward. I want Codex and its cli to be completely owned by and configured through Nix. This below is a plan and instructions how we will do it. It follows the same rules as `claude-instructions.md`: upstream home-manager options are assigned directly in `shared/home/agents.nix`, and `options/agents/codex/` holds only what upstream doesn't cover.

Two things stay as they are: **the ChatGPT desktop app is kept**, and there are still **two profiles, `api` and `chatgpt`**, each with its own home, `config.toml`, `auth.json`, chats and projects, sharing skills, plugins, hooks, rules, `AGENTS.md` and memories.

## Configuration Directory

- This is where all Codex configuration files will be stored:

```text
/Users/ven/.config/codex/
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

### All Nix Options for Codex

Upstream home-manager options are assigned directly in `shared/home/agents.nix`, and `options/agents/codex/` will hold custom features, which upstream doesn't cover.

- Here are the nix options I want to have. None of them are optional; I want all of them existing and to be declared and managed through Nix.

#### settings
home-manager/option/programs.codex.settings

`programs.codex.settings`
Configuration written to `CODEX_HOME/config.toml` (0.2.0+) or `~/.codex/config.yaml` (<0.2.0). Per default `CODEX_HOME` defaults to `~/.codex` , see above for our override. [See config-reference](https://developers.openai.com/codex/config-reference) for supported values.

**Declarations type**: null or TOML value
**Default**: {}
**Example**:
```nix
{
  model = "gemma3:latest";
  model_provider = "ollama";
  model_providers = {
    ollama = {
      name = "Ollama";
      base_url = "http://localhost:11434/v1";
      env_key = "OLLAMA_API_KEY";
    };
  };
  mcp_servers = {
    context7 = {
      command = "npx";
      args = [
        "-y"
        "@upstash/context7-mcp"
      ];
    };
  };
}
```

#### profiles
home-manager/option/programs.codex.profiles

`programs.codex.profiles`
Named Codex configuration profiles written to `CODEX_HOME/<name>.config.toml`.

These profiles are selected with `codex --profile <name>`. Codex 0.134.0 and later no longer reads profile settings from `programs.codex.settings.profiles`, and the top-level `programs.codex.settings.profile` selector is no longer supported.

**Declarations type**: attribute set of (TOML value)
**Default**: {}
**Example**:
```nix
{
  deep-review = {
    model = "gpt-5.5";
    model_reasoning_effort = "xhigh";
    approval_policy = "on-request";
    sandbox_mode = "workspace-write";
  };
}
```



#### skills
home-manager/option/programs.codex.skills

`programs.codex.skills`
Custom skills for Codex.

This option can be either:
  • An attribute set defining skills
  • A path to a directory containing skill folders

If an attribute set is used, the attribute name becomes the skill directory name, and the value is either:
  • Inline content as a string (creates a generated skill directory at `<skills-dir>/<name>/`
  • A path to a file (creates a generated skill directory at `<skills-dir>/<name>/`
  • A path to a directory (symlinks (`<skills-dir>/<name>/` to that directory)

If a path is used, it is expected to contain one folder per skill name, each containing a `SKILL.md`. Each top-level skill entry is symlinked into (`<skills-dir>`), leaving (`<skills-dir>/`)
itself as a normal directory so unmanaged skills can coexist.

Home Manager manages skills under `CODEX_HOME/skills` (typically `~/.codex/skills`, or `~/.config/codex/skills` when `home.preferXdgDirectories` is enabled).

**Declarations type**: attribute set of (strings concatenated with "\n" or absolute path)) or absolute path
**Default**: {}
**Example**:
```nix
{
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
  data-analysis = ./skills/data-analysis;
}
```


#### plugins
home-manager/option/programs.codex.plugins

`programs.codex.plugins`
List of plugins to use when running Codex. Each entry is either:
  • A path to the plugin directory
  • The plugin package, whether a nix package or the output of a fetcher. Plugins are installed into Codex's plugin cache and enabled through `CODEX_HOME/config.toml`.

**Declarations type**: list of (package or absolute path)
**Default**: []
**Example**:
```nix
[
  ./my-local-plugin
  (fetchFromGitHub {
    owner = "some-github-org";
    repo = "codex-plugin";
    rev = "779a68ebc2a75e4a184d2c87e5a43a758e6458a1";
    sha256 = "228fdd7e5908ea1d2f65218ecd9c71e1eefa0834d200d55fbb8bf8b5563acec0";
  })
]
```


#### hooks
home-manager/option/programs.codex.hooks

`programs.codex.hooks`



#### context
home-manager/option/programs.codex.context

`programs.codex.context`
Lifecycle hook events written to `CODEX_HOME/hooks.json`.

This option can either be a hook event attribute set, a path to a complete hooks JSON file, or a path to a hook bundle directory containing `hooks.json` and supporting hook scripts.

Attribute set values use the same event structure as `programs.codex.settings.hooks` and are written under the top-level `hooks` key expected by Codex's JSON hooks file.

Directory values install `hooks.json` to `CODEX_HOME/hooks.json` and install the full directory to the active Codex home hooks directory. In the default layout, commands can reference bundled scripts with paths such as `$HOME/.codex/hooks/my-hook`. When `home.preferXdgDirectories` is enabled, use `$CODEX_HOME/hooks/my-hook`.

Hooks can also be configured inline through `programs.codex.settings.hooks`; prefer using only one hook representation per layer.

**Declarations type**: JSON value or absolute path
**Default**: {}
**Example**:
```nix
{
  PreToolUse = [
    {
      matcher = "^Bash$";
      hooks = [
        {
          type = "command";
          command = "/usr/local/bin/codex-pre-tool-use";
          timeout = 30;
          statusMessage = "Checking Bash command";
        }
      ];
    }
  ];
}
```


#### rules
home-manager/option/programs.codex.rules

`programs.codex.rules`
Codex rules files to manage under `CODEX_HOME/rules/`.

The attribute name becomes the filename, with a `.rules` extension added automatically. The value is either:
• Inline content as a string
• A path to an existing rules file

This is useful for declaratively managing persistent `prefix_rule()` definitions, including the default `default.rules` allow-list Codex writes when you accept recurring approvals
interactively.

**Declarations type**: attribute set of (strings concatenated with "\n" or absolute path)
**Default**: {}
**Example**:
```nix
{
  default = "prefix_rule(pattern = [\"nix\", \"build\"], decision = \"allow\")\n";
  github = ./codex/github.rules;
}
```

#### marketplaces
home-manager/option/programs.codex.marketplaces

`programs.codex.marketplaces`
Custom marketplaces for Codex plugins. The attribute name becomes the marketplace name, and the value is either:
• A path to the marketplace directory
• The marketplace package, whether a nix package or the output of a fetcher

Marketplaces are configured through `CODEX_HOME/config.toml`.

**Declarations type**: attribute set of (package or absolute path)
**Default**: {}
**Example**:
```nix
{
  local-marketplace = ./my-local-marketplace;
  gh-marketplace = fetchFromGitHub {
    owner = "some-github-org";
    repo = "codex-marketplace";
    rev = "8a873a220b8427b25b03ce1a821593a24e098c34";
    sha256 = "5c2dce95122b5bb73fa547edabbb6c3061c2d193d11e51faecd4d22659e67279";
  };
}
```

#### contextOverride
home-manager/option/programs.codex.contextOverride

`programs.codex.contextOverride`
Global override context for Codex.
This has the same value format as `programs.codex.context`, but writes `CODEX_HOME/AGENTS.override.md`.

Codex prefers `AGENTS.override.md` over `AGENTS.md` in the same directory.

**Declarations type**: null or strings concatenated with "\n" or absolute path
**Default**: null
**Example**:
''
  - Temporarily ignore default global guidance
  - Prefer brief answers while debugging
''



---

## How it works today

**One home, two logins.** `darwin/packages/codex/codex.nix` exports `CODEX_HOME=/Users/ven/.config/codex/chatgpt` for the CLI, the app and every GUI program, through `environment.variables`, `launchd.user.envVariables` and a `codex-environment` launchd agent. Both "profiles" therefore use the same home, the same `config.toml`, the same sessions and the same database.

**`codexa` never reached the api profile.** The `codex-api` wrapper in that file exports the *chatgpt* home before launching (`codex.nix:54`) and only adds the API key, so every `codexa` session was a chatgpt-home session.

**Archiving failed for project chats.** `CODEX_HOME/skills` and `plugins` are symlinks into `~/.config/codex/shared/`, and earlier the session trees were shared the same way. Codex records absolute paths for sessions and projects, so a chat reached through a differently-prefixed path can't be renamed, deleted or archived.

**`codex-profiles` (Ducksss) is packaged** in `darwin/packages/codex/default.nix`, patched by `xdg-profile-root.patch`, and configured through `CODEX_PROFILE_HOME_ROOT` and `CODEX_PROFILE_CONFIG_HOME`.

**Plugins and marketplaces are registered imperatively.** The modules under `darwin/packages/codex/extensions/` build each plugin from a pinned flake input into a small Nix marketplace, then run `codex-profile … plugin marketplace add` / `plugin add`, writing `[marketplaces.*]` and `[plugins.*]` into `config.toml`.

**`config.toml` is a live file the app writes:** `[projects.*]` trust, `[desktop]` appearance, `[tui]`, `[features]`, `[memories]`, `[hooks.state]` trust hashes, the app's own marketplaces and plugins, and MCP servers with absolute paths into `/Applications/ChatGPT.app`.

**Backups:** `codex-backup` archives `codex/chatgpt`, `codex/api`, `codex/shared`, `codex/backups` and the app's preferences.

---

## Target architecture: one home per profile, one shared root

Each profile is a real `CODEX_HOME` with its own `config.toml`, `auth.json`, chats and projects. Everything that can be shared is shared from the root above them.

```text
/Users/ven/.config/codex/            <- shared root, managed by home-manager (not a home)
  skills/                            programs.codex.skills
  plugins/                           programs.codex.plugins + marketplaces (incl. the app's own cache)
  rules/                             programs.codex.rules
  hooks.json                         programs.codex.hooks
  AGENTS.md                          programs.codex.context
  AGENTS.override.md                 programs.codex.contextOverride
  config.toml                        programs.codex.settings — the shared base
  chatgpt.config.toml                programs.codex.profiles.chatgpt — complete config for that home
  api.config.toml                    programs.codex.profiles.api — complete config for that home
  memories/                          shared, mutable
  memories-db/memories_1.sqlite      shared, mutable

  chatgpt/                           <- CODEX_HOME for the chatgpt profile
    config.toml   -> ../chatgpt.config.toml
    skills -> ../skills   plugins -> ../plugins   rules -> ../rules
    hooks.json -> ../hooks.json   AGENTS.md -> ../AGENTS.md
    memories -> ../memories
    sqlite/memories_1.sqlite -> ../../memories-db/memories_1.sqlite
    auth.json, sessions/, archived_sessions/, session_index.jsonl,
    sqlite/ (its own databases), .chatgpt-projects/, cache/, installation_id

  api/                               <- CODEX_HOME for the api profile
    same links, its own auth.json, chats, projects and databases
```

**Separate per profile:** `config.toml`, `auth.json`, chats, chat names, sessions, archived sessions, projects and their trust, and every database except memories.

**Shared:** skills, plugins and their cache, marketplaces, rules, hooks, `AGENTS.md`, and memories.

**Why sharing memories is safe.** Tested 2026-09-23: SQLite follows a symlinked database and writes its `-wal` and `-shm` files next to the *real* file, so both homes use one set of side files and SQLite's normal locking keeps two processes in order. Each home keeps its own `sqlite/` folder for its chat databases; only `memories_1.sqlite` is a link.

**Why chats can't be shared** (for the record): Codex records absolute paths for sessions and projects, so a chat reached through two different home prefixes can't be renamed, deleted or archived. Skills, plugins and hooks are read-only lookups, so links are invisible to Codex — which is why they can be shared.

**`shared/` is retired.** The root *is* the shared area now, so `~/.config/codex/shared/` goes away and `AGENTS.md` names the repo folders instead.

**To verify while building:**
- that Codex accepts a home whose `config.toml`, `skills`, `plugins` and `hooks.json` are symlinks;
- that a memory written in one profile shows up in the other, and that `memories_1.sqlite` is still a symlink afterwards;
- that the `memories_1.sqlite` filename survives Codex updates (the `_1` looks like a version counter);
- whether `[hooks.state]` approval works when `config.toml` is read-only.

---

## Launching each profile

| | `chatgpt` | `api` |
|---|---|---|
| Home | `~/.config/codex/chatgpt` | `~/.config/codex/api` |
| Login | subscription in its `auth.json` | API key in its own `auth.json` |
| App | Dock, Raycast, and the default everywhere | `codexa` |
| CLI | `codex` | `codexa cli` |
| VS Code | yes, the extension uses it | no |

- **Dock, Raycast, VS Code and a bare `codex`** get `CODEX_HOME=~/.config/codex/chatgpt` from `launchd.user.envVariables` and `environment.variables`, so nothing needs a flag or a wrapper. The VS Code extension has no setting for a home or a profile (`chatgpt.cliExecutable` is marked development-only), and it doesn't need one: it inherits the chatgpt home.
- **`codexa`** opens ChatGPT.app with `CODEX_HOME` pointed at the api home, and **`codexa cli`** starts the CLI there. It replaces today's `codex-api`, which pointed at the chatgpt home — the reason the api profile never appeared.
- **One app instance at a time.** macOS runs a single ChatGPT.app, so `codexa` refuses to launch while the app is already open, as the current wrapper does.
- **Logins are one-time commands:** `codex login` in the chatgpt home, and `codex login --with-api-key` in the api home. No sops secret and no `env_key` provider are needed, because each home stores its own login.
- **`-p` / `profiles` is still how each home gets its settings:** the module writes `chatgpt.config.toml` and `api.config.toml`, and each home's `config.toml` is a link to its own file. Since every home reads its `config.toml` directly, no `-p` flag is needed at runtime.

---

## The home-manager module

The pinned home-manager (26.05) only has `enable`, `package`, `settings`, `context`, `skills`, `rules` and `enableMcpIntegration`. `profiles`, `plugins`, `marketplaces`, `hooks` and `contextOverride` exist only on master.

**So Codex imports master's module,** as the Claude plan does, sharing one `home-manager-master` flake input:

```nix
# options/agents/codex/default.nix
disabledModules = [ "programs/codex.nix" ];
imports = [ "${inputs.home-manager-master}/modules/programs/codex" ];
```

**`home.preferXdgDirectories = true`** makes the module write to `~/.config/codex` instead of `~/.codex`. The setting is repo-wide, so check which other modules move their files before enabling it (Decisions A).

### Every option, and how it is used here

| Option | Writes | Used for |
|---|---|---|
| `enable`, `package` | the CLI | replaces the system-level `codex` package |
| `settings` | root `config.toml` | the shared base every profile file is built from |
| `profiles` | root `<name>.config.toml` | the complete config for each home, linked in as its `config.toml` |
| `skills` | root `skills/` | `web-to-obsidian-archive` from the repo, `defuddle`, `json-canvas`, kepano's skills |
| `plugins` | root `plugins/cache` + config | caveman, scholarbrain, SimpleEnglish |
| `marketplaces` | config | the personal marketplace |
| `hooks` | root `hooks.json` | lifecycle hooks, shared by both homes |
| `rules` | root `rules/*.rules` | persistent `prefix_rule()` approvals |
| `context` | root `AGENTS.md` | the storage rules, pointing at the repo folders |
| `contextOverride` | root `AGENTS.override.md` | temporary global guidance; wins over `AGENTS.md` |
| `enableMcpIntegration` | merges `programs.mcp.servers` | shared MCP servers; needs `programs.mcp.enable` and `programs.mcp.servers` |

**Each profile file is a complete config,** built in Nix as the `settings` base merged with that profile's differences, so shared blocks (projects, features, memories, plugins, desktop) don't have to be typed twice.

---

## What isn't home-manager

| Piece | Where |
|---|---|
| `CODEX_HOME`, `CODEX_SQLITE_HOME` for the app and GUI launches | nix-darwin: `launchd.user.envVariables`, `environment.variables` |
| `codexa` (app + `cli`) | a Nix-built wrapper package |
| The two homes: their folders and every symlink into the shared root | custom logic in `options/agents/codex/`, since the module manages one home |
| Per-home settings knob (which profiles exist, what differs) | a `ven.*` option, because upstream has no second-home concept |
| ChatGPT.app | Homebrew cask / app bundle, unchanged |
| `codex-backup` | nix-darwin, using the repo's backup helpers |
| Flake inputs (`codex-skills`, `obsidian-skills`, `caveman`, `scholarbrain`, `simple-english`, `home-manager-master`) | `flake.nix` |

---

## `config.toml` is Nix-owned, so app-written state must be declared

Each home's `config.toml` is a link into the Nix store, so Codex and the app can't write to it. Codex has no separate state file, so things the app normally saves there have to be declared:

| App-written today | Declared as |
|---|---|
| `[projects."…"] trust_level` | the same entries, per profile |
| `[desktop]` appearance, fonts, themes | the same keys |
| `[features]`, `[memories]`, `[tui]` | the same keys |
| `[marketplaces.*]`, `[plugins.*]` for your own plugins | `marketplaces` and `plugins` |

**What changes for you:** trusting a folder, switching a theme in the app or enabling a plugin from its menu no longer sticks. Those go in Nix and apply on rebuild.

**Two parts stay outside Nix's reach:**
- **The app's own plugins** (`openai-bundled`, `openai-primary-runtime`, `browser`, `computer-use`, `sites`, `visualize`). They ship inside ChatGPT.app and register with versioned paths such as `plugins/cache/openai-bundled/browser/26.908.70816/…`. Nix can copy the current entries, but they go stale at the next app update.
- **`[hooks.state]` trust hashes,** computed when a hook is approved. A new plugin version means a new hash.

**Nothing on disk is erased.** The module keeps to its own paths: managed plugins in `plugins/cache/home-manager/<name>`, managed skills in `skills/<name>`, and its activation step removes only those. The app's own cache and any skill installed by hand stay.

**So the first test, before anything is built:** copy the current `config.toml`, make it read-only, point a spare `CODEX_HOME` at it, and start the app and the CLI. Does the app work? Does it lose its own plugins or re-register them? Do hooks re-prompt? The answers decide how much of the app's state has to be copied into Nix.

---

## Skills, plugins and marketplaces

- **Own skill:** `web-to-obsidian-archive` moves into the repo at `shared/home/agents/codex/skills/web-to-obsidian-archive/`, with its `agents/`, `references/` and `SKILL.md`.
- **Fetched skills** come from flake inputs: `codex-skills` (`github:JiaxI2/Codex-Skills`, `flake = false`) gives `defuddle` and `json-canvas` as subdirectories; `obsidian-skills` (`github:kepano/obsidian-skills`) is shared with the Claude setup.
- **Plugins** keep their inputs — caveman, scholarbrain, simple-english — declared through `plugins` instead of the extension sync scripts.
- **claude-mem** keeps its writable copy, since it installs `node_modules` beside its scripts and can't run from the store. Its module moves to `options/agents/claude-mem/` and serves Claude and Codex both.
- **The personal marketplace** moves to `shared/home/agents/codex/marketplace/`, and `AGENTS.md` names that path so `plugin-creator` writes into the repo.
- **Left alone:** everything ChatGPT.app installs itself.

---

## Decisions

**A. `home.preferXdgDirectories = true`** — required for `~/.config/codex`. Check which other modules move their files first.

**B. Who owns `config.toml`** — Nix, per your rule that the options are not optional. The read-only test measures what that costs in app state, not whether to do it.

**C. Logins** — each home holds its own `auth.json`: `codex login` in `chatgpt`, `codex login --with-api-key` in `api`. No sops secret, no `env_key` provider.

**D. kepano's skills** — as `skills` entries from the flake input, like `defuddle` and `json-canvas`, rather than the git marketplace Codex updates by itself.

---

## Migration

1. **Quit ChatGPT.app and every `codex` session.**
2. **Back up twice:** `codex-backup`, then `cp -a /Users/ven/.config/codex /Users/ven/Downloads/codex-<date>`.
3. **Keep `chatgpt/` where it is.** It stays the chatgpt home; only its `config.toml`, `skills`, `plugins`, `rules`, `hooks.json`, `AGENTS.md` and `memories` become links into the shared root.
4. **Rebuild `api/` as a real home:** keep its `auth.json`, add the same links, and let Codex create its own `sessions/`, `sqlite/` and project folders on first run.
5. **Move the shared material out of `shared/`** into the root, then delete `shared/`.
6. **Seed the shared memories** from the chatgpt home: move `memories/` and `sqlite/memories_1.sqlite` up to the root, then link them back into both homes.
7. **Copy the settings** from the current `config.toml` into `settings` and the two profile files, including the `[projects.*]` trust entries and the `[desktop]` block. Check the absolute paths the app wrote (`node_repl`, `notify`, `SKY_CUA_SERVICE_PATH`).
8. **Rebuild,** then check: old chats and projects in the chatgpt app, `codexa` opening the api profile, memories visible from both, plugins and skills loading in both, archiving working again.
9. **If something goes wrong:** restore the backup folder and re-enable the old module.

**`codex-backup.nix` is not touched.** It keeps archiving `codex/chatgpt`, `codex/api`, `codex/shared` and `codex/backups` as it does today, which still covers both homes after the move. Extending it to the shared root and the memories database is a separate task, after the rewrite is verified.

---

## Replaced — the old modules are disabled, not edited

**The old files are not touched at all,** not even their comments. They are disabled by commenting out their import lines in [darwin/packages/agents-pkgs.nix](darwin/packages/agents-pkgs.nix) (`./codex/codex.nix`, `./codex/extensions`, and the `codex`/`codexProfile` package entries), so the old setup can be re-enabled by uncommenting. They are deleted only once both profiles are confirmed working, as a separate change.

- `darwin/packages/codex/default.nix` (the `codex-profile` package) and `xdg-profile-root.patch`.
- `darwin/packages/codex/codex.nix`; the `codexa` launcher is replaced by a fish function in `options/agents/codex/`.
- `darwin/packages/codex/extensions/` — the sync scripts are replaced by `plugins` and `marketplaces`; `extensions/claude-mem/` moves to `options/agents/claude-mem/`.
- **Backups stay untouched:** `codex-backup.nix` keeps working as it is.
- `CODEX_PROFILE_HOME_ROOT`, `CODEX_PROFILE_CONFIG_HOME` and `~/.config/codex-profile`.
- `~/.config/codex/shared/`, once its contents live in the root and the repo.
- **One-time commands for you,** not activation: the folder moves, the two `codex login` runs, `launchctl unsetenv` for the dropped variables, and deleting the old folders once the rebuild works.
