# shared/packages/development-pkgs.nix
#
# =====================================================================
# PACKAGES: SHARED DEVELOPMENT TOOLS
#
# Installs development and document-building tools shared between
# Darwin and Linux. Darwin-only application bundles stay guarded by
# the Darwin platform check and keep their categorized application links.
# =====================================================================

{ lib, pkgs, ... }:

let
  # ------------------------------------------------------------
  # ------ PLATFORM DETECTION ------ #
  #
  # Determines which operating system is currently evaluating
  # this shared package module.
  # ------------------------------------------------------------

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  # ------------------------------------------------------------
  # ------ CUSTOM TEX LIVE ENVIRONMENT ------ #
  #
  # Combines a medium TeX Live scheme with the extra LaTeX package
  # needed by Pandoc and PDF workflows on both supported platforms.
  # ------------------------------------------------------------

  myTex = pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-medium titlesec;
  };

  # ------------------------------------------------------------
  # ------ DEVELOPMENT PACKAGE DEFINITIONS ------ #
  #
  # enable:
  #   Controls whether the package exists at all.
  #
  # installOn.darwin:
  #   Controls whether the package is installed on macOS.
  #
  # installOn.linux:
  #   Controls whether the package is installed on Linux.
  # ------------------------------------------------------------

  developmentPackages = {
    # ------------------------------------------------
    ## Nix tools

    # Nixpkgs Rust linter
    alejandra = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.alejandra;
    };

    # Nix Home Manager
    homeManager = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.home-manager;
    };

    # Check unused Nix code
    deadnix = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.deadnix;
    };

    # Better rebuild output
    nh = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nh;
    };

    # Nix language server
    nil = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nil;
    };

    # Reproducible installation of packages from GitHub
    npins = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.npins;
    };

    # Nix shell environment manager
    nixDirenv = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nix-direnv;
    };

    # Nix language server
    nixd = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nixd;
    };

    # Nix formatter
    nixfmt = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nixfmt;
    };

    # Check Nix style problems
    statix = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.statix;
    };

    # Nix output monitor
    nixOutputMonitor = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nix-output-monitor;
    };

    # Nix dependency tree viewer
    nixTree = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nix-tree;
    };

    # Searches Nix packages by name and metadata.
    nixSearch = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nix-search;
    };

    # Provides nix-locate for searching files inside Nix packages.
    nixIndex = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nix-index;
    };

    # Runs a command from Nixpkgs without first installing its package.
    comma = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.comma;
    };

    # Update locally packaged flake outputs
    nixUpdate = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nix-update;
    };

    # ------------------------------------------------
    ## Language servers and toolchains

    # JavaScript and TypeScript compiler
    typescript = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.typescript;
    };

    # JavaScript and TypeScript language server
    typescriptLanguageServer = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.typescript-language-server;
    };

    # Vue language server
    vueLanguageServer = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.vue-language-server;
    };

    # Go toolchain
    go = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.go;
    };

    # Go language server
    gopls = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.gopls;
    };

    # Rust compiler
    rustc = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.rustc;
    };

    # Rust package manager and build tool
    cargo = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.cargo;
    };

    # Rust language server
    rustAnalyzer = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.rust-analyzer;
    };

    # Python language server
    pyright = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.pyright;
    };

    # Python linter, code actions, and formatter
    ruff = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.ruff;
    };

    # JSON language server
    vscodeLanguageServers = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.vscode-langservers-extracted;
    };

    # YAML language server
    yamlLanguageServer = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.yaml-language-server;
    };

    # TOML language server and formatter
    taplo = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.taplo;
    };

    # Lua language server
    luaLanguageServer = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.lua-language-server;
    };

    # ------------------------------------------------
    ## Development and document tools

    # Password manager CLI
    bitwardenCli = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.bitwarden-cli;
    };

    # Git diff viewer
    delta = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.delta;
    };

    # Container engine
    docker = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.docker_29;
    };

    # Docker Compose
    dockerCompose = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.docker-compose;
    };

    # Shell environment loader
    direnv = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.direnv;
    };

    # Custom LaTeX environment
    texLive = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = myTex;
    };

    # Security certificate tools
    nssTools = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nssTools;
    };

    # Document converter
    pandoc = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.pandoc;
    };

    # ------------------------------------------------
    ## Git tools

    # GitHub CLI for repositories, releases, pull requests, issues, and Actions
    gh = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.gh;
    };

    # Git encrypted files
    gitCrypt = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.git-crypt;
    };

    # Git history rewriting tools
    gitFilterRepo = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.git-filter-repo;
    };

    # Git large file storage
    gitLfs = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.git-lfs;
    };

    # Terminal Git UI
    lazygit = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.lazygit;
    };

    # ------------------------------------------------
    ## Code linters and formatters

    # Code formatter
    prettier = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.prettier;
    };

    # JavaScript, TypeScript, and Vue linter daemon
    eslintD = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.eslint_d;
    };

    # Go linter runner
    golangciLint = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.golangci-lint;
    };

    # Lua linter
    selene = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.selene;
    };

    # YAML linter
    yamllint = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.yamllint;
    };

    # Go formatter with stricter formatting rules
    gofumpt = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.gofumpt;
    };

    # Rust formatter
    rustfmt = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.rustfmt;
    };

    # CSS/SCSS linter
    stylelint = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.stylelint;
    };

    # Lua formatter
    stylua = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.stylua;
    };

    # ------------------------------------------------
    ## JavaScript tools

    # JavaScript runtime, bundler, transpiler and package manager
    bun = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.bun;
    };

    # Event-driven I/O framework for JavaScript engine
    nodejs = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.nodejs;
    };

    # ------------------------------------------------
    ## Python tools

    # Python interpreter
    python3 = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.python3;
    };

    # Python data analysis library
    pandas = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.python3Packages.pandas;
    };

    # Python PDF generation library
    reportlab = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.python3Packages.reportlab;
    };

    # Python package installer and resolver
    uv = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.uv;
    };
  };

  # ------------------------------------------------------------
  # ------ PACKAGE FILTERING ------ #
  #
  # Selects only packages that are enabled for the system currently
  # evaluating this module.
  # ------------------------------------------------------------

  enabledForCurrentSystem =
    developmentPackage:
      developmentPackage.enable
      && (
        (isDarwin && developmentPackage.installOn.darwin)
        || (isLinux && developmentPackage.installOn.linux)
      );

  enabledDevelopmentPackages = map
    (developmentPackage: developmentPackage.package)
    (lib.filter enabledForCurrentSystem (lib.attrValues developmentPackages));

  # ------------------------------------------------------------
  # ------ DARWIN DEVELOPMENT APPLICATIONS ------ #
  #
  # These application bundles are only available on macOS. They use
  # the same enable and installOn toggles as the shared CLI packages.
  # ------------------------------------------------------------

  darwinDevelopmentApplications = lib.optionalAttrs isDarwin {
    # ---- iTerm2
    iterm2 = {
      displayName = "iTerm2";
      enable = true;

      installOn = {
        darwin = true;
        linux = false;
      };

      package = pkgs.callPackage ../../darwin/packages/iterm2 { };
      link = true;
      appName = "iTerm.app";
    };

    # ---- iTerm AI Plugin
    itermAiPlugin = {
      displayName = "iTerm AI Plugin";
      enable = true;

      installOn = {
        darwin = true;
        linux = false;
      };

      package = pkgs.callPackage ../../darwin/packages/iterm2/iterm-ai-plugin.nix { };
      link = true;
      appName = "iTermAI.app";
    };

    # ---- iTerm Browser Plugin
    itermBrowserPlugin = {
      displayName = "iTerm Browser Plugin";
      enable = true;

      installOn = {
        darwin = true;
        linux = false;
      };

      package = pkgs.callPackage ../../darwin/packages/iterm2/iterm-browser-plugin.nix { };
      link = true;
      appName = "iTermBrowserPlugin.app";
    };
  };

  enabledDarwinDevelopmentApplications =
    lib.mapAttrs
      (_: application: application // {
        enable = enabledForCurrentSystem application;
      })
      darwinDevelopmentApplications;

  enabledDarwinDevelopmentApplicationPackages = map
    (application: application.package)
    (lib.filter enabledForCurrentSystem (lib.attrValues darwinDevelopmentApplications));

  # ------------------------------------------------------------
  # ------ DARWIN APPLICATION LINKS ------ #
  #
  # Uses the existing guarded link helper. Disabled applications only
  # remove links that point to their expected Nix-managed source.
  # ------------------------------------------------------------

  applicationLinkHelper = import ../../darwin/packages/helper.nix {
    inherit lib pkgs;
  };

  developmentApplicationLinks = applicationLinkHelper {
    applications = enabledDarwinDevelopmentApplications;
    targetDirectory = "/Applications/Programming";
    managerName = "manage-darwin-development-application-links";
  };
in
{
  config = lib.mkMerge [
    {
      # ------------------------------------------------------------
      # ------ SHARED DEVELOPMENT PACKAGES ------ #
      #
      # Installs every enabled package for the current Darwin or Linux
      # system.
      # ------------------------------------------------------------

      environment.systemPackages = enabledDevelopmentPackages;
    }

    (lib.mkIf isDarwin {
      # ------------------------------------------------------------
      # ------ DARWIN DEVELOPMENT APPLICATIONS ------ #
      #
      # Installs enabled Darwin-only application bundles and manages
      # their categorized links after application linking completes.
      # ------------------------------------------------------------

      environment.systemPackages = enabledDarwinDevelopmentApplicationPackages;

      system.activationScripts.postActivation.text = lib.mkAfter ''
        ${developmentApplicationLinks.linkManager}/bin/manage-darwin-development-application-links
      '';
    })
  ];
}
