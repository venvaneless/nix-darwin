# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/user-groups.nix
#
# DARWIN: CONTAINER DATA GROUP + USER ACCESS
# ============================================================
# - Creates shared system group "containers"
# - Adds ven (primary user) to "containers" via extraGroups
# ============================================================

{ config, lib, pkgs, ... }:

{
  # ------------------------------------------------------------
  # GROUP: containers
  # ------------------------------------------------------------
  users.groups.containers = {
    gid = 450;
  };

  # ------------------------------------------------------------
  # ACCESS: ven gets read/write access
  # IMPORTANT: extraGroups ONLY works on primaryUser
  # ------------------------------------------------------------
  users.users.${config.system.primaryUser}.extraGroups = [ "containers" ];
}
