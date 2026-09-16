# darwin/terminal/fish-aliases.nix
#
# =====================================================================
# FISH: DARWIN-ONLY ALIASES
#
# - Portable aliases live in shared/terminal/aliases
# - This module only holds aliases that depend on macOS tooling
# =====================================================================

{ ... }:

{
  programs.fish = {
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

      # ---- CODEX LAUNCHERS ---- #
      # Subscription login (c) or API key (a); one shared Codex home.
      codexc = "exec open -a /Applications/ChatGPT.app";
      codexc-cli = "codex";
      codexa = "codex-api app";
      codexa-cli = "codex-api cli";
    };

    # ---- ABBREVIATIONS ---- #
    shellAbbrs.unhide = "chflags nohidden";
  };
}
