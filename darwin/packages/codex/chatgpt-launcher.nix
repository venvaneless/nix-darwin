# darwin/packages/codex/chatgpt-launcher.nix
#
# CODEX: CHATGPT PROFILE LAUNCHER
# =====================================================================
# Provides a Dock-compatible macOS application bundle that launches
# Codex through codex-profile with the primary chatgpt profile.
# =====================================================================

{
  codexProfile,
  lib,
  paths,
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
        <key>CFBundleName</key>
        <string>${appName}</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>CFBundleShortVersionString</key>
        <string>1.0</string>
      </dict>
    </plist>
  '';

  launcher = writeShellScript "launch-${appName}" ''
    export CHATGPT_APP=${lib.escapeShellArg paths.darwin.applications.bundles.chatgpt}
    export CODEX_PROFILE_CONFIG_HOME=${lib.escapeShellArg paths.darwin.agents.codex.profileConfig}
    export CODEX_PROFILE_HOME_ROOT=${lib.escapeShellArg paths.darwin.agents.codex.root}

    exec ${lib.escapeShellArg "${codexProfile}/bin/codex-profile"} app chatgpt
  '';
in
runCommand "codex-chatgpt-launcher" { } ''
  application="$out/Applications/${appName}.app"

  install -Dm444 \
    ${infoPlist} \
    "$application/Contents/Info.plist"

  install -Dm555 \
    ${launcher} \
    "$application/Contents/MacOS/${appName}"
''
