# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/mkcert.nix
#
# MKCERT: GLOBAL SETUP
# ====================
# - Installs mkcert as a system package.
# - Ensures the local CA is installed.
# - Uses XDG-style CAROOT under ~/.config/mkcert.
# ====================

{ config, pkgs, lib, ... }:

let
  userHome = config.users.users.ven.home;
  caroot   = "${userHome}/.config/mkcert";
in
{
  environment.systemPackages = [ pkgs.mkcert ];

  system.activationScripts.mkcert-install.text = lib.mkAfter ''
    echo ">>> [mkcert] Ensuring mkcert CA is installed"

    CAROOT="${caroot}"

    if [ ! -f "${caroot}/rootCA.pem" ]; then
      echo ">>> [mkcert] No rootCA.pem found → running mkcert -install"
      CAROOT="${caroot}" "${pkgs.mkcert}/bin/mkcert" -install || {
        echo "!!! [mkcert] mkcert -install failed"
      }
    else
      echo ">>> [mkcert] mkcert CA already present at ${caroot}"
    fi
  '';
}
