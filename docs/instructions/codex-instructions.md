# Codex: Instructions

This file also describes how Codex is set up today and what should change moving forward. I want Codex and its cli to be completely owned by and configured through Nix. This below is a plan and instructions how we will do it. It follows the same rules as `claude-instructions.md`: upstream home-manager options are assigned directly in `shared/home/agents.nix`, and `options/agents/codex/` holds only what upstream doesn't cover.

Two things stay as they are: **the ChatGPT desktop app is kept**, and there are still **two profiles, `api` and `chatgpt`**, sharing plugins, skills, memories, chats and projects.

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

**The difference between the profiles is only the key.** `codex-api` (a `writeShellApplication` in the same file) reads `OPENAI_API_KEY` from `~/.config/codex/api/auth.json` and starts either the app or the CLI with that key in the environment. `~/.config/codex/api/` holds nothing else that matters: an `auth.json`, a near-empty `config.toml`, and leftovers. The subscription login lives in `~/.config/codex/chatgpt/auth.json`.

**`codex-profiles` (Ducksss) is packaged** in `darwin/packages/codex/default.nix`, patched by `xdg-profile-root.patch` to keep its data under `~/.config`, and configured through `CODEX_PROFILE_HOME_ROOT` and `CODEX_PROFILE_CONFIG_HOME`. Because both profiles already share one home, it isn't separating anything anymore.

**Shared material lives beside the homes** in `~/.config/codex/shared/`: `skills/` (own and fetched), `plugins/`, `personal-marketplace/` and the `codebase-memory-mcp` cache. `AGENTS.md` in the Codex home tells Codex to create new skills and plugins there instead of in `~/`.

**Plugins and marketplaces are registered imperatively.** The modules under `darwin/packages/codex/extensions/` build each plugin from a pinned flake input into a small Nix marketplace and then run `codex-profile ... plugin marketplace add` / `plugin add`, writing `[marketplaces.*]` and `[plugins.*]` sections into `config.toml`. That's how `ven-caveman`, `ven-simple-english`, `ven-scholarbrain` and `claude-mem-local` got there.

**`config.toml` is a live file the app writes.** Beside the settings you chose (model, sandbox, approvals, `writable_roots`) it holds things Codex and the app maintain by themselves: every `[projects.*]` trust entry, the `[desktop]` appearance block, `[tui]`, `[features]`, `[memories]`, `[hooks.state]` trust hashes, the app's own `[marketplaces.*]` and `[plugins.*]` entries, and MCP servers the app generates with absolute paths into `/Applications/ChatGPT.app`. It was last written by the app today.

**Backups** are handled by `codex-backup` (`darwin/packages/codex/codex-backup.nix`), which archives `codex/chatgpt`, `codex/api`, `codex/shared`, `codex/backups` and the app's preferences.

---

## What changes

1. **One home at `/Users/ven/.config/codex`.** Everything currently under `chatgpt/` moves up one level. The `api/` folder is reduced to the key, or replaced by a secret.
2. **Profiles become real profiles.** `programs.codex.profiles` writes `CODEX_HOME/<name>.config.toml`, selected with `codex --profile <name>`, so `api` and `chatgpt` can finally differ in settings while sharing one home. Requires Codex 0.134.0 or later.
3. **`chatgpt` stays the default.** The app has no `--profile` flag, so it reads plain `config.toml`. Opening Codex from the Dock or Raycast keeps working as it does now, with no flag anywhere.
4. **`codex-profiles` is dropped,** with `CODEX_PROFILE_HOME_ROOT`, `CODEX_PROFILE_CONFIG_HOME` and `~/.config/codex-profile`.
5. **Skills, rules, `AGENTS.md`, hooks and profiles become declarative** through the home-manager module.
6. **Plugins and marketplaces:** see the constraint in section 4 before deciding.
7. **The app, its launchd variables and `codex-backup` stay,** with paths adjusted to the flattened layout.

### Separate homes, or shared chats? Why it can't be both

**What was wanted:** a separate home per profile, so each has its own `config.toml` and its own `auth.json`, while chats, projects, their names in the sidebar, and archiving still work across both.

**Why that failed before:** two homes can only share data through symlinks, and Codex resolves session and project paths relative to `CODEX_HOME`. A session reached through a symlink does not resolve to the path it was written to, so renaming, deleting and archiving fail. On top of that, a Dock or Raycast launch has no wrapper, so without `CODEX_HOME` in the GUI environment the app fell back to a home in `~/` and wrote there. That is why everything was moved into one home.

**Why symlinking works for skills but not for chats.** `skills/` and `plugins/` are read-only lookups: Codex reads what it finds, so a link to `shared/` is invisible to it. Chats, projects and the sidebar are different, because Codex records absolute paths. The same session file reached from two homes is `…/codex/api/sessions/x` in one and `…/codex/chatgpt/sessions/x` in the other, and the index and the sqlite database store one of them. Renaming, deleting or archiving then compares a path that doesn't match, which is the error you saw. Linking more folders doesn't help: what breaks is the home prefix in the recorded path, and only one home removes it.

**Project trust is the same story.** It lives in `[projects.*]` in `config.toml`, so two homes means two lists. With one home and profile files, the trust list stays in the shared `config.toml` while the profiles differ in the settings you actually wanted to vary.

**Why one home is still the answer:** the limitation is Codex's, not Nix's. Nix can lay out any number of homes, but it cannot make a symlinked session resolve to two paths at once. So sharing chats, projects, names and archiving means one real `CODEX_HOME`.

**What Nix adds is the part that was missing:** with `programs.codex.profiles`, one home no longer means one set of settings. Each profile gets its own `<name>.config.toml` — model, reasoning effort, personality, approvals, sandbox, `writable_roots` — so the two profiles differ in exactly the way a separate home was supposed to give you, without giving up shared chats.

**Logins:** the subscription login stays in the Codex home's own `auth.json`; the API key moves to sops and reaches the `api` profile through an `env_key` variable (section 2b).

**What stays shared, as today:**


| Shared                          | Where it lives                                                                  |
| ------------------------------- | ------------------------------------------------------------------------------- |
| Chats, sidebar titles, sessions | `sessions/`, `session_index.jsonl`, `sqlite/`                                   |
| Archived chats                  | `archived_sessions/`                                                            |
| Memories                        | `memories/`, plus `[features] memories` and `[memories]` in `config.toml`       |
| Projects and their trust        | `.chatgpt-projects/` and the `[projects.*]` entries in `config.toml`            |
| Plugins                         | `plugins/`, `plugins/cache`, and the `[plugins.*]` / `[marketplaces.*]` entries |
| Skills                          | `skills/`                                                                       |
| Installation identity           | `installation_id`, `cache/`, `models_cache.json`                                |

**Different per profile,** in `CODEX_HOME/<name>.config.toml`: model, reasoning effort, personality, `approval_policy`, `sandbox_mode`, `web_search`, `writable_roots` and anything else Codex reads from a profile.

**The target layout.** `/Users/ven/.config/codex` becomes `CODEX_HOME` itself, so everything Codex owns is inside it — nothing in `~/.codex` or anywhere else. A profile is then a settings file in that root, not a subfolder:

```text
/Users/ven/.config/codex/          <- CODEX_HOME
  config.toml                      app + shared defaults (chatgpt login)
  chatgpt.config.toml              profile settings, `codex --profile chatgpt`
  api.config.toml                  profile settings, `codex --profile api`
  auth.json                        subscription login
  AGENTS.md, rules/, hooks.json    declared by Nix
  skills/                          skills (link to shared/skills, or the real folder)
  plugins/                         plugins (link to shared/plugins, or the real folder)
    cache/openai-bundled/…         installed by the app
    cache/home-manager/…           installed by Nix
  sessions/, archived_sessions/, session_index.jsonl
  memories/, sqlite/, .chatgpt-projects/
  shared/                          kept or dropped, see Decisions E
```

Profiles are files rather than folders because that's how Codex 0.134 and the `profiles` option work, and it's what makes shared chats, projects and archiving possible. Per-profile folders would mean a `CODEX_HOME` each, which is the layout that broke renaming, deleting and archiving.

**What happens to the `api/` and `chatgpt/` folders.** They stop being homes, because a profile is now a settings file rather than a directory:

- **`chatgpt/`** was the real home, so its contents move up into `codex/` and the folder is deleted. Its `auth.json` becomes `codex/auth.json`, which is where Codex expects the login.
- **`api/`** goes too, once the key is in sops. Its near-empty `config.toml` is replaced by `api.config.toml`.
- **`backups/`** and anything else beside them are untouched.

Keeping a folder per profile is only possible by making each one a `CODEX_HOME`, which is the layout that broke sharing. If you want the key somewhere tidier, sops is the alternative (Decisions C) and then `api/` disappears too.

**How the two profiles are then used:**

- **`chatgpt`:** subscription login from the home's `auth.json`, its own `chatgpt.config.toml`. Used by the app from the Dock and Raycast, and by a bare `codex`.
- **`api`:** key from sops through an `env_key` variable, its own `api.config.toml`, selected with `codex -p api` in the CLI and through a wrapper in VS Code. Not used in the app.

**The two things that broke stay fixed:** archiving works because sessions are a real directory, and the Dock launch works because `CODEX_HOME` reaches GUI apps through launchd and needs no wrapper.

**To verify while building:** whether `codex --profile api` reads `config.toml` as the base and only overlays `<name>.config.toml`. Everything shared above lives in `config.toml` or beside it, so if a profile file replaced the base file instead of layering on it, the API profile would lose plugins, projects and memory settings. If that turns out to be the case, the shared blocks have to be repeated in each profile file.

### Profiles and logins without `codex-profiles`

`codex-profiles` is not needed. Everything it was used for is covered by Codex itself plus home-manager options.

**How each profile is used:**

|               | `chatgpt`                                    | `api`                                            |
| ------------- | -------------------------------------------- | ------------------------------------------------ |
| Used from     | the app (Dock, Raycast), a bare `codex`      | CLI and VS Code only                             |
| Login         | subscription, from `CODEX_HOME/auth.json`    | API key, from the environment                    |
| Settings      | `config.toml` (the app can't load a profile) | `config.toml` + `api.config.toml` layered on top |
| Selected with | nothing, it's the default                    | `codex -p api`, or the VS Code wrapper           |

**How Codex layers profiles** (checked on 0.154.0): `codex -p api` reads `config.toml` first and applies `api.config.toml` on top, overriding only the keys it sets. A missing profile file is ignored silently. The app has no `-p`, so it always uses `config.toml` — which is why `chatgpt` is the default rather than a profile the app selects.

**Everything shared stays in `config.toml`:** memories and `[features]`, `[projects.*]` trust, plugins and marketplaces, `[desktop]`, MCP servers. Hooks are shared through `CODEX_HOME/hooks.json`, chats and names through the one home.

**What each profile file carries:** only what differs.
- **Folder access:** `sandbox_workspace_write.writable_roots` (and `sandbox_mode` if needed), so one profile can write to folders the other can't.
- **Login:** `api.config.toml` sets `model_provider = "openai-api"`. That provider is defined once in `config.toml`, with `env_key` naming the variable the key comes from.
- **Anything else** you want to differ: model, reasoning effort, approvals.

**Why the key comes from the environment, not a second `auth.json` entry.** `auth.json` has one `auth_mode` field — yours is `chatgpt`, with the subscription tokens and an empty `OPENAI_API_KEY` field. Logging in with a key would switch that mode for everyone. A provider with `env_key` leaves `auth.json` alone and gives the `api` profile its own key.

**Where the key lives:** sops. The logic module exposes the decrypted secret as the `env_key` variable:
- **CLI:** exported in fish, so `codex -p api` finds it.
- **VS Code:** the Codex extension starts the CLI itself and has no profile setting, so it's pointed at a small Nix-built wrapper (`chatgpt.cliExecutable`) that sets the variable and runs `codex -p api`.

**Use a variable name of your own** (e.g. `CODEX_API_PROFILE_KEY`), not `OPENAI_API_KEY` or `CODEX_API_KEY`, so the `chatgpt` profile can never pick the key up by accident.

**To verify while building:**
- that `model_provider` is honored inside a profile file (the docs exclude provider keys from *project-local* config, not clearly from profiles);
- that the `env_key` provider works while `auth.json` stays in `chatgpt` mode;
- the exact VS Code setting name for the CLI path.

---

## The home-manager module

The pinned home-manager (26.05) only has `enable`, `package`, `settings`, `context`, `skills`, `rules` and `enableMcpIntegration`. `profiles`, `plugins`, `marketplaces` and `hooks` exist only on master.

**So Codex imports master's module,** exactly as the Claude plan does, sharing one `home-manager-master` flake input:

```nix
# options/agents/codex/default.nix
disabledModules = [ "programs/codex.nix" ];
imports = [ "${inputs.home-manager-master}/modules/programs/codex" ];
```

**`CODEX_HOME` comes from `home.preferXdgDirectories`.** The module has no `configDir` option: it writes to `~/.codex` unless that setting is true, in which case it uses `~/.config/codex` and exports `CODEX_HOME` through `home.sessionVariables`. The setting is repo-wide, so check what else moves before enabling it (section 7 A).

### Options, and what each is for

| Option                 | Writes                          | Used for                                                                                    | Remember                                                                                                                     |
| ---------------------- | ------------------------------- | ------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `enable`, `package`    | the CLI                         | Replaces the system-level `codex` package                                                   | The app is separate and stays a cask/bundle                                                                                  |
| `settings`             | `CODEX_HOME/config.toml`        | Shared defaults: model, reasoning effort, sandbox, approvals, `writable_roots`, MCP servers | **Makes the file read-only. See section 4.**                                                                                 |
| `profiles`             | `CODEX_HOME/<name>.config.toml` | The `api` and `chatgpt` profiles                                                            | Codex 0.134.0+; `settings.profile` and `settings.profiles` are no longer read                                                |
| `skills`               | `CODEX_HOME/skills/<name>`      | `web-to-obsidian-archive`, `defuddle`, `json-canvas`, kepano's skills                       | Each skill is symlinked as a whole directory; unmanaged skills in that folder keep working                                   |
| `plugins`              | `config.toml` + `plugins/cache` | caveman, scholarbrain, SimpleEnglish                                                        | Goes through `config.toml`, so section 4 applies. A plugin needing a writable install (claude-mem) can't come from the store |
| `marketplaces`         | `config.toml`                   | The personal marketplace                                                                    | Same constraint                                                                                                              |
| `hooks`                | `CODEX_HOME/hooks.json`         | Hook events, or a whole hook bundle directory                                               | Separate file, so it stays safe to manage                                                                                    |
| `rules`                | `CODEX_HOME/rules/<name>.rules` | Persistent `prefix_rule()` approvals                                                        | Values must be files or inline text, not directories                                                                         |
| `context`              | `CODEX_HOME/AGENTS.md`          | The storage rules currently in that file                                                    | `contextOverride` writes `AGENTS.override.md`, which wins over `AGENTS.md`                                                   |
| `enableMcpIntegration` | merges `programs.mcp.servers`   | Only if MCP servers should be shared with other agents                                      | Codex-specific keys (`http_headers`) are converted for you                                                                   |

---

## The constraint that decides the shape: `config.toml` is written by the app

home-manager writes `config.toml` as a symlink into the Nix store, so nothing can change it at runtime. But Codex and the app write to that file constantly: project trust decisions, the whole `[desktop]` appearance block, `[tui]`, `[features]`, `[memories]`, `[hooks.state]` hashes, and their own marketplace and plugin entries.

**Why Codex does this:** it has no separate state file. User configuration and runtime state share one file, so an interactive "trust this folder", a change of theme in the app, or an approved hook all land in `config.toml`.

**The goal is that Nix declares it.** Almost everything in that file is a plain setting and can be declared, including the parts Codex writes by itself:

| App-written today                                      | Declared in Nix as                              |
| ------------------------------------------------------ | ----------------------------------------------- |
| `[projects."…"] trust_level`                           | the same entries, listed in `settings.projects` |
| `[desktop]` appearance, fonts, themes                  | the same keys in `settings.desktop`             |
| `[features]`, `[memories]`, `[tui]`                    | the same keys                                   |
| `[marketplaces.*]`, `[plugins.*]` for your own plugins | `marketplaces` and `plugins`                    |

**What changes for you:** those settings are then changed in Nix and applied with a rebuild, instead of in the app's interface. Trusting a new folder, switching a theme or enabling a plugin from the app's menu stops sticking.

**Your own plugins and skills are declarable** — that's what `plugins`, `marketplaces` and `skills` are for: caveman, scholarbrain, SimpleEnglish, the personal marketplace, `web-to-obsidian-archive`, `defuddle`, `json-canvas` and kepano's skills all come from pinned inputs or the repo.

**Two things in that file still aren't yours to declare:**
- **The app's own plugins** (`openai-bundled`, `openai-primary-runtime`, `browser`, `computer-use`, `sites`, `visualize`). They ship inside ChatGPT.app, which installs them into the home and writes entries pointing at versioned paths such as `plugins/cache/openai-bundled/browser/26.908.70816/…`. They aren't packages Nix can fetch, and the paths change with every app update, so Nix can only copy the current entries, not keep them correct.
- **`[hooks.state]` trust hashes,** which Codex computes from a hook's contents when you approve it. A new plugin version means a new hash.

**Nothing on disk is erased.** The module keeps to its own paths: each managed plugin goes to `plugins/cache/home-manager/<name>`, each managed skill to `skills/<name>`, and its activation step only removes those exact paths. The app's `plugins/cache/openai-bundled/…` and any skill you installed yourself stay where they are, and unmanaged entries in `skills/` keep working.

**What a Nix-owned `config.toml` does erase is the registration.** The generated file lists only the marketplaces and plugins declared in Nix, so the app's `[marketplaces.openai-bundled]` and `[plugins."browser@openai-bundled"]` entries are gone after a rebuild. The files remain, but Codex no longer loads them, and the app can't write the entries back into a read-only file. Copying the current entries into `settings` works until the next app update changes the version in their paths.

**So the test comes first, before anything else is built.** Make a copy of the current `config.toml`, make it read-only, point a spare `CODEX_HOME` at it, and start the app and the CLI:

- Does the app start and work, or does it error when it can't write?
- Does it lose the app-managed plugins, or re-register them each start?
- Do hooks re-prompt for approval every session?

**Then choose:**

- **If the app copes:** Nix owns `config.toml`, with `projects`, `desktop`, `features` and your own plugins declared, and the app-managed entries copied into the Nix file once and refreshed when the app updates.
- **If it doesn't:** the app keeps `config.toml`, and Nix declares the separate files instead — `profiles`, `skills`, `rules`, `hooks`, `context` — with your own plugins staying with the existing extension modules, which register them through the CLI. Your settings still become declarative, in `profiles.chatgpt`, and the app reads its copy from `config.toml`.

**Also verify:** whether `codex --profile api` layers on `config.toml` or replaces it (section 2a), since that decides whether shared blocks have to be repeated per profile.

---

## Skills, plugins and marketplaces

**Own skill.** `web-to-obsidian-archive` moves from `~/.config/codex/shared/skills/` into the repo at `shared/home/agents/codex/skills/web-to-obsidian-archive/`, declared as `skills.web-to-obsidian-archive = ./skills/web-to-obsidian-archive;`. It keeps its `agents/`, `references/` and `SKILL.md`.

**Fetched skills** come from flake inputs, so `nix flake update` moves them:
- `codex-skills` = `github:JiaxI2/Codex-Skills`, `flake = false` → `skills.defuddle = "${inputs.codex-skills}/defuddle";` and `skills.json-canvas = "${inputs.codex-skills}/json-canvas";`
- `obsidian-skills` = `github:kepano/obsidian-skills`, shared with the Claude setup. It's currently registered as a git marketplace (`obsidian@obsidian-skills`); as skills it would instead appear as plain skill directories. Decide which form you want (section 7 D).

**Plugins** keep their existing inputs: `caveman`, `scholarbrain`, `simple-english`. Under option A they stay with the extension modules; under option B they become `plugins = [ ... ]`.

**claude-mem** stays as it is in either case: it needs a writable `node_modules` beside its scripts, so it can't run from a read-only store path. Its module moves to `options/agents/claude-mem/` and serves Claude and Codex both.

**The personal marketplace** moves into the repo as `shared/home/agents/codex/marketplace/`, so `plugin-creator` writes new plugins into a folder that's part of the configuration. `AGENTS.md` (the `context` option) has to name the new path.

**Left alone:** everything the app installs itself — `openai-bundled`, `openai-primary-runtime`, `computer-use`, `browser`, `sites`, `visualize`. They're app-managed and must not be declared.

---

## Environment, the app, and the API key

- **`CODEX_HOME` must reach GUI apps,** because Codex is opened from the Dock and Raycast. The launchd export stays, moved to `options/agents/codex/environment.nix`, with the value pointing at the flattened home. This is the opposite of Claude, where the launchd export is dropped.
- **`CODEX_SQLITE_HOME`** follows the same move; today it points at `chatgpt/sqlite`, afterwards at `~/.config/codex/sqlite`.
- **The API key** comes from sops through an `env_key` provider, used by the CLI and VS Code only (section 2b). The app no longer gets it.
- **Dropped variables:** `CODEX_PROFILE_HOME_ROOT`, `CODEX_PROFILE_CONFIG_HOME`. `CODEX_CLI` and `CHATGPT_APP` stay, since the app's plugin helpers read them.

---

## Decisions

**A. `home.preferXdgDirectories = true`.** Required to get `CODEX_HOME=~/.config/codex`, and it affects other home-manager modules. Before enabling it, check which enabled modules read it and would move their files, and whether those moves are wanted.

**B. Who owns `config.toml`** — Nix, if the app tolerates a read-only file. The test in section 4 decides it, and it is the first thing to run.

**C. API key** — decided: sops, exposed as an `env_key` variable (section 2b). `~/.config/codex/api/` and the `codex-api` wrapper go away; the app is no longer started with the API key.

**E. Keep `shared/`?** Today `CODEX_HOME/skills` and `CODEX_HOME/plugins` are symlinks to `~/.config/codex/shared/…`, and even the app installs into `shared/plugins/cache/openai-bundled/`. Both work with the new layout:
- **Keep the links:** nothing moves, `AGENTS.md` paths stay valid, home-manager writes through them. Test that home-manager is content managing `~/.config/codex/skills/<name>` when `skills` itself is a symlink.
- **Drop them:** `skills/` and `plugins/` become real folders in `CODEX_HOME`, one indirection less, and `AGENTS.md` is rewritten.

**D. kepano's skills** — keep them as the current git marketplace, or take them as plain skills through the `skills` option like the other two. As skills they're pinned by the flake and update with it; as a marketplace Codex updates them itself.

---

## Migration: keep chats, memories and projects

1. **Quit ChatGPT.app and every `codex` session.**
2. **Back up twice:** run `codex-backup`, then `cp -a /Users/ven/.config/codex /Users/ven/Downloads/codex-2026-09-17`.
3. **Move the contents of `chatgpt/` up into `~/.config/codex/`:** `sessions/`, `archived_sessions/`, `memories/`, `sqlite/`, `session_index.jsonl`, `installation_id`, `auth.json`, `cache/`, `models_cache.json`, `vendor_imports/`, `visualizations/`, `computer-use/`, `plugins/` and `.chatgpt-projects/`.
4. **`config.toml`:** under option A it moves up with the rest and stays the app's file. Under option B its values are copied into `settings` and the file is deleted. Either way the `[projects.*]` trust entries and the `[desktop]` block must survive, and the app's absolute paths that mention `codex/chatgpt` (the `node_repl` MCP server, `notify`, `SKY_CUA_SERVICE_PATH`) need updating or letting the app rewrite them.
5. **Update the launchd variables** and rebuild.
6. **Check:** old chats and memories are listed in the app, projects are still trusted, plugins and skills load in both the app and the CLI, and `codex --profile api` uses the key.
7. **If something goes wrong:** restore the backup folder to `/Users/ven/.config/codex/` and re-enable the old module.

**`codex-backup.nix` is updated** for the flattened layout: one entry for `codex/` instead of `chatgpt`, `api` and `shared`, still excluding what shouldn't be archived, plus the app's `~/Documents/Codex` folder.

---

## Removed when this is done

- `darwin/packages/codex/default.nix` (the `codex-profile` package) and `xdg-profile-root.patch`.
- `darwin/packages/codex/codex.nix`, except the launchd environment, which moves to `options/agents/codex/`. `codex-api` is replaced by the VS Code wrapper and `codex -p api`.
- `darwin/packages/codex/extensions/claude-mem/` → `options/agents/claude-mem/`. The other extension modules stay under option A and are removed under option B.
- `~/.config/codex-profile`, `~/.config/codex/api/` (once the key has moved) and `~/.config/codex/shared/` (once skills and the marketplace live in the repo).
- **One-time commands for you,** not activation: the folder moves above, `launchctl unsetenv` for the dropped variables, and deleting the old folders once the rebuild works.
