# /Users/ven/.config/nix/nix-config/flake.nix
#
# ==========================================================
# FLAKE: MAIN ENTRYPOINT
# - Provides nix-darwin configuration "macbook"
# - Integrates Home Manager via darwin/default.nix
# ==========================================================

{
  description = "Ven’s setup";

  # Allow committing even with build artefacts like ./result
  nixConfig.allow-dirty = true;

  inputs = {

    # Core package set
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    # nix-darwin
    darwin.url = "github:LnL7/nix-darwin/nix-darwin-26.05";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Unstable branch
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # SOPS secret management for Darwin, standalone Home Manager, and NixOS
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # nix-homebrew
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Flake module framework
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Shared composition dependencies. Flake syntax requires source inputs
    # here; flake-modules/hosts.nix exposes them to every host module.
    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    den.url = "github:denful/den";

    # AstroNvim (managed as config)
    astronvim = {
      url = "github:AstroNvim/template";
      flake = false;
    };

    # Codex extension sources are pinned in flake.lock and assembled locally.
    caveman = {
      url = "github:JuliusBrussee/caveman";
      flake = false;
    };

    claude-mem = {
      url = "github:thedotmack/claude-mem";
      flake = false;
    };

    simple-english = {
      url = "github:AminBlg/SimpleEnglish";
      flake = false;
    };

    codebase-memory-mcp = {
      url = "github:DeusData/codebase-memory-mcp";
      flake = false;
    };

    scholarbrain = {
      url = "github:SHzzzAyys/scholarbrain/feat/deepseek-pubmed-arxiv";
      flake = false;
    };

    # WezTerm plugins are pinned in flake.lock and deployed by
    # shared/terminal/wezterm/wez-plugins.nix, so `nix flake update`
    # updates them together with every other input.
    wezterm-resurrect = {
      url = "github:MLFlexer/resurrect.wezterm";
      flake = false;
    };

    wezterm-tabline = {
      url = "github:michaelbrusegard/tabline.wez";
      flake = false;
    };

    wezterm-sessions = {
      url = "github:abidibo/wezterm-sessions";
      flake = false;
    };

    wezterm-smart-workspace-switcher = {
      url = "github:MLFlexer/smart_workspace_switcher.wezterm";
      flake = false;
    };
  };

  outputs =
    inputs@{
      flake-parts,
      ...

    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Governs the per-system package outputs. Darwin builds the local
      # macOS application packages, and x86_64-linux is required before
      # the Linux and NixOS host outputs in flake-modules/ can be
      # evaluated or built from any machine.
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      imports = [
        # ---- SHARED BUILDING BLOCKS ---- #
        ./flake-modules/packages.nix
        ./flake-modules/hosts.nix

        # ---- ONE FILE PER MACHINE ---- #
        # macbook   : Apple Silicon MacBook, nix-darwin
        # linux     : ROG Zephyrus
        # imac-nix  : 2015 Intel iMac, NixOS
        ./flake-modules/macbook.nix
        ./flake-modules/linux.nix
        ./flake-modules/imac-nix.nix
      ];
    };

}
