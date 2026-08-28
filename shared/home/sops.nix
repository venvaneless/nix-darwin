# shared/home/sops.nix
#
# =====================================================================
# HOME MANAGER: SOPS CONFIGURATION
#
# Provides the shared SOPS CLI configuration for all Home Manager hosts.
# The public Age recipient is safe to store in Git.
#
# The private Age identity remains outside the Nix store at:
#   ~/.config/sops/age/keys.txt
# =====================================================================

{ config, ... }:

let
  sopsConfigDirectory = "${config.xdg.configHome}/sops";
in
{
  # ------------------------------------------------------------
  # ------ SOPS CLI CONFIG ------ #
  #
  # Makes the SOPS CLI use the configuration generated below instead of
  # requiring a manually maintained .sops.yaml in the repository.

  home.sessionVariables.SOPS_CONFIG =
    "${sopsConfigDirectory}/config.yaml";

  # ------------------------------------------------------------
  # ------ SOPS CREATION RULES ------ #
  #
  # This recipient is derived from the existing age identity with:
  #
  #   age-keygen -y ~/.config/sops/age/keys.txt
  #
  # It is the PUBLIC recipient and is safe to commit.

  xdg.configFile."sops/config.yaml".text = ''
    keys:
      - &ven age1tux8c6hrsx4z5s2gsd8vjl58v8yd7kv7xsddhsmydmpwj629mdhqn90gdp

    creation_rules:
      - path_regex: .*\.sops\.env$
        key_groups:
          - age:
              - *ven

      - path_regex: .*\.sops\.json$
        key_groups:
          - age:
              - *ven
  '';
}
