# /Users/ven/.config/nix/nix-config/darwin/modules/overlays/codex-profile.nix
#
# CODEX PROFILE: OVERLAY
# =====================================================================
# Adds the locally patched codex-profile package to pkgs.
# =====================================================================

final: prev: {
  codex-profile =
    final.callPackage ../system/packages/codex { };
}