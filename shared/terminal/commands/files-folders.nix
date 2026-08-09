# shared/terminal/commands/files-folders.nix
#
# =====================================================================
# FISH FUNCTIONS: FILES AND FOLDERS
# =====================================================================

{ config, lib, ... }:

let
  cfg = config.ven.features.terminal.fish.commands;
in
{
  config = lib.mkIf cfg.enable {
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
