# darwin/system/default.nix
#
# =====================================================================
# MACOS SYSTEM SETTINGS
#
# Consolidates the active nix-darwin system settings previously split by
# subject in this directory. Homebrew stays in ./homebrew.nix.
# =====================================================================
{
  paths,
  pkgs,
  ...
}: {
  system.defaults = {
    # ===================================================================
    # DOCK APPLICATIONS
    # ===================================================================
    dock = {
      # Persistent applications: pins these application bundles to the Dock.
      persistent-apps = [
        paths.darwin.applications.bundles.cider
        paths.darwin.applications.bundles.wezterm
        paths.darwin.applications.bundles.helium
        paths.darwin.applications.bundles.zed
        paths.darwin.applications.bundles.snippetsLab

        # Launcher tile: opens the chatgpt Codex profile. It shares the real
        # app's bundle identifier, so the running-dot stays on this tile.
        paths.darwin.applications.bundles.codexChatgpt
      ];
    };
  };

  # ===================================================================
  # KEYBOARD SETTINGS
  # ===================================================================
  system.keyboard = {
    # Custom key mapping: enables nix-darwin hardware key remapping.
    enableKeyMapping = true;

    # Caps Lock to Escape: keeps Caps Lock from acting as Escape.
    remapCapsLockToEscape = false;

    # Caps Lock to Control: keeps Caps Lock from acting as Control.
    remapCapsLockToControl = false;
  };

  # ===================================================================
  # POWER MANAGEMENT SETTINGS
  # ===================================================================
  # Power sleep: placeholder for future display, computer, and disk sleep rules.
  power.sleep = {};

  # ===================================================================
  # SYSTEM LOCALE SETTINGS
  # ===================================================================
  environment.variables = {
    # Default locale: uses US English with UTF-8 encoding.
    LANG = "en_US.UTF-8";

    # Locale override: applies the same locale to every locale category.
    LC_ALL = "en_US.UTF-8";
  };

  # ===================================================================
  # SYSTEM FONT SETTINGS
  # ===================================================================
  # System fonts: installs these Nerd Font families for all users.
  fonts.packages = [
    # JetBrains Mono: patched monospaced font for terminals and editors.
    pkgs.nerd-fonts.jetbrains-mono

    # Fira Code: patched monospaced font with programming ligatures.
    pkgs.nerd-fonts.fira-code

    # Meslo LG: patched monospaced font commonly used by shell prompts.
    pkgs.nerd-fonts.meslo-lg
  ];

  # ===================================================================
  # WALLPAPER (DISABLED)
  # ===================================================================
  # The previous wallpaper module was not imported. Keep it disabled so
  # this consolidation does not introduce activation-time behavior.
  #
  # system.activationScripts.setWallpaper.text = ''
  #   ...
  # '';
}
