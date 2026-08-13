# options/paths.nix
#
# =====================================================================
# OPTIONS: COMMON PATHS
#
# Single source of truth for every filesystem location the
# configuration refers to more than once.
#
# This module only centralizes values. It does not change existing
# service, backup, alias, Fish, or iCloud behavior.
#
# Layout: shared definitions first, then macOS, then Linux. Each group
# owns its whole family of paths, so a directory is defined once and
# every path below it is composed from that definition.
# =====================================================================

{ }:

let
  # =====================================================================
  # BASE ROOTS
  # =====================================================================
  # Bound before the output set because several groups below compose
  # their own paths from them. Only genuine roots belong here: anything
  # that is used by a single group is defined inside that group instead.

  # ------------------------------------------------------------
  # ------ PRIMARY USER ------ #
  # ------------------------------------------------------------
  # The same account name is used on macOS and on Linux, so the two
  # home trees differ only in their prefix.

  userName = "ven";

  darwinHome = "/Users/${userName}";
  linuxHome = "/home/${userName}";

  # ------------------------------------------------------------
  # ------ SHARED HOME LAYOUT ------ #
  # ------------------------------------------------------------
  # The directories that exist on both platforms with the same shape.
  # Only the prefix differs, so they are written once and built from
  # whichever home root is passed in.
  #
  # ** Anything whose location genuinely differs between platforms is
  # ** not in here. It is added by the platform tree below, so a real
  # ** difference stays visible instead of hiding inside this function.

  mkHomePaths = home: {
    root = home;

    # ---- Configuration
    config = "${home}/.config";
    nixConfig = "${home}/.config/nix/nix-config";
    nixScripts = "${home}/.config/nix/nix-scripts";
    containers = "${home}/.config/containers";
    secrets = "${home}/.config/secrets";

    # ---- Editors
    # VS Code portable root. The same relative location on both
    # platforms, so only the home prefix differs.
    #
    # ** VS Code resolves VSCODE_PORTABLE before VSCODE_APPDATA,
    # ** --user-data-dir, and its platform default, and derives every
    # ** subdirectory below from it. The names are fixed upstream, so
    # ** they are written once here instead of in each caller.
    vscode = rec {
      root = "${home}/.config/vscode";

      userData = "${root}/user-data";
      extensions = "${root}/extensions";
      sharedData = "${root}/shared-data";

      settings = "${userData}/User/settings.json";
      keybindings = "${userData}/User/keybindings.json";
      snippets = "${userData}/User/snippets";
    };

    # ---- Other
    downloads = "${home}/Downloads";
    localBin = "${home}/.local/bin";
  };

  # ------------------------------------------------------------
  # ------ PLATFORM HOME TREES ------ #
  # ------------------------------------------------------------
  # Bound here so the platform selector can return one of them. Each is
  # published in its own platform group further down.

  darwinHomePaths = mkHomePaths darwinHome // {
    # ---- State, data, and cache
    # ** This host deliberately keeps all three below .config rather
    # ** than at the standard XDG locations. Preserved as configured.
    state = "${darwinHome}/.config/.state";
    data = "${darwinHome}/.config/.local/share";
    cache = "${darwinHome}/.config/.cache";

    # ---- Certificates
    # mkcert CA root holding rootCA.pem, rootCA-key.pem and the Android
    # export copies. Read by every local HTTPS service.
    mkcert = "${darwinHome}/.config/mkcert";

    # mkcert-issued certificates and keys, one subdirectory per service.
    # Kept out of the Nix store: private keys must not be world-readable.
    ssl = "${darwinHome}/.config/ssl";
  };

  linuxHomePaths = mkHomePaths linuxHome // {
    # ---- State, data, and cache
    # ** Standard XDG locations, unlike the macOS tree above.
    state = "${linuxHome}/.local/state";
    data = "${linuxHome}/.local/share";
    cache = "${linuxHome}/.cache";
  };

  # ------------------------------------------------------------
  # ------ MACOS ROOTS ------ #
  # ------------------------------------------------------------
  # macOS-only roots that have no Linux counterpart.

  # ---- Library
  darwinLibrary = "${darwinHome}/Library";
  mobileDocuments = "${darwinLibrary}/Mobile Documents";
  iCloudDrive = "${mobileDocuments}/com~apple~CloudDocs";

  # ---- Applications
  applicationsRoot = "/Applications";
  programmingApps = "${applicationsRoot}/Programming";
in
{
  # =====================================================================
  # SHARED
  # =====================================================================
  # Values that are meaningful on both platforms.

  # ------------------------------------------------------------
  # ------ USER ACCOUNT ------ #
  # ------------------------------------------------------------

  user = {
    name = userName;

    darwinHome = darwinHome;
    linuxHome = linuxHome;
  };

  # ------------------------------------------------------------
  # ------ PLATFORM SELECTOR ------ #
  # ------------------------------------------------------------
  # For modules that run on both platforms. The caller supplies its own
  # platform check rather than this file guessing one, because paths.nix
  # takes no arguments and cannot see pkgs.
  #
  #   paths.forPlatform pkgs.stdenv.hostPlatform.isDarwin
  #     => darwin.home or linux.home
  #
  # ** The Linux tree deliberately omits the macOS-only entries such as
  # ** mkcert and ssl. Read a value that exists on both platforms, or
  # ** branch explicitly when it does not.

  forPlatform = isDarwin: if isDarwin then darwinHomePaths else linuxHomePaths;

  # ------------------------------------------------------------
  # ------ NIX STORE AND PROFILES ------ #
  # ------------------------------------------------------------
  # Locations owned by the Nix daemon. Identical on macOS and Linux,
  # because the store layout does not vary by platform.
  #
  # ** Never write into these. They are referenced so commands can read
  # ** generation state, not so anything can modify the store directly.

  nixPaths = rec {
    store = "/nix/store";
    var = "/nix/var/nix";
    profiles = "${var}/profiles";

    # Profile whose generations a system rebuild adds to.
    systemProfile = "${profiles}/system";
  };

  # ------------------------------------------------------------
  # ------ HOME-RELATIVE FRAGMENTS ------ #
  # ------------------------------------------------------------
  # For cross-platform modules that must build a path from Home
  # Manager's config.home.homeDirectory instead of a fixed prefix.

  relative = {
    config = ".config";
    localBin = ".local/bin";
    nixConfig = ".config/nix/nix-config";
    nixScripts = ".config/nix/nix-scripts";
  };

  # =====================================================================
  # MACOS
  # =====================================================================

  # ------------------------------------------------------------
  # ------ HOME ------ #
  # ------------------------------------------------------------
  # Everything below the user's home directory. Configuration,
  # certificates, and iCloud all live here so a change to the .config
  # root reaches every path derived from it.

  darwin.home = darwinHomePaths;

  # ---- iCloud
  # Prefer the short symlink forms. They are user-created, already in
  # place, and keep the com~apple~CloudDocs literal out of every module.
  #
  #   docs       -> Library/Mobile Documents/com~apple~CloudDocs
  #   containers -> Library/Mobile Documents
  #
  # ** Both symlinks are user-owned. Never recreate or replace them; a
  # ** module that finds one missing must fail loudly instead.
  #
  # ** The real* entries stay available for anything that must not
  # ** depend on a home-directory symlink, such as a job that runs
  # ** before the user session is fully available.

  darwin.icloud = rec {
    docs = "${darwinHome}/iCloudDocs";
    containers = "${darwinHome}/iCloudContainers";

    realDrive = iCloudDrive;
    realContainers = mobileDocuments;

    # ---- Application containers
    obsidianVaults = "${containers}/iCloud~md~obsidian/Documents";

    # ---- Locally served content
    # Content a local service reads out of iCloud Drive.
    #
    # ** These are user-owned files. A service may read them and must
    # ** never create, move, or delete anything beside them. iCloud can
    # ** report a path as missing while it is still downloading, so a
    # ** service has to fail loudly instead of recreating the directory.
    #
    # ** The real drive path is used here rather than the docs symlink,
    # ** because this content is served by a LaunchAgent that starts at
    # ** login, before a home-directory symlink is worth depending on.
    services = rec {
      root = "${realDrive}/Documents/system/services";

      # ** The trailing slash is deliberate: it is part of the path this
      # ** service has always used.
      tartarusStartpage = "${root}/tartarus-startpage/";
    };
  };

  # ------------------------------------------------------------
  # ------ HOME-RELATIVE FRAGMENTS ------ #
  # ------------------------------------------------------------
  # macOS locations expressed without a home prefix.
  #
  # ** For generated shell that must resolve against the running user's
  # ** own $HOME rather than a fixed account: guard clauses in the
  # ** user-facing file commands, and substring tests against a path.
  # ** Interpolating an absolute value there would bake one username
  # ** into a command meant to work for whoever runs it.

  darwin.relative = rec {
    library = "Library";
    mobileDocuments = "${library}/Mobile Documents";
    iCloudDrive = "${mobileDocuments}/com~apple~CloudDocs";
  };

  # ------------------------------------------------------------
  # ------ LIBRARY ------ #
  # ------------------------------------------------------------
  # Apple-managed roots below ~/Library.
  #
  # ** mobileDocuments and iCloudDrive are the real locations of the
  # ** two symlinks in the iCloud group above. Prefer that group in new
  # ** modules; these stay because they are Library facts in their own
  # ** right and several modules already read them.

  darwin.library = rec {
    root = darwinLibrary;
    applicationSupport = "${root}/Application Support";
    preferences = "${root}/Preferences";
    containers = "${root}/Containers";
    groupContainers = "${root}/Group Containers";
    logs = "${root}/Logs";
    mobileDocuments = "${root}/Mobile Documents";
    iCloudDrive = "${mobileDocuments}/com~apple~CloudDocs";
  };

  # ------------------------------------------------------------
  # ------ APPLICATIONS ------ #
  # ------------------------------------------------------------

  darwin.applications = rec {
    # ---- Category directories
    root = applicationsRoot;
    nixApps = "${root}/Nix Apps";
    programming = programmingApps;
    productivity = "${root}/Productivity";
    tools = "${root}/Tools";
    multimedia = "${root}/Multimedia";
    system = "${root}/System";

    # ---- Individual bundles
    # Named bundles referenced outside their own install module, for
    # example from the Fish PATH and environment variables.
    #
    # ** Docker Desktop is deliberately absent here: its bundle, binary
    # ** directory, and CLI belong with the container paths in the
    # ** Docker group below.
    bundles = {
      chatgpt = "${root}/ChatGPT.app";
    };
  };

  # ------------------------------------------------------------
  # ------ SYSTEM ------ #
  # ------------------------------------------------------------
  # Root-owned locations outside $HOME, used by LaunchDaemons and
  # activation.
  #
  # ** A LaunchDaemon can start before the user's home directory is
  # ** available, so its configuration, logs, and pid files must not
  # ** live under /Users.

  darwin.system = rec {
    # ---- Roots
    etc = "/etc";
    var = "/var";
    logs = "${var}/log";
    run = "${var}/run";

    # Ephemeral launchd job logs. Never use this for persistent service
    # data: macOS prunes /tmp.
    tmp = "/tmp";

    # Real location of /tmp, used for lock directories and staging that
    # must not be reached through the /tmp symlink.
    privateTmp = "/private/tmp";

    # ---- Generation-stable service wrappers
    # Wrapper scripts referenced by launchd jobs.
    venEtc = "${etc}/ven";
    venServices = "${venEtc}/services";

    # environment.etc targets are relative to /etc, so the same location
    # is also needed without its leading slash.
    venServicesTarget = "ven/services";

    # ---- Base binaries
    # Addressed absolutely because launchd and activation both run with
    # a minimal PATH that must not be relied on.
    bin = {
      open = "/usr/bin/open";
      install = "/usr/bin/install";
      chown = "/usr/sbin/chown";
      find = "/usr/bin/find";
      mv = "/bin/mv";
      mount = "/sbin/mount";
      chmod = "/bin/chmod";
      rm = "/bin/rm";

      # Clears the immutable and system-immutable file flags.
      chflags = "/bin/chflags";

      # iCloud file-provider control. Used to force a placeholder to
      # download before it is moved or archived, never to evict data.
      brctl = "/usr/bin/brctl";

      # Not part of macOS. The user-facing file commands probe for it
      # and fall back when it is absent.
      trash = "/usr/bin/trash";

      # ** For a command that deliberately re-executes itself as root.
      # ** Adding this here does not make sudo appropriate anywhere else.
      sudo = "/usr/bin/sudo";

      # ** Used only to nudge the iCloud daemons after a move or archive
      # ** so Finder stops showing a stale entry. Never used to reset or
      # ** evict iCloud data.
      killall = "/usr/bin/killall";
    };

    # ---- Fallback PATH for generated runners
    # The directories a launchd runner needs before it can reach system
    # tools. Services prepend their own requirements to this list.
    launchdPath = [
      "/run/current-system/sw/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ];
  };

  # ------------------------------------------------------------
  # ------ HOMEBREW ------ #
  # ------------------------------------------------------------
  # Homebrew's own installation, bootstrapped by nix-homebrew and
  # therefore outside the Nix store.
  #
  # ** Activation runs with a minimal PATH and cannot assume `brew` is
  # ** reachable, so the executable is addressed absolutely.

  darwin.homebrew = rec {
    prefix = "/opt/homebrew";
    binDir = "${prefix}/bin";
    brew = "${binDir}/brew";
  };

  # ------------------------------------------------------------
  # ------ DOCKER ------ #
  # ------------------------------------------------------------
  # Every path used by the modules under darwin/services/docker.

  darwin.docker = rec {
    # ---- Docker Desktop
    # ** Installed into /Applications/Programming by docker.nix, so its
    # ** CLI is not on launchd's PATH and has to be addressed through
    # ** the bundle.
    app = "${programmingApps}/Docker.app";
    binDir = "${app}/Contents/Resources/bin";
    cli = "${binDir}/docker";

    # ---- Service data
    # The container root is the same directory as the home group's
    # `containers`; it is repeated here so every service data path is
    # composed from one place.
    #
    # ** Persistent data must survive container recreation. Never point
    # ** these at a Docker volume or a writable container layer.
    data = rec {
      root = darwinHomePaths.containers;

      archivebox = "${root}/archivebox";
      browsertrix = "${root}/browsertrix";
      karakeep = "${root}/karakeep";
      vaultwarden = "${root}/vaultwarden";
      wallabag = "${root}/wallabag";
    };

    # ---- Environment files
    # ** Credentials stay outside the Nix store, which is world-readable.
    env = rec {
      root = darwinHomePaths.secrets;

      archivebox = "${root}/archivebox.env";
      karakeep = "${root}/karakeep.env";
    };
  };

  # ------------------------------------------------------------
  # ------ BACKUPS ------ #
  # ------------------------------------------------------------
  # Layout of the external SystemBackup volume plus the local staging
  # and lock locations used while a backup runs.
  #
  # ** The volume is removable. Every backup command verifies it is
  # ** actually mounted before writing, because an unmounted volume
  # ** leaves a writable empty directory at the same path.
  #
  # ** Backups only ever read their sources. Nothing here is a source.

  darwin.backups = rec {
    # ---- External volume
    volume = "/Volumes/SystemBackup";

    # ---- System tree
    system = "${volume}/system";
    terminal = "${system}/terminal";

    # ---- Data tree
    data = "${volume}/data-backups";
    apps = "${data}/app-backups";
    browsers = "${apps}/browsers";
    containers = "${data}/container-backups";

    # Local certificate authority material, kept as a plain mirror
    # rather than an archive so a restore is a straight copy back.
    certificates = "${data}/certificates";

    # ---- Obsidian library
    # Permanent plugin and theme library kept beside the app backups.
    obsidian = "${apps}/obsidian";
    obsidianExtensions = "${obsidian}/obsidian_extensions";
    obsidianThemes = "${obsidian}/obsidian_themes";

    # ---- Local staging
    # Archives are built in Downloads and only moved to the volume once
    # they are complete and verified.
    staging = "${darwinHome}/Downloads/backup-staging";

    # ---- Per-container locations
    # One entry per container backup command: where its finished archive
    # lands on the volume, and where it is staged while being built.
    #
    # ** This is the place to add or move a container backup. Its module
    # ** never composes a path; the backup helper reads these entries by
    # ** the container's slug and fails loudly if one is missing.
    #
    # ** Sources are absent on purpose. A backup reads its source from
    # ** the service that owns the data, so the two can never drift.
    perContainer = {
      archivebox = {
        destination = "${containers}/archivebox";
        staging = "${staging}/archivebox";
      };

      browsertrix = {
        destination = "${containers}/browsertrix";
        staging = "${staging}/browsertrix";
      };

      karakeep = {
        destination = "${containers}/karakeep";
        staging = "${staging}/karakeep";
      };

      vaultwarden = {
        destination = "${containers}/vaultwarden";
        staging = "${staging}/vaultwarden";
      };

      wallabag = {
        destination = "${containers}/wallabag";
        staging = "${staging}/wallabag";
      };
    };

    # ---- Locks
    # A single global lock keeps concurrent backups from competing for
    # the volume; per-application locks sit beside it.
    lockRoot = "/private/tmp";
    appLock = "${lockRoot}/com.ven.app-backup.lock";
    archiveLock = "${lockRoot}/com.ven.backup-archive.lock";
  };

  # =====================================================================
  # LINUX
  # =====================================================================

  # ------------------------------------------------------------
  # ------ HOME ------ #
  # ------------------------------------------------------------
  # Everything below the user's home directory. macOS-only families
  # such as certificates, iCloud, and the backup volume have no Linux
  # equivalent yet and are deliberately absent.

  linux.home = linuxHomePaths;
}
