# shared/terminal/wezterm/default.nix
#
# =====================================================================
# WEZTERM: SHARED TERMINAL EMULATOR CONFIGURATION
#
# This is the shared, user-facing knobs file. The option module owns all
# validation and Lua/Home Manager rendering.
# =====================================================================

{
  imports = [
    ./themes
    ./wez-personal.nix
    ./wez-plugins.nix
  ];

  config = {
    shared.terminal.wezterm = {
      enable = true;
      installOn = {
        darwin = true;
        linux = true;
      };

      themes = {
        list = [
          "gruvbox"
          "nord"
          "nord-otto"
          "otto"
        ];
        default = "gruvbox";
      };

      # ------------------------------------------------------------
      # Keyboard shortcuts
      # ------------------------------------------------------------
      keybindings = {
        leader = {
          key = "F14";
          timeoutMilliseconds = 1000;
        };

        shortcuts = {
          personalCommandPalette = {
            key = "phys:O";
            modifiers = [ "SUPER" "SHIFT" ];
            action = "openPersonalCommandPalette";
            description = "Open the personal command and directory picker.";
          };

          nativeCommandPalette = {
            key = "phys:P";
            modifiers = [ "SUPER" "SHIFT" ];
            action = "activateCommandPalette";
            description = "Open WezTerm's native command palette.";
          };

          commandPalette = {
            key = "Space";
            modifiers = [ "SHIFT" ];
            action = "activateCommandPalette";
            description = "Open WezTerm's native command palette.";
          };

          copy = {
            key = "c";
            modifiers = [ "CTRL" "SHIFT" ];
            action = "copyClipboard";
            description = "Copy the active selection to the clipboard.";
          };

          paste = {
            key = "v";
            modifiers = [ "CTRL" "SHIFT" ];
            action = "pasteClipboard";
            description = "Paste from the clipboard.";
          };

          quit = {
            key = "q";
            modifiers = [ "CTRL" "SHIFT" ];
            action = "quitApplication";
            description = "Quit WezTerm.";
          };

          searchScrollback = {
            key = "f";
            modifiers = [ "CTRL" ];
            action = "searchScrollback";
            description = "Search the current pane's scrollback.";
          };

          clearScrollback = {
            key = "d";
            modifiers = [ "CTRL" ];
            action = "clearScrollback";
            description = "Clear the active pane's scrollback and viewport.";
          };

          copyMode = {
            key = "Enter";
            modifiers = [ "CTRL" "SHIFT" ];
            action = "activateCopyMode";
            description = "Enter keyboard-driven copy mode.";
          };

          clearTypedCommand = {
            key = "c";
            modifiers = [ "CTRL" ];
            action = "clearTypedCommand";
            description = "Send Ctrl+U to clear the typed shell command.";
          };

          abortCommand = {
            key = "h";
            modifiers = [ "CTRL" ];
            action = "abortCommand";
            description = "Send Ctrl+C to interrupt the active command.";
          };

          smartCopyOrInterrupt = {
            key = "u";
            modifiers = [ "SUPER" ];
            action = "smartCopyOrInterrupt";
            description = "Copy a selection, or send Ctrl+C when none exists.";
          };

          splitHorizontal = {
            key = "phys:Comma";
            modifiers = [ "CTRL" "SHIFT" ];
            action = "splitHorizontal";
            description = "Split the current pane side by side.";
          };

          splitVertical = {
            key = "phys:Period";
            modifiers = [ "CTRL" "SHIFT" ];
            action = "splitVertical";
            description = "Split the current pane above and below.";
          };

          closePane = {
            key = "x";
            modifiers = [ "CTRL" "SHIFT" ];
            action = "closeCurrentPane";
            description = "Close the active pane without confirmation.";
          };

          focusPaneLeft = {
            key = "LeftArrow";
            modifiers = [ "CTRL" "SHIFT" ];
            action = "focusPaneLeft";
            description = "Move focus to the pane on the left.";
          };

          focusPaneRight = {
            key = "RightArrow";
            modifiers = [ "CTRL" "SHIFT" ];
            action = "focusPaneRight";
            description = "Move focus to the pane on the right.";
          };

          focusPaneUp = {
            key = "UpArrow";
            modifiers = [ "CTRL" "SHIFT" ];
            action = "focusPaneUp";
            description = "Move focus to the pane above.";
          };

          focusPaneDown = {
            key = "DownArrow";
            modifiers = [ "CTRL" "SHIFT" ];
            action = "focusPaneDown";
            description = "Move focus to the pane below.";
          };

          newTab = {
            key = "n";
            modifiers = [ "CTRL" "SHIFT" ];
            action = "spawnTab";
            description = "Open a tab in the active pane's domain.";
          };

          closeTab = {
            key = "w";
            modifiers = [ "CTRL" ];
            action = "closeCurrentTab";
            description = "Close the active tab without confirmation.";
          };

          nextTab = {
            key = "t";
            modifiers = [ "CTRL" "SHIFT" ];
            action = "nextTab";
            description = "Activate the next tab.";
          };

          increaseFontSize = {
            key = "Add";
            modifiers = [ "CTRL" "SHIFT" ];
            action = "increaseFontSize";
            description = "Increase the terminal font size.";
          };

          decreaseFontSize = {
            key = "Subtract";
            modifiers = [ "CTRL" "SHIFT" ];
            action = "decreaseFontSize";
            description = "Decrease the terminal font size.";
          };

          resetFontSize = {
            key = "0";
            modifiers = [ "CTRL" ];
            action = "resetFontSize";
            description = "Restore the configured terminal font size.";
          };
        };
      };

      windows = {
        closeConfirmation = "NeverPrompt";
        decorations = "INTEGRATED_BUTTONS|RESIZE";
        backgroundOpacity = 0.90;
        macosBackgroundBlur = 20;
        padding = {
          left = "1cell";
          right = "1cell";
          top = "1.2cell";
          bottom = "0.6cell";
        };
        frame = {
          fontFamily = "JetBrainsMono Nerd Font";
          fontWeight = "Bold";
          fontSize = 13.0;
        };
        titleButtonAlignment = "Left";
        titleButtons = [
          "Hide"
          "Maximize"
          "Close"
        ];
      };
      startup = {
        columns = 95;
        rows = 30;
      };
      font = {
        family = "JetBrainsMono Nerd Font";
        size = 13.0;
        lineHeight = 1.5;
      };
      cursor = {
        style = "SteadyBar";
        thickness = "1pt";
        blinkRate = 800;
        forceReverseVideo = false;
        animationFps = 80;
      };
      tabs = {
        enable = true;
        fancy = false;
        atBottom = true;
        hideWhenSingle = false;
        showNewTabButton = false;
        showIndex = false;
        maximumWidth = 28;
      };
      scrollbar.enable = true;
      mouse.openSelectionOrLink = {
        enable = true;
        button = "Left";
        streak = 1;
        modifiers = [ ];
        selectionDestination = "ClipboardAndPrimarySelection";
      };

      ssh = { };
      runtime = {
        scrollbackLines = 100000;
        debugKeyEvents = true;
        notificationHandling = "AlwaysShow";
      };
    };
  };
}
