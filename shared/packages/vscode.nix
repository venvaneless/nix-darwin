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
# --user-data-dir, and its platform default, so one variable moves user
# data, extensions, and argv.json together.
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
  # ------ GUI SESSION ENVIRONMENT ------ #
  # ------------------------------------------------------------
  # environment.variables reaches shells, and with them the `code` CLI,
  # but never an application started from the Dock, Spotlight, or
  # Finder. Those launches go through LaunchServices, which reads
  # LSEnvironment out of the bundle's own Info.plist.
  #
  # ** The upstream bundle already ships an LSEnvironment dictionary
  # ** holding MallocNanoZone, so the variable is inserted beside it.
  # ** The anchor is a single line and unique in the file, and
  # ** --replace-fail turns a future upstream change into a build
  # ** failure rather than a silently unset variable.
  #
  # ** Patching the bundle keeps this generation-scoped: a rollback
  # ** restores the previous store path and takes the variable with it.
  # ** launchctl setenv would instead persist in the user's launchd
  # ** domain long after the configuration stopped setting it.

  vscodePackage =
    if platforms.isDarwin then
      pkgs.vscode.overrideAttrs (previous: {
        postInstall = (previous.postInstall or "") + ''
          substituteInPlace "$out/Applications/${appName}/Contents/Info.plist" \
            --replace-fail \
              '<key>MallocNanoZone</key>' \
              '<key>VSCODE_PORTABLE</key><string>${vscodePaths.root}</string><key>MallocNanoZone</key>'
        '';
      })
    else
      pkgs.vscode;

  # ------------------------------------------------------------
  # ------ PACKAGE DEFINITION ------ #
  # ------------------------------------------------------------

  # ---- Visual Studio Code
  # Installed from nixpkgs on both platforms; the Darwin bundle is
  # linked into /Applications/Programming by the shared link manager.
  vscode = {
    enable = true;
    installOn = { darwin = true; linux = true; };
    package = vscodePackage;
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
    environment.variables.VSCODE_PORTABLE = vscodePaths.root;
  }
]
