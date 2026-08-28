# shared/packages.nix
#
# =====================================================================
# PACKAGES: SHARED PACKAGE DECLARATIONS
#
# Every cross-platform package declaration, grouped by category in one
# file. Each entry keeps its own enable flag, its per-platform installOn
# toggle, and its Darwin application-link category.
#
# This file is imported once per host:
#   darwin/default.nix       -> environment.systemPackages
#   linux/default.nix        -> environment.systemPackages
#   nixos/home-manager.nix   -> home.packages
#
# The shared helpers choose that destination automatically, so the same
# declarations work at system level and inside Home Manager.
# =====================================================================

{ inputs, lib, options, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ SHARED PACKAGE HELPERS ------ #
  # Provides mkPackageModule, byPlatform, and the Darwin
  # application-link manager. Defined once in options/.
  # ------------------------------------------------------------

  helpers = import ../options { inherit lib options pkgs; };

  # ------------------------------------------------------------
  # ------ CUSTOM TEX LIVE ENVIRONMENT ------ #
  # Only the schemes actually used, which keeps the closure small.
  # ------------------------------------------------------------

  myTex = pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-medium titlesec;
  };

  # ------------------------------------------------------------
  # ------ GENERAL APPLICATION DEFINITIONS ------ #
  # ------------------------------------------------------------

  appPackages = {
    # ---- LibreWolf
    # Privacy-focused Firefox-derived web browser.
    librewolf = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.librewolf;
      appName = "LibreWolf.app";
      symlinkApplications = true;
    };
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

    # Runs a program from nixpkgs without installing it.
    comma = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.comma;
    };

    # Rebuilds the active nix-darwin system configuration.
    # This command is only available on Darwin.
    darwinRebuild = {
      enable = true;
      installOn = { darwin = true; linux = false; };
      package = inputs.darwin.packages.${pkgs.stdenv.hostPlatform.system}.darwin-rebuild;
    };

    # Finds unused declarations in Nix files.
    deadnix = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.deadnix;
    };

    # Standalone Home Manager command-line tool.
    homeManager = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.home-manager;
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

    # Locates which package provides a given file.
    nixIndex = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nix-index;
    };

    # Renders build output as a live dependency tree.
    nixOutputMonitor = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nix-output-monitor;
    };

    # Searches nixpkgs from the terminal.
    nixSearch = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nix-search;
    };

    # Interactive browser for store paths and their dependencies.
    nixTree = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nix-tree;
    };

    # Updates package versions and their hashes.
    nixUpdate = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nix-update;
    };

    # Dependency pinning for Nix projects.
    npins = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.npins;
    };

    # Lints Nix files for antipatterns.
    statix = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.statix;
    };

    # ---- Language servers and toolchains

    # Rust package manager and build tool.
    cargo = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.cargo;
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

    # Language server for Lua.
    luaLanguageServer = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.lua-language-server;
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

    # Rust language server.
    rustAnalyzer = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.rust-analyzer;
    };

    # Rust compiler.
    rustc = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.rustc;
    };

    # TOML formatter, linter, and language server.
    taplo = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.taplo;
    };

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

    # Language servers for HTML, CSS, JSON, and ESLint.
    vscodeLanguageServers = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.vscode-langservers-extracted;
    };

    # Language server for Vue single-file components.
    vueLanguageServer = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.vue-language-server;
    };

    # Language server for YAML, with schema support.
    yamlLanguageServer = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.yaml-language-server;
    };

    # ---- Development and document tools

    # Modern file encryption tool.
    age = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.age;
    };

    # Command-line client for the Bitwarden vault.
    bitwardenCli = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.bitwarden-cli;
    };

    # Loads and unloads environment variables per directory.
    direnv = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.direnv;
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

    # Manages encrypted secrets using age keys.
    sops = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.sops;
    };

    # Custom TeX Live environment defined in the let block above.
    texLive = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = myTex;
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

    # Long-running ESLint daemon.
    eslintD = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.eslint_d;
    };

    # Stricter gofmt.
    gofumpt = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.gofumpt;
    };

    # Runs many Go linters through one command.
    golangciLint = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.golangci-lint;
    };

    # Formatter for web languages.
    prettier = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.prettier;
    };

    # Rust formatter.
    rustfmt = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.rustfmt;
    };

    # Lua linter.
    selene = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.selene;
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

    # YAML linter.
    yamllint = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.yamllint;
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

    # Python data analysis library.
    pandas = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.python3Packages.pandas;
    };

    # Python interpreter.
    python3 = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.python3;
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
  # ------ CLI PACKAGE DEFINITIONS ------ #
  # Every entry can override enable or installOn locally.
  # ------------------------------------------------------------

  # fd is installed cross-platform by shared/terminal/cli-tuis/fd/fd.nix,
  # which also owns its ignore file and colours.

  cliPackages = {
    # Interactive Bash shell with completion support.
    bashInteractive = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.bashInteractive;
    };

    # Generates thumbnails for video files.
    ffmpegthumbnailer = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.ffmpegthumbnailer;
    };

    # Cross-platform command shell.
    fish = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.fish;
    };

    # GNU implementation of awk.
    gawk = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.gawk;
    };

    # Tool for creating shell scripts with styled output.
    gum = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.gum;
    };

    # Image manipulation command-line tools.
    imagemagick = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.imagemagick;
    };

    # 7-Zip-compatible archive tools.
    p7zip = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.p7zip;
    };

    # Displays directory trees in the terminal.
    tree = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.tree;
    };

    # Extracts a broad range of archive formats.
    unar = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.unar;
    };

    # Non-interactive network downloader.
    wget = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.wget;
    };

    # Zstandard compression tools.
    zstd = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.zstd;
    };

    unison = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.unison;
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
      package = pkgs.callPackage ../darwin/packages/iterm2 { };
      appName = "iTerm.app";
      symlinkProgramming = true;
    };

    # ---- iTerm2 AI plugin
    # Adds the AI features iTerm2 no longer bundles.
    itermAiPlugin = {
      enable = true;
      installOn = { darwin = true; linux = false; };
      package = pkgs.callPackage ../darwin/packages/iterm2/iterm-ai-plugin.nix { };
      appName = "iTermAI.app";
      symlinkProgramming = true;
    };

    # ---- iTerm2 browser plugin
    # Adds the embedded browser component.
    itermBrowserPlugin = {
      enable = true;
      installOn = { darwin = true; linux = false; };
      package = pkgs.callPackage ../darwin/packages/iterm2/iterm-browser-plugin.nix { };
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
      installOn = { darwin = true; linux = true; };
      package = pkgs.zed-editor;
      appName = "Zed.app";
      symlinkProgramming = true;
    };
  };

  # ------------------------------------------------------------
  # ------ MEDIA PACKAGE DEFINITIONS ------ #
  # ------------------------------------------------------------

  mediaPackages = {
    # ---- Kiwix
    # Offline content reader with platform-specific application bundles.
    kiwix = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = helpers.packageOptions.byPlatform {
        darwin = pkgs.kiwix-apple;
        linux = pkgs.kiwix;
      };
      appName = "Kiwix.app";
      symlinkMultimedia = true;
    };

    # ---- MediaInfo
    # Inspects technical and tag information in media files.
    mediainfo = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.mediainfo;
    };

    # ---- Poppler
    # Provides command-line utilities for rendering and inspecting PDFs.
    poppler = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.poppler-utils;
    };

    # ---- VLC
    # Plays video, audio, streams, discs, and many media formats.
    vlc = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = helpers.packageOptions.byPlatform {
        darwin = pkgs.vlc-bin;
        linux = pkgs.vlc;
      };
      appName = "VLC.app";
      symlinkMultimedia = true;
    };

    # ---- YouTube Music Desktop
    # Shared desktop application for YouTube Music.
    ytmdesktop = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.ytmdesktop;
      appName = "YouTube Music Desktop App.app";
      symlinkMultimedia = true;
    };
  };

  # ------------------------------------------------------------
  # ------ PRODUCTIVITY PACKAGE DEFINITIONS ------ #
  # ------------------------------------------------------------

  productivityPackages = {
    # ---- Obsidian
    # Knowledge base and note-taking application with Markdown support.
    obsidian = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.obsidian;
      appName = "Obsidian.app";
      symlinkProductivity = true;
    };

    # ---- Vesktop
    # Alternate Discord client with Vencord built in.
    vesktop = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.vesktop;
      appName = "Vesktop.app";
      symlinkProductivity = true;
    };

    # ---- Signal Desktop
    # Private messenger linked to the Signal mobile application.
    signalDesktop = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.signal-desktop;
      appName = "Signal.app";
      symlinkProductivity = true;
    };

    # ---- Signal Export
    # Command-line tool that exports Signal chats to Markdown.
    signalExport = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.signal-export;
    };
  };

  # ------------------------------------------------------------
  # ------ TOOL PACKAGE DEFINITIONS ------ #
  # ------------------------------------------------------------

  espanso = import ./home/pkgs-configs/espanso/default.nix {
    inherit lib pkgs;

    paths = import ../options/paths.nix;
  };

  toolPackages = {
    # ---- Espanso
    # Cross-platform text expander for keyboard-driven snippets.
    espanso = espanso.package;
  };

in
{
  # ------------------------------------------------------------
  # ------ PROGRAMS THAT OWN THEIR OWN MODULE ------ #
  # VS Code keeps its package, its Darwin application link, and the
  # relocation of its state together rather than split across files.
  #
  # qBittorrent does the same for its package, its application link,
  # its profile location, and the settings declared for that profile.
  # The optional NixOS daemon is not part of it: a system service
  # cannot be declared from a file that Home Manager also evaluates.
  # ------------------------------------------------------------

  imports = [
    ./packages/vscode.nix
    ./packages/qbittorrent.nix
  ];

  # ------------------------------------------------------------
  # ------ PACKAGE MODULE ASSEMBLY ------ #
  # One call per category, merged into a single config. Each call keeps
  # its own name so the Darwin application-link manager it generates
  # stays separate, exactly as it was when these were five files.
  # ------------------------------------------------------------

  config = lib.mkMerge [
    (helpers.packageOptions.mkPackageModule {
      name = "shared-apps";
      packages = appPackages;
    })

    (helpers.packageOptions.mkPackageModule {
      name = "shared-development";
      packages = developmentPackages // darwinDevelopmentApplications // developmentApplications;
    })

    (helpers.packageOptions.mkPackageModule {
      name = "shared-cli";
      packages = cliPackages;
    })

    (helpers.packageOptions.mkPackageModule {
      name = "shared-media";
      packages = mediaPackages;
    })

    (helpers.packageOptions.mkPackageModule {
      name = "shared-productivity";
      packages = productivityPackages;
    })

    (helpers.packageOptions.mkPackageModule {
      name = "shared-tools";
      packages = toolPackages;
    })
  ];
}
