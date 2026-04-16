# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/plugins/history.nix
#
# ============================================================
# ZSH: HISTORY
# - Persists command history across terminal restarts
# - Shares history across shell sessions
# - Keeps a large searchable history file
# ============================================================

{ config, ... }:

{
  programs.zsh = {
    history = {
      # ---------- History file ---------- #

      # --- HISTFILE
      # #### Path to the zsh history file on disk.
      path = "${config.home.homeDirectory}/.config/zsh/.zsh_history";

      # ---------- History size ---------- #

      # --- HISTSIZE
      # #### Number of commands kept in memory.
      size = 100000;

      # --- SAVEHIST
      # #### Number of commands saved to disk.
      save = 100000;

      # ---------- History behavior ---------- #

      # --- APPEND_HISTORY
      # #### Append commands to the history file instead of overwriting it.
      append = true;

      # --- SHARE_HISTORY
      # #### Share history across multiple running shells.
      share = true;

      # --- EXTENDED_HISTORY
      # #### Record timestamps in history.
      extended = true;

      # --- HIST_IGNORE_DUPS
      # #### Ignore duplicate consecutive entries.
      ignoreDups = true;

      # --- HIST_IGNORE_SPACE
      # #### Do not store commands that start with a space.
      ignoreSpace = true;
    };

    setOptions = [
      # --- BANG_HIST
      # #### Enable ! history expansion in zsh.
      "BANG_HIST"

      # --- INC_APPEND_HISTORY
      # #### Write commands to the history file immediately.
      "INC_APPEND_HISTORY"

      # --- HIST_EXPIRE_DUPS_FIRST
      # #### Expire duplicate entries first when trimming history.
      "HIST_EXPIRE_DUPS_FIRST"

      # --- HIST_REDUCE_BLANKS
      # #### Reduce extra blank entries.
      "HIST_REDUCE_BLANKS"

      # --- HIST_IGNORE_ALL_DUPS
      # #### Remove older duplicate entries when a new duplicate is added.
      "HIST_IGNORE_ALL_DUPS"

      # --- HIST_FIND_NO_DUPS
      # #### Skip duplicate entries during history searches.
      "HIST_FIND_NO_DUPS"

      # --- HIST_SAVE_NO_DUPS
      # #### Avoid writing duplicate entries to the history file.
      "HIST_SAVE_NO_DUPS"
    ];

    initContent = ''
      # Ensure history directory exists
      mkdir -p "$(dirname "${config.home.homeDirectory}/.config/zsh/.zsh_history")"
      
      # ---------- History loading ---------- #

      # --- fc -R
      # #### Import history from the history file on shell startup.
      fc -R

      # ---------- History command ---------- #

      # --- history()
      # #### Show command history with line numbers and timestamps.
      history() {
          builtin fc -il 1
      }
    '';
  };
}