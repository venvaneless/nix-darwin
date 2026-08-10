# shared/terminal/wezterm/wez-keybindings.nix
#
# =====================================================================
# WEZTERM: KEY BINDINGS
#
# Nix equivalent of keybindings.lua.
#
# Every binding below carries a title line and a description line, so
# that the purpose of each command is readable without cross checking
# the WezTerm documentation.
#
# The platform modifiers mirror personal/platform.lua exactly:
# `super` is Command on macOS and Super on Linux, while
# `terminalMod` is CTRL|SHIFT on both platforms.
#
# Bindings added at runtime live elsewhere and are listed here for
# reference only:
#
#   personal/context_palette.lua    super + Shift + P
#   personal/save_scrollback.lua    super + Shift + S
#   personal/replace_tab.lua        super + Shift + T
#   plugins/resurrect.lua           Alt + w / W / T / S / R
#   wezterm-sessions plugin         Alt + s / l / r / a / f
#                                   Ctrl + Shift + d / e
#   smart_workspace_switcher        LEADER + s / S
# =====================================================================

{ lib, pkgs, ... }:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # ---- PLATFORM MODIFIERS ---- #
  # Command on macOS, Super/Windows key on Linux.
  super =
    if isDarwin
    then "CMD"
    else "SUPER";

  # Shared terminal modifier, identical on both platforms.
  terminalMod = "CTRL|SHIFT";

in
{
  # ---- LEADER KEY ---- #
  #
  # What a leader is
  # ------------------------------------------------------------
  # A leader is a prefix key rather than part of a chord. Press it,
  # release it, then press the next key within the timeout below.
  # LEADER+s therefore means two separate presses, not one combination.
  # It gives a whole namespace of shortcuts without consuming further
  # modifier combinations.
  #
  # Why F14 and not Caps Lock
  # ------------------------------------------------------------
  # Caps Lock cannot be bound directly on either platform, because the
  # operating system consumes it as a lock toggle and never delivers a
  # key press to the application. The working approach is to remap it
  # at the OS level to a key nothing else claims, and bind that:
  #
  #   macOS  Karabiner-Elements, Caps Lock -> F14
  #   Linux  keyd, Caps Lock -> F14
  #
  # keyd works at the kernel level, so it applies under Wayland as
  # well as X11.
  #
  # F14 rather than F13, because F13 is used for screenshots.
  #
  # Shift cannot be used as a leader: modifiers do not generate key
  # presses of their own, and if it could bind, every capital letter
  # would trigger it.
  #
  # Until the remap is in place the leader is simply unreachable, and
  # only the workspace switcher bindings are affected.
  leader = {
    key = "F14";
    timeout_milliseconds = 1000;
  };

  keys = [
    # =================================================================
    # STANDARD KEYS
    # =================================================================

    {
      # Open command palette
      # Opens WezTerm's built in command palette, listing every
      # available action with its shortcut.
      key = "Space";
      mods = "SHIFT";

      action = lib.generators.mkLuaInline ''
        wezterm.action.ActivateCommandPalette
      '';
    }

    {
      # Copy selection
      # Copies the current selection to the system clipboard.
      key = "c";
      mods = terminalMod;

      action = lib.generators.mkLuaInline ''
        wezterm.action.CopyTo("Clipboard")
      '';
    }

    {
      # Paste
      # Inserts the system clipboard contents at the cursor.
      key = "v";
      mods = terminalMod;

      action = lib.generators.mkLuaInline ''
        wezterm.action.PasteFrom("Clipboard")
      '';
    }

    {
      # Quit WezTerm
      # Closes every window and exits the application.
      key = "q";
      mods = terminalMod;

      action = lib.generators.mkLuaInline ''
        wezterm.action.QuitApplication
      '';
    }


    # =================================================================
    # SCROLLBACK
    # =================================================================

    {
      # Search scrollback
      # Opens the search overlay for the current pane, starting with an
      # empty case insensitive pattern.
      key = "f";
      mods = "CTRL";

      action = lib.generators.mkLuaInline ''
        wezterm.action.Search({
            CaseInSensitiveString = "",
        })
      '';
    }

    {
      # Clear scrollback
      # Discards the visible viewport and the retained scrollback of
      # the active pane. Ctrl + D on both platforms.
      key = "d";
      mods = "CTRL";

      action = lib.generators.mkLuaInline ''
        wezterm.action.ClearScrollback("ScrollbackAndViewport")
      '';
    }

    {
      # Enter copy mode
      # Switches to keyboard driven selection of scrollback text.
      key = "Enter";
      mods = terminalMod;

      action = lib.generators.mkLuaInline ''
        wezterm.action.ActivateCopyMode
      '';
    }


    # =================================================================
    # COMMAND LINE
    # =================================================================

    {
      # Clear typed command
      # Sends Ctrl + U to the shell, which deletes the command
      # currently being typed without running it.
      key = "c";
      mods = "CTRL";

      action = lib.generators.mkLuaInline ''
        wezterm.action.SendKey({
            key = "u",
            mods = "CTRL",
        })
      '';
    }

    {
      # Abort command
      # Sends Ctrl + C to the shell, interrupting the running command
      # and returning to a fresh prompt.
      key = "h";
      mods = "CTRL";

      action = lib.generators.mkLuaInline ''
        wezterm.action.SendKey({
            key = "c",
            mods = "CTRL",
        })
      '';
    }

    {
      # Smart copy or interrupt
      # Copies the selection and clears it when text is selected,
      # otherwise sends Ctrl + C to interrupt. Command + U on macOS,
      # Super + U on Linux.
      key = "u";
      mods = super;

      action = lib.generators.mkLuaInline ''
        wezterm.action_callback(function(window, pane)
            local selection = window:get_selection_text_for_pane(pane)

            if selection ~= "" then
                window:perform_action(
                    wezterm.action.CopyTo("ClipboardAndPrimarySelection"),
                    pane
                )

                window:perform_action(
                    wezterm.action.ClearSelection,
                    pane
                )
            else
                window:perform_action(
                    wezterm.action.SendKey({
                        key = "c",
                        mods = "CTRL",
                    }),
                    pane
                )
            end
        end)
      '';
    }


    # =================================================================
    # PANES
    # =================================================================

    {
      # Split horizontally
      # Splits the active pane side by side, keeping the current
      # working directory and domain.
      key = "phys:Comma";
      mods = terminalMod;

      action = lib.generators.mkLuaInline ''
        wezterm.action.SplitHorizontal({
            domain = "CurrentPaneDomain",
        })
      '';
    }

    {
      # Split vertically
      # Splits the active pane top and bottom, keeping the current
      # working directory and domain.
      key = "phys:Period";
      mods = terminalMod;

      action = lib.generators.mkLuaInline ''
        wezterm.action.SplitVertical({
            domain = "CurrentPaneDomain",
        })
      '';
    }

    {
      # Close pane
      # Closes the active pane immediately, without a confirmation
      # prompt.
      key = "x";
      mods = terminalMod;

      action = lib.generators.mkLuaInline ''
        wezterm.action.CloseCurrentPane({
            confirm = false,
        })
      '';
    }

    {
      # Focus pane left
      # Moves keyboard focus to the pane to the left of the active one.
      key = "LeftArrow";
      mods = terminalMod;

      action = lib.generators.mkLuaInline ''
        wezterm.action.ActivatePaneDirection("Left")
      '';
    }

    {
      # Focus pane right
      # Moves keyboard focus to the pane to the right of the active
      # one.
      key = "RightArrow";
      mods = terminalMod;

      action = lib.generators.mkLuaInline ''
        wezterm.action.ActivatePaneDirection("Right")
      '';
    }

    {
      # Focus pane up
      # Moves keyboard focus to the pane above the active one.
      key = "UpArrow";
      mods = terminalMod;

      action = lib.generators.mkLuaInline ''
        wezterm.action.ActivatePaneDirection("Up")
      '';
    }

    {
      # Focus pane down
      # Moves keyboard focus to the pane below the active one.
      key = "DownArrow";
      mods = terminalMod;

      action = lib.generators.mkLuaInline ''
        wezterm.action.ActivatePaneDirection("Down")
      '';
    }


    # =================================================================
    # TABS
    # =================================================================

    {
      # New tab
      # Opens a tab in the domain of the active pane.
      key = "n";
      mods = terminalMod;

      action = lib.generators.mkLuaInline ''
        wezterm.action.SpawnTab("CurrentPaneDomain")
      '';
    }

    {
      # Close tab
      # Closes the active tab and all of its panes, without a
      # confirmation prompt.
      key = "w";
      mods = "CTRL";

      action = lib.generators.mkLuaInline ''
        wezterm.action.CloseCurrentTab({
            confirm = false,
        })
      '';
    }

    {
      # Next tab
      # Cycles forward through the tab bar, wrapping at the end.
      key = "t";
      mods = terminalMod;

      action = lib.generators.mkLuaInline ''
        wezterm.action.ActivateTabRelative(1)
      '';
    }


    # =================================================================
    # UI / STYLE
    # =================================================================

    {
      # Increase font size
      # Steps the font size up. Bound to the numeric keypad plus key.
      key = "Add";
      mods = terminalMod;

      action = lib.generators.mkLuaInline ''
        wezterm.action.IncreaseFontSize
      '';
    }

    {
      # Decrease font size
      # Steps the font size down. Bound to the numeric keypad minus
      # key.
      key = "Subtract";
      mods = terminalMod;

      action = lib.generators.mkLuaInline ''
        wezterm.action.DecreaseFontSize
      '';
    }

    {
      # Reset font size
      # Returns the font size to the value set in wez-appearance.nix.
      key = "0";
      mods = "CTRL";

      action = lib.generators.mkLuaInline ''
        wezterm.action.ResetFontSize
      '';
    }
  ];
}
