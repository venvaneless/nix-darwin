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
  # The Dock requires an .app bundle. The launcher hands the real launch
  # to LaunchServices via open(1); see the note on the launcher script
  # for why it must not exec the ChatGPT binary itself.

  appName = "Codex ChatGPT";
  chatgptApp = paths.darwin.applications.bundles.chatgpt;
  chatgptExecutable = "${chatgptApp}/Contents/MacOS/ChatGPT";
  codexIcon = "${chatgptApp}/Contents/Resources/icon-codex-dark-color.png";

  # Keep the named profile contract aligned with codex-profile.
  codexHome = paths.darwin.agents.codex.chatgpt;
  codexSqliteHome = "${codexHome}/sqlite";
  electronUserData = "${codexHome}/electron-user-data";

  # ------------------------------------------------------------
  # ------ ICON LADDER ------ #
  # Apple's canonical representation set. Every consumer picks a
  # representation out of this ladder; an icon file that carries only
  # icon_512x512@2x is accepted by Finder but rejected by Chromium, and
  # the running Electron process then falls back to its own bundled
  # electron.icns. Emitting the full ladder is what keeps the Dock tile
  # correct both before and after the app starts.

  iconLadder = [
    { pixels = 16; name = "icon_16x16"; }
    { pixels = 32; name = "icon_16x16@2x"; }
    { pixels = 32; name = "icon_32x32"; }
    { pixels = 64; name = "icon_32x32@2x"; }
    { pixels = 128; name = "icon_128x128"; }
    { pixels = 256; name = "icon_128x128@2x"; }
    { pixels = 256; name = "icon_256x256"; }
    { pixels = 512; name = "icon_256x256@2x"; }
    { pixels = 512; name = "icon_512x512"; }
    { pixels = 1024; name = "icon_512x512@2x"; }
  ];

  renderIconEntry = entry: ''
    /usr/bin/sips \
      --setProperty format png \
      --resampleHeightWidth ${toString entry.pixels} ${toString entry.pixels} \
      "$source_icon" \
      --out "$iconset/${entry.name}.png" \
      > /dev/null
  '';

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
        <key>NSHighResolutionCapable</key>
        <true/>
      </dict>
    </plist>
  '';

  launcher = writeShellScript "launch-${appName}" ''
    set -euo pipefail

    chatgpt_app=${lib.escapeShellArg chatgptApp}
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

    # Already running for this profile: just bring it forward. Launching a
    # second copy of the same profile would fight over its Electron state.
    if /usr/bin/pgrep -qf "user-data-dir=$electron_user_data"; then
      exec /usr/bin/open -a "$chatgpt_app"
    fi

    # Hand the launch to LaunchServices rather than exec'ing the binary.
    #
    # ** An exec'd binary inherits the Dock's bootstrap namespace and
    # ** registers com.openai.codex.MachPortRendezvousServer.<n> there. A
    # ** second profile started later through open(1) then cannot claim that
    # ** name, fails with "Permission denied (1100)", and its whole instance
    # ** dies a few seconds after starting -- which is what broke
    # ** `codex-profile app api` while this launcher's instance was running.
    # ** Going through open(1) gives each instance its own LaunchServices
    # ** context, and the profiles coexist.
    exec /usr/bin/open -n \
      --env "CODEX_HOME=$codex_home" \
      --env "CODEX_SQLITE_HOME=$codex_sqlite_home" \
      -a "$chatgpt_app" \
      --args "--user-data-dir=$electron_user_data"
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


  # ------ ICON ------ #
  # sips and iconutil are the system tools that produce a canonical
  # icns. They are reachable here because this derivation already reads
  # the artwork out of the signed ChatGPT bundle, so the build is
  # host-impure by design.

  source_icon=${lib.escapeShellArg codexIcon}

  if [ ! -f "$source_icon" ]; then
    echo "[Codex ChatGPT] ERROR: Codex artwork was not found: $source_icon" >&2
    echo "[Codex ChatGPT] ChatGPT.app may have renamed its icon resources." >&2
    exit 1
  fi

  iconset="$TMPDIR/Codex.iconset"
  mkdir -p "$iconset"

  ${lib.concatMapStringsSep "\n" renderIconEntry iconLadder}

  mkdir -p "$application/Contents/Resources"

  /usr/bin/iconutil \
    --convert icns \
    "$iconset" \
    --output "$application/Contents/Resources/Codex.icns"
''
