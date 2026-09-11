# shared/nix-options.nix
#
# =====================================================================
# SHARED: NIX CONFIGURATION
#
# What every machine gets and no machine decides for itself. Applied to
# all of them by the constructors in flake-modules/hosts.nix.
#
# ** Only settings this file actually decides are written here. A setting
# ** left as default resolves to the same value whether it is written or
# ** not, so writing one here as well as in a machine would be the same
# ** knob twice, saying nothing in either place.
#
# ** These four are always the same everywhere, so they are decided here
# ** and nowhere else. Everything a machine decides for itself -- cores,
# ** job limits, log length, store retention, the cache fallback, its
# ** users and its build group -- is written in that machine's own
# ** default.nix.
#
# ** A machine writing one of these again with a different value is an
# ** error, on purpose: two files would be deciding one setting. Use
# ** lib.mkForce in the machine if that is really what is wanted.
# =====================================================================

{ ... }:

{
  ven.nix.settings = {
    # ---- Flakes
    # Every machine here is built from this flake.
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # ---- Official binary cache ----
    # ** A machine writing substituters of its own adds to these rather
    # ** than replacing them.
    substituters = [
      "https://cache.nixos.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];

    # Ignore dirty git tree warnings
    # ** The normal state while editing this repository, on any machine.
    # ** It could instead live in flake.nix under nixConfig, beside
    # ** allow-dirty, which would scope it to this flake rather than to
    # ** everything built on the machine. Settings there are not in Nix's
    # ** trusted set, so that route can prompt before it applies.
    warn-dirty = false;
  };
}
