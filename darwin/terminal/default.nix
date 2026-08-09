# darwin/terminal/default.nix
#
# =====================================================================
# FISH: DARWIN-ONLY EXTRAS
#
# - Shared Fish configuration lives in shared/terminal
# - This module keeps Apple paths, Docker Desktop integration, and macOS
#   maintenance helpers out of the shared Fish module
# =====================================================================

{ config, pkgs, ... }:

{
  # ---- MAN PAGE CACHE ---- #
  # macOS uses its built-in `man`; Home Manager's GNU man package is null.
  # Fish enables cache generation by default, but it cannot run without it.
  programs.man.generateCaches = false;

  programs.fish = {
    interactiveShellInit = ''
      # Common paths
      set -gx ICLOUD_MOBILE "$HOME/Library/Mobile Documents"
    '';

    shellAliases = {
      # ---- MACOS SYSTEM HELPERS ---- #
      localip = "ifconfig | grep 'inet '";
      cpuinfo = "sysctl -n machdep.cpu.brand_string";
      meminfo = "vm_stat";
      osinfo = "sw_vers";
      sysinfo = "system_profiler SPSoftwareDataType";
      syshw = "system_profiler SPHardwareDataType";
      upd = "softwareupdate -ia";
      ip = "ifconfig";

      # ---- NIXOS-SPECIFIC CODEX LAUNCHERS ---- #
      # Kept as compatibility aliases for the existing Darwin profile.
      codexc = "exec /run/current-system/sw/bin/codex-profile app chatgpt";
      codexc-cli = "codex-profile cli chatgpt";
      codexa = "exec /run/current-system/sw/bin/codex-profile app api";
      codexa-cli = "codex-profile cli api";
    };

    shellAbbrs.unhide = "chflags nohidden";
  };

  # ---- COMPLETIONS ---- #
  xdg.configFile."fish/completions/docker.fish".source =
    "${pkgs.docker_29}/share/fish/vendor_completions.d/docker.fish";

  # ---- ENVIRONMENT ---- #
  home = {
    sessionPath = [
      # Docker PATH
      "/Applications/Programming/Docker.app/Contents/Resources/bin"
    ];

    sessionVariables = {
      MICRO_TRUECOLOR = "1";
      ICLOUD = "$HOME/iCloudDocs";
      CHATGPT_APP = "/Applications/ChatGPT.app";
    };
  };

  imports = [
    # Finder, iCloud, macOS Trash, and macOS Obsidian helpers.
    ./commands
  ];
}
