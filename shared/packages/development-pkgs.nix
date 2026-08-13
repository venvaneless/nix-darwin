# shared/packages/development-pkgs.nix
#
# =====================================================================
# PACKAGES: SHARED DEVELOPMENT TOOLS
#
# Declares development packages for Darwin and Linux. Shared helpers
# provide the common enable, platform-selection, and Darwin-link logic.
# =====================================================================

{ lib, options, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ SHARED PACKAGE HELPERS ------ #
  # ------------------------------------------------------------

  helpers = import ../../options { inherit lib options pkgs; };

  # ------------------------------------------------------------
  # ------ CUSTOM TEX LIVE ENVIRONMENT ------ #
  # ------------------------------------------------------------

  myTex = pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-medium titlesec;
  };

  # ------------------------------------------------------------
  # ------ DEVELOPMENT PACKAGE DEFINITIONS ------ #
  # Every entry can override enable or installOn locally.
  # ------------------------------------------------------------

  developmentPackages = {
    # ---- Nix tools

    # Opinionated Nix source formatter.
    alejandra = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.alejandra;
    };

    # Standalone Home Manager command-line tool.
    homeManager = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.home-manager;
    };

    # Finds unused declarations in Nix files.
    deadnix = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.deadnix;
    };

    # Wrapper around rebuild, search, and garbage-collection commands.
    nh = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nh;
    };

    # Nix language server.
    nil = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nil;
    };

    # Dependency pinning for Nix projects.
    npins = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.npins;
    };

    # Faster direnv integration for Nix shells.
    nixDirenv = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nix-direnv;
    };

    # Alternative Nix language server with flake awareness.
    nixd = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nixd;
    };

    # The official Nix formatter.
    nixfmt = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nixfmt;
    };

    # Lints Nix files for antipatterns.
    statix = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.statix;
    };

    # Renders build output as a live dependency tree.
    nixOutputMonitor = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nix-output-monitor;
    };

    # Interactive browser for store paths and their dependencies.
    nixTree = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nix-tree;
    };

    # Searches nixpkgs from the terminal.
    nixSearch = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nix-search;
    };

    # Locates which package provides a given file.
    nixIndex = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nix-index;
    };

    # Runs a program from nixpkgs without installing it.
    comma = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.comma;
    };

    # Updates package versions and their hashes.
    nixUpdate = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nix-update;
    };

    # ---- Language servers and toolchains

    # TypeScript compiler.
    typescript = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.typescript;
    };

    # Language server for JavaScript and TypeScript.
    typescriptLanguageServer = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.typescript-language-server;
    };

    # Language server for Vue single-file components.
    vueLanguageServer = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.vue-language-server;
    };

    # Go compiler and toolchain.
    go = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.go;
    };

    # Official Go language server.
    gopls = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.gopls;
    };

    # Rust compiler.
    rustc = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.rustc;
    };

    # Rust package manager and build tool.
    cargo = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.cargo;
    };

    # Rust language server.
    rustAnalyzer = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.rust-analyzer;
    };

    # Static type checker and language server for Python.
    pyright = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.pyright;
    };

    # Fast Python linter and formatter.
    ruff = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.ruff;
    };

    # Language servers for HTML, CSS, JSON, and ESLint.
    vscodeLanguageServers = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.vscode-langservers-extracted;
    };

    # Language server for YAML, with schema support.
    yamlLanguageServer = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.yaml-language-server;
    };

    # TOML formatter, linter, and language server.
    taplo = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.taplo;
    };

    # Language server for Lua.
    luaLanguageServer = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.lua-language-server;
    };

    # ---- Development and document tools

    # Command-line client for the Bitwarden vault.
    bitwardenCli = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.bitwarden-cli;
    };

    # Container runtime CLI, pinned to the 29 series.
    docker = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.docker_29;
    };

    # Runs multi-container applications from a compose file.
    dockerCompose = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.docker-compose;
    };

    # Loads and unloads environment variables per directory.
    direnv = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.direnv;
    };

    # Custom TeX Live environment defined in the let block above.
    texLive = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = myTex;
    };

    # certutil and related tools for managing certificate stores.
    nssTools = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nssTools;
    };

    # Converts documents between markup formats.
    pandoc = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.pandoc;
    };

    # ---- Git tools

    # Transparent file encryption inside a Git repository.
    gitCrypt = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.git-crypt;
    };

    # Rewrites Git history.
    gitFilterRepo = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.git-filter-repo;
    };

    # Git extension for versioning large files.
    gitLfs = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.git-lfs;
    };

    # Terminal UI for Git.
    lazygit = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.lazygit;
    };

    # ---- Linters and formatters

    # Formatter for web languages.
    prettier = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.prettier;
    };

    # Long-running ESLint daemon.
    eslintD = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.eslint_d;
    };

    # Runs many Go linters through one command.
    golangciLint = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.golangci-lint;
    };

    # Lua linter.
    selene = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.selene;
    };

    # YAML linter.
    yamllint = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.yamllint;
    };

    # Stricter gofmt.
    gofumpt = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.gofumpt;
    };

    # Rust formatter.
    rustfmt = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.rustfmt;
    };

    # CSS and SCSS linter.
    stylelint = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.stylelint;
    };

    # Lua formatter.
    stylua = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.stylua;
    };

    # ---- JavaScript and Python

    # JavaScript runtime, bundler, and package manager.
    bun = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.bun;
    };

    # Node.js runtime and npm.
    nodejs = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nodejs;
    };

    # Python interpreter.
    python3 = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.python3;
    };

    # Python data analysis library.
    pandas = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.python3Packages.pandas;
    };

    # Python PDF generation library.
    reportlab = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.python3Packages.reportlab;
    };

    # Fast Python package and project manager.
    uv = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.uv;
    };
  };

  # ------------------------------------------------------------
  # ------ DARWIN-ONLY DEVELOPMENT APPLICATIONS ------ #
  # Self-packaged applications stay beside the rest of development.
  # ------------------------------------------------------------

  darwinDevelopmentApplications = {
    # ---- iTerm2
    # Terminal emulator built from the repository's own package.
    iterm2 = {
      enable = true;
      installOn = { darwin = true; linux = false; };
      package = pkgs.callPackage ../../darwin/packages/iterm2 { };
      appName = "iTerm.app";
      symlinkProgramming = true;
    };

    # ---- iTerm2 AI plugin
    # Adds the AI features iTerm2 no longer bundles.
    itermAiPlugin = {
      enable = true;
      installOn = { darwin = true; linux = false; };
      package = pkgs.callPackage ../../darwin/packages/iterm2/iterm-ai-plugin.nix { };
      appName = "iTermAI.app";
      symlinkProgramming = true;
    };

    # ---- iTerm2 browser plugin
    # Adds the embedded browser component.
    itermBrowserPlugin = {
      enable = true;
      installOn = { darwin = true; linux = false; };
      package = pkgs.callPackage ../../darwin/packages/iterm2/iterm-browser-plugin.nix { };
      appName = "iTermBrowserPlugin.app";
      symlinkProgramming = true;
    };
  };

  # ------------------------------------------------------------
  # ------ SHARED DEVELOPMENT APPLICATIONS ------ #
  # ------------------------------------------------------------

  developmentApplications = {
    # ---- WezTerm
    # GPU-accelerated terminal emulator; its config lives in
    # shared/terminal/wezterm.
    wezterm = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.wezterm;
      appName = "WezTerm.app";
      symlinkProgramming = true;
    };

    # ** Visual Studio Code is not listed here. It owns ./vscode.nix,
    # ** which keeps its package, its application link, and the
    # ** relocation of its state in one place.

    # ---- Zed
    zed = {
      enable = true;
      package = pkgs.zed-editor;
      installOn = { darwin = true; linux = true; };
      appName = "Zed.app";
      symlinkProgramming = true;
    };
  };
in
{
  # ---- Programs that own their own module
  # VS Code keeps its package, its Darwin application link, and the
  # relocation of its state together rather than split across files.
  imports = [ ./vscode.nix ];

  config = helpers.packageOptions.mkPackageModule {
    name = "shared-development";
    packages = developmentPackages // darwinDevelopmentApplications // developmentApplications;
  };
}
