# shared/services/qbittorrent.nix
#
# =====================================================================
# SERVICES: QBITTORRENT DAEMON
#
# Optional headless qBittorrent for hosts that keep torrenting while
# nobody is logged in. The daemon has no user interface at all: it is
# driven through its Web UI or through qbittorrent-cli.
#
# ** This module is NixOS-only. services.qbittorrent is a system
# ** option, and shared/packages.nix is evaluated inside Home Manager
# ** on the Linux hosts, so the daemon can never live beside the
# ** package declarations. Import it from a NixOS host module only.
#
# ** The daemon is a second, independent qBittorrent instance. It has
# ** its own profile below /var/lib, its own torrents, and its own
# ** session state. A host that also runs the desktop client from
# ** shared/packages/qbittorrent.nix runs two clients that share
# ** nothing but the machine, and their torrenting ports must differ.
# =====================================================================

{ config, lib, options, pkgs, ... }:

let
  helpers = import ../../options { inherit lib options pkgs; };

  inherit (helpers) paths;

  cfg = config.ven.features.services.qbittorrent;

  daemonPaths = paths.linux.services.qbittorrent;

  # ------------------------------------------------------------
  # ------ DECLARED SETTINGS ------ #
  # ------------------------------------------------------------
  # The ports are passed on the command line by the upstream module, so
  # only settings without a command-line equivalent are declared here.
  #
  # ** The Web UI password is a PBKDF2 hash. It is never written from
  # ** Nix directly, because the store is world-readable; when a secret
  # ** is configured the value is substituted by sops-nix while the
  # ** file is rendered outside the store.

  passwordPlaceholder =
    if cfg.webuiPasswordSecret == null then
      null
    else
      config.sops.placeholder.${cfg.webuiPasswordSecret};

  declaredSettings = {
    # Accepts the legal notice so the daemon does not exit on a fresh
    # profile while waiting for a terminal answer.
    LegalNotice = {
      Accepted = "true";
    };

    BitTorrent = {
      "Session\\DefaultSavePath" = daemonPaths.downloads;
    };

    Preferences = {
      "WebUI\\Enabled" = "true";
      "WebUI\\Username" = cfg.webuiUsername;
    }
    // lib.optionalAttrs (passwordPlaceholder != null) {
      "WebUI\\Password_PBKDF2" = passwordPlaceholder;
    };
  };

  # Qt writes its INI files without spaces around the separator, so the
  # generated file matches what qBittorrent produces itself.
  renderSettings = settings:
    lib.generators.toINI
      {
        mkKeyValue = key: value: "${key}=${value}";
      }
      settings;

  declaredConfigText = renderSettings declaredSettings;

  # ------------------------------------------------------------
  # ------ CONFIGURATION SOURCE ------ #
  # ------------------------------------------------------------
  # The upstream module copies its own serverConfig into the profile at
  # every start, and that copy would carry the password hash through
  # the Nix store. serverConfig therefore stays empty and this module
  # installs the file itself, either from the store when no secret is
  # configured, or from the sops-rendered copy when one is.
  #
  # ** sops-nix renders templates during system activation, which
  # ** happens before multi-user.target starts this unit.

  configTemplateName = "qbittorrent-daemon.conf";

  configSource =
    if cfg.webuiPasswordSecret == null then
      "${pkgs.writeText configTemplateName declaredConfigText}"
    else
      config.sops.templates.${configTemplateName}.path;
in
{
  # ------------------------------------------------------------
  # ------ HOST TOGGLE ------ #
  # ------------------------------------------------------------
  # Each NixOS host decides for itself whether it seeds in the
  # background. Nothing is installed or started while this is off.

  options.ven.features.services.qbittorrent = {
    enable = lib.mkEnableOption "headless qBittorrent Enhanced daemon";

    webuiPort = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port the daemon's Web UI listens on.";
    };

    torrentingPort = lib.mkOption {
      type = lib.types.port;
      default = 6882;
      description = ''
        Fixed incoming torrent port for the daemon. It must differ from
        the desktop client's port when both run on the same host.
      '';
    };

    webuiUsername = lib.mkOption {
      type = lib.types.str;
      default = paths.user.name;
      description = "Web UI account name for the daemon.";
    };

    webuiPasswordSecret = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "qbittorrent/webui-password-hash";
      description = ''
        Name of the sops-nix secret holding the Web UI password, stored
        exactly as qBittorrent writes it, including the wrapper:

          @ByteArray(<salt>:<hash>)

        The value is substituted into the daemon's configuration file
        outside the Nix store. Leave this null to let qBittorrent
        generate a temporary password on first start and print it to
        the journal.
      '';
    };

    openTorrentingPort = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Opens the torrenting port in the firewall. The Web UI port is
        deliberately never opened: reach it over Tailscale instead of
        exposing it on the local network.
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # ------------------------------------------------------------
      # ------ DAEMON ------ #
      # ------------------------------------------------------------
      # serverConfig stays empty on purpose: this module installs the
      # configuration file itself, see the ExecStartPre below.

      services.qbittorrent = {
        enable = true;
        package = pkgs.qbittorrent-enhanced-nox;

        profileDir = daemonPaths.profileDir;

        webuiPort = cfg.webuiPort;
        torrentingPort = cfg.torrentingPort;

        extraArgs = [
          "--confirm-legal-notice"
        ];

        # Explicit rules below, so the upstream helper never opens the
        # Web UI port along with the torrenting port.
        openFirewall = false;
      };

      # ---- Declared configuration
      # Installed before every start, so a rebuild restores the
      # declared settings while everything qBittorrent writes for
      # itself stays in place between starts.
      systemd.services.qbittorrent = {
        restartTriggers = [ declaredConfigText ];

        serviceConfig.ExecStartPre =
          "${pkgs.coreutils}/bin/install -Dm600 ${configSource} ${daemonPaths.configFile}";
      };

      # ---- Download directory
      # The upstream module creates the profile and its config
      # directory; the save path is this module's own choice.
      systemd.tmpfiles.settings.qbittorrent-downloads.${daemonPaths.downloads}."d" = {
        mode = "755";
        user = config.services.qbittorrent.user;
        group = config.services.qbittorrent.group;
      };
    }

    # ------------------------------------------------------------
    # ------ WEB UI PASSWORD ------ #
    # ------------------------------------------------------------
    # Renders the configuration file with the hash substituted, owned
    # by the service account and readable by nobody else.
    #
    # ** The secret itself is declared by the host, because only the
    # ** host knows which sops file and key it comes from:
    # **
    # **   sops.secrets."qbittorrent/webui-password-hash" = {
    # **     sopsFile = ../secrets/qbittorrent.yaml;
    # **   };
    # **
    # **   ven.features.services.qbittorrent.webuiPasswordSecret =
    # **     "qbittorrent/webui-password-hash";

    (lib.mkIf (cfg.webuiPasswordSecret != null) {
      sops.templates.${configTemplateName} = {
        content = declaredConfigText;

        owner = config.services.qbittorrent.user;
        group = config.services.qbittorrent.group;
        mode = "0400";
      };
    })

    # ------------------------------------------------------------
    # ------ FIREWALL ------ #
    # ------------------------------------------------------------
    # Incoming peer connections only. The Web UI stays unreachable from
    # the network and is used over Tailscale.

    (lib.mkIf cfg.openTorrentingPort {
      networking.firewall = {
        allowedTCPPorts = [ cfg.torrentingPort ];
        allowedUDPPorts = [ cfg.torrentingPort ];
      };
    })
  ]);
}
