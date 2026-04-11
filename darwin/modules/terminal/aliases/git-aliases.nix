# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/aliases/git-aliases.nix

{ lib, ... }:

{
  programs.zsh.shellAliases = {
    # ---------- Git ---------- #

    # Stage everything in the current repo.
    gaa = "git add .";

    # Stage files for commit.
    ga = "git add";

    # List or manage branches.
    gb = "git branch";

    # Start a git commit.
    gc = "git commit";

    # Commit tracked file changes without staging each file manually.
    gca = "git commit -a";

    # Start a commit with inline message.
    gcm = "git commit -m";

    # Show git diff.
    gd = "git diff";

    # Pull changes from remote.
    gl = "git pull";

    # Switch branch or restore files with checkout.
    gco = "git checkout";

    # Push commits to remote.
    gp = "git push";

    # Show git status.
    gs = "git status";

    # Open the dotfiles repo helper script.
    gsd = "/Users/ven/iCloudDocs/my-system/00-sys_assets/scripts/git-scripts/dotfiles-repo.sh";

    # Open the nix repo helper script.
    gsn = "/Users/ven/iCloudDocs/my-system/00-sys_assets/scripts/git-scripts/nix-repo.sh";

    # Open lazygit.
    l-g = "lazygit";
  };
}