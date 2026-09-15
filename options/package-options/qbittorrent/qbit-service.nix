# options/package-options/qbittorrent/qbit-service.nix
#
# =====================================================================
# PACKAGE OPTIONS: QBITTORRENT SYSTEM SERVICE
# =====================================================================
#
# Renders the explicitly configured qBittorrent daemon INI and its NixOS
# systemd service. It never uses activation scripts: tmpfiles prepares the
# download directory and ExecStartPre installs the current configuration.
# =====================================================================

{
  config,
  lib,
  pkgs,
  paths,
  platforms,
  ...
}:

let
  cfg = config.ven.packages.qbittorrent.daemon;

  passwordPlaceholder =
    if cfg.webui.passwordSecret == null then
      null
    else
      config.sops.placeholder.${cfg.webui.passwordSecret};

  declaredSettings = {
    LegalNotice.Accepted = if cfg.acceptLegalNotice then "true" else "false";

    BitTorrent = {
      "Session\\DefaultSavePath" = cfg.downloads;
      "Session\\Port" = toString cfg.torrentingPort;
    };

    Preferences = {
      "WebUI\\Enabled" = if cfg.webui.enable then "true" else "false";
      "WebUI\\Port" = toString cfg.webui.port;
      "WebUI\\Username" = cfg.webui.username;
    }
    // lib.optionalAttrs (passwordPlaceholder != null) {
      "WebUI\\Password_PBKDF2" = passwordPlaceholder;
    };
  };

  renderIni =
    settings:
    lib.generators.toINI {
      mkKeyValue = key: value: "${key}=${value}";
    } settings;

  daemonConfigText = renderIni declaredSettings;
  daemonTemplateName = "qbittorrent-service.conf";
  daemonConfigSource =
    if cfg.webui.passwordSecret == null then
      pkgs.writeText daemonTemplateName daemonConfigText
    else
      config.sops.templates.${daemonTemplateName}.path;
in
{
  options.ven.packages.qbittorrent.daemon = {
    enable = lib.mkEnableOption "headless qBittorrent system service";

    package = lib.mkOption {
      type = lib.types.package;
      description = "qBittorrent package used by the headless system service.";
    };

    profileDir = lib.mkOption {
      type = lib.types.str;
      description = "Persistent qBittorrent system-service profile directory.";
    };

    configFile = lib.mkOption {
      type = lib.types.str;
      description = "Mutable qBittorrent system-service configuration file.";
    };

    downloads = lib.mkOption {
      type = lib.types.str;
      description = "Directory where the system service saves completed torrents.";
    };

    acceptLegalNotice = lib.mkOption {
      type = lib.types.bool;
      description = "Accept qBittorrent's legal notice for unattended service startup.";
    };

    webui = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable qBittorrent's Web UI.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        description = "Port on which qBittorrent's Web UI listens.";
      };

      username = lib.mkOption {
        type = lib.types.str;
        description = "qBittorrent Web UI user name.";
      };

      passwordSecret = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "Optional SOPS secret holding qBittorrent's PBKDF2 Web UI password.";
      };
    };

    torrentingPort = lib.mkOption {
      type = lib.types.port;
      description = "Incoming BitTorrent peer port.";
    };

    firewall.openTorrentingPort = lib.mkOption {
      type = lib.types.bool;
      description = "Open the incoming BitTorrent port in the NixOS firewall.";
    };
  };

  config = lib.mkIf (cfg.enable && platforms.isLinux) (
    lib.mkMerge [
      {
        services.qbittorrent = {
          enable = true;
          package = cfg.package;
          profileDir = cfg.profileDir;
          webuiPort = cfg.webui.port;
          torrentingPort = cfg.torrentingPort;
          extraArgs = lib.optionals cfg.acceptLegalNotice [ "--confirm-legal-notice" ];
          openFirewall = false;
        };

        systemd.services.qbittorrent = {
          restartTriggers = [ daemonConfigText ];
          serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/install -Dm600 ${daemonConfigSource} ${cfg.configFile}";
        };

        systemd.tmpfiles.settings.qbittorrent-downloads.${cfg.downloads}."d" = {
          mode = "755";
          user = config.services.qbittorrent.user;
          group = config.services.qbittorrent.group;
        };
      }

      (lib.mkIf (cfg.webui.passwordSecret != null) {
        sops.templates.${daemonTemplateName} = {
          content = daemonConfigText;
          owner = config.services.qbittorrent.user;
          group = config.services.qbittorrent.group;
          mode = "0400";
        };
      })

      (lib.mkIf cfg.firewall.openTorrentingPort {
        networking.firewall = {
          allowedTCPPorts = [ cfg.torrentingPort ];
          allowedUDPPorts = [ cfg.torrentingPort ];
        };
      })
    ]
  );
}
