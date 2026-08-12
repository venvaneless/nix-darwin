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

  # Packages use these defaults unless an entry overrides a toggle.
  sharedPackage = package: {
    enable = true;
    installOn = { darwin = true; linux = true; };
    inherit package;
  };

  darwinPackage = package: {
    enable = true;
    installOn = { darwin = true; linux = false; };
    inherit package;
  };

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
    alejandra = sharedPackage pkgs.alejandra;
    homeManager = sharedPackage pkgs.home-manager;
    deadnix = sharedPackage pkgs.deadnix;
    nh = sharedPackage pkgs.nh;
    nil = sharedPackage pkgs.nil;
    npins = sharedPackage pkgs.npins;
    nixDirenv = sharedPackage pkgs.nix-direnv;
    nixd = sharedPackage pkgs.nixd;
    nixfmt = sharedPackage pkgs.nixfmt;
    statix = sharedPackage pkgs.statix;
    nixOutputMonitor = sharedPackage pkgs.nix-output-monitor;
    nixTree = sharedPackage pkgs.nix-tree;
    nixSearch = sharedPackage pkgs.nix-search;
    nixIndex = sharedPackage pkgs.nix-index;
    comma = sharedPackage pkgs.comma;
    nixUpdate = sharedPackage pkgs.nix-update;

    # ---- Language servers and toolchains
    typescript = sharedPackage pkgs.typescript;
    typescriptLanguageServer = sharedPackage pkgs.typescript-language-server;
    vueLanguageServer = sharedPackage pkgs.vue-language-server;
    go = sharedPackage pkgs.go;
    gopls = sharedPackage pkgs.gopls;
    rustc = sharedPackage pkgs.rustc;
    cargo = sharedPackage pkgs.cargo;
    rustAnalyzer = sharedPackage pkgs.rust-analyzer;
    pyright = sharedPackage pkgs.pyright;
    ruff = sharedPackage pkgs.ruff;
    vscodeLanguageServers = sharedPackage pkgs.vscode-langservers-extracted;
    yamlLanguageServer = sharedPackage pkgs.yaml-language-server;
    taplo = sharedPackage pkgs.taplo;
    luaLanguageServer = sharedPackage pkgs.lua-language-server;

    # ---- Development and document tools
    bitwardenCli = sharedPackage pkgs.bitwarden-cli;
    delta = sharedPackage pkgs.delta;
    docker = sharedPackage pkgs.docker_29;
    dockerCompose = sharedPackage pkgs.docker-compose;
    direnv = sharedPackage pkgs.direnv;
    texLive = sharedPackage myTex;
    nssTools = sharedPackage pkgs.nssTools;
    pandoc = sharedPackage pkgs.pandoc;

    # ---- Git tools
    gh = sharedPackage pkgs.gh;
    gitCrypt = sharedPackage pkgs.git-crypt;
    gitFilterRepo = sharedPackage pkgs.git-filter-repo;
    gitLfs = sharedPackage pkgs.git-lfs;
    lazygit = sharedPackage pkgs.lazygit;

    # ---- Linters and formatters
    prettier = sharedPackage pkgs.prettier;
    eslintD = sharedPackage pkgs.eslint_d;
    golangciLint = sharedPackage pkgs.golangci-lint;
    selene = sharedPackage pkgs.selene;
    yamllint = sharedPackage pkgs.yamllint;
    gofumpt = sharedPackage pkgs.gofumpt;
    rustfmt = sharedPackage pkgs.rustfmt;
    stylelint = sharedPackage pkgs.stylelint;
    stylua = sharedPackage pkgs.stylua;

    # ---- JavaScript and Python
    bun = sharedPackage pkgs.bun;
    nodejs = sharedPackage pkgs.nodejs;
    python3 = sharedPackage pkgs.python3;
    pandas = sharedPackage pkgs.python3Packages.pandas;
    reportlab = sharedPackage pkgs.python3Packages.reportlab;
    uv = sharedPackage pkgs.uv;
  };

  # ------------------------------------------------------------
  # ------ DARWIN-ONLY DEVELOPMENT APPLICATIONS ------ #
  # Self-packaged applications stay beside the rest of development.
  # ------------------------------------------------------------

  darwinDevelopmentApplications = {
    iterm2 = (darwinPackage (pkgs.callPackage ../../darwin/packages/iterm2 { })) // {
      appName = "iTerm.app";
      symlinkProgramming = true;
    };

    itermAiPlugin = (darwinPackage (pkgs.callPackage ../../darwin/packages/iterm2/iterm-ai-plugin.nix { })) // {
      appName = "iTermAI.app";
      symlinkProgramming = true;
    };

    itermBrowserPlugin = (darwinPackage (pkgs.callPackage ../../darwin/packages/iterm2/iterm-browser-plugin.nix { })) // {
      appName = "iTermBrowserPlugin.app";
      symlinkProgramming = true;
    };
  };

  # ------------------------------------------------------------
  # ------ SHARED DEVELOPMENT APPLICATIONS ------ #
  # ------------------------------------------------------------

  developmentApplications = {
    # ---- WezTerm
    wezterm = (sharedPackage pkgs.wezterm) // {
      appName = "WezTerm.app";
      symlinkProgramming = true;
    };

    # ---- Visual Studio Code
    vscode = {
      enable = true;
      package = pkgs.vscode;
      installOn = { darwin = true; linux = true; };
      appName = "Visual Studio Code.app";
      symlinkProgramming = true;
    };

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
helpers.packageOptions.mkPackageModule {
  name = "shared-development";
  packages = developmentPackages // darwinDevelopmentApplications // developmentApplications;
}
