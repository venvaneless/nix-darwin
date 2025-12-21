# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/aliases/git-aliases.nix

{ lib, ... }:

{
  programs.zsh.shellAliases = {
    gsn = "/Users/ven/iCloudDocs/my-system/00-sys_assets/scripts/git-scripts/nix-repo.sh";
    gsd = "/Users/ven/iCloudDocs/my-system/00-sys_assets/scripts/git-scripts/dotfiles-repo.sh";
  };
}
