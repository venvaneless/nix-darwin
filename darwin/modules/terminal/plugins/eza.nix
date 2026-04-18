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
    git = true;

    colors = "always";
    icons = "auto";

    extraOptions = [
      "--group-directories-first"
      "--header"
      "--all"
    ];
  };

  xdg.configFile."eza/theme.yml".source =
    config.lib.file.mkOutOfStoreSymlink "/Users/ven/.config/eza/rose-pine-moon.yml";

  environment.variables.EZA_CONFIG_DIR = "/Users/ven/.config/eza";
}