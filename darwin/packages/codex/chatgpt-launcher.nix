# darwin/packages/codex/chatgpt-launcher.nix
#
# CODEX: CHATGPT PROFILE LAUNCHER
# =====================================================================
# Provides a Dock-compatible macOS application bundle that launches
# the primary chatgpt Codex profile through the signed ChatGPT app.
# =====================================================================

{
  lib,
  paths,
  runCommand,
  writeShellScript,
  writeText,
}:

let
  # ------------------------------------------------------------
  # ------ APPLICATION BUNDLE ------ #
  # The Dock requires an .app bundle. The launcher directly execs the
  # signed ChatGPT executable so macOS keeps one running Dock item.

  appName = "Codex ChatGPT";
  chatgptApp = paths.darwin.applications.bundles.chatgpt;
  chatgptExecutable = "${chatgptApp}/Contents/MacOS/ChatGPT";
  chatgptIcon = "${chatgptApp}/Contents/Resources/app.icns";

  # Keep the named profile contract aligned with codex-profile.
  codexHome = paths.darwin.agents.codex.chatgpt;
  codexSqliteHome = "${codexHome}/sqlite";
  electronUserData = "${codexHome}/electron-user-data";

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
        <string>app.icns</string>
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
    set -euo pipefail

    chatgpt_executable=${lib.escapeShellArg chatgptExecutable}
    codex_home=${lib.escapeShellArg codexHome}
    codex_sqlite_home=${lib.escapeShellArg codexSqliteHome}
    electron_user_data=${lib.escapeShellArg electronUserData}

    if [ ! -x "$chatgpt_executable" ]; then
      echo "[Codex ChatGPT] ERROR: ChatGPT executable was not found: $chatgpt_executable" >&2
      exit 1
    fi

    # Create only the exact mutable profile directories required by ChatGPT.
    umask 077
    /bin/mkdir -p "$codex_home" "$codex_sqlite_home" "$electron_user_data"

    export CODEX_HOME="$codex_home"
    export CODEX_SQLITE_HOME="$codex_sqlite_home"

    exec "$chatgpt_executable" "--user-data-dir=$electron_user_data"
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

  # Reuse the installed signed app's icon without modifying its bundle.
  mkdir -p "$application/Contents/Resources"
  ln -s ${lib.escapeShellArg chatgptIcon} \
    "$application/Contents/Resources/app.icns"
''
