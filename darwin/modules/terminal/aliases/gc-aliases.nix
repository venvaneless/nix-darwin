# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/aliases/gc-aliases.nix
#
# NIX GARBAGE COLLECTION & GENERATION HELPERS
# ===========================================

{ ... }:

{
  # --- Simple aliases ---
  programs.zsh.shellAliases = {
    # List system generations
    drg = "sudo -H nix-env --list-generations --profile /nix/var/nix/profiles/system";
  };

  # --- GC helper functions ---
  programs.zsh.initContent = ''
    # --- NIX MAINTENANCE HELPERS ---
    # ------------------------------

    # --- Delete old generations (interactive)
    ddg() {
      sudo -H nix-env --delete-generations "$@" \
        --profile /nix/var/nix/profiles/system
    }

    # --- Garbage collector (by days)
    ndg() {
      sudo nix-collect-garbage --delete-older-than "$1"d
    }

    # --- Delete old generations + collect garbage (30 days)
    ndgcg30() {
      echo "Deleting old generations (+5) and collecting garbage older than 30 days..."
      sudo -H nix-env --delete-generations +5 \
        --profile /nix/var/nix/profiles/system
      sudo nix-collect-garbage --delete-older-than 30d
      echo "Cleanup complete."
    }
  '';
}