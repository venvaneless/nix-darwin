# /Users/ven/.config/nix/nix-darwin/darwin/modules/overlays/overlay-asdf.nix
#
# OVERRIDE: ASDF VERSION MANAGER
# ====================================================================
# Replaces the Nix-provided asdf-vm package with the upstream Git
# version. This version respects ASDF_CONFIG_FILE correctly, unlike
# the patched Nix package.
# ====================================================================

final: prev: {
  asdf-vm = prev.asdf-vm.overrideAttrs (old: {
    version = "git-master";

    src = builtins.fetchGit {
      url = "https://github.com/asdf-vm/asdf.git";
      ref = "master";
    };
  });
}
