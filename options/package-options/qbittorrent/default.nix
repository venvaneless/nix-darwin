# options/package-options/qbittorrent/default.nix
#
# =====================================================================
# PACKAGE OPTIONS: QBITTORRENT
# =====================================================================
#
# Declares desktop and CLI package knobs. The optional NixOS system
# service is owned by qbit-service.nix and configured below desktop.service.
# =====================================================================

{ lib, ... }:

let
  cliPathOptions = platformName: {
    profileRoot = lib.mkOption {
      type = lib.types.str;
      description = "qBittorrent CLI profile root on ${platformName}.";
    };

    config = lib.mkOption {
      type = lib.types.str;
      description = "qBittorrent CLI configuration directory on ${platformName}.";
    };

    configFile = lib.mkOption {
      type = lib.types.str;
      description = "qBittorrent CLI configuration file on ${platformName}.";
    };

    downloads = lib.mkOption {
      type = lib.types.str;
      description = "qBittorrent CLI torrent download directory on ${platformName}.";
    };
  };
in
{
  imports = [
    ./qbit-service.nix
  ];

  # Installed and linked by the mediaPackages group.
  options.system.sharedPackages.mediaPackages = lib.mkOption {
    type = lib.types.submodule ({ config, ... }: {
      options.qbittorrent = {
        desktop = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = config.enable;
            description = "Install the qBittorrent Enhanced desktop client. Defaults to its group.";
          };

          installOn = lib.mkOption {
            type = lib.types.attrsOf lib.types.bool;
            default = config.installOn;
            description = "Platforms on which qBittorrent Enhanced is installed. Defaults to its group.";
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
          enable = lib.mkOption {
            type = lib.types.bool;
            default = config.enable;
            description = "Install the qBittorrent command-line client. Defaults to its group.";
          };

          installOn = lib.mkOption {
            type = lib.types.attrsOf lib.types.bool;
            default = config.installOn;
            description = "Platforms on which qBittorrent CLI is installed. Defaults to its group.";
          };

          package = lib.mkOption {
            type = lib.types.package;
            description = "qBittorrent command-line client package.";
          };

          # Home paths differ per platform, so each platform gets its own set.
          # Read them with platforms.valueForCurrentPlatform cfg.cli.paths.
          paths = {
            darwin = cliPathOptions "macOS";
            linux = cliPathOptions "Linux";
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
    });
  };
}
