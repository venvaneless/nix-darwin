# shared/terminal/cli-tuis/fastfetch/fastfetch-linux.nix
#
# =====================================================================
# FASTFETCH: LINUX PALETTE PROFILE
#
# - Preserves fastfetch-linux.jsonc as the Linux machine profile
# - Enabled directly in fastfetch.nix with profiles.linuxPalette.enable
# - Uses an XDG-relative ASCII logo path
# =====================================================================

{ config, lib, pkgs, ... }:

let
  fastfetchCfg = config.ven.features.terminal.cliTuis.fastfetch;
  cfg = fastfetchCfg.profiles.linuxPalette;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  # Preserve the supplied Linux profile while making the logo path portable.
  fastfetchConfig =
    builtins.replaceStrings [ "/Users/ven/.config/fastfetch/ascii.txt" ] [ "${config.xdg.configHome}/fastfetch/ascii.txt" ]
      (builtins.readFile ./fastfetch-linux.jsonc);
in
{
  options.ven.features.terminal.cliTuis.fastfetch.profiles.linuxPalette.enable =
    lib.mkEnableOption "Fastfetch Linux palette profile";

  config = lib.mkIf (fastfetchCfg.enable && cfg.enable && isLinux) {
    # Fastfetch reads this immutable, Nix-managed configuration file.
    xdg.configFile."fastfetch/config.jsonc".text = fastfetchConfig;

    # Keep the matching ASCII logo at the portable XDG path.
    xdg.configFile."fastfetch/ascii.txt".source = ./ascii.txt;
  };
}
