# shared/terminal/cli-tuis/ripgrep.nix
#
# =====================================================================
# RIPGREP
#
# Fast recursive search
#
# Installation, the global colour configuration, and shell aliases are
# managed through Home Manager.
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.ripgrep;

  # ---- PLATFORM TOGGLES ---- #
  # Change these values to set Ripgrep's default per platform. Hosts can
  # still override ven.features.terminal.cliTuis.ripgrep.enable directly.
  ripgrep = {
    enable = true;
    installOn = {
      darwin = true;
      linux = true;
    };
  };

  # ---- Variables from platforms.nix
  # Platform detection is defined once in options/platforms.nix,
  # so every module tests the current system the same way.
  platforms = import ../../../options/platforms.nix { inherit pkgs; };
  inherit (platforms) isDarwin isLinux;
  enabledForCurrentSystem =
    ripgrep.enable && ((isDarwin && ripgrep.installOn.darwin) || (isLinux && ripgrep.installOn.linux));
in
{
  options.ven.features.terminal.cliTuis.ripgrep.enable =
    lib.mkEnableOption "Ripgrep recursive search";

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.ripgrep.enable = lib.mkDefault enabledForCurrentSystem;
    }
    (lib.mkIf cfg.enable {
      # ---- INSTALLATION ---- #
      # Install ripgrep through Home Manager whenever this feature is enabled.
      programs.ripgrep.enable = true;

      # ---- GLOBAL COLOURS ---- #
      # Home Manager owns the configuration file read by RIPGREP_CONFIG_PATH.
      xdg.configFile."ripgrep/config".text = ''
        --colors=path:fg:0xbd,0x93,0xf9
        --colors=line:fg:0x50,0xfa,0x7b
        --colors=column:fg:0x50,0xfa,0x7b
        --colors=match:fg:0xff,0x55,0x55
      '';

      # Tell ripgrep to use its Nix-owned configuration file.
      home.sessionVariables.RIPGREP_CONFIG_PATH =
        "${config.xdg.configHome}/ripgrep/config";

      programs.fish.shellAliases = {
        # ---- KEYBINDINGS ---- #

        # --- grep -> rg
        # Use ripgrep instead of grep
        grep = "rg --color=auto";

        # --- erg -> rg
        # Extended regex search.
        erg = "rg --color=auto";

        # --- frg -> rg -F
        # Fixed-string search.
        frg = "rg -F --color=auto";

        # --- fgrep -> rg -F
        # Fixed-string search compatibility alias.
        fgrep = "rg -F --color=auto";
      };
    })
  ];
}
