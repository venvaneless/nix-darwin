# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/aliases/git-aliases.nix

{ ... }:

{
  programs.zsh.shellAliases = {
    # ---------- Git ---------- #

    # --- ga -> git add
    ## Stage files for commit
    ga = "git add";

    # --- gaa -> git add .
    ## Stage everything in the current repo
    gaa = "git add .";

    # --- gb -> git branch
    ## List or manage branches
    gb = "git branch";

    # --- gc -> git commit
    ## Start a git commit
    gc = "git commit";

    # --- gca -> git commit -a
    ## Commit tracked file changes without staging each file manually
    gca = "git commit -a";

    # --- gcm -> git commit -m
    ## Start a commit with inline message
    gcm = "git commit -m";

    # --- gco -> git checkout
    ## Switch branch or restore files with checkout
    gco = "git checkout";

    # --- gd -> git diff
    ## Show git diff.
    gd = "git diff";

    # --- gl -> git pull
    ## Pull changes from remote
    gl = "git pull";

    # --- gp -> git push
    ## Push commits to remote
    gp = "git push";

    # --- gs -> git status
    ## Show git status
    gs = "git status";

    # --- gsd
    ## Open the dotfiles repo helper script
    gsd = "/Users/ven/iCloudDocs/my-system/00-sys_assets/scripts/git-scripts/dotfiles-repo.sh";

    # --- gsn
    ## Open the nix repo helper script
    gsn = "/Users/ven/iCloudDocs/my-system/00-sys_assets/scripts/git-scripts/nix-repo.sh";

    # --- l-g -> lazygit
    ## Open lazygit
    "l-g" = "lazygit";
  };
}