# /Users/ven/dotfiles/nix/darwin/modules/services/app-definitions.nix
#
# APP DEFINITIONS (RUNNABLE COMMANDS)
# =========================
# Central registry of all nix-run apps (update-all, update-zed, etc.)
# Each entry points to a programPath exported by its own module.
# =========================

{ pkgs, lib, ... }:

let
  zed = import ../apps/update/zed-update.nix { inherit pkgs lib; };
  # In future:
  # obsidian = import ./obsidian/obsidian-update.nix { inherit pkgs lib; };
  # vscode   = import ./vscode/vscode-update.nix { inherit pkgs lib; };
in {
  update-all = {
    type = "app";
    program =
      let all = import ../apps/update/update-all.nix { inherit pkgs lib; };
      in all.programPath;

  meta = {
      description = "Updates all managed apps and extensions";
      platforms = [ "aarch64-darwin" ];
    };
  };

  update-zed = {
    type = "app";
    program = zed.programPath;

  meta = {
      description = "Updates Zed.app data and themes";
      platforms = [ "aarch64-darwin" ];
    };
  };

  # update-obsidian = {
  #   type = "app";
  #   program = obsidian.programPath;
  # };
}
