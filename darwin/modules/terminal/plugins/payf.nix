{ config, pkgs, ... }:

{
  programs.pay-respects = {
    enable = true;

    # OPTIONAL SETTINGS (choose what you want)
    # suggestionsOnly = true;     # only suggest, don’t auto-run
    # alias = "f";                # the command to trigger corrections
    # enableZshIntegration = true; # integrates automatically with Zsh
  };
}
