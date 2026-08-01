# /Users/ven/.config/nix/nix-config/darwin/overlays/codex-profile.nix
#
# CODEX PROFILE: OVERLAY
# =====================================================================
# Adds the locally patched codex-profile package to pkgs.
# =====================================================================

# Calling the overlay in nix-darwin's configuration.nix
final: prev: {
  codex-profile =
    final.callPackage ../packages/codex { };
}