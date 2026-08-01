# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/plugins/fzf.nix
#
# =====================================================================
# FZF
# Command-line fuzzy finder written in Go
# -----------------------------------------
# 
# ---- Plugins
# - zsh-fzf-tab: fzf UI on <TAB>
# - zsh-fzf-history-search
# - zsh-forgit: fzf-powered git helper functions
#
# ---- Theme
#  Rosé Pine Moon theme sourced from upstream repo
#
# ---- Keybindings
# -- Command picker
# Ctrl-F
# -- fzf history search
# Ctrl-O 
# =====================================================================

{ ... }:

{
  programs.fzf = {
 	# Install and enable fzf and integrate it with fish shell
    enable = true;
    enableFishIntegration = true;

    # ---- OPTIONS ---- #
    defaultOptions = [

      # Set fzf height % the terminal window
      "--height=40%"

      # Set fzf layout to reverse (bottom-up)
      "--layout=reverse"

      # Set rounded borders
      "--border=rounded"

      # Set inline info
      "--info=inline"

      # Set the prompt symbol
      "--prompt=❯ "

      # Set the pointer symbol
      "--pointer=▸"

      # Set the marker symbol
      "--marker=✓"

      # Set the scrollbar symbol
      "--scrollbar=▌"

      # Set the preview window position, width and border visibility
      "--preview-window=right,60%,border-left"

      # Set the color scheme
      # ** NOTE:
      # ** 'bg' is the background color of the unselected items in the list
      # ** 'bg+' is the background color of the selected item in the list
      # ** 'fg' is the foreground color of the unselected items in the list
      # ** 'fg+' is the foreground color of the selected item in the list
      # ** 'header' is the color of the header text in the list
      # ** 'hl' is the color of the highlighted text in the list
      # ** 'info' is the color of the info text in the list
      # ** 'marker' is the color of the checkmark that appears next to selected items in multi-select mode
      # ** 'pointer' in fzf is the element that points to the currently selected item in the list
      # ** 'prompt' is the color of the prompt text in the list
      # ** 'spinner' is the color of loading element
      "--color=bg+:#2a273f,bg:#232136,spinner:#f6c177,hl:#ea9a97"
      "--color=fg:#e0def4,header:#ea9a97,info:#9ccfd8,pointer:#c4a7e7"
      "--color=marker:#eb6f92,fg+:#e0def4,prompt:#c4a7e7,hl+:#ea9a97"
    ];
  };

  programs.fish.interactiveShellInit = ''
    # ---- KEYBINDINGS ----
    # Tab    = normal Fish completion
    # Ctrl-F = fuzzy command picker
    # Ctrl-L = fuzzy history picker

    # Store the selected history entry in the variable 'selected'
    # ** The variable 'selected' is then used to replace the current command line with the selected history entry
    function __ven_fzf_history
      set -l selected (history | fzf)

      # If a history entry was selected, replace the current command line with it
      if test -n "$selected"
        commandline -r -- $selected
      end

      # Redraw the command line with the new content to reflect the change
      commandline -f repaint
    end

    # Store the selected command in the variable 'selected'
	# ** The variable 'selected' is then used to replace the current command line with the selected command
    function __ven_fzf_command_picker
      set -l selected (complete -C "" | awk '{print $1}' | sort -u | fzf)

      # Replace the current command line with the selected command if one was selected
      if test -n "$selected"
        commandline -r -- $selected
      end

      # Execute the commandline function with the following arguments and redraw the command line to reflect the change
      commandline -f repaint
    end

    # Bind the Ctrl-F key combination to the __ven_fzf_command_picker function
    bind \cf __ven_fzf_command_picker

    # Bind the Ctrl-O key combination to the __ven_fzf_history function
    bind \cl __ven_fzf_history
  '';
}