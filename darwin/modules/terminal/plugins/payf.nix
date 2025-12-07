{ config, pkgs, ... }:

{
  programs.pay-respects = {
    enable = true;

    suggestionsOnly = true;     # only suggest, don’t auto-run
    alias = "f";                # the command to trigger corrections
    enableZshIntegration = true; # integrates automatically with Zsh
  };
}
