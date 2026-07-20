# /Users/ven/.config/nix/nix-config/darwin/modules/system/app-store.nix

{
  programs.mas = {
    enable = true;

    packages = {
      SnippetsLab = 1006087419;
    };

    update = true;
    cleanup = false;
  };
}