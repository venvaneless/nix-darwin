# options/package-options/wezterm/default.nix
#
# =====================================================================
# OPTIONS: WEZTERM
#
# Declares WezTerm's shared Home Manager interface and renders its
# declarative values into Home Manager and the generated runtime Lua files.
# =====================================================================

{
  config,
  lib,
  pkgs,
  platforms,
  ...
}:

let
  cfg = config.shared.terminal.wezterm;
  superModifier = if platforms.isDarwin then "CMD" else "SUPER";
  keybindingModifiers =
    modifiers:
    let
      platformModifiers = map (
        modifier: if modifier == "SUPER" then superModifier else modifier
      ) modifiers;
    in
    if platformModifiers == [ ] then "NONE" else lib.concatStringsSep "|" platformModifiers;

  keybindingAction =
    action:
    lib.generators.mkLuaInline (
      if action == "openPersonalCommandPalette" then
        ''dofile(wezterm.config_dir .. "/personal/command_palette.lua").action''
      else if action == "activateCommandPalette" then
        "wezterm.action.ActivateCommandPalette"
      else if action == "copyClipboard" then
        ''wezterm.action.CopyTo("Clipboard")''
      else if action == "pasteClipboard" then
        ''wezterm.action.PasteFrom("Clipboard")''
      else if action == "quitApplication" then
        "wezterm.action.QuitApplication"
      else if action == "searchScrollback" then
        ''wezterm.action.Search({ CaseInSensitiveString = "" })''
      else if action == "clearScrollback" then
        ''wezterm.action.ClearScrollback("ScrollbackAndViewport")''
      else if action == "activateCopyMode" then
        "wezterm.action.ActivateCopyMode"
      else if action == "clearTypedCommand" then
        ''wezterm.action.SendKey({ key = "u", mods = "CTRL" })''
      else if action == "abortCommand" then
        ''wezterm.action.SendKey({ key = "c", mods = "CTRL" })''
      else if action == "smartCopyOrInterrupt" then
        ''
          wezterm.action_callback(function(window, pane)
              local selection = window:get_selection_text_for_pane(pane)

              if selection ~= "" then
                  window:perform_action(
                      wezterm.action.CopyTo("ClipboardAndPrimarySelection"),
                      pane
                  )
                  window:perform_action(wezterm.action.ClearSelection, pane)
              else
                  window:perform_action(
                      wezterm.action.SendKey({ key = "c", mods = "CTRL" }),
                      pane
                  )
              end
          end)
        ''
      else if action == "splitHorizontal" then
        ''wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" })''
      else if action == "splitVertical" then
        ''wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" })''
      else if action == "closeCurrentPane" then
        "wezterm.action.CloseCurrentPane({ confirm = false })"
      else if action == "focusPaneLeft" then
        ''wezterm.action.ActivatePaneDirection("Left")''
      else if action == "focusPaneRight" then
        ''wezterm.action.ActivatePaneDirection("Right")''
      else if action == "focusPaneUp" then
        ''wezterm.action.ActivatePaneDirection("Up")''
      else if action == "focusPaneDown" then
        ''wezterm.action.ActivatePaneDirection("Down")''
      else if action == "spawnTab" then
        ''wezterm.action.SpawnTab("CurrentPaneDomain")''
      else if action == "closeCurrentTab" then
        "wezterm.action.CloseCurrentTab({ confirm = false })"
      else if action == "nextTab" then
        "wezterm.action.ActivateTabRelative(1)"
      else if action == "increaseFontSize" then
        "wezterm.action.IncreaseFontSize"
      else if action == "decreaseFontSize" then
        "wezterm.action.DecreaseFontSize"
      else if action == "resetFontSize" then
        "wezterm.action.ResetFontSize"
      else
        throw "Unknown WezTerm keybinding action: ${action}"
    );

  enabledKeybindings = lib.mapAttrsToList (_: shortcut: {
    key = shortcut.key;
    mods = keybindingModifiers shortcut.modifiers;
    action = keybindingAction shortcut.action;
  }) (lib.filterAttrs (_: shortcut: shortcut.enable) cfg.keybindings.shortcuts);

  mouseBindings = lib.optionals cfg.mouse.openSelectionOrLink.enable [
    {
      event = {
        Up = {
          streak = cfg.mouse.openSelectionOrLink.streak;
          button = cfg.mouse.openSelectionOrLink.button;
        };
      };
      mods = keybindingModifiers cfg.mouse.openSelectionOrLink.modifiers;
      action = lib.generators.mkLuaInline ''
        wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor(
            ${builtins.toJSON cfg.mouse.openSelectionOrLink.selectionDestination}
        )
      '';
    }
  ];
in
{
  imports = [
    ./themes
    ./plugins
    ./personal
  ];

  options.shared.terminal.wezterm = {
    enable = lib.mkEnableOption "WezTerm terminal emulator";

    installOn = lib.mkOption {
      type = lib.types.attrsOf lib.types.bool;
      default = {
        darwin = true;
        linux = true;
      };
      description = "Platforms on which the shared WezTerm configuration is installed.";
    };

    keybindings = lib.mkOption {
      type = lib.types.submodule {
        options = {
          leader = lib.mkOption {
            type = lib.types.submodule {
              options = {
                key = lib.mkOption {
                  type = lib.types.str;
                  description = "Physical key used as the WezTerm leader.";
                };

                timeoutMilliseconds = lib.mkOption {
                  type = lib.types.ints.positive;
                  description = "Milliseconds in which a leader sequence must complete.";
                };
              };
            };
            default = { };
            description = "WezTerm leader-key settings.";
          };

          shortcuts = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule {
                options = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                    description = "Whether this shortcut is emitted into WezTerm's key table.";
                  };

                  key = lib.mkOption {
                    type = lib.types.str;
                    description = "WezTerm physical or logical key name.";
                  };

                  modifiers = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    description = "Platform-neutral modifier names, such as SUPER or CTRL.";
                  };

                  action = lib.mkOption {
                    type = lib.types.enum [
                      "openPersonalCommandPalette"
                      "activateCommandPalette"
                      "copyClipboard"
                      "pasteClipboard"
                      "quitApplication"
                      "searchScrollback"
                      "clearScrollback"
                      "activateCopyMode"
                      "clearTypedCommand"
                      "abortCommand"
                      "smartCopyOrInterrupt"
                      "splitHorizontal"
                      "splitVertical"
                      "closeCurrentPane"
                      "focusPaneLeft"
                      "focusPaneRight"
                      "focusPaneUp"
                      "focusPaneDown"
                      "spawnTab"
                      "closeCurrentTab"
                      "nextTab"
                      "increaseFontSize"
                      "decreaseFontSize"
                      "resetFontSize"
                    ];
                    description = "Semantic WezTerm action translated into Lua by this module.";
                  };

                  description = lib.mkOption {
                    type = lib.types.str;
                    description = "Human-readable purpose of this shortcut.";
                  };
                };
              }
            );
            default = { };
            description = "Named, typed WezTerm shortcuts.";
          };
        };
      };
      default = { };
      description = "WezTerm leader and shortcut settings.";
    };

    mouse = lib.mkOption {
      type = lib.types.submodule {
        options.openSelectionOrLink = lib.mkOption {
          type = lib.types.submodule {
            options = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Open the selected link or copy selected text on mouse release.";
              };

              button = lib.mkOption {
                type = lib.types.str;
                description = "Mouse button that triggers the selection action.";
              };

              streak = lib.mkOption {
                type = lib.types.ints.positive;
                description = "Required consecutive click count.";
              };

              modifiers = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Platform-neutral modifiers required by the mouse action.";
              };

              selectionDestination = lib.mkOption {
                type = lib.types.str;
                description = "WezTerm selection destination used by the action.";
              };
            };
          };
          default = { };
          description = "Mouse-release behavior for selections and links.";
        };
      };
      default = { };
      description = "Semantic WezTerm mouse bindings.";
    };

    ssh = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "WezTerm SSH and remote-program settings.";
    };

    runtime = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "WezTerm runtime behavior settings.";
    };

    windows = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "WezTerm window appearance and frame settings.";
    };

    startup = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Initial WezTerm window dimensions.";
    };

    font = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "WezTerm terminal font settings.";
    };

    cursor = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "WezTerm cursor settings.";
    };

    tabs = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "WezTerm built-in tab bar settings.";
    };

    scrollbar = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "WezTerm scrollbar settings.";
    };

  };

  config = lib.mkIf (cfg.enable && platforms.enabledForCurrentPlatform cfg) {
    assertions = [
      {
        assertion = cfg.themes.default == "none" || lib.elem cfg.themes.default cfg.themes.list;
        message = ''
          shared.terminal.wezterm.themes.default is "${cfg.themes.default}",
          which is not one of: ${lib.concatStringsSep ", " cfg.themes.list}
        '';
      }
      {
        assertion = cfg.themes.default == "none" || lib.hasAttr cfg.themes.default cfg.themes;
        message = ''
          shared.terminal.wezterm.themes.default is "${cfg.themes.default}",
          but no palette settings were declared for it.
        '';
      }
    ];

    programs.wezterm = {
      enable = true;
      package = pkgs.wezterm;

      settings = cfg.ssh // {
        mouse_bindings = mouseBindings;
        scrollback_lines = cfg.runtime.scrollbackLines;
        debug_key_events = cfg.runtime.debugKeyEvents;
        notification_handling = cfg.runtime.notificationHandling;
        window_close_confirmation = cfg.windows.closeConfirmation;
        window_decorations = cfg.windows.decorations;
        window_background_opacity = cfg.windows.backgroundOpacity;
        macos_window_background_blur = cfg.windows.macosBackgroundBlur;
        window_padding = cfg.windows.padding;
        initial_cols = cfg.startup.columns;
        initial_rows = cfg.startup.rows;
        font = lib.generators.mkLuaInline ''
          wezterm.font(${builtins.toJSON cfg.font.family})
        '';
        font_size = cfg.font.size;
        line_height = cfg.font.lineHeight;
        default_cursor_style = cfg.cursor.style;
        cursor_thickness = cfg.cursor.thickness;
        cursor_blink_rate = cfg.cursor.blinkRate;
        force_reverse_video_cursor = cfg.cursor.forceReverseVideo;
        animation_fps = cfg.cursor.animationFps;
        integrated_title_button_alignment = cfg.windows.titleButtonAlignment;
        integrated_title_buttons = cfg.windows.titleButtons;
        window_frame = {
          font = lib.generators.mkLuaInline ''
            wezterm.font({
              family = ${builtins.toJSON cfg.windows.frame.fontFamily},
              weight = ${builtins.toJSON cfg.windows.frame.fontWeight},
            })
          '';
          font_size = cfg.windows.frame.fontSize;
        };
        enable_tab_bar = cfg.tabs.enable;
        use_fancy_tab_bar = cfg.tabs.fancy;
        tab_bar_at_bottom = cfg.tabs.atBottom;
        hide_tab_bar_if_only_one_tab = cfg.tabs.hideWhenSingle;
        show_new_tab_button_in_tab_bar = cfg.tabs.showNewTabButton;
        show_tab_index_in_tab_bar = cfg.tabs.showIndex;
        tab_max_width = cfg.tabs.maximumWidth;
        enable_scroll_bar = cfg.scrollbar.enable;
        leader = {
          key = cfg.keybindings.leader.key;
          timeout_milliseconds = cfg.keybindings.leader.timeoutMilliseconds;
        };
        keys = enabledKeybindings;
      };

      extraConfig = ''
        ${lib.optionalString (cfg.themes.default != "none") ''
          local theme = dofile(wezterm.config_dir .. "/themes/${cfg.themes.default}.lua")
          theme.apply(config)
        ''}

        local plugins = dofile(wezterm.config_dir .. "/plugins/plugins.lua")
        plugins.apply(config)

        ${lib.concatMapStringsSep "\n\n" (module: ''
          local ${module} = dofile(wezterm.config_dir .. "/personal/${module}.lua")
          ${module}.apply(config)
        '') cfg.personal.modules}
      '';
    };

    home.file.".config/wezterm/plugins/plugins.lua".text = ''
      -- options/package-options/wezterm/plugins/plugins.lua
      local wezterm = require("wezterm")
      local M = {}
      local plugin_modules = ${lib.generators.toLua { } cfg.plugins.modules}

      function M.apply(config)
          wezterm.log_info("plugins.apply() called")
          for _, plugin_name in ipairs(plugin_modules) do
              wezterm.log_info("Loading plugin module: " .. plugin_name)
              local ok, plugin = pcall(dofile, wezterm.config_dir .. "/plugins/" .. plugin_name .. ".lua")
              if ok and plugin and type(plugin.apply) == "function" then
                  local ok_apply, err = pcall(plugin.apply, config)
                  if ok_apply then
                      wezterm.log_info("Applied plugin module: " .. plugin_name)
                  else
                      wezterm.log_error("Failed while applying plugin " .. plugin_name .. ": " .. tostring(err))
                  end
              else
                  wezterm.log_error("Failed to load plugin module: " .. plugin_name .. " :: " .. tostring(plugin))
              end
          end
      end
      return M
    '';
  };
}
