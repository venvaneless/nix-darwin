# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/eza.nix
#
# ZSH: EZA
# =========================
# A modern replacement for ls

{ config, ... }:

{
  programs.eza = {
    enable = true;
    enableZshIntegration = true;

    colors = "auto";
    icons = "auto";
    git = true;

    extraOptions = [
      "--group-directories-first"
      "--header"
      "--all"
    ];
  };

  xdg.configFile."eza/theme.yml".source =
    config.lib.file.mkOutOfStoreSymlink "/Users/ven/.config/eza/rose-pine-dawn.yml";
}