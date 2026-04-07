# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/aliases/test-aliases.nix

{ lib, ... }:

{
  programs.zsh.shellAliases = {
    cat = "bat";
    ccx = "clear";
    cd = "z";
    ess = "exec zsh";
    ff = "fastfetch";
    gs = "git status";
    l-g = "lazygit";
    la = "ls -A";
    lh = "ls -lah";
    nano = "micro";
    yy = "yazi";
  };
}
