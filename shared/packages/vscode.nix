# shared/packages/vscode.nix
#
# =====================================================================
# PACKAGES: VISUAL STUDIO CODE
#
# Owns everything VS Code: installation, the Darwin application link,
# and the relocation of its mutable state out of the home folder into
# .config/vscode.
#
# VS Code resolves VSCODE_PORTABLE before VSCODE_APPDATA,
# --user-data-dir, and its platform default, so a single variable moves
# the editor's own state. The tunnel CLI is the one part that ignores
# it and needs a second variable of its own.
#
# ** Nothing here makes extensions immutable. The Marketplace still
# ** installs normally, only into the relocated extensions directory.
# =====================================================================

{ lib, options, pkgs, ... }:

let
  helpers = import ../../options { inherit lib options pkgs; };

  inherit (helpers) paths platforms;

  # The same relative location on both platforms, so the selector only
  # decides which home prefix is used.
  vscodePaths = (paths.forPlatform platforms.isDarwin).vscode;

  appName = "Visual Studio Code.app";

  # ------------------------------------------------------------
  # ------ RELOCATED STATE ------ #
  # ------------------------------------------------------------
  # Two variables are needed, because they cover different processes.
  #
  #   VSCODE_PORTABLE      the editor itself: user data, extensions,
  #                        argv.json, and the shared-data directory
  #                        that otherwise lands in ~/.vscode-shared
  #
  #   VSCODE_CLI_DATA_DIR  the tunnel and serve-web CLI, which stores
  #                        its metadata in ~/.vscode/cli and does not
  #                        consult VSCODE_PORTABLE at all
  #
  # ** Together these empty ~/.vscode completely. They do not affect
  # ** directories that extensions create for themselves in $HOME:
  # ** those come from the extension calling the operating system's
  # ** home-directory lookup, which no VS Code setting intercepts.
  #
  # ** The root directory has to exist for any of this to take effect.
  # ** VS Code's portable bootstrap tests the path and, when it is
  # ** missing, deletes VSCODE_PORTABLE from its own environment and
  # ** falls back to the standard locations. That makes activation
  # ** safe before the data has been migrated, but it also means an
  # ** empty root silently produces a first-run editor, so the
  # ** directory should be created by the migration and not by this
  # ** module.

  vscodeEnvironment = {
    VSCODE_PORTABLE = vscodePaths.root;
    VSCODE_CLI_DATA_DIR = vscodePaths.cli;
  };

  # ------------------------------------------------------------
  # ------ GUI SESSION ENVIRONMENT ------ #
  # ------------------------------------------------------------
  # environment.variables reaches shells, and with them the `code` CLI,
  # but never an application started from the Dock, Spotlight, or
  # Finder. Changing the signed application bundle's Info.plist to pass
  # these variables to LaunchServices invalidates the bundle signature,
  # so Finder can no longer launch the application.
  #
  # ** Keep the upstream bundle unmodified. Finder launches use VS
  # ** Code's standard state locations; terminal launches remain
  # ** portable through environment.variables below.

  # ------------------------------------------------------------
  # ------ PACKAGE DEFINITION ------ #
  # ------------------------------------------------------------

  # ---- Visual Studio Code
  # Installed from nixpkgs on both platforms; the Darwin bundle is
  # linked into /Applications/Programming by the shared link manager.
  vscode = {
    enable = true;
    installOn = { darwin = true; linux = true; };
    package = pkgs.vscode;
    inherit appName;
    symlinkProgramming = true;
  };
in
lib.mkMerge [
  # ---- Installation and the Darwin application link
  (helpers.packageOptions.mkPackageModule {
    name = "vscode";
    packages = { inherit vscode; };
  })

  # ---- Shell environment
  # Covers the `code` CLI and any terminal launch on both platforms. On
  # Linux this is the only mechanism needed; macOS additionally relies
  # on the LSEnvironment patch above.
  {
    environment.variables = vscodeEnvironment;
  }
]
