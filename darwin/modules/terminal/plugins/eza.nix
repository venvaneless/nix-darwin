# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/eza.nix
#
# ZSH: EZA
# =========================
# A modern replacement for ls

{ pkgs, ... }:

let
  ezaThemeDir = pkgs.runCommand "eza-theme-dir" {} ''
    mkdir -p "$out"
    cp /Users/ven/.config/eza/rose-pine-moon.yml "$out/theme.yml"
  '';
in
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

  home.sessionVariables = {
    EZA_CONFIG_DIR = "${ezaThemeDir}";
  };
}