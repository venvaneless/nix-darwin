# shared/terminal/cli-tuis/fd/fd.nix
#
# =====================================================================
# FD
#
# Fast, user-friendly alternative to find, used as:
# - The interactive file and directory search command
# - The file source behind fzf pickers and the fmove helper
#
# Installation, the global ignore file, and the shell aliases are
# managed through Home Manager. Colours live in their own theme files;
# select one directly below. fd imports and enables only that one.
# =====================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.ven.features.terminal.cliTuis.fd;

  # ---- SHARED PATHS ---- #
  # Reuse the centralized user, Library, and iCloud paths instead of
  # repeating literal home directories inside the ignore list.
  paths = import ../../../../options/paths.nix { };

  # ---- PLATFORM TOGGLES ---- #
  # Change these values to set Fd's default per platform. Hosts can
  # still override ven.features.terminal.cliTuis.fd.enable directly.
  fd = {
    enable = true;
    installOn = {
      darwin = true;
      linux = true;
    };
  };

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  enabledForCurrentSystem =
    fd.enable && ((isDarwin && fd.installOn.darwin) || (isLinux && fd.installOn.linux));

  # ---- THEME SELECTION ---- #
  # Change this value to select a different saved fd colour set. The
  # Default selection leaves fd on the terminal's inherited colours.
  selectedTheme = "gruvbox";

  # ---- AVAILABLE THEMES ---- #
  # Each palette remains separate, but only selectedTheme is imported.
  themeModules = {
    default = {
      module = null;
      option = null;
    };
    gruvbox = {
      module = ./themes/gruvbox.nix;
      option = "gruvbox";
    };
  };

  selectedThemeConfig =
    if lib.hasAttr selectedTheme themeModules then
      themeModules.${selectedTheme}
    else
      throw ''
        fd: unknown selectedTheme "${selectedTheme}".
        Choose one of: ${lib.concatStringsSep ", " (lib.attrNames themeModules)}
      '';

  # ---- GLOBAL IGNORE LIST: DARWIN ---- #
  # Keeps whole-disk searches away from read-only system trees and from
  # Apple-managed state. The user Library is skipped as a whole because
  # it holds caches, Containers, Group Containers, and Mobile Documents.
  darwinIgnores = [
    # Nix store and read-only macOS system trees.
    "/nix/"
    "/System/"
    "/Library/"
    "/private/"
    "/usr/"

    # Caches, preferences, containers, and iCloud state.
    "${paths.darwin.library.root}/*"

    # Keep third-party cloud mounts searchable. A negation only works
    # when it follows the broader rule above, so this line must stay here.
    "!${paths.darwin.library.root}/CloudStorage/"

    # Photos libraries are opaque bundles holding thousands of files.
    "${paths.user.darwinHome}/**/*.photoslibrary/"
  ];

  # ---- GLOBAL IGNORE LIST: LINUX ---- #
  # The Linux equivalents of the Darwin entries: the Nix store, the
  # kernel's virtual filesystems, and the user cache directory.
  linuxIgnores = [
    "/nix/"
    "/proc/"
    "/sys/"
    "/dev/"
    "/run/"

    "${paths.user.linuxHome}/.cache/"
  ];

  ignoreEntries = if isDarwin then darwinIgnores else linuxIgnores;
in
{
  options.ven.features.terminal.cliTuis.fd.enable = lib.mkEnableOption "Fd file search";

  config = lib.mkMerge [
    {
      ven.features.terminal.cliTuis.fd.enable = lib.mkDefault enabledForCurrentSystem;
    }
    (lib.mkIf cfg.enable {
      programs.fd = {
        # Install fd and generate its global ignore file.
        enable = true;

        # Written to $XDG_CONFIG_HOME/fd/ignore in list order.
        ignores = ignoreEntries;

        # Left empty on purpose. Home Manager turns these into an `fd`
        # shell alias that shadows the real command; the variants below
        # keep the plain `fd` behaviour intact instead.
        hidden = false;
        extraOptions = [ ];
      };

      programs.fish.shellAliases = {
        # ---- SEARCH VARIANTS ---- #

        # --- fdh -> fd --hidden
        ## Include dotfiles and dot-directories in the search.
        fdh = "fd --hidden";

        # --- fda -> fd --hidden --no-ignore
        ## Search everything, bypassing the ignore file above.
        fda = "fd --hidden --no-ignore";

        # --- fdd -> fd --type d
        ## List matching directories only.
        fdd = "fd --type d";

        # --- fdf -> fd --type f
        ## List matching regular files only.
        fdf = "fd --type f";
      };
    })
    (lib.mkIf (cfg.enable && selectedThemeConfig.option != null) {
      # Only the selected theme module is imported and enabled.
      ven.features.terminal.cliTuis.fd.themes.${selectedThemeConfig.option}.enable = true;
    })
  ];

  imports = lib.optional (selectedThemeConfig.module != null) selectedThemeConfig.module;
}
