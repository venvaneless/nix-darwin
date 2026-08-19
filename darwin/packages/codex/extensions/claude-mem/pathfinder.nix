# CODEX: CLAUDE-MEM PATHFINDER
# =========================
# Keep architecture reports in their target repository instead of user config

{ ... }:

{
  # RUNTIME OUTPUT
  # =========================
  # Pathfinder creates dated reports at the root of the repository it audits.
  # Those project artifacts are intentionally not linked from the Nix store.
}
