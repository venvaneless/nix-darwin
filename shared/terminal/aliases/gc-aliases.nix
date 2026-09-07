# shared/terminal/aliases/gc-aliases.nix
#
# =====================================================================
# NIX GARBAGE COLLECTION & GENERATION HELPERS
# =====================================================================

{ nixAliasValues, ... }:

{
  ven.features.terminal.aliases = {
    shell = {
      # List all generations of the system profile
      drg = {
        command = {
          darwin = "sudo -H nix-env --list-generations --profile ${nixAliasValues.systemProfile.darwin}";
          linux = "sudo -H nix-env --list-generations --profile ${nixAliasValues.systemProfile.linux}";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
    };

    functions = {
      # Delete old generations of the system profile
      ddg = {
        command = {
          darwin = ''
            sudo -H nix-env --delete-generations $argv --profile ${nixAliasValues.systemProfile.darwin}
          '';
          linux = ''
            sudo -H nix-env --delete-generations $argv --profile ${nixAliasValues.systemProfile.linux}
          '';
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };

      # Delete old generations and collect garbage after the requested number of days
      ndg = {
        command = {
          darwin = "sudo nix-collect-garbage --delete-older-than \"$days\"d";
          linux = "sudo nix-collect-garbage --delete-older-than \"$days\"d";
        };
        days = 3;
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };

      # Delete old generations and collect garbage older than 30 days
      ndgcg30 = {
        command = {
          darwin = ''
            echo "Deleting old generations (+5) and collecting garbage older than 30 days..."
            sudo -H nix-env --delete-generations +5 --profile ${nixAliasValues.systemProfile.darwin}
            sudo nix-collect-garbage --delete-older-than 30d
            echo "Cleanup complete."
          '';
          linux = ''
            echo "Deleting old generations (+5) and collecting garbage older than 30 days..."
            sudo -H nix-env --delete-generations +5 --profile ${nixAliasValues.systemProfile.linux}
            sudo nix-collect-garbage --delete-older-than 30d
            echo "Cleanup complete."
          '';
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
    };
  };
}
