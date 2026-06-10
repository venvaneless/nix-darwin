# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/aliases/git-aliases.nix

{ ... }:

{
  programs.fish.shellAliases = {
    # ---------- Git Aliases ---------- #

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
    # ---- gm -> Stage all repo changes with drs ---- #
    # Create a git commit using the provided message
    # Run darwin-rebuild switch afterwards
    #
    # Example:
    # gm "Adding fzf trash and iCloud functions"
    # ---------------------------------------------------------
    gm = ''
      set message (string join " " $argv)

      if test -z "$message"
        echo "Usage: gm <commit-message>"
        return 1
      end

      git add -A

      if git diff --cached --quiet
        echo "Nothing to commit."
        return 0
      end

      git commit -m "$message"
      and drs
    '';
    # ---------------------------------------------------------
    

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
    
      set current_branch (git branch --show-current)
    
      set selected_branch (
        git branch --format="%(refname:short)" \
        | fzf \
          --prompt="Switch branch [$current_branch]: " \
          --header="Current branch: $current_branch"
      )
    
      if test -z "$selected_branch"
        echo "No branch selected."
        return 0
      end
    
      git switch "$selected_branch"
    '';
    # ---------------------------------------------------------


    fbranch = ''
      if not command -q fzf
        echo "fzf is required for fbranch."
        return 1
      end
    
      if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "Not inside a Git repository."
        return 1
      end
    
      set current_branch (git branch --show-current)
      set create_option "+ Create new branch"
    
      set selected_branch (
        begin
          git branch --format="%(refname:short)"
          echo "$create_option"
        end | fzf \
          --no-sort \
          --prompt="Switch branch [$current_branch]: " \
          --header="Current branch: $current_branch"
      )
    
      if test -z "$selected_branch"
        echo "No branch selected."
        return 0
      end
    
      if test "$selected_branch" = "$create_option"
        read -l -P "New branch name: " new_branch
    
        if test -z "$new_branch"
          echo "No branch name given."
          return 1
        end
    
        if git show-ref --verify --quiet "refs/heads/$new_branch"
          echo "Branch already exists: $new_branch"
          return 1
        end
    
        set branch_mode (
          printf "Whole repo\nOnly one folder\n" \
          | fzf \
            --no-sort \
            --prompt="Branch content: " \
            --header="Create branch '$new_branch' from current branch: $current_branch"
        )
    
        if test -z "$branch_mode"
          echo "No branch mode selected."
          return 0
        end
    
        if test "$branch_mode" = "Whole repo"
          git branch "$new_branch"
          echo "Created branch: $new_branch"
          echo "Still on branch: $current_branch"
          return 0
        end
    
        set selected_folder (
          find . -type d \
            -not -path "./.git" \
            -not -path "./.git/*" \
            | sed 's#^\./##' \
            | fzf \
              --prompt="Folder for branch: " \
              --header="Pick one folder to keep in '$new_branch'"
        )
    
        if test -z "$selected_folder"
          echo "No folder selected."
          return 0
        end
    
        set temp_worktree (mktemp -d)
    
        git worktree add -b "$new_branch" "$temp_worktree" HEAD
    
        pushd "$temp_worktree" >/dev/null
    
        git rm -r --quiet -- .
        git checkout HEAD -- "$selected_folder"
        git add -A
        git commit -m "Create branch with only $selected_folder"
    
        popd >/dev/null
    
        git worktree remove "$temp_worktree"
    
        echo "Created branch: $new_branch"
        echo "Kept folder: $selected_folder"
        echo "Still on branch: $current_branch"
    
        return 0
      end
    
      git switch "$selected_branch"
    '';
  };
}