# nixos/system/hyprland.nix
#
# =====================================================================
# ZEPHYRUS: HYPRLAND DESKTOP
#
# The system half of the desktop: the compositor itself, the portals
# every Wayland application needs for screen sharing and file dialogs,
# the greeter that starts the session, audio, and the few tools a bare
# compositor has no substitute for.
#
# ** The user half -- keybindings, monitor layout, bar, and theme -- is
# ** Home Manager's, and is not written yet. Hyprland reads it from
# ** ~/.config/hypr/hyprland.conf, so the session starts without it and
# ** can be configured afterwards.
# =====================================================================

{ pkgs, ... }:

{
  # ---- COMPOSITOR ---- #
  # Also installs the session file the greeter offers and sets the
  # environment variables Wayland clients read.
  #
  # ** withUWSM wraps the session in systemd units, which is where
  # ** upstream is heading but adds moving parts to a first install.
  # ** Plain Hyprland first; turn it on once the session is trusted.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # ---- PORTALS ---- #
  # Screen sharing and native file pickers both go through
  # xdg-desktop-portal. Hyprland's own portal arrives with the compositor
  # above; the GTK portal is what answers file-chooser requests.
  xdg.portal = {
    enable = true;

    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # ---- GREETER ---- #
  # tuigreet stays on the console rather than pulling a second toolkit
  # into the closure just to draw a login screen.
  services.greetd = {
    enable = true;

    settings.default_session = {
      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
      user = "greeter";
    };
  };

  # ---- AUDIO ---- #
  # PipeWire with the PulseAudio and ALSA shims, which is what every
  # current client expects to find.
  services.pulseaudio.enable = false;

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ---- PERMISSIONS AND SETTINGS ---- #
  # polkit answers privilege prompts from graphical applications, and
  # dconf stores GTK settings.
  security.polkit.enable = true;

  programs.dconf.enable = true;

  # ---- FONTS ---- #
  # A bare NixOS installation has almost none, which is visible
  # immediately in a bar or a terminal.
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    nerd-fonts.jetbrains-mono
  ];

  # ---- SESSION TOOLS ---- #
  # Hyprland ships no bar, launcher, notifier, or screenshot tool, and a
  # session without them has no way to do those things at all. Everything
  # else belongs in shared/packages.nix once its Linux flags are audited.
  environment.systemPackages = with pkgs; [
    # Bar and launcher
    waybar
    wofi

    # Notifications
    mako
    libnotify

    # Clipboard and screenshots
    wl-clipboard
    grim
    slurp

    # Laptop keys
    brightnessctl
    playerctl

    # Wallpaper
    hyprpaper
  ];
}
