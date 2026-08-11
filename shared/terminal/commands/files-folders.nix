# shared/terminal/commands/files-folders.nix
#
# =====================================================================
# FISH FUNCTIONS: FILES AND FOLDERS
# =====================================================================

{ config, lib, pkgs, ... }:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  # Provides the zz zoxide folder picker.
  installOn = {
    darwin = true;
    linux = true;
  };

  enabledForCurrentSystem =
    (isDarwin && installOn.darwin) || (isLinux && installOn.linux);
in
{
  config = lib.mkIf enabledForCurrentSystem {
    programs.fish.functions.zz = ''
      # ---- zz -> Pick zoxide path with fzf and cd into it ---- #
      # Shows zoxide tracked paths in fzf.
      set selected_path (
        zoxide query -l |
        fzf --height=60% --reverse --prompt="zoxide cd> "
      )

      if test -z "$selected_path"
        return 0
      end

      builtin cd "$selected_path"
    '';
  };
}
