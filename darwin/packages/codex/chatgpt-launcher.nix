# darwin/packages/codex/chatgpt-launcher.nix
#
# CODEX: CHATGPT PROFILE LAUNCHER
# =====================================================================
# Provides a Dock-compatible macOS application bundle that launches
# the primary chatgpt Codex profile through codex-profile.
# =====================================================================

{
  codexProfile,
  lib,
  paths,
  python3,
  runCommand,
  writeShellScript,
  writeText,
}:

let
  # ------------------------------------------------------------
  # ------ APPLICATION BUNDLE ------ #
  # The Dock requires an .app bundle, while codex-profile supplies
  # the profile-specific CODEX_HOME and Electron user-data directory.

  appName = "Codex ChatGPT";
  codexIcon = "${paths.darwin.applications.bundles.chatgpt}/Contents/Resources/icon-codex-dark-color.png";

  infoPlist = writeText "${appName}.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>CFBundleDisplayName</key>
        <string>${appName}</string>
        <key>CFBundleExecutable</key>
        <string>${appName}</string>
        <key>CFBundleIdentifier</key>
        <string>com.ven.codex-chatgpt</string>
        <key>CFBundleIconFile</key>
        <string>Codex.icns</string>
        <key>CFBundleName</key>
        <string>${appName}</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>CFBundleShortVersionString</key>
        <string>2.0</string>
        <key>CFBundleVersion</key>
        <string>2</string>
      </dict>
    </plist>
  '';

  launcher = writeShellScript "launch-${appName}" ''
    set -euo pipefail

    # Delegate profile setup and LaunchServices startup to the same command
    # used by Raycast, including the chatgpt Electron user-data directory.
    export CHATGPT_APP=${lib.escapeShellArg paths.darwin.applications.bundles.chatgpt}
    export CODEX_PROFILE_CONFIG_HOME=${lib.escapeShellArg paths.darwin.agents.codex.profileConfig}
    export CODEX_PROFILE_HOME_ROOT=${lib.escapeShellArg paths.darwin.agents.codex.root}

    exec ${lib.escapeShellArg "${codexProfile}/bin/codex-profile"} app chatgpt
  '';
in
runCommand "codex-chatgpt-launcher" {
  nativeBuildInputs = [ python3 ];
} ''
  application="$out/Applications/${appName}.app"

  install -Dm444 \
    ${infoPlist} \
    "$application/Contents/Info.plist"

  install -Dm555 \
    ${launcher} \
    "$application/Contents/MacOS/${appName}"

  # Package the Codex artwork as a native icon so the Dock has it before the
  # Electron application starts and can supply its runtime icon.
  mkdir -p "$application/Contents/Resources"

  python3 - ${lib.escapeShellArg codexIcon} \
    "$application/Contents/Resources/Codex.icns" <<'PY'
import struct
import sys

png_path, icns_path = sys.argv[1:]
png = open(png_path, "rb").read()

with open(icns_path, "wb") as icon:
    icon.write(b"icns")
    icon.write(struct.pack(">I", 16 + len(png)))
    icon.write(b"ic10")
    icon.write(struct.pack(">I", 8 + len(png)))
    icon.write(png)
PY
''
