# shared/terminal/cli-tuis/fastfetch/fastfetch-mac.nix
#
# =====================================================================
# FASTFETCH: MACOS GRUVBOX PROFILE
#
# - macOS Fastfetch layout with the Gruvbox palette
# - Enabled directly in fastfetch.nix with profiles.gruvbox.enable
# - Uses an XDG-relative ASCII logo path
# =====================================================================

{ config, lib, pkgs, ... }:

let
  fastfetchCfg = config.ven.features.terminal.cliTuis.fastfetch;
  cfg = fastfetchCfg.profiles.gruvbox;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # Resolve the logo location at evaluation time for the current host.
  fastfetchConfig =
    builtins.replaceStrings [ "__FASTFETCH_ASCII__" ] [ "${config.xdg.configHome}/fastfetch/ascii.txt" ]
      (builtins.readFile ./fastfetch-mac.jsonc);
in
{
  options.ven.features.terminal.cliTuis.fastfetch.profiles.gruvbox.enable =
    lib.mkEnableOption "Fastfetch macOS Gruvbox profile";

  config = lib.mkIf (fastfetchCfg.enable && cfg.enable && isDarwin) {
    # Fastfetch reads this immutable, Nix-managed configuration file.
    xdg.configFile."fastfetch/config.jsonc".text = fastfetchConfig;

    # Keep the matching ASCII logo at the portable XDG path.
    xdg.configFile."fastfetch/ascii.txt".source = ./ascii.txt;
  };
}
