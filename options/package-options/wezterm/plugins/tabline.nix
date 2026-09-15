# options/package-options/wezterm/plugins/tabline.nix
#
# Embedded Lua source generated into .config/wezterm/plugins/tabline.lua.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.shared.terminal.wezterm;
  tablineCfg = cfg.plugins.tabline;

  paddingOptions = component: {
    left = lib.mkOption {
      type = lib.types.int;
      description = "Left padding for the ${component} component.";
    };

    right = lib.mkOption {
      type = lib.types.int;
      description = "Right padding for the ${component} component.";
    };
  };

  separatorOptions = position: {
    left = lib.mkOption {
      type = lib.types.str;
      description = "Left ${position} separator.";
    };

    right = lib.mkOption {
      type = lib.types.str;
      description = "Right ${position} separator.";
    };
  };

  tabColorOptions = state: {
    fg = lib.mkOption {
      type = lib.types.str;
      description = "${state} tab foreground color.";
    };

    bg = lib.mkOption {
      type = lib.types.str;
      description = "${state} tab background color.";
    };
  };

  paletteRoleOptions = component: {
    foreground = lib.mkOption {
      type = lib.types.str;
      description = "Palette role used for the ${component} foreground.";
    };

    background = lib.mkOption {
      type = lib.types.str;
      description = "Palette role used for the ${component} background.";
    };
  };

  processIcons = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (process: icon: ''
      [${builtins.toJSON process}] = wezterm.nerdfonts[${builtins.toJSON icon}],
    '') tablineCfg.processIcons
  );

  luaConfig = pkgs.writeText "tabline.lua" /* lua */ ''
        -- options/package-options/wezterm/plugins/tabline.lua

        local wezterm = require("wezterm")
        local tabline = wezterm.plugin.require(${builtins.toJSON tablineCfg.url})

        local colors = ${lib.generators.toLua { multiline = true; } tablineCfg.colors}
        local palette = ${lib.generators.toLua { multiline = true; } tablineCfg.palette}
        local section_colors = ${lib.generators.toLua { multiline = true; } tablineCfg.sectionColors}
        local process_to_icon = {
    ${processIcons}    }

        local M = {}

        function M.apply(config)
            tabline.setup({
                options = {
                    theme = ${builtins.toJSON tablineCfg.theme},
                    icons_enabled = ${if tablineCfg.iconsEnabled then "true" else "false"},
                    tabs_enabled = ${if tablineCfg.tabsEnabled then "true" else "false"},

                    theme_overrides = {
                        tab = {
                            active = { fg = colors.active.fg, bg = colors.active.bg },
                            inactive = { fg = colors.inactive.fg, bg = colors.inactive.bg },
                            inactive_hover = { fg = colors.inactiveHover.fg, bg = colors.inactiveHover.bg },
                        },
                    },

                    section_separators = ${lib.generators.toLua { } tablineCfg.sectionSeparators},
                    component_separators = ${lib.generators.toLua { } tablineCfg.componentSeparators},
                    tab_separators = ${lib.generators.toLua { } tablineCfg.tabSeparators},
                },

                sections = {
                    tabline_a = {},
                    tabline_b = {},
                    tabline_c = {},

                    tab_active = {
                        {
                            "cwd",
                            padding = ${lib.generators.toLua { } tablineCfg.cwd.padding},
                            max_length = ${toString tablineCfg.cwd.maximumLength},
                        },
                        {
                            "process",
                            padding = ${lib.generators.toLua { } tablineCfg.process.padding},
                            process_to_icon = process_to_icon,
                        },

                        { Foreground = { Color = palette[section_colors.tab_active.divider.foreground] } },
                        { Background = { Color = palette[section_colors.tab_active.divider.background] } },
                        { Text = wezterm.nerdfonts.pl_left_hard_divider },
                    },

                    tab_inactive = {
                        {
                            "cwd",
                            padding = ${lib.generators.toLua { } tablineCfg.cwd.padding},
                            max_length = ${toString tablineCfg.cwd.maximumLength},
                        },
                    },

                    tabline_x = {
                        { Foreground = { Color = palette[section_colors.tabline_x.divider.foreground] } },
                        { Background = { Color = palette[section_colors.tabline_x.divider.background] } },
                        { Text = wezterm.nerdfonts.pl_right_hard_divider },

                        { Foreground = { Color = palette[section_colors.tabline_x.content.foreground] } },
                        { Background = { Color = palette[section_colors.tabline_x.content.background] } },

                        {
                            "hostname",
                            padding = ${lib.generators.toLua { } tablineCfg.hostname.padding},
                        },
                    },

                    tabline_y = {
                        { Foreground = { Color = palette[section_colors.tabline_y.divider.foreground] } },
                        { Background = { Color = palette[section_colors.tabline_y.divider.background] } },
                        { Text = wezterm.nerdfonts.pl_right_hard_divider },

                        { Foreground = { Color = palette[section_colors.tabline_y.content.foreground] } },
                        { Background = { Color = palette[section_colors.tabline_y.content.background] } },

                        {
                            "datetime",
                            padding = ${lib.generators.toLua { } tablineCfg.datetime.padding},
                        },
                    },

                    tabline_z = {
                        { Foreground = { Color = palette[section_colors.tabline_z.divider.foreground] } },
                        { Background = { Color = palette[section_colors.tabline_z.divider.background] } },
                        { Text = wezterm.nerdfonts.pl_right_hard_divider },

                        { Foreground = { Color = palette[section_colors.tabline_z.content.foreground] } },
                        { Background = { Color = palette[section_colors.tabline_z.content.background] } },

                        {
                            "battery",
                            padding = ${lib.generators.toLua { } tablineCfg.battery.padding},
                        },
                    },
                },

                extensions = {},
            })

            config.enable_tab_bar = ${if tablineCfg.window.enableTabBar then "true" else "false"}
            config.use_fancy_tab_bar = ${if tablineCfg.window.fancyTabBar then "true" else "false"}
            config.tab_bar_at_bottom = ${if tablineCfg.window.atBottom then "true" else "false"}
            config.tab_max_width = ${toString tablineCfg.window.maximumWidth}

            config.colors = config.colors or {}
            config.colors.tab_bar = config.colors.tab_bar or {}
            config.colors.tab_bar.background = palette[section_colors.background]
        end

        return M
  '';
in
{
  options.shared.terminal.wezterm.plugins.tabline = {
    url = lib.mkOption {
      type = lib.types.str;
      description = "Git URL for the tabline.wez plugin.";
    };

    theme = lib.mkOption {
      type = lib.types.str;
      description = "Tabline theme name supplied to the plugin.";
    };

    iconsEnabled = lib.mkOption {
      type = lib.types.bool;
      description = "Show icons in the tabline.";
    };

    tabsEnabled = lib.mkOption {
      type = lib.types.bool;
      description = "Show tabs in the tabline.";
    };

    cwd = {
      padding = paddingOptions "current-directory";

      maximumLength = lib.mkOption {
        type = lib.types.ints.positive;
        description = "Maximum displayed length of a current directory.";
      };
    };

    process.padding = paddingOptions "active process";

    processIcons = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "Process names mapped to WezTerm Nerd Font icon names.";
    };

    hostname.padding = paddingOptions "hostname";

    datetime.padding = paddingOptions "date and time";

    battery.padding = paddingOptions "battery";

    window = {
      enableTabBar = lib.mkOption {
        type = lib.types.bool;
        description = "Enable WezTerm's tab bar.";
      };

      fancyTabBar = lib.mkOption {
        type = lib.types.bool;
        description = "Use WezTerm's built-in fancy tab bar.";
      };

      atBottom = lib.mkOption {
        type = lib.types.bool;
        description = "Place the tab bar at the bottom of the window.";
      };

      maximumWidth = lib.mkOption {
        type = lib.types.ints.positive;
        description = "Maximum width of an individual tab.";
      };
    };

    sectionSeparators = separatorOptions "section";

    componentSeparators = separatorOptions "component";

    tabSeparators = separatorOptions "tab";

    colors = {
      active = tabColorOptions "Active";
      inactive = tabColorOptions "Inactive";
      inactiveHover = tabColorOptions "Hovered inactive";
    };

    sectionColors = {
      background = lib.mkOption {
        type = lib.types.str;
        description = "Palette role used for the tab bar background.";
      };

      tabActive.divider = paletteRoleOptions "active-tab divider";

      tablineX = {
        divider = paletteRoleOptions "hostname divider";
        content = paletteRoleOptions "hostname";
      };

      tablineY = {
        divider = paletteRoleOptions "date and time divider";
        content = paletteRoleOptions "date and time";
      };

      tablineZ = {
        divider = paletteRoleOptions "battery divider";
        content = paletteRoleOptions "battery";
      };
    };

    palette = {
      bg0 = lib.mkOption {
        type = lib.types.str;
        description = "Primary tabline background color.";
      };
      bg1 = lib.mkOption {
        type = lib.types.str;
        description = "Secondary tabline background color.";
      };
      bg2 = lib.mkOption {
        type = lib.types.str;
        description = "Hovered tabline background color.";
      };
      bg3 = lib.mkOption {
        type = lib.types.str;
        description = "Muted tabline background color.";
      };
      fg0 = lib.mkOption {
        type = lib.types.str;
        description = "Brightest tabline foreground color.";
      };
      fg1 = lib.mkOption {
        type = lib.types.str;
        description = "Primary tabline foreground color.";
      };
      gray = lib.mkOption {
        type = lib.types.str;
        description = "Muted tabline foreground color.";
      };
      yellow = lib.mkOption {
        type = lib.types.str;
        description = "Yellow tabline accent color.";
      };
      orange = lib.mkOption {
        type = lib.types.str;
        description = "Orange tabline accent color.";
      };
      red = lib.mkOption {
        type = lib.types.str;
        description = "Red tabline accent color.";
      };
      aqua = lib.mkOption {
        type = lib.types.str;
        description = "Aqua tabline accent color.";
      };
      blue = lib.mkOption {
        type = lib.types.str;
        description = "Blue tabline accent color.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.file.".config/wezterm/plugins/tabline.lua".source = luaConfig;
  };
}
