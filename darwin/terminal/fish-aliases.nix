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

      # ---- NIXOS-SPECIFIC CODEX LAUNCHERS ---- #
      # Kept as compatibility aliases for the existing Darwin profile.
      codexc = "exec /run/current-system/sw/bin/codex-profile app chatgpt";
      codexc-cli = "codex-profile cli chatgpt";
      codexa = "exec /run/current-system/sw/bin/codex-profile app api";
      codexa-cli = "codex-profile cli api";
    };

    # ---- ABBREVIATIONS ---- #
    shellAbbrs.unhide = "chflags nohidden";
  };
}
