# options/cli/nvim/keys.nix
#
# =====================================================================
# OPTIONS: NEOVIM KEYBINDINGS
#
# Writes the mapping file from the keybinding knobs.
# =====================================================================

{ config, lib, ... }:

let
  lua = import ./lua.nix { inherit lib; };

  cfg = config.home.shared.terminal.nvim;
  keys = cfg.keys;

  bindingType = lib.types.submodule {
    options = {
      key = lib.mkOption {
        type = lib.types.str;
        example = "<Leader>e";
        description = "Key sequence this mapping binds.";
      };

      command = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "<cmd>w<cr>";
        description = "Command the key runs. Use lua instead for a function body.";
      };

      lua = lib.mkOption {
        type = lib.types.nullOr lib.types.lines;
        default = null;
        description = "Lua function body the key runs, when a command is not enough.";
      };

      description = lib.mkOption {
        type = lib.types.str;
        description = "What the mapping does, shown in which-key.";
      };
    };
  };

  # An AstroNvim mapping is a table whose first entry is the action.
  renderBinding = binding: {
    __positional = [
      (
        if binding.command != null then
          binding.command
        else
          lua.raw ''
            function()
              ${binding.lua}
            end
          ''
      )
    ];

    desc = binding.description;
  };

  mappingsFor = bindings:
    lib.listToAttrs (
      map (binding: lib.nameValuePair binding.key (renderBinding binding)) (lib.attrValues bindings)
    );

  mappings =
    lib.optionalAttrs (keys.normal != { }) { n = mappingsFor keys.normal; }
    // lib.optionalAttrs (keys.insert != { }) { i = mappingsFor keys.insert; }
    // lib.optionalAttrs (keys.visual != { }) { v = mappingsFor keys.visual; }
    // lib.optionalAttrs (keys.terminal != { }) { t = mappingsFor keys.terminal; };
in
{
  options.home.shared.terminal.nvim.keys = {
    relativePath = lib.mkOption {
      type = lib.types.str;
      default = "nvim/lua/plugins/keyboard.lua";
      description = "Config-relative Lua file these mappings are written to.";
    };

    normal = lib.mkOption {
      type = lib.types.attrsOf bindingType;
      default = { };
      description = "Normal-mode mappings.";
    };

    insert = lib.mkOption {
      type = lib.types.attrsOf bindingType;
      default = { };
      description = "Insert-mode mappings.";
    };

    visual = lib.mkOption {
      type = lib.types.attrsOf bindingType;
      default = { };
      description = "Visual-mode mappings.";
    };

    terminal = lib.mkOption {
      type = lib.types.attrsOf bindingType;
      default = { };
      description = "Terminal-mode mappings.";
    };

    toggleLineBlame = lib.mkOption {
      type = lib.types.str;
      default = "<Leader>gb";
      description = "Key that toggles the Gitsigns inline blame text.";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile.${keys.relativePath}.text = lua.renderSpecs [
      {
        __positional = [ "AstroNvim/astrocore" ];

        opts.mappings = mappings;
      }
    ];
  };
}
