# CODEX: CLAUDE-MEM STANDUP
# =========================
# Keep the standup transcript mutable because the skill appends to it at runtime

{ ... }:

{
  # RUNTIME STATE
  # =========================
  # Standup writes its atomically locked conversation to its upstream default
  # path. It is session state, not declarative configuration.
}
