# shared/home/default.nix
#
# =====================================================================
# SHARED HOME MANAGER
#
# Central dispatcher for reusable Home Manager configuration.
#
# All shared modules are imported here.
#
# FUTURE:
# When multiple machines/platforms exist, pass a machine/platform
# descriptor through extraSpecialArgs and use mkIf/mkMerge below to
# enable the same feature with different settings per machine.
#
# Platform-specific implementations should normally use:
#
#   pkgs.stdenv.hostPlatform.isDarwin
#   pkgs.stdenv.hostPlatform.isLinux
#
# rather than conditional imports based on config.
# =====================================================================

{ ... }:

{
  imports = [
   # ./services
   ./pkgs-configs
  ];
}