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

    # Extra history behavior not covered by the history block
    setOptions = [
      "INC_APPEND_HISTORY"
      "HIST_EXPIRE_DUPS_FIRST"
      "HIST_REDUCE_BLANKS"
    ];

    # Shell-level setup
    interactiveShellInit = ''
      # Ensure history directory exists
      mkdir -p "$(dirname "${config.home.homeDirectory}/ven-dots/zsh/.zsh_history")"

      # Import history from file on shell startup
      fc -R
    '';

    # Substring search plugin
    historySubstringSearch.enable = true;
  };
}