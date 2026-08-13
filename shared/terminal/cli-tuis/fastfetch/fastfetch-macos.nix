# shared/terminal/cli-tuis/fastfetch/fastfetch-macos.nix
#
# =====================================================================
# FASTFETCH: MACOS LAYOUT
#
# - Selected in fastfetch.nix with selectedLayout.<platform> = "macos"
# - Writes fastfetch's config.jsonc when it is the selected layout
#
# Flat section rules. No graphics row: on Apple Silicon the GPU sits on
# the same chip the CPU row already names. No desktop section either,
# since macOS has no themeable icon, cursor, or widget packs to report.
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
      (render.rule sections.system "────────────────────────────────  SYSTEM ──────────────────────────────────")
      (render.entry sections.system { type = "os"; icon = "󰣇"; text = "OS"; })
      (render.entry sections.system { type = "host"; icon = "󰌢"; text = "Host"; })
      (render.entry sections.system { type = "kernel"; icon = ""; text = "Kernel"; })
      (render.entry sections.system { type = "uptime"; icon = "󰅐"; text = "Uptime"; })
      (render.entry sections.system { type = "packages"; icon = "󰏖"; text = "Packages"; })
      render.blank

      # ---- HARDWARE ---- #
      (render.rule sections.hardware "───────────────────────────────  HARDWARE ─────────────────────────────────")
      (render.entry sections.hardware {
        type = "cpu";
        icon = "";
        text = "CPU";
        extra = {
          showPeCoreCount = true;
          temp = true;
        };
      })
      (render.entry sections.hardware {
        type = "memory";
        icon = "󰍛";
        text = "RAM";
        extra = {
          format = "{used} / {total}";
        };
      })
      (render.entry sections.hardware { type = "swap"; icon = "󰓡"; text = "Swap"; })
      (render.entry sections.hardware { type = "disk"; icon = ""; text = "Disk"; })
      render.blank

      # ---- TERMINAL ---- #
      (render.rule sections.terminal "───────────────────────────────  TERMINAL / SHELL ──────────────────────────")
      (render.entry sections.terminal { type = "shell"; icon = ""; text = "Shell"; })
      (render.entry sections.terminal { type = "editor"; icon = ""; text = "Editor"; })
      (render.entry sections.terminal { type = "terminal"; icon = ""; text = "Terminal"; })
      (render.entry sections.terminal { type = "terminalfont"; icon = ""; text = "Term Font"; })
      (render.entry sections.terminal { type = "terminalsize"; icon = ""; text = "Term Size"; })
      (render.entry sections.terminal {
        type = "command";
        icon = "";
        text = "Cwd";
        extra = {
          text = "{1}";
          shell = "/bin/sh";
          param = "-c";
          cmd = "pwd";
        };
      })
      render.blank

      # ---- STATE ---- #
      (render.rule sections.state "────────────────────────────────  STATE ─────────────────────────────────────")
      (render.entry sections.state { type = "loadavg"; icon = "󰓅"; text = "Load Avg"; })
      (render.entry sections.state { type = "processes"; icon = ""; text = "Processes"; })
      (render.entry sections.state { type = "datetime"; icon = "󰃰"; text = "Date"; })
      (render.entry sections.state { type = "locale"; icon = "󰗊"; text = "Locale"; })
      render.blank

      "break"
      "colors"
    ];
  };
in
{
  # Only the layout fastfetch.nix selected writes the configuration file.
  config = lib.mkIf (fastfetchCfg.enable && fastfetchCfg.layout == "macos") {
    xdg.configFile."fastfetch/config.jsonc".text = builtins.toJSON fastfetchConfig;
  };
}
