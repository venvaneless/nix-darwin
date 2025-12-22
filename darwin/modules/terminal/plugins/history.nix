# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/history.nix
#
# ZSH: HISTORY
# ============================================================

{ config, ... }:

{
  programs.zsh = {
    history = {
      # Explicitly tell Zsh where the history file lives
      path = "${config.home.homeDirectory}/ven-dots/zsh/.zsh_history";

      # Sensible defaults
      size = 100000;
      save = 100000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
    };

    # Substring search plugin
    historySubstringSearch.enable = true;
  };
}
