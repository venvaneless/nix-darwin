# /Users/ven/.config/nix/nix-darwin/darwin/modules/system/user-groups.nix
#
# DARWIN: CONTAINER DATA GROUP + USER ACCESS
# ============================================================
# - Creates shared system group "containers"
# - All container data will live under /var/lib/containers
# - Adds ven to the "containers" group for backup access
# ============================================================

{ config, lib, pkgs, ... }:

{
  # ------------------------------------------------------------
  # GROUP: containers (shared by all containers)
  # ------------------------------------------------------------
  users.groups.containers = {
    gid = 450;  # fixed, unused GID
  };

  # ------------------------------------------------------------
  # ACCESS: ven gets read/write access to container data
  # ------------------------------------------------------------
  users.users.ven.extraGroups = [ "containers" ];
}
