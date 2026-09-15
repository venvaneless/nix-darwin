# options/package-options/qbittorrent/default.nix
#
# =====================================================================
# PACKAGE OPTIONS: QBITTORRENT
# =====================================================================
#
# Declares desktop and CLI package knobs. The optional NixOS system
# service is owned by qbit-service.nix and configured below desktop.service.
# =====================================================================

{
  config,
  lib,
  packageOptions,
  platforms,
  symlinks ? null,
  ...
}:

let
  cfg = config.ven.packages.qbittorrent;
  desktopCfg = cfg.desktop;

  desktopPackage = desktopCfg;
in
{
  imports = [
    ./qbit-service.nix
  ];

  options.ven.packages.qbittorrent = {
    desktop = {
      enable = lib.mkEnableOption "qBittorrent Enhanced desktop client";

      installOn = lib.mkOption {
        type = lib.types.attrsOf lib.types.bool;
        description = "Platforms on which qBittorrent Enhanced is installed.";
      };

      package = lib.mkOption {
        type = lib.types.package;
        description = "qBittorrent Enhanced desktop package.";
      };

      appName = lib.mkOption {
        type = lib.types.str;
        description = "qBittorrent application bundle name.";
      };

      symlinkTools = lib.mkOption {
        type = lib.types.bool;
        description = "Link qBittorrent into the Darwin Tools application category.";
      };
    };

    cli = {
      enable = lib.mkEnableOption "qBittorrent command-line client";

      installOn = lib.mkOption {
        type = lib.types.attrsOf lib.types.bool;
        description = "Platforms on which qBittorrent CLI is installed.";
      };

      package = lib.mkOption {
        type = lib.types.package;
        description = "qBittorrent command-line client package.";
      };

      paths = {
        profileRoot = lib.mkOption {
          type = lib.types.str;
          description = "qBittorrent CLI profile root.";
        };

        config = lib.mkOption {
          type = lib.types.str;
          description = "qBittorrent CLI configuration directory.";
        };

        configFile = lib.mkOption {
          type = lib.types.str;
          description = "qBittorrent CLI configuration file.";
        };

        downloads = lib.mkOption {
          type = lib.types.str;
          description = "qBittorrent CLI torrent download directory.";
        };
      };

      settings = {
        webuiPort = lib.mkOption {
          type = lib.types.port;
          description = "qBittorrent CLI Web UI port.";
        };

        torrentingPort = lib.mkOption {
          type = lib.types.port;
          description = "qBittorrent CLI incoming torrent port.";
        };

        webuiUsername = lib.mkOption {
          type = lib.types.str;
          description = "qBittorrent CLI Web UI user name.";
        };
      };
    };
  };

  config = packageOptions.mkPackageModule {
    name = "qbittorrent";
    packages = {
      qbittorrent = desktopPackage;
      qbittorrentCli = cfg.cli;
    };
    inherit symlinks;
  };
}
