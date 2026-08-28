# shared/home/default.nix
#
# =====================================================================
# SHARED HOME MANAGER
#
# Top-level glue for Home Manager configuration that can be shared
# between machines.
#
# Shared modules are imported normally.
# Cross-platform modules that should only apply on one platform can be
# conditionally imported here.
# =====================================================================

{ platforms, ... }:

let
  inherit (platforms) isDarwin isLinux;
in
{
  imports =
    [
      # Shared Home Manager categories
      ./services
    ]

    # Shared modules enabled only on Darwin
    ++ (if isDarwin then [
      # ./some-shared-darwin-only-module.nix
    ] else [ ])

    # Shared modules enabled only on Linux
    ++ (if isLinux then [
      # ./some-shared-linux-only-module.nix
    ] else [ ]);
}