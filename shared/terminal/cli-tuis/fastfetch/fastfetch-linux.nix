# shared/terminal/cli-tuis/fastfetch/fastfetch-linux.nix
#
# =====================================================================
# FASTFETCH: LINUX LAYOUT
#
# - Selected in fastfetch.nix with selectedLayout.<platform> = "linux"
# - Writes fastfetch's config.jsonc when it is the selected layout
#
# Framed sections. Adds a desktop section for the environment,
# theme, fonts, and cursor, which only resolve on a Linux desktop.
#
# Colours come from whichever palette fastfetch.nix selected, so this
# layout is not tied to a palette or to a platform. Every escape
# sequence is built by ./render.nix rather than written out by hand.
# =====================================================================

{ config, lib, ... }:

let
  fastfetchCfg = config.ven.features.terminal.cliTuis.fastfetch;

  render = import ./render.nix { inherit lib; };

  palette = fastfetchCfg.colours;
  sections = palette.sections;

  # ---- GENERATED CONFIGURATION ---- #
  # Home Manager renders this to $XDG_CONFIG_HOME/fastfetch/config.jsonc.
  fastfetchConfig = {
    "$schema" = "https://raw.githubusercontent.com/fastfetch-cli/fastfetch/dev/doc/json_schema.json";

    logo = {
      # Resolved from fastfetch.nix so the path stays portable.
      source = fastfetchCfg.asciiPath;
      padding = {
        top = 1;
        left = 1;
      };
    };

    display = {
      separator = "";
    };

    modules = [
      # ---- TITLE ---- #
      {
        type = "title";
        color = palette.title;
      }

      # ---- SYSTEM ---- #
      (render.rule sections.system "╭───────── 󰣇 SYSTEM ─────────────────────────────────────────────╮")
      (render.entry sections.system { type = "os"; icon = "󰣇"; text = "OS"; prefix = "│ "; })
      (render.entry sections.system { type = "host"; icon = "󰌢"; text = "Host"; prefix = "│ "; })
      (render.entry sections.system { type = "kernel"; icon = ""; text = "Kernel"; prefix = "│ "; })
      (render.entry sections.system { type = "uptime"; icon = "󰅐"; text = "Uptime"; prefix = "│ "; })
      (render.entry sections.system { type = "packages"; icon = "󰏖"; text = "Packages"; prefix = "│ "; })
      (render.rule sections.system "╰────────────────────────────────────────────────────────────────╯")

      # ---- HARDWARE ---- #
      (render.rule sections.hardware "╭─────────  HARDWARE ───────────────────────────────────────────╮")
      (render.entry sections.hardware {
        type = "cpu";
        icon = "";
        text = "CPU";
        prefix = "│ ";
        extra = {
          showPeCoreCount = true;
          temp = true;
        };
      })
      (render.entry sections.hardware { type = "gpu"; icon = "󰢮"; text = "GPU"; prefix = "│ "; })
      (render.entry sections.hardware {
        type = "memory";
        icon = "󰍛";
        text = "RAM";
        prefix = "│ ";
        extra = {
          format = "{used} / {total}";
        };
      })
      (render.entry sections.hardware { type = "swap"; icon = "󰓡"; text = "Swap"; prefix = "│ "; })
      (render.entry sections.hardware { type = "disk"; icon = ""; text = "Disk"; prefix = "│ "; })
      (render.rule sections.hardware "╰────────────────────────────────────────────────────────────────╯")

      # ---- DESKTOP ---- #
      (render.rule sections.desktop "╭───────── 󰉼 PLASMA / THEME ─────────────────────────────────────╮")
      (render.entry sections.desktop { type = "de"; icon = ""; text = "DE"; prefix = "│ "; })
      (render.entry sections.desktop { type = "theme"; icon = "󰉼"; text = "Theme"; prefix = "│ "; })
      (render.entry sections.desktop { type = "icons"; icon = "󰀻"; text = "Icons"; prefix = "│ "; })
      (render.entry sections.desktop { type = "font"; icon = ""; text = "Font"; prefix = "│ "; })
      (render.entry sections.desktop { type = "cursor"; icon = "󰇀"; text = "Cursor"; prefix = "│ "; })
      (render.rule sections.desktop "╰────────────────────────────────────────────────────────────────╯")

      # ---- TERMINAL ---- #
      (render.rule sections.terminal "╭─────────  TERMINAL / SHELL ───────────────────────────────────╮")
      (render.entry sections.terminal { type = "shell"; icon = ""; text = "Shell"; prefix = "│ "; })
      (render.entry sections.terminal { type = "editor"; icon = ""; text = "Editor"; prefix = "│ "; })
      (render.entry sections.terminal { type = "terminal"; icon = ""; text = "Terminal"; prefix = "│ "; })
      (render.entry sections.terminal { type = "terminalfont"; icon = ""; text = "Term Font"; prefix = "│ "; })
      (render.entry sections.terminal { type = "terminalsize"; icon = ""; text = "Term Size"; prefix = "│ "; })
      (render.entry sections.terminal {
        type = "command";
        icon = "";
        text = "Cwd";
        prefix = "│ ";
        extra = {
          text = "{1}";
          shell = "/bin/sh";
          param = "-c";
          cmd = "pwd";
        };
      })
      (render.rule sections.terminal "╰────────────────────────────────────────────────────────────────╯")

      # ---- STATE ---- #
      (render.rule sections.state "╭─────────  STATE ──────────────────────────────────────────────╮")
      (render.entry sections.state { type = "loadavg"; icon = "󰓅"; text = "Load Avg"; prefix = "│ "; })
      (render.entry sections.state { type = "processes"; icon = ""; text = "Processes"; prefix = "│ "; })
      (render.entry sections.state { type = "datetime"; icon = "󰃰"; text = "Date"; prefix = "│ "; })
      (render.entry sections.state { type = "locale"; icon = "󰗊"; text = "Locale"; prefix = "│ "; })
      (render.rule sections.state "╰────────────────────────────────────────────────────────────────╯")

      "break"
      "colors"
    ];
  };
in
{
  # Only the layout fastfetch.nix selected writes the configuration file.
  config = lib.mkIf (fastfetchCfg.enable && fastfetchCfg.layout == "linux") {
    xdg.configFile."fastfetch/config.jsonc".text = builtins.toJSON fastfetchConfig;
  };
}
