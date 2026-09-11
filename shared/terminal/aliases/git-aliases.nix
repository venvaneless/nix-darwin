# shared/terminal/aliases/git-aliases.nix
#
# =====================================================================
# GIT: ALIASES
# =====================================================================

{ ... }:

{
  ven.features.terminal.aliases = {
    shell = {
      # ---------- Git Aliases ---------- #

      # ---------------------------------------------------------
      # ---- Stage selected files manually ---- #
      # --- gd -> git add
      gd = {
        command = "git add";
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------------------------------------------------------

      # ---------------------------------------------------------
      # ---- Stage all new, modified, and deleted files ---- #
      gda = {
        command = "git add -A";
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------------------------------------------------------

      # ---------------------------------------------------------
      # ---- List or manage branches ---- #
      gb = {
        command = "git branch";
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------------------------------------------------------

      # ---------------------------------------------------------
      # --- gc -> git commit
      ## Start a git commit
      gc = {
        command = "git commit";
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------------------------------------------------------

      # ---------------------------------------------------------
      # ---- # Commit tracked file changes without staging each file ---- #
      gca = {
        command = "git commit -a";
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------------------------------------------------------

      # ---------------------------------------------------------
      # --- # Start a commit with inline message ---- #
      gcm = {
        command = "git commit -m";
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------------------------------------------------------

      # ---------------------------------------------------------
      # ---  Switch branch or restore files with checkout ---- #
      gco = {
        command = "git checkout";
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------------------------------------------------------

      # ---------------------------------------------------------
      # --- # Show git diff ---- #
      gff = {
        command = "git diff";
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------------------------------------------------------

      # ---------------------------------------------------------
      # --- guu -> git pull
      #
      gpu = {
        command = "git pull";
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------------------------------------------------------

      # ---------------------------------------------------------
      # --- ghh -> git push
      ## Push commits to remote
      gph = {
        command = "git push";
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------------------------------------------------------

      # ---------------------------------------------------------
      # --- gss -> git status
      ## Show git status
      gss = {
        command = "git status";
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------------------------------------------------------

      # ---------------------------------------------------------
      # --- l-g -> Open lazygit ----
      #
      "l-g" = {
        command = "lazygit";
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };

      # ---------------------------------------------------------
    };

    functions = {
      # ---------- Git Functions ---------- #

      # ---------------------------------------------------------
      # ---- gm -> Stage all repo changes with drs ---- #
      # Create a git commit using the provided message
      # Run darwin-rebuild switch afterwards
      #
      # Example:
      # gm "Adding fzf trash and iCloud functions"
      # ---------------------------------------------------------
      gm = {
        help = "Stage everything, commit with a timestamp, then rebuild the system";
        command.commit = {
          date.enable = true;
          date.format = "+%Y-%m-%d-%H:%M";
          rebuild = true;
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------------------------------------------------------

      # ---------------------------------------------------------
      # ---- gaa -> Stage all repo changes ---- #
      #
      # Create a git commit using the provided message
      # ---------------------------------------------------------
      gaa = {
        help = "Stage everything and commit with a timestamp";
        command.commit = {
          date.enable = true;
          date.format = "+%Y-%m-%d-%H:%M";
          rebuild = false;
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
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
      gsd = {
        help = "Stage everything, commit with a timestamp, then rebuild the system";
        command.commit = {
          date.enable = true;
          date.format = "+%Y-%m-%d %H:%M";
          rebuild = true;
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
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
      sbranch = {
        command = ''
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
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------------------------------------------------------

      # ---------------------------------------------------------
      # fbranch
      # ---------------------------------------------------------
      # Interactive Git branch switcher and branch creator
      #
      # Features:
      #   - Browse local branches with fzf
      #   - Switch to an existing branch
      #   - Create a new branch without switching to it
      #   - Optionally create a branch containing:
      #       - the entire repository, or
      #       - only a single selected folder
      #
      # When creating a folder-only branch:
      #   - Creates a temporary Git worktree
      #   - Removes all tracked files
      #   - Restores only the selected folder
      #   - Commits the resulting branch
      #   - Cleans up the temporary worktree
      #
      # Example:
      # fbranch
      # ---------------------------------------------------------
      fbranch = {
        command = ''
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
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------------------------------------------------------

      # ---------------------------------------------------------
      # repo-date
      # ---------------------------------------------------------
      # Show the date of the very first commit in a Git repository
      #
      # Accepts either:
      #   - a local Git repository path
      #   - a remote Git repository or GitHub gist URL
      #
      # If a remote URL is provided, the repository is cloned into a
      # temporary directory, the first commit is displayed, and the
      # temporary clone is removed automatically.
      #
      # Displays:
      #   - first commit date
      #   - commit author
      #   - commit hash
      #
      # Note:
      #   For forked repositories or gists, this shows the first commit
      #   in the complete Git history, not the date the fork was created.
      #
      # Example:
      # repo-date ~/Downloads/my-repo
      # repo-date https://github.com/user/repo.git
      # repo-date https://gist.github.com/jshmllr/dce62a4c67bb10592c82370a985dd3e4
      # ---------------------------------------------------------
      repo-date = {
        command = ''
        if test (count $argv) -lt 1
          echo "Usage: repo-date <repo-path-or-url>"
          return 1
        end

        set target "$argv[1]"
        set cleanup 0
        set repo "$target"

        if string match -qr '^https?://|^git@' "$target"
          set temp_dir (mktemp -d)
          set cleanup 1

          git clone --quiet "$target" "$temp_dir"
          or begin
            echo "Could not clone: $target"
            rm -rf "$temp_dir"
            return 1
          end

          set repo "$temp_dir"
        end

        if not git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1
          echo "Not a Git repository: $target"

          if test "$cleanup" -eq 1
            rm -rf "$repo"
          end

          return 1
        end

        git -C "$repo" log --reverse --max-parents=0 \
          --format="First commit: %ad%nAuthor: %an <%ae>%nCommit: %H" \
          --date=iso \
          | head -n 3

        if test "$cleanup" -eq 1
          rm -rf "$repo"
        end
        '';
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------------------------------------------------------
    };
  };
}
