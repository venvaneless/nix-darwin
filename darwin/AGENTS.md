# AGENTS.md --- nix-darwin specific instructions

## Scope

This file extends the repository root `AGENTS.md`.

The root rules always apply. These rules add nix-darwin-specific
behavior for:

-   `darwin/nix-darwin.nix`
-   `darwin/modules/**`
-   Home Manager modules integrated through nix-darwin
-   macOS system configuration
-   launchd services
-   Docker Desktop services
-   generated macOS configuration files

Primary host:

``` text
macbook
```

------------------------------------------------------------------------

# nix-darwin architecture

## Ownership

Use the correct layer:

  Task                           Owner
  ------------------------------ -------------------------------------------
  macOS system defaults          nix-darwin
  `environment.systemPackages`   nix-darwin
  machine-wide environment       nix-darwin
  Home Manager user files        Home Manager
  Fish configuration             Home Manager
  GUI casks                      Homebrew/nix-darwin Homebrew module
  Nix `.app` bundles             Nix package + guarded application linking
  user services                  launchd agents
  system services                launchd daemons only when required

Do not move settings between layers without a reason.

------------------------------------------------------------------------

# Module structure

Follow the existing pattern:

``` text
darwin/modules/
├── apps/
├── home/
├── overlays/
├── services/
├── system/
├── terminal/
```

Keep modules focused.

Prefer:

-   `keyboard.nix`
-   `trackpad.nix`
-   `finder.nix`
-   `dock.nix`
-   `wallpaper.nix`

over one large macOS settings file.

Use options when values may change:

-   ports;
-   paths;
-   domains;
-   enable flags;
-   package lists;
-   application names.

------------------------------------------------------------------------

# Generated files

Many programs are configured declaratively by generating files from Nix.

Examples:

-   Fastfetch configuration;
-   terminal configuration;
-   editor configuration;
-   theme files.

Choose the correct mechanism.

## Store-backed configuration

Use:

``` nix
xdg.configFile."program/config".text = ''
  configuration
'';
```

or:

``` nix
xdg.configFile."program/config".source = ./config;
```

Remember:

Home Manager creates links to immutable Nix store files.

Therefore:

Do not use this for:

-   databases;
-   caches;
-   history files;
-   lock files;
-   application state;
-   files applications modify.

------------------------------------------------------------------------

# Out-of-store symlinks

Use:

``` nix
config.lib.file.mkOutOfStoreSymlink
```

only when the user explicitly needs a live editable file.

Never use it for:

-   iCloud containers;
-   application databases;
-   browser profiles;
-   mutable application state.

Never replace an existing file or directory without checking first.

------------------------------------------------------------------------

# Generated scripts

Follow the style used by scripts such as `rsync.nix`.

Generated scripts should:

-   use `pkgs.writeShellScriptBin`;
-   use `set -euo pipefail`;
-   use absolute paths for required binaries;
-   quote paths;
-   validate prerequisites;
-   log meaningful actions;
-   be idempotent;
-   have bounded retries;
-   avoid destructive defaults.

Avoid:

``` bash
rm -rf
rsync --delete
find ... -delete
chmod -R
chown -R
```

unless the exact scope is known and explicitly approved.

Activation scripts must be safe to run repeatedly.

------------------------------------------------------------------------

# macOS defaults

Prefer typed nix-darwin options.

Example:

``` nix
system.keyboard = {
  enableKeyMapping = true;
};
```

Use:

``` nix
system.defaults
```

before:

``` nix
defaults write
```

Use:

``` nix
system.defaults.CustomUserPreferences
```

only for settings unavailable through typed options.

Rules:

-   verify preference domains;
-   preserve value types;
-   document unusual settings;
-   avoid reset scripts.

Never add broad preference cleanup.

------------------------------------------------------------------------

# Fish integration

Fish is managed through Home Manager.

Keep modules composable.

## shellInit

Use for:

-   environment variables;
-   paths;
-   non-interactive setup.

Example:

``` nix
programs.fish.shellInit = ''
  set -gx VARIABLE value
'';
```

Do not put:

-   prompts;
-   menus;
-   interactive commands;
-   output-producing commands.

## interactiveShellInit

Use for:

-   bindings;
-   interactive tools;
-   startup behavior.

Example:

``` nix
programs.fish.interactiveShellInit = ''
  bind \cr _atuin_search
'';
```

Never add top-level `return` statements that prevent later fragments
from loading.

Preserve:

``` text
Ctrl-F → command picker
Ctrl-L → history picker
Ctrl-R → Atuin search
```

------------------------------------------------------------------------

# launchd

## User agents

Use agents for:

-   Docker Desktop;
-   user applications;
-   local services;
-   services using `/Users/ven`.

## Daemons

Use daemons only when root privileges or pre-login startup are genuinely
required.

Do not use daemons as a shortcut.

------------------------------------------------------------------------

# launchd runners

A launchd runner must:

-   use absolute paths;
-   not depend on shell profiles;
-   define PATH when needed;
-   log output;
-   use bounded waits;
-   avoid infinite loops;
-   use `exec` for foreground services.

Do not assume terminal environment variables exist.

------------------------------------------------------------------------

# Docker Desktop

Docker Desktop is a user application.

Do not create a root daemon for it.

Wait for Docker engine readiness, not only the application process.

------------------------------------------------------------------------

# Docker services

Every service module must define:

-   image;
-   ports;
-   container name;
-   project name;
-   persistent data paths;
-   secrets source;
-   restart ownership.

Persistent data must live outside containers.

Never use:

``` text
docker volume prune
docker system prune
docker compose down -v
```

during rebuilds.

Never delete service data automatically.

------------------------------------------------------------------------

# Docker Compose generation

Use:

``` nix
pkgs.writeText
```

for generated compose files.

Do not place secrets inside generated Nix text.

Use:

-   environment files;
-   secret files;
-   external secret systems.

Keep ports, paths, domains, and container names configurable.

------------------------------------------------------------------------

# iCloud safety

Treat these as fragile:

``` text
/Users/ven/Library/Mobile Documents
/Users/ven/Library/Containers
/Users/ven/Library/Group Containers
```

Never automatically:

-   delete;
-   rename;
-   migrate;
-   rsync;
-   chmod recursively;
-   chown recursively;
-   recreate;
-   replace with symlinks.

Never use:

``` bash
rsync --delete
```

against iCloud paths.

Only touch the exact service directory requested.

Never assume an empty directory is safe.

------------------------------------------------------------------------

# Application management

## Homebrew apps

Keep:

-   cask name;
-   app name;
-   target directory

in variables.

Do not move existing apps unless the module owns that migration.

Be aware that Homebrew cleanup can remove undeclared applications.

## Nix applications

Use the existing guarded application-link helper.

Never blindly run:

``` bash
ln -sf
```

into `/Applications`.

Only remove links owned by the module.

------------------------------------------------------------------------

# Validation

Before switching:

``` fish
nix flake check
nix build
darwin-rebuild build
```

Do not automatically run:

``` fish
darwin-rebuild switch
```

Do not execute:

-   activation scripts;
-   launchctl changes;
-   Docker changes;
-   Homebrew cleanup;
-   filesystem migrations

unless explicitly requested.
