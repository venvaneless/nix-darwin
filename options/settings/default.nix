# options/settings/default.nix
#
# =====================================================================
# OPTIONS: MACOS SETTINGS
#
# Readable knobs for macOS preferences whose stored values are codes.
# =====================================================================

{
  imports = [
    ./clock.nix
    ./control-center.nix
    ./finder.nix
    ./global.nix
    ./trackpad.nix
  ];
}
