# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/aliases/git-aliases.nix

{ ... }:

{
  programs.fish.shellAliases = {
    # ---------- Git Aliases ---------- #

    # ---------------------------------------------------------
    # ---- gm -> Stage all repo changes with drs ---- #
    # Create a git commit using the provided message
    # Run darwin-rebuild switch afterwards
    # ---------------------------------------------------------
    gm = ''
      git add -A
      and git commit -m "$argv"
      and drs
    '';
    # ---------------------------------------------------------


    # ---------------------------------------------------------
    # ---- gsd -> Git commit with timestamp + drs ---- #
    # Stage all repository changes
    # Create commit with appended timestamp:
    # yyyy-mm-dd hh:mm
    # Run darwin-rebuild switch afterwards
    #
    # Example:
    # gsd "Fixing nginx"
    # -> "Fixing nginx 2026-05-23 19:42"
    # ---------------------------------------------------------
    gsd = ''
      set timestamp (date "+%Y-%m-%d %H:%M")
      set message (string join " " $argv)

      gaa "$message $timestamp"
      and drs
    '';
    # ---------------------------------------------------------

    
    # ---------------------------------------------------------
    # ---- Stage selected files manually ---- #
    # --- gd -> git add
    gd = "git add";
    # ---------------------------------------------------------

    # ---------------------------------------------------------
    # ---- Stage all new, modified, and deleted files ---- #
    gda = "git add -A";
    # ---------------------------------------------------------

    # ---------------------------------------------------------
    # ---- List or manage branches ---- #
    gb = "git branch";
    # ---------------------------------------------------------

    # ---------------------------------------------------------
    # --- gc -> git commit
    ## Start a git commit
    gc = "git commit";
    # ---------------------------------------------------------

    # ---------------------------------------------------------
    # ---- # Commit tracked file changes without staging each file ---- #
    gca = "git commit -a";
    # ---------------------------------------------------------

    # ---------------------------------------------------------
    # --- # Start a commit with inline message ---- #
    gcm = "git commit -m";
    # ---------------------------------------------------------

    # ---------------------------------------------------------
    # ---  Switch branch or restore files with checkout ---- #
    gco = "git checkout";
    # ---------------------------------------------------------

    # ---------------------------------------------------------
    # --- # Show git diff ---- #
    gff = "git diff";
    # ---------------------------------------------------------

    # ---------------------------------------------------------
    # --- guu -> git pull
    #
    gpu = "git pull";
    # ---------------------------------------------------------

    # ---------------------------------------------------------
    # --- ghh -> git push
    ## Push commits to remote
    gph = "git push";
    # ---------------------------------------------------------

    # ---------------------------------------------------------
    # --- gss -> git status
    ## Show git status
    gss = "git status";
    # ---------------------------------------------------------

    # ---------------------------------------------------------
    # --- l-g -> Open lazygit ---- 
    #
    "l-g" = "lazygit";
    # ---------------------------------------------------------
  };


  
  programs.fish.functions = {
    # ---------- Git Functions ---------- #

    # ---------------------------------------------------------
    # ---- gaa -> Stage all repo changes ---- #
    #
    # Create a git commit using the provided message
    # ---------------------------------------------------------
    gaa = ''
      git add -A
      and git commit -m "$argv"
    '';
    # ---------------------------------------------------------

    
    # ---------------------------------------------------------
    # sbranch
    # ---------------------------------------------------------
    # Show local Git branches in fzf
    # Switch to the selected branch
    #
    # Example:
    # sbranch
    # ---------------------------------------------------------
    sbranch = ''
      if not command -q fzf
        echo "fzf is required for sbranch."
        return 1
      end

      if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "Not inside a Git repository."
        return 1
      end

      set selected_branch (
        git branch --format="%(refname:short)" \
        | fzf --prompt="Switch branch: "
      )

      if test -z "$selected_branch"
        echo "No branch selected."
        return 0
      end

      git switch "$selected_branch"
    '';
    # ---------------------------------------------------------
  };
}