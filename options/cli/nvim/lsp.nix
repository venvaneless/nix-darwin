# options/cli/nvim/lsp.nix
#
# =====================================================================
# OPTIONS: NEOVIM LSP
#
# Declares the language server knobs and writes their Lua file.
# =====================================================================

{ config, lib, ... }:

let
  lua = import ./lua.nix { inherit lib; };

  cfg = config.home.shared.terminal.nvim;
  lsp = cfg.lsp;
in
{
  options.home.shared.terminal.nvim.lsp = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Configure AstroLSP and its language servers.";
    };

    relativePath = lib.mkOption {
      type = lib.types.str;
      default = "nvim/lua/plugins/lsp.lua";
      description = "Config-relative Lua file these knobs are written to.";
    };

    servers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = lib.literalExpression ''[ "nixd" "lua_ls" ]'';
      description = "Language servers AstroLSP starts, in the order given.";
    };

    serverSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      example = lib.literalExpression ''{ yamlls.settings.yaml.keyOrdering = false; }'';
      description = "Per-server settings rendered into AstroLSP's config table.";
    };
  };

  config = lib.mkIf (cfg.enable && lsp.enable) {
    xdg.configFile.${lsp.relativePath}.text = lua.renderSpecs [
      {
        __positional = [ "AstroNvim/astrolsp" ];

        opts = {
          servers = lsp.servers;
          config = lsp.serverSettings;
        };
      }
    ];
  };
}
