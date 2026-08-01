# darwin/overlays/default.nix
#
# OVERLAYS: GLUE FILE
# =====================================================================
# Loads all local overlays from ./overlays/
# This makes overlays modular, maintainable and scalable.
# =====================================================================

[
  (import ./codex-profile.nix)
]