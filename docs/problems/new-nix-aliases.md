nix run nixpkgs#statix check .
nix run nixpkgs#deadnix .
sudo -H darwin-rebuild build --flake .#macbook
sudo -H nix run github:LnL7/nix-darwin -- switch --flake /Users/ven/dotfiles/nix#macbook
