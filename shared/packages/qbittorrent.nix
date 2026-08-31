# shared/packages/qbittorrent.nix
#
# =====================================================================
# PACKAGES: QBITTORRENT
#
# Owns everything the desktop client needs: the enhanced build on both
# platforms, the command-line client where nixpkgs supports it, the
# Darwin application link, the profile location, and the settings this
# configuration declares for that profile.
#
# qBittorrent resolves --profile, and the QBT_PROFILE variable that
# mirrors it, before any platform default, and then creates
# <profile>/qBittorrent/{cache,config,data} itself. The profile root is
# therefore .config, which puts the whole profile below
# .config/qBittorrent on macOS and on Linux alike.
#
# ** The NixOS daemon in shared/services/qbittorrent.nix is a separate
# ** instance with its own profile below /var/lib. Nothing here touches
# ** it, and a host that runs both runs two independent clients with
# ** their own torrents, their own session state, and their own ports.
# =====================================================================

{ lib, packageOptions, paths, platforms, pkgs, ... }:

let
  # The same relative layout on both platforms, so the selector only
  # decides which home prefix is used.
  homePaths = paths.forPlatform platforms.isDarwin;
  qbittorrentPaths = homePaths.qbittorrent;

  appName = "qbittorrent.app";

  # ------------------------------------------------------------
  # ------ PROFILE LOCATION ------ #
  # ------------------------------------------------------------
  # QBT_PROFILE is qBittorrent's own environment equivalent of
  # --profile: every command-line option has a QBT_ variable built from
  # its upper-case name. The variable is what makes the profile apply
  # to a launch that carries no command line of its own, such as
  # opening a magnet link from a browser, or starting the application
  # from the Dock.

  qbittorrentEnvironment = {
    QBT_PROFILE = qbittorrentPaths.profileRoot;
  };

  # ------------------------------------------------------------
  # ------ DECLARED SETTINGS ------ #
  # ------------------------------------------------------------
  # Only the settings this configuration owns. qBittorrent writes
  # categories, column layouts, window geometry, and the Web UI
  # password hash into the same file, so everything not listed here is
  # deliberately left to the application.
  #
  # ** The Web UI listens on 8090 rather than the usual 8080, because
  # ** Vaultwarden already owns 8080 on the Darwin host. The NixOS
  # ** daemon keeps 8080: it is a different machine and a different
  # ** instance.

  webuiPort = "8090";
  torrentingPort = "6881";

  declaredSettings = {
    # Skips the first-run legal notice, which otherwise holds a fresh
    # profile behind a modal dialog.
    LegalNotice = {
      Accepted = "true";
    };

    BitTorrent = {
      "Session\\DefaultSavePath" = qbittorrentPaths.downloads;
      "Session\\Port" = torrentingPort;
    };

    Preferences = {
      # Remote control from a browser or a phone while the application
      # is running.
      #
      # ** The password is deliberately absent. qBittorrent stores it
      # ** as a PBKDF2 hash in this same file, and anything written
      # ** from Nix would land world-readable in the store. Set it once
      # ** in the Web UI; the merge below preserves it.
      "WebUI\\Enabled" = "true";
      "WebUI\\Port" = webuiPort;
      "WebUI\\Username" = paths.user.name;
    };
  };

  # Qt writes its INI files without spaces around the separator, so the
  # generated file matches what qBittorrent produces itself.
  declaredConfig = pkgs.writeText "qbittorrent-declared.conf" (
    lib.generators.toINI
      {
        mkKeyValue = key: value: "${key}=${value}";
      }
      declaredSettings
  );

  # ------------------------------------------------------------
  # ------ CONFIGURATION WRITER ------ #
  # ------------------------------------------------------------
  # qBittorrent rewrites its own configuration file whenever a setting,
  # a category, or a window changes, so that file must never be a
  # symbolic link into the Nix store. The declared settings are merged
  # into the existing file instead: declared keys are replaced, every
  # other key is preserved, and the result is moved into place
  # atomically.
  #
  # ** Merging while qBittorrent is running is pointless rather than
  # ** harmful. The application holds its settings in memory and writes
  # ** them back when it exits, so quit it before a rebuild when a
  # ** declared setting has to take effect immediately.

  mergeDeclaredSettings = pkgs.writeText "merge-qbittorrent-settings.py" ''
    import configparser
    import os
    import sys
    import tempfile

    live_path, declared_path = sys.argv[1], sys.argv[2]


    def load(path):
        parser = configparser.RawConfigParser(strict=False)

        # Qt keys are case-sensitive and contain backslashes, so the
        # default lower-casing transform has to be disabled.
        parser.optionxform = str
        parser.read(path, encoding="utf-8")

        return parser


    live = load(live_path)
    declared = load(declared_path)

    for section in declared.sections():
        if not live.has_section(section):
            live.add_section(section)

        for key, value in declared.items(section):
            live.set(section, key, value)

    handle, temporary_path = tempfile.mkstemp(dir=os.path.dirname(live_path))

    with os.fdopen(handle, "w", encoding="utf-8") as stream:
        live.write(stream, space_around_delimiters=False)

    os.chmod(temporary_path, 0o600)
    os.replace(temporary_path, live_path)
  '';

  installDeclaredConfig = pkgs.writeShellScriptBin "install-qbittorrent-config" ''
    set -euo pipefail

    config_directory=${lib.escapeShellArg qbittorrentPaths.config}
    config_file=${lib.escapeShellArg qbittorrentPaths.configFile}
    download_directory=${lib.escapeShellArg qbittorrentPaths.downloads}

    ${pkgs.coreutils}/bin/mkdir -p -- "$config_directory" "$download_directory"

    # A profile that has never been started has no file to merge into.
    if [ ! -e "$config_file" ]; then
      ${pkgs.coreutils}/bin/install -m 600 -- \
        ${declaredConfig} \
        "$config_file"

      echo "[qbittorrent] Installed the declared configuration: $config_file"
      exit 0
    fi

    # Refuse anything that is not qBittorrent's own regular file, so a
    # stray symbolic link is reported instead of followed.
    if [ -L "$config_file" ] || [ ! -f "$config_file" ]; then
      echo "[qbittorrent] ERROR: Refusing to write a configuration that is not a regular file: $config_file" >&2
      exit 1
    fi

    ${pkgs.python3}/bin/python3 \
      ${mergeDeclaredSettings} \
      "$config_file" \
      ${declaredConfig}

    echo "[qbittorrent] Applied the declared settings: $config_file"
  '';

  # ------------------------------------------------------------
  # ------ PACKAGE DEFINITIONS ------ #
  # ------------------------------------------------------------

  qbittorrentPackages = {
    # ---- qBittorrent Enhanced
    # Desktop client with the enhanced edition's extra peer handling.
    # The Darwin bundle keeps upstream's lower-case name, and the
    # shared link manager places it in /Applications/Tools.
    qbittorrent = {
      enable = true;
      installOn = { darwin = true; linux = true; };
      package = pkgs.qbittorrent-enhanced;
      inherit appName;
      symlinkTools = true;
    };

    # ---- qBittorrent CLI
    # Command-line client that drives a running instance through its
    # Web UI.
    #
    # ** nixpkgs marks this package bad on aarch64-darwin, because its
    # ** .NET build has no application host for osx-arm64. It is
    # ** therefore declared Linux-only rather than forced onto macOS.
    qbittorrentCli = {
      enable = true;
      installOn = { darwin = false; linux = true; };
      package = pkgs.qbittorrent-cli;
    };
  };
in
lib.mkMerge [
  # ---- Installation and the Darwin application link
  (packageOptions.mkPackageModule {
    name = "qbittorrent";
    packages = qbittorrentPackages;
  })

  # ---- Profile location and declared settings
  # nix-darwin owns the process environment and the system activation
  # script; Home Manager owns the session environment and the user
  # activation script on Linux.
  (
    if platforms.isDarwin then
      {
        environment.variables = qbittorrentEnvironment;

        # ** postActivation is one of the fixed hooks nix-darwin runs.
        # ** A module-specific activation script name is accepted by
        # ** the option type and then never executed.
        system.activationScripts.postActivation.text = lib.mkAfter ''
          qbittorrent_user_uid="$(/usr/bin/id -u ${paths.user.name})"

          # Reaches Dock, Spotlight, and Finder launches, which never
          # see environment.variables.
          /bin/launchctl asuser "$qbittorrent_user_uid" \
            /bin/launchctl setenv QBT_PROFILE "${qbittorrentPaths.profileRoot}"

          # The profile belongs to the user, so the writer runs as the
          # user rather than as root.
          /usr/bin/sudo \
            -u ${paths.user.name} \
            /usr/bin/env \
            HOME=${homePaths.root} \
            ${installDeclaredConfig}/bin/install-qbittorrent-config
        '';
      }
    else
      {
        home.sessionVariables = qbittorrentEnvironment;

        home.activation.qbittorrentConfiguration =
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            ''${DRY_RUN_CMD} ${installDeclaredConfig}/bin/install-qbittorrent-config
          '';
      }
  )
]
