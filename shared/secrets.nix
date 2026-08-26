# shared/secrets.nix
#
# =====================================================================
# HOME MANAGER: USER SECRETS
#
# Decrypts service dotenv files outside the Nix store. The encrypted
# source files remain in secrets/, while the services keep using their
# existing mutable paths below the user's configuration directory.
# =====================================================================

{ config, ... }:

let
  # ---- User-owned secret locations
  secretsDirectory = "${config.home.homeDirectory}/.config/secrets";
  ageKeyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
in
{
  # ------------------------------------------------------------
  # ------ SOPS IDENTITY ------ #
  # Uses the existing Age identity. The private key stays outside the
  # Nix store and is never copied into this configuration.

  sops.age.keyFile = ageKeyFile;

  # ------------------------------------------------------------
  # ------ ENCRYPTED DOTENV VALUES ------ #
  # sops-nix decrypts each dotenv value, then the templates below render
  # the complete files expected by the existing services.

  sops.secrets = {
    ARCHIVEBOX_ADMIN_USERNAME = {
      sopsFile = ../secrets/archivebox.sops.env;
      format = "dotenv";
    };

    ARCHIVEBOX_ADMIN_PASSWORD = {
      sopsFile = ../secrets/archivebox.sops.env;
      format = "dotenv";
    };

    MEILI_MASTER_KEY = {
      sopsFile = ../secrets/karakeep.sops.env;
      format = "dotenv";
    };

    NEXTAUTH_SECRET = {
      sopsFile = ../secrets/karakeep.sops.env;
      format = "dotenv";
    };

    NEXTAUTH_URL = {
      sopsFile = ../secrets/karakeep.sops.env;
      format = "dotenv";
    };
  };

  # ------------------------------------------------------------
  # ------ GENERATED SERVICE FILES ------ #
  # These preserve the current service paths. Home Manager replaces them
  # only when its SOPS activation runs; it does not touch them otherwise.

  sops.templates = {
    "archivebox.env" = {
      content = ''
        ARCHIVEBOX_ADMIN_USERNAME=${config.sops.placeholder.ARCHIVEBOX_ADMIN_USERNAME}
        ARCHIVEBOX_ADMIN_PASSWORD=${config.sops.placeholder.ARCHIVEBOX_ADMIN_PASSWORD}
      '';
      path = "${secretsDirectory}/archivebox.env";
      mode = "0600";
    };

    "karakeep.env" = {
      content = ''
        MEILI_MASTER_KEY=${config.sops.placeholder.MEILI_MASTER_KEY}
        NEXTAUTH_SECRET=${config.sops.placeholder.NEXTAUTH_SECRET}
        NEXTAUTH_URL=${config.sops.placeholder.NEXTAUTH_URL}
      '';
      path = "${secretsDirectory}/karakeep.env";
      mode = "0600";
    };
  };
}
