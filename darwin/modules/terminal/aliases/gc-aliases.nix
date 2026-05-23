# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/aliases/gc-aliases.nix
#
# NIX GARBAGE COLLECTION & GENERATION HELPERS
# ===========================================

{ ... }:

{
  programs.fish.shellAliases = {
    drg = "sudo -H nix-env --list-generations --profile /nix/var/nix/profiles/system";
  };

  programs.fish.functions = {
    ddg = ''
      sudo -H nix-env --delete-generations $argv \
        --profile /nix/var/nix/profiles/system
    '';

    ndg = ''
      sudo nix-collect-garbage --delete-older-than "$argv[1]"d
    '';

    ndgcg30 = ''
      echo "Deleting old generations (+5) and collecting garbage older than 30 days..."
      sudo -H nix-env --delete-generations +5 \
        --profile /nix/var/nix/profiles/system
      sudo nix-collect-garbage --delete-older-than 30d
      echo "Cleanup complete."
    '';
  };
}