# /Users/ven/.config/nix/nix-darwin/darwin/modules/services/docker/mkcert.nix
#
# MKCERT: GLOBAL SETUP
# ====================
# - Installs mkcert as a system package.
# - Ensures the local CA is installed.
# - Uses XDG-style CAROOT under ~/.config/mkcert.
# ====================

{ config, pkgs, lib, ... }:

{
  # Install mkcert globally
  environment.systemPackages = [ pkgs.mkcert ];

  # Activation script: ensure mkcert CA is installed
  system.activationScripts.mkcert-install.text = lib.mkAfter ''
    echo ">>> [mkcert] Ensuring mkcert CA is installed"
    CAROOT="${HOME}/.config/mkcert"

    if [ ! -f "${HOME}/.config/mkcert/rootCA.pem" ]; then
      echo ">>> [mkcert] No rootCA.pem found, running mkcert -install"
      CAROOT="$CAROOT" "${pkgs.mkcert}/bin/mkcert" -install || {
        echo "!!! [mkcert] mkcert -install failed"
      }
    else
      echo ">>> [mkcert] mkcert CA already present at ${HOME}/.config/mkcert"
    fi
  '';
}
