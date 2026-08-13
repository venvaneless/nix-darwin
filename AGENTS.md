# AGENTS.md — Nix configuration project instructions

## Project purpose

This repository is a modular Nix configuration intended to support
both: - macOS through nix-darwin - Linux through NixOS

- macOS through nix-darwin;
- user configuration through Home Manager integrated into nix-darwin;
- future or shared Linux/NixOS support;
- Fish shell tooling;
- Homebrew-managed macOS applications;
- Nix-managed CLI tools and application bundles;
- launchd services;
- Docker Desktop services with persistent host data.
- Ignore any files that aren't imported in my nix-config - these are only saved templates or things I'm still working on but don't want to wire in
- test.nix is only for testing if nil, etc. is working on different machines - ignore it
- Make sure you always utilise flakeParts when creating and editing my nix-config.
- Make sure you always add short descriptions to each code block (grouping them in sections) and short comments, the way I'm doing it till now.

Primary repository: `/Users/ven/.config/nix/nix-config`

The configuration should stay portable and should avoid macOS-only
assumptions unless a module is explicitly platform-specific.

## Scope and precedence

This file applies to the entire repository.

More specific `AGENTS.md` files extend these rules for their directory tree. In particular:

- `darwin/AGENTS.md` contains mandatory nix-darwin, Home Manager, launchd, Docker, and macOS rules.
- When instructions conflict, the file closest to the edited file wins.
- Safety rules in this root file always remain in force.
- Please never delete comments I already added
- Only change comments if they wrongly describe what they're supposed to describe and correct them instead
- Use formatting the same way I do
- For any existing paths, use the variables set in paths.nix. If a path doesn't exist yet, add them with their variable to paths.nix and then use paths.nix to add these variables in the file you're just working on.


```text
/Users/ven/.config/nix/nix-config
```

Current nix-darwin host:

```text
macbook
```

Primary entry points:

```text
flake.nix
darwin/default.nix
darwin/home/home-manager.nix
```

Primary Darwin configuration:

```text
/Users/ven/.config/nix/nix-config/darwin/default.nix
```

Main workflow: - modular nix-darwin; - Home Manager integration; -
Docker-based services; - fish shell; - CLI-focused environment.

---

## Entry points and aggregators

The main module graph is:

```text
flake.nix
└── darwin/default.nix
    ├── home/home-manager.nix
    ├── system/system-options.nix
    ├── system-commands/default.nix
    ├── services/services.nix
    └── apps/apps.nix
```

- All installed apps are in:

```
nix/nix-config/darwin/packages/agents-pkgs.nix
```

Keep aggregators simple:

- imports grouped by purpose;
- explicit enable flags near the top when needed;
- no generated scripts in an aggregator;
- no package implementation in an aggregator;
- no hidden service startup in an import list.

When adding a module, update the nearest aggregator. Do not add the same module through multiple import paths.

---

## Platform support

This configuration will eventually support both:

- nix-darwin
- NixOS/Linux

Do not assume macOS-only paths or tools unless such is only available for darwin.

When adding software consider:

- Is this available on both platforms?
- Should this be behind `lib.mkIf pkgs.stdenv.isDarwin`?
- Should there be a Linux equivalent?
- Should the option exist on both systems?

---

# General agent behavior

## Before changing files

- Inspect the existing structure first.
- Follow the existing module organization and naming.
- Prefer extending existing modules over creating duplicate ones.
- Keep the configuration modular.
- Suggest improvements that reduce duplication and make future
  maintenance easier.

When adding features, prefer: - modules; - reusable options; -
variables; - `mkOption`; - `mkEnableOption`; - platform conditionals; -
reusable helpers; - flake inputs; - flake-parts where appropriate; -
flake-utils where they simplify multi-system handling.

Do not create large monolithic files when a module split would improve
maintenance.

---

# Nix architecture rules and repository architecture

## Standard module shape

Use this shape when the feature is configurable:

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.example;

  appName = "example";
  dataDir = cfg.dataDir;

  runner = pkgs.writeShellScriptBin "run-${appName}" ''
    set -euo pipefail

    # implementation
  '';
in
{
  options.services.example = {
    enable = lib.mkEnableOption "Example service";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/Users/ven/.config/containers/example";
      description = "Persistent data directory for Example.";
    };
  };

  config = lib.mkIf cfg.enable {
    # implementation
  };
}
```

Use a simpler module when no option surface is needed. Do not create options solely to make a tiny constant look abstract.

---

## Keep modules small and correctly owned

Before adding a feature, decide which layer owns it:

| Concern                                            | Preferred owner                                         |
| -------------------------------------------------- | ------------------------------------------------------- |
| Nix daemon, host, system defaults, system packages | nix-darwin system module                                |
| Fish, CLI program settings, XDG config, user files | Home Manager module                                     |
| macOS GUI application installed as a cask          | Homebrew module or app module                           |
| Nix-built macOS `.app` bundle                      | Nix package module plus guarded application link helper |
| User login service                                 | launchd agent                                           |
| Root or machine-level service                      | launchd daemon only when genuinely required             |
| Cross-platform package                             | `shared/` or a shared module                            |
| Darwin-only package or behavior                    | `darwin/`                                               |

Do not put system packages into Home Manager merely because the module is nearby. Do not put user configuration into a system package list.

---

## Existing structure

Follow the repository's existing organization:

```text
darwin/
├── default.nix
├── apps/
├── home/
├── overlays/
├── packages/
├── services/
│   └── docker/
├── system/
├── system-commands/
└── terminal/
    ├── aliases/
    ├── plugins/
    └── themes/

shared/
└── packages/
```

Aggregator modules should primarily import related modules and set deliberate enable flags. They should not accumulate unrelated implementation details.

Prefer extending an existing module over creating a second module for the same program or service.

---

## Repository hygiene

Treat the archive and working tree as source material, not as a cleanup target.

Do not edit or package repository noise such as:

```text
.git/
result
.DS_Store
__MACOSX/
.nvimlog
.last-branch
```

Do not modify `flake.lock` unless the task explicitly changes inputs or requests an update. Never run `nix flake update` as part of routine validation.

Before finishing, use `git status` and `git diff` to make sure only intended files changed.

---

## Portability

The repository is expected to support both Darwin and Linux over time.

Before adding a path, package, option, or command, ask:

- Is it Darwin-only?
- Does it belong in `shared/` instead?
- Does it require `pkgs.stdenv.isDarwin` or `lib.optionalAttrs`?
- Is there a Linux equivalent?
- Is the option available in nix-darwin, Home Manager, NixOS, or only one of them?

Do not put macOS paths, `launchctl`, `/Applications`, `defaults`, or Homebrew assumptions into shared modules.

---

## Modularization

Always consider:

- Can this become its own module?
- WIll it profit from being a toggle instead of a hardcoded feature?
- What kind of configurable paths does the feature use that we could add as a variable?
- Does it need a package list variable?
- Does it need Darwin/Linux separation?
- Can it be used on both platforms?
- Is it a GUI-based program or tool for darwin, which means it needs a symlink to /Applications or other folders?

### nix-darwin system layer

Use nix-darwin for:

- `system.*`;
- `system.defaults.*`;
- `networking.*`;
- `nix.*`;
- `nixpkgs.*`;
- `environment.systemPackages`;
- `environment.systemPath`;
- `environment.variables`;
- `environment.etc`;
- system activation scripts;
- nix-darwin launchd jobs;
- Homebrew and nix-homebrew;
- machine-level application bundle handling.

### Home Manager

Home Manager is integrated through nix-darwin. There is no standalone Home Manager switch for this repository.

Use Home Manager for:

- `home.packages` when the package is intentionally user-scoped;
- `home.file`;
- `xdg.configFile`;
- `home.sessionVariables` and `home.sessionPath`;
- `programs.fish`;
- user aliases and functions;
- terminal program settings;
- `targets.darwin.defaults` for user-scoped defaults unavailable at system level;
- Home Manager launchd jobs.

Do not use the nix-darwin launchd schema inside a Home Manager module or vice versa.

Nix-darwin user agent:

```nix
launchd.agents.example = {
  serviceConfig = {
    Label = "com.ven.example";
    ProgramArguments = [ "${runner}/bin/run-example" ];
    RunAtLoad = true;
  };
};
```

Home Manager user agent:

```nix
launchd.agents.example = {
  config = {
    Label = "com.ven.example";
    ProgramArguments = [ "${runner}/bin/run-example" ];
    RunAtLoad = true;
  };
};
```

---

# Non-negotiable safety rules

## Inspect before changing

Before editing any file:

1. Read the target file completely.
2. Read its direct importer or aggregator.
3. Read at least one nearby module that solves a similar problem.
4. Search for duplicate options, service labels, ports, paths, package declarations, aliases, and generated filenames.
5. Inspect Git history when the current implementation looks unusual or a previous failure is mentioned.
6. Preserve unrelated local changes.

Do not rewrite a module merely to match a preferred personal style. Follow the repository's current architecture and naming unless the user asks for a refactor.

## Do not execute mutating operations by default

Repository work is inspect-and-edit only unless the user explicitly asks for commands to be executed.

Do not automatically run:

- `darwin-rebuild switch`;
- Home Manager activation;
- activation scripts copied from a Nix module;
- `launchctl bootstrap`, `bootout`, `kickstart`, `load`, or `unload`;
- `brew bundle cleanup`, cask upgrades, or application moves;
- Docker `up`, `down`, `rm`, `system prune`, `volume prune`, or image pulls;
- backup or restore scripts;
- rsync jobs;
- commands using `sudo`;
- commands that restart Finder, Dock, SystemUIServer, FileProvider, iCloud, or Docker Desktop;
- generated helper scripts merely to see what they do.

Read-only inspection and non-activating evaluation are preferred. A build may be run only when it cannot trigger activation or mutate user data.

## iCloud and Apple-managed data are hazardous

Treat all of the following as fragile, user-owned data:

```text
/Users/ven/Library/Mobile Documents
/Users/ven/Library/Mobile Documents/com~apple~CloudDocs
/Users/ven/Library/Containers
/Users/ven/Library/Group Containers
/Users/ven/iCloudDocs
```

The `Mobile Documents` directory contains both iCloud Drive and application-specific containers. Those containers have already been damaged during previous configuration work.

Without explicit, task-specific approval, never:

- delete, rename, move, replace, or recreate anything inside these roots;
- run recursive `chmod`, `chown`, `rm`, `mv`, `cp`, `ditto`, or `rsync` against them;
- run `find ... -delete` anywhere under them;
- use `rsync --delete`, `--remove-source-files`, or an equivalent mirror operation;
- create or replace symlinks inside application containers;
- replace an existing directory with a symlink;
- traverse every iCloud container as part of activation;
- kill `bird`, `cloudd`, or `fileproviderd`;
- reset, evict, re-download, or re-index iCloud data;
- assume a missing path is safe to recreate;
- assume an empty-looking directory is actually empty or fully downloaded.

When a configured path intentionally lives in iCloud:

- preserve the exact path unless the user requests a migration;
- create only the explicitly named child directories required by the service;
- never modify sibling containers;
- never apply broad permissions to the parent tree;
- check whether the path is a real directory or a symlink before writing;
- do not copy, migrate, or repair live database data while its service is running;
- make failure non-destructive and clearly logged.

A convenient `~/iCloudDocs` symlink must be treated as user-owned once it exists. Never replace it automatically. If it is wrong, report the state and provide a manual repair plan.

---

# Nix module rules

## Prefer clear data flow

Use a `let` block for repeated names, paths, ports, package values, generated text, and helper scripts.

Typical order:

1. module arguments;
2. `let` bindings;
3. `options` when the module is configurable;
4. `config = lib.mkIf cfg.enable { ... };` when optional;
5. imports near the end for aggregator modules.

Use `lib.mkEnableOption` for independently optional features. Use typed `lib.mkOption` values for ports, paths, booleans, package values, lists, and enums.

Avoid `lib.types.anything` unless the value really is a function or deliberately untyped helper and no better module interface exists.

## Avoid unnecessary framework refactors

The flake already works with direct nix-darwin outputs, a composed `overlays.macbook`, integrated Home Manager, and modular imports.

Keep overlays as functions and keep the overlay list shape expected by `lib.composeManyExtensions`. Do not replace an overlay function with a list or nest a list where a function is required.

Do not introduce or restructure around:

- flake-parts;
- flake-utils;
- a new host framework;
- a new option namespace;
- a new package manager;
- a new secrets system;

unless the requested task benefits concretely and the migration scope is explicit.

---

# Module organization

## Nix and shell interpolation

Inside a Nix indented string:

```nix
''
  echo "Nix value: ${appName}"
  echo "Shell value: ''${HOME}"
''
```

Do not accidentally let Nix consume a shell parameter expansion.

For generated arguments:

```nix
envArgs =
  lib.concatMapStringsSep " "
    (value: "-e ${lib.escapeShellArg value}")
    envVars;
```

Prefer argument lists where the module option supports them. String-rendered commands require extra scrutiny.

---

## Generated scripts

Follow the pattern used by service runners such as `rsync.nix`:

1. define stable paths and settings in a `let` block;
2. keep executable inputs explicit;
3. render a script with `pkgs.writeShellScriptBin`;
4. use strict shell mode;
5. validate prerequisites;
6. log each action;
7. make repeat execution safe;
8. install the runner only when it should be callable or referenced by launchd;
9. invoke it from activation or launchd only when that behavior is intentional.

Example structure:

```nix
let
  scriptDir = "/Users/ven/.config/nix/nix-scripts";
  timeoutBin = "${pkgs.coreutils}/bin/timeout";

  scripts = [
    "${scriptDir}/one.sh"
    "${scriptDir}/two.sh"
  ];

  runner = pkgs.writeShellScriptBin "run-example" ''
    set -euo pipefail

    LOG_PREFIX="[nix-darwin][example]"

    # Explicit, guarded operations only.
  '';
in
{
  environment.systemPackages = [ runner ];
}
```

---

# macOS settings

## Prefer typed nix-darwin options

Use nix-darwin's typed options first:

```nix
system.keyboard = {
  enableKeyMapping = true;
  remapCapsLockToEscape = false;
  remapCapsLockToControl = false;
};

system.defaults.NSGlobalDomain = {
  "com.apple.keyboard.fnState" = true;
  NSAutomaticSpellingCorrectionEnabled = false;
};
```

Keep related settings in domain-specific modules:

```text
keyboard.nix
mouse.nix
trackpad.nix
dock-options.nix
finder-options.nix
screenshot-options.nix
statusbar.nix
locale.nix
fonts.nix
```

Do not collect every macOS default into `system-options.nix`. That file is glue plus genuinely global settings.

## Raw preferences

Use:

```nix
system.defaults.CustomUserPreferences
```

only for settings not exposed as typed nix-darwin options.

Use:

```nix
targets.darwin.defaults
```

for Home Manager user-scoped defaults when that is the correct owner.

Rules:

- verify the preference domain and value type;
- quote keys containing dots;
- preserve booleans as booleans and integers as integers;
- do not copy a random `defaults write` command without confirming its current value type;
- document whether logout, app restart, Dock restart, or Finder restart is required;
- do not add an imperative `defaults write` activation when a declarative option exists.

## Imperative macOS changes

Imperative settings are a last resort.

Never add broad reset logic such as:

- deleting every `.DS_Store` under `$HOME`;
- clearing all Finder caches;
- killing multiple Apple services;
- resetting a preference domain;
- removing application preferences;

without explicit approval and a one-time migration plan.

A one-time script must use a narrowly scoped state marker, precise paths, a dry-run or preview where possible, and a clear rollback procedure. It must never search or delete within iCloud application containers.

---

# macOS applications

## Homebrew cask modules

Follow the existing per-application pattern:

```nix
{ ... }:

let
  appName = "Example.app";
  caskName = "example";
  targetDir = "/Applications/Tools";
in
{
  homebrew.casks = [
    {
      name = caskName;
      args = { appdir = targetDir; };
    }
  ];

  system.activationScripts.ensureExampleAppDir.text = ''
    if [ ! -d "${targetDir}" ]; then
      mkdir -p "${targetDir}"
    fi
  '';
}
```

Rules:

- keep cask name and destination explicit;
- use the existing category directories;
- create only the category directory;
- do not move an existing bundle unless the module already owns that migration;
- do not overwrite a manually installed application;
- do not manage application support data in the app installation module.

The current Homebrew module performs an explicit `brew bundle cleanup --force` during activation. Therefore, changing `homebrew.brews`, `homebrew.casks`, taps, or generated Brewfile content can uninstall undeclared software on the next switch. Always call this out in the change summary, inspect the generated package set, and never activate such a change automatically.

## Nix application bundles

Nix-built `.app` bundles live under:

```text
/Applications/Nix Apps
```

Categorized links may be created under paths such as:

```text
/Applications/Tools
/Applications/Programming
/Applications/Multimedia
```

Use the repository's application-link helper. Do not write a new ad hoc `ln -sf` activation script.

The helper's safety behavior is mandatory:

- only expected `.app` source and target paths;
- never overwrite regular files or directories;
- never replace unrelated symlinks;
- remove only a link that points to the expected managed source;
- leave the source bundle untouched.

---

# launchd services

## Agent versus daemon

Prefer a user LaunchAgent for:

- Docker Desktop;
- services that need the logged-in user's GUI session;
- services using user-owned files;
- services using paths under `/Users/ven`;
- local web applications intended for Ven.

Use a LaunchDaemon only when the service genuinely requires machine-level root execution before login.

Do not use a daemon merely because an activation script runs as root.

## Runner requirements

A launchd runner must:

- have an absolute `ProgramArguments` path;
- not depend on shell aliases or interactive environment setup;
- set any required `PATH` explicitly;
- verify required application binaries exist;
- log useful startup state;
- wait for dependencies with a finite timeout;
- use `exec` for a foreground service;
- produce a stable exit code;
- avoid writing into the Nix store;
- avoid writing into `/tmp` except logs, sockets, or ephemeral markers.

Use explicit log files when troubleshooting matters:

```nix
StandardOutPath = "/tmp/com.ven.example.out.log";
StandardErrorPath = "/tmp/com.ven.example.err.log";
```

Do not put persistent service data in `/tmp`.

## `RunAtLoad` and `KeepAlive`

Set these deliberately:

- `RunAtLoad = true` starts the job at login or load time;
- `KeepAlive = false` is appropriate for a one-shot runner or when Docker owns restart behavior;
- `KeepAlive = true` is appropriate when launchd directly supervises a foreground process;
- `KeepAlive = { SuccessfulExit = false; };` restarts after failure but not after a clean exit.

Do not combine a detached service, Docker restart policy, and aggressive launchd `KeepAlive` without understanding which layer owns supervision.

## Stable wrapper paths

A store path in `ProgramArguments` is normally valid because the generated launchd plist references the active generation.

Use an `environment.etc` stable wrapper only when the service specifically needs a generation-stable path or an existing module already uses that design.

Do not create stable wrappers by copying store scripts into arbitrary mutable directories.

---

# Docker Desktop and container services

## Docker Desktop

Docker Desktop is installed through a Homebrew cask into:

```text
/Applications/Programming/Docker.app
```

A user LaunchAgent opens it at login.

Do not assume Docker is ready when the app process appears. Container runners must test the Docker engine.

Do not create a system LaunchDaemon for Docker Desktop unless the user explicitly requests a different architecture.

## Persistence model

A Docker service is persistent only when all required state is mounted to a stable host path.

For every service, identify:

- container name;
- project name;
- image and tag;
- host and internal ports;
- persistent host directories;
- container mount destinations;
- secret source;
- restart owner;
- launchd job;
- logs;
- backup expectations.

Never rely on writable container layers for important data.

Never delete persistent volumes or host data during rebuild.

Prohibited during activation and routine service updates:

```text
docker compose down -v
docker volume prune
docker system prune
docker rm -v
rm -rf <dataDir>
```

## Configurable options

A service module should expose options for values that may change:

```nix
options.services.example = {
  enable = lib.mkEnableOption "Example Docker service";

  port = lib.mkOption {
    type = lib.types.port;
    default = 8080;
    description = "Local host port for Example.";
  };

  dataDir = lib.mkOption {
    type = lib.types.str;
    default = "/Users/ven/.config/containers/example";
    description = "Persistent Example data directory.";
  };
};
```

Keep service-specific options in one namespace and reuse them from runner, proxy, certificate, and backup modules.

## Compose files

Generate non-secret Compose configuration with `pkgs.writeText`.

Use stable project names:

```bash
docker-compose -p "$project_name" -f "$compose_file" ...
```

Rules:

- quote YAML values that contain URLs, colons, hashes, or special characters;
- bind local-only services to `127.0.0.1` unless LAN access is intentional;
- preserve the existing port unless the user requests a change;
- do not put passwords directly in the generated Nix string;
- use an external environment file or another secret mechanism outside the Nix store;
- set narrow permissions on secret files;
- keep database, image, attachment, and cache mounts explicit;
- do not add anonymous volumes for data that must survive recreation.

## Data directories

Directory preparation must be narrow and idempotent:

```bash
mkdir -p "$data_dir/data" "$data_dir/images"
```

Do not use broad patterns such as:

```bash
chmod -R u+rwX,go+rwX "$data_dir"
chown -R ven:staff "$containers_root"
```

unless the exact permission requirement is known and the user approved it.

Prefer creating each required child with the correct mode. Never recursively change the iCloud parent or sibling service directories.

## iCloud-backed service data

Some existing service data paths are intentionally under:

```text
/Users/ven/Library/Mobile Documents/com~apple~CloudDocs/my-system/user-data/01-databases-containers
```

Do not relocate these paths silently.

When working with such a service:

- touch only that service's exact directory;
- do not traverse other iCloud containers;
- do not recreate the service root if it is missing without reporting the state;
- do not perform migrations while containers are running;
- do not use recursive world-writable permissions;
- do not symlink live database files into or out of the directory;
- do not run backup, restore, or rsync automatically;
- explain the risk before any data-layout change.

## Startup and readiness

A runner may wait for Docker, a database, or another service, but every wait must be bounded.

Use a maximum attempt count or `timeout`. Log the final failure and exit non-zero.

For multi-container applications:

- add health checks where supported;
- wait for the database rather than only for the container process;
- preserve service dependencies;
- avoid authentication defaults such as `root` unless the application requires them;
- keep database names, users, and host names consistent between Compose and application environment variables.

## Rebuild and recreation

Recreating a container is acceptable when its configuration changes, provided persistent host mounts remain untouched.

Safe goals:

- stop only the named project or container;
- recreate only that service;
- preserve data directories and named persistent volumes;
- remove only orphans belonging to the same project;
- update restart policy intentionally;
- retain logs needed for diagnosis.

Do not prune unrelated containers, networks, images, or volumes.

Choose one supervision model:

### Foreground Compose model

- launchd starts `docker-compose up` without `-d`;
- the runner ends with `exec`;
- launchd supervises the Compose process;
- `KeepAlive` may restart it after failure.

### Detached Docker model

- the runner creates or starts detached containers;
- containers use `--restart unless-stopped`;
- the runner exits successfully;
- launchd normally uses `KeepAlive = false`.

Do not mix these models accidentally.

## Secrets

Never store these in a Nix string, `pkgs.writeText`, the flake, or Git:

- passwords;
- API tokens;
- private keys;
- database credentials;
- admin tokens;
- cookie secrets.

Nix store paths are not secret.

Reference a user-owned secret file, environment file, or approved secret-management mechanism. The runner should fail clearly when the file is absent and must not print secret values.

---

# Reverse proxies and certificates

Keep proxy, certificate generation, and application container logic separable when the existing service is split that way.

A generated nginx virtual host should reuse service options for:

- host port;
- server names;
- certificate paths;
- application name.

Before starting nginx:

- verify certificate and key exist;
- verify file permissions;
- run `nginx -t` against the exact generated config;
- do not start with an invalid config;
- do not regenerate trust roots or certificates on every activation unless explicitly designed that way.

Private keys must not be written into the Nix store.

---

# Validation

## Inspect first

Before building, inspect:

- module imports;
- option names and types;
- duplicate definitions;
- Nix string interpolation;
- launchd schema;
- generated paths;
- service labels;
- ports;
- persistent directories;
- whether any path enters iCloud or an Apple-managed container;
- whether the script contains destructive commands.

## Non-activating validation order

Use the least invasive applicable steps:

```fish
nix flake check /Users/ven/.config/nix/nix-config

sudo -H nix build \
  /Users/ven/.config/nix/nix-config#darwinConfigurations.macbook.system \
  --no-link

sudo -H darwin-rebuild build \
  --flake /Users/ven/.config/nix/nix-config#macbook
```

Do not run:

```fish
sudo -H darwin-rebuild switch \
  --flake /Users/ven/.config/nix/nix-config#macbook
```

unless the user explicitly asks to activate the configuration.

A successful build proves evaluation and derivation construction. It does not prove that:

- activation is safe;
- a launchd service will start;
- Docker data permissions are correct;
- an iCloud path is available;
- a migration is reversible;
- a secret file exists.

## Service-specific validation

Prefer validation that does not start the service:

- inspect the generated script in the build output;
- run ShellCheck on extracted script content when practical;
- validate Compose with `docker-compose config` only when Docker access is approved and no service is started;
- run `nginx -t` against a prepared config without loading launchd;
- use `plutil -lint` for manually generated plist files;
- inspect `launchctl print` only when the user requests runtime diagnosis.

---

# Required review checklist

Before finishing a Darwin change, confirm:

- [ ] The correct nix-darwin or Home Manager layer owns the option.
- [ ] The nearest aggregator imports the module exactly once.
- [ ] Fish code is Fish, and generated Bash is clearly separated.
- [ ] Shell and Nix interpolation are correct.
- [ ] Generated config uses `.text`, `.source`, `writeText`, or a runtime writer for a deliberate reason.
- [ ] No mutable application state is symlinked to the Nix store.
- [ ] No secret enters the Nix store.
- [ ] launchd uses the correct `serviceConfig` or `config` schema.
- [ ] Long-running runners end with `exec`.
- [ ] Retry loops are bounded.
- [ ] Persistent Docker data is mounted outside the container.
- [ ] No rebuild path deletes volumes or data.
- [ ] iCloud and Apple-managed roots are untouched except for an exact approved path.
- [ ] No broad recursive `chmod`, `chown`, `find`, `rm`, or `rsync` was added.
- [ ] Validation stops before activation unless activation was explicitly requested.
- [ ] Any state-changing command is clearly labeled.

---

## Activation scripts

Activation is machine mutation, not a general task runner.

A system activation script should be:

- short;
- idempotent;
- local;
- deterministic;
- non-interactive;
- safe to run repeatedly;
- explicit about whether failure should abort activation.

Prefer a unique name:

```nix
system.activationScripts.ensureExampleData.text = lib.mkAfter ''
  # exact setup only
'';
```

Use the shared `extraActivation` key only when preserving an existing pattern or when ordering is intentionally coordinated.

Do not put the following in activation without explicit approval:

- unbounded network downloads;
- Docker image pulls;
- long database migrations;
- broad backups;
- recursive iCloud scans;
- service data copies;
- `find "$HOME" ... -delete`;
- unconditional application restarts;
- cleanup of files not owned by the module.

The rsync activation runner is a special, deliberate pattern: explicit scripts, per-script timeout, skip missing or non-executable files, continue after failure, and never make the Darwin switch fail because an optional backup failed.

---

## Script rules

Every generated script must:

- quote paths and values;
- use `lib.escapeShellArg` when rendering arbitrary list values;
- use absolute Nix store paths for required tools;
- not rely on aliases, Fish functions, shell profiles, or the terminal environment;
- not assume Homebrew is in launchd's `PATH`;
- use a bounded timeout for external processes that can hang;
- avoid endless `until ...; do sleep ...; done` loops;
- check file type before replacing a path;
- refuse to replace unrelated symlinks;
- create only exact required directories;
- avoid recursive ownership or permission changes;
- return a clear non-zero status for required failures;
- explicitly downgrade only known optional failures;
- use `exec` for the final long-running foreground process.

Do not use shell globbing to discover and execute every script in a directory. The rsync runner intentionally uses an explicit allow-list.

---

# Files generated from Nix

## Home Manager-managed files

When configuration content belongs in the Nix module, use `.text`:

```nix
xdg.configFile."fastfetch/config.jsonc".text = ''
  {
    // Fastfetch configuration
  }
'';
```

When a related asset is also generated:

```nix
xdg.configFile."fastfetch/ascii.txt".text = ''
  ...
'';
```

When the source is a repository file:

```nix
xdg.configFile."fastfetch/config.jsonc".source = ./config.jsonc;
```

Use `home.file` instead of `xdg.configFile` when the destination is not below the XDG config directory.

Rules:

- keep the package, generated config, assets, and shell integration in the same program module;
- use relative target names;
- do not hard-code `/Users/ven/.config` as the target of `xdg.configFile`;
- understand that Home Manager creates a symlink to an immutable store file;
- do not use this pattern for files the application rewrites;
- do not manage cache, history, database, lock, state, socket, or PID files;
- do not generate secrets into `.text` because Nix store content is readable;
- do not point a managed config symlink into an iCloud app container.

---

# Comments and formatting

## File formatting rules

Keep formatting consistent with existing files.

## Nix files

Prefer:

- clear section headers;
- descriptive comments;
- logical grouping;
- variables for repeated values;
- readable indentation.

Example style:

    # =========================
    # SERVICE NAME
    # =========================

Keep option descriptions meaningful.

Use names that describe what a file actually configures.

Example:

Good:

    SYSTEM: BASE CONFIGURATION

Avoid vague names.

Match surrounding files.

Preferred traits:

- file path comment at the top;
- clear title and purpose;
- section headers for meaningful groups;
- comments that explain intent, safety, or non-obvious behavior;
- stable indentation;
- descriptive variable names;
- no decorative comment wall around every trivial line;
- no stale comments that describe old paths or old shell behavior.

Fix comments when code changes. A wrong comment is worse than no comment.

## Nix string interpolation

Inside Nix indented strings:

- `${value}` is Nix interpolation;
- a literal shell expansion such as `${HOME}` must usually be written as `''${HOME}`;
- dynamic values inserted into shell commands must be quoted;
- values rendered from lists should use helpers such as `lib.escapeShellArg`, `lib.concatMapStringsSep`, or structured argument lists;
- do not concatenate untrusted strings into shell commands.

---

# Code modification rules

When suggesting changes:

- Give exact blocks to replace.
- Give exact blocks to remove.
- Preserve indentation.
- Prefer copy/paste-ready replacements.
- Avoid vague instructions like "modify this section".

For moving code: - show what to cut; - show where to paste; - include
surrounding context when needed.

---

# Generated files and symlinks

## Choose the correct mechanism

For Home Manager-managed XDG files:

```nix
xdg.configFile."program/config.toml".text = ''
  # generated content
'';
```

For a repository or store-backed source:

```nix
xdg.configFile."program/config.toml".source = ./config.toml;
```

For a non-XDG file in the home directory:

```nix
home.file."relative/path".text = ''
  # generated content
'';
```

For generated service input that can remain in the Nix store:

```nix
configFile = pkgs.writeText "service-config.yml" generatedConfig;
```

Home Manager normally materializes managed files as symlinks to immutable Nix store paths. Therefore:

- use `.text` when the source of truth should be the Nix module;
- use `.source` for a tracked file or a known store path;
- keep target paths relative to the home or XDG root;
- do not edit the resulting symlink target manually;
- do not use a store symlink for a file the application must rewrite;
- do not manage databases, caches, histories, lock files, sockets, or live application state this way.

The intended Fastfetch pattern is: package declaration, managed config/assets, and Fish startup behavior remain together in the Fastfetch module. Do not scatter them across unrelated files.

## Out-of-store symlinks

`config.lib.file.mkOutOfStoreSymlink` is allowed only when the user explicitly wants a live, editable external source.

Before using it:

- explain that it is impure and points outside the Nix store;
- verify the source is stable and user-managed;
- ensure the target application accepts a symlink;
- refuse to replace an existing regular file or directory;
- never point it into an Apple-managed application container;
- never use it for mutable app state, databases, browser profiles, or iCloud container internals.

## Runtime-written files

Use runtime writers only when a program requires a mutable path or a non-store location.

A runtime writer must:

- create only its exact parent directories;
- write to a temporary file first when replacing an existing config;
- validate generated content when a validator exists;
- atomically move the validated file into place;
- preserve ownership and permissions intentionally;
- avoid recursive permission changes;
- refuse to overwrite unrelated files when ownership is uncertain;
- never write into iCloud or Apple-managed containers unless the module already has an explicit, user-approved path there.

---

## Out-of-store sources

Use:

```nix
config.lib.file.mkOutOfStoreSymlink
```

only when an editable external file is explicitly required.

Never use an out-of-store symlink to:

- replace an existing application settings directory;
- connect an app's live database to the repository;
- connect an Apple-managed iCloud container to another path;
- make browser, Obsidian, Raycast, Paste, iTerm, or similar live state declarative;
- hide a migration that should be handled manually.

If the target exists and is not the exact managed symlink, stop and report it.

## Store-generated service files

Use `pkgs.writeText` when the service can read immutable configuration directly:

```nix
composeFile = pkgs.writeText "example-compose.yml" ''
  services:
    example:
      image: example/image:tag
'';
```

This is appropriate for Docker Compose definitions, static helper config, and command input that does not contain secrets.

Do not place passwords, tokens, private keys, or secret environment values in `pkgs.writeText`.

## Mutable runtime config

Some services, such as the custom nginx setup, write generated content into a mutable user config directory.

For new runtime writers:

1. generate the content as a Nix string;
2. create the exact parent directory;
3. write to a temporary file in the same filesystem;
4. validate the temporary file;
5. set narrow permissions;
6. atomically rename it into place;
7. never replace an unrelated directory or symlink.

Use a quoted heredoc when needed:

```bash
cat > "$tmp_file" <<'EOF_CONFIG'
${generatedConfig}
EOF_CONFIG
```

The quoted heredoc prevents runtime shell expansion. Nix interpolation still occurs while the derivation is built.

---

# Nix commands

For nix-darwin commands use:

    sudo -H

Example:

    sudo -H darwin-rebuild switch --flake ~/.config/nix/nix-config#macbook

Do not omit `-H`.

---

## Keybinding ownership

Preserve these bindings:

```text
Ctrl-F -> FZF command picker
Ctrl-L -> FZF history picker
Ctrl-R -> Atuin search
```

Before adding a binding, search all Fish modules for the same key.

---

# Shell and command rules

## Interactive shell

The user uses fish.

- Commands shown to the user must be Fish-compatible unless clearly labeled as code inside a generated Bash script.
- Check syntax carefully before suggesting shell commands.
- Fish configuration should remain modular.

Avoid: - zsh-only glob syntax; - bash arrays; - bash-specific
substitutions; - commands requiring shell-specific behavior.

Existing command preferences include:

```text
ls   -> eza
cat  -> bat
grep -> rg
nano -> micro
```

Do not replace established tools or keybindings without being asked.

Current important Fish bindings:

```text
Ctrl-F -> command picker
Ctrl-L -> history picker
Ctrl-R -> Atuin search
```

Plugins include:

- autopair.fish
- rose-pine/fish

### Existing fish preferences

Important features:

- autosuggestions
- completions
- ghost suggestions where provided by the configured integration;
- syntax highlighting
- `autopair.fish`;
- the configured Fish theme modules.

Do not reintroduce zsh modules or copy zsh plugin instructions into Fish configuration.

## Generated scripts

Non-interactive launchd and activation helpers may be Bash when the module deliberately creates them with `pkgs.writeShellScriptBin` or an equivalent Nix helper.

Generated Bash scripts should normally use:

```bash
set -euo pipefail
```

They must also:

- use absolute package paths in launchd or activation contexts where `PATH` is minimal;
- use a clear log prefix;
- quote every path;
- use `--` before positional paths where supported;
- check prerequisites before modifying state;
- be idempotent;
- use bounded retries or explicit timeouts;
- avoid broad filesystem searches;
- avoid swallowing unexpected failures;
- distinguish an optional non-fatal task from a required task;
- never execute during Nix evaluation or build merely because the script was generated.

Follow the explicit-list and per-item safety pattern used by the rsync runner. Do not auto-discover executable scripts with a glob and run them during activation.

---

# Fish initialization

## Keep Fish modules composable

Fish configuration is split across modules. Home Manager merges `programs.fish.shellInit`, `programs.fish.interactiveShellInit`, aliases, functions, and program integrations.

Do not use `lib.mkForce` to replace the combined initialization unless explicitly requested.

Do not consolidate all plugin setup into `darwin/terminal/default.nix`. Each integration should remain in its own module.

## `shellInit`

Use `programs.fish.shellInit` for setup that should exist before interactive bindings and that is safe in every Fish process, such as:

- exported variables;
- disabling an integration's automatic keybindings;
- static path variables;
- lightweight, non-output initialization.

Atuin's intended split is the model:

```nix
programs.fish.shellInit = ''
  set -gx ATUIN_NOBIND true
'';
```

Do not put prompts, menus, `fzf`, network calls, long subprocesses, or unconditional output in general shell initialization.

Because Home Manager merges initialization fragments, do not add a top-level `return` that can prevent later fragments from running. Prefer `interactiveShellInit` or wrap interactive logic in an `if status is-interactive ... end` block. Preserve an existing guarded pattern unless the task specifically fixes its ordering.

## `interactiveShellInit`

Use `programs.fish.interactiveShellInit` for:

- `bind` commands;
- interactive helper functions;
- command pickers;
- history pickers;
- interactive-only completions;
- startup behavior intended only for a terminal session.

Atuin's keybinding is the model:

```nix
programs.fish.interactiveShellInit = ''
  bind \cr _atuin_search
'';
```

Use Fish syntax only:

- `set -gx`, not `export`;
- `type -q`, not `command -v` when writing Fish code;
- `test`, not `[[ ... ]]`;
- `bind \cr`, not zsh `bindkey`;
- `string`, Fish lists, and Fish command substitutions.

## Startup output

A tool such as Fastfetch may print on startup from `interactiveShellInit`, or from an existing guarded `shellInit` fragment when its ordering is intentionally preserved, only when:

- the shell is interactive;
- the command exists;
- its config exists;
- it is guarded against repeated output in nested shells or panes;
- its marker is in `$TMPDIR` or another ephemeral runtime location, never iCloud;
- failure does not prevent opening a shell.

Do not use a persistent marker in the repository or home config directory for session-only behavior.

---

# Package management

## System packages

The main system package layer is:

```nix
environment.systemPackages
```

Keep package groups split by purpose. Existing groups include:

```text
darwin/packages/agents-pkgs.nix
darwin/packages/tools-pkgs.nix
darwin/packages/cli-tools.nix
darwin/packages/development-pkgs.nix
darwin/packages/media-pkgs.nix
shared/packages/media-pkgs.nix
```

Do not rename a package group to a vague name such as `misc` or `things`. Use a name that describes what the file actually owns.

When adding a package:

- search all package modules first;
- place it in the narrowest correct group;
- avoid duplicate installation through Nix, Home Manager, and Homebrew;
- explain whether it is cross-platform;
- keep GUI bundle handling separate from CLI package inclusion;
- do not silently change an application's installation source.

## Tool suggestions

When improving workflows, suggest tools that integrate well with Nix.

Examples:

- flake-parts
- flake-utils
- devenv when a project development environment actually needs it.
- direnv
- nix-direnv
- treefmt
- statix
- deadnix
- nil/nixd
- alejandra or another chosen Nix formatter;

Do not add them automatically. Explain the concrete benefit, where they will be configured, and whether they introduce a new workflow before changing the flake or package lists.

## Homebrew applications

Use Homebrew for casks already managed through Homebrew.

Keep per-app metadata such as `appName`, `caskName`, and `targetDir` in a `let` block. Ensure custom `/Applications/...` directories idempotently and do not move or replace unrelated application bundles.

## Nix-managed application links

Use the existing guarded application-link helper for Nix-built `.app` bundles.

A link manager must:

- accept only expected source and target roots;
- create missing category directories;
- leave correct links unchanged;
- refuse to replace regular files, directories, or unrelated links;
- remove only links that point to the source owned by the module;
- leave `/Applications/Nix Apps` bundles untouched.

---

# Services

Keep each service modular and configurable.

Prefer:
services/
├── docker/
├── databases/
└── applications/

Use options for values likely to change, including:

- enable state;
- ports;
- host names and domains;
- data directories;
- image names and tags;
- container names;
- certificate paths;
- log paths;
- application paths.

Avoid hard-coded values for those that are likely to be changed with time or across machines.

Persistent data must live outside the Nix store and outside ephemeral containers.

Service code must clearly separate:

1. configuration data;
2. generated files;
3. one-time directory preparation;
4. the long-running runner;
5. launchd wiring;
6. logging and health checks.

More detailed Darwin service rules are in `darwin/AGENTS.md`.

---

# Development workflow

Prefer the least invasive validation that answers the question.

Recommended order:

1. format or parse the edited file;
2. inspect the diff;
3. evaluate the relevant option or module;
4. run a non-activating flake check;
5. build the Darwin system without switching;
6. switch only when the user explicitly requests it.

Prefer validation before switching. Use:

- nix flake check
- nix eval
- nix build
- darwin-rebuild build

before:
darwin-rebuild switch

For custom packages:
Check: - derivation evaluation; - standalone builds; - final output
paths; - system inclusion.

---

# Validation workflow

For custom packages and overlays, validate progressively:

1. evaluate the expression;
2. build the package directly;
3. inspect the output path and application bundle when applicable;
4. confirm the package is included in the correct package set;
5. build the full system;
6. activate only on explicit request.

Useful commands to provide when relevant:

```fish
nix flake check /Users/ven/.config/nix/nix-config

sudo -H nix build \
  /Users/ven/.config/nix/nix-config#darwinConfigurations.macbook.system \
  --no-link

sudo -H darwin-rebuild build \
  --flake /Users/ven/.config/nix/nix-config#macbook

sudo -H darwin-rebuild switch \
  --flake /Users/ven/.config/nix/nix-config#macbook
```

Always include `sudo -H` for nix-darwin commands that require `sudo`. Never run the final switch automatically.

Do not use a successful evaluation as proof that an activation script, launchd job, Docker service, or iCloud operation is safe.

---

# Change delivery rules

When explaining changes:

- identify the exact file path;
- provide complete copy/paste-ready blocks;
- state exactly what is replaced or inserted;
- preserve indentation and surrounding structure;
- call out any command that changes machine state;
- separate validation commands from activation commands;
- explain persistent data paths and migration implications;
- mention when a generated file becomes read-only because it is store-backed;
- mention when a change requires logout, service restart, or application restart;
- do not claim a command was run when it was not.

When the user asks for manual copy/paste instructions:

- show the exact block to remove;
- show the exact replacement block;
- include enough surrounding context to find the location;
- do not say only “modify this section”;
- do not omit braces, imports, or commas required for a valid result.

For larger edits, summarize:

- files changed;
- options added or altered;
- services affected;
- persistent paths touched;
- commands intentionally not executed.

---

# Do not

Do not:

- Create unnecessary duplicate modules
- Suggest bash/zsh scripts, commands or tools
  Explanation: When giving bash scripts and commands as well as files, make sure they're able to run in fish environment.
- Forget to use existing aliases and functions, instead of their originals. The list of all the aliases you find under the folder:

```
nix-config/darwin/terminal/aliases
```

- silently move code between nix-darwin and Home Manager;
- use zsh-only or Bash-only syntax in user-facing Fish configuration;
- run activation during routine validation;
- hard-code macOS-only assumptions
- remove modular structure for simplicity
- mutate iCloud or Apple-managed application containers;
- use recursive permission changes on broad user-data roots;
- make services depend on an interactive shell profile;
- rely on launchd inheriting the user's terminal `PATH`;
- store secrets directly in Nix strings or the Nix store;
- introduce tools without explaining their purpose.
- update flake inputs or rewrite `flake.lock` during unrelated work;
- delete Docker volumes during rebuilds;
- replace existing files or links merely to make activation succeed;
- use destructive cleanup as a repair strategy;
- add abstractions that are more complicated than the repeated code they replace;
- change established keybindings, paths, ports, or service labels without checking their existing use.
