# options/cli/nvim/projects.nix
#
# =====================================================================
# OPTIONS: NEOVIM PROJECTS
#
# Declares the project switching knobs and writes their Lua file.
# Picking a project saves the current dirsession, changes directory,
# then restores that project's dirsession.
# =====================================================================

{ config, lib, ... }:

let
  lua = import ./lua.nix { inherit lib; };

  cfg = config.home.shared.terminal.nvim;
  projects = cfg.projects;

  pickerOptions = {
    inherit (projects) dev projects patterns recent;

    confirm = lua.raw ''
      function(picker, item)
        picker:close()

        if not item then
          return
        end

        switch_to(item.file or item.dir)
      end
    '';
  };

  mappingLua = lib.concatStringsSep "\n\n    " (
    lib.mapAttrsToList (_: mapping: ''
      opts.mappings.n["${mapping.key}"] = {
          ${mapping.action},
          desc = "${mapping.description}",
        }'') projects.keymaps
  );

  projectsLua = ''
    function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}

      -- AstroNvim keeps per-directory sessions in the resession
      -- "${projects.sessionDirectory}" directory.
      local function save_dirsession()
        pcall(function()
          require("resession").save(vim.uv.cwd(), {
            dir = "${projects.sessionDirectory}",
            notify = false,
          })
        end)
      end

      local function load_dirsession()
        pcall(function()
          require("resession").load(vim.uv.cwd(), {
            dir = "${projects.sessionDirectory}",
            silence_errors = true,
          })
        end)
      end

      local function switch_to(directory)
        if not directory or directory == "" then
          return
        end

        if vim.fn.isdirectory(directory) == 0 then
          vim.notify("Not a directory: " .. directory, vim.log.levels.WARN)
          return
        end

        save_dirsession()
        vim.fn.chdir(directory)
        load_dirsession()

        vim.notify("Project: " .. vim.fn.fnamemodify(directory, ":~"))
      end

      local function pick_project()
        require("snacks").picker.projects(${lua.render "    " pickerOptions})
      end

      ${mappingLua}

      return opts
    end
  '';
in
{
  options.home.shared.terminal.nvim.projects = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Switch projects, restoring each one's session.";
    };

    plugin = lib.mkOption {
      type = lib.types.str;
      default = "folke/snacks.nvim";
      description = "Plugin providing the project picker.";
    };

    relativePath = lib.mkOption {
      type = lib.types.str;
      default = "nvim/lua/plugins/projects.lua";
      description = "Config-relative Lua file these knobs are written to.";
    };

    sessionDirectory = lib.mkOption {
      type = lib.types.str;
      default = "dirsession";
      description = "resession directory holding the per-project sessions.";
    };

    dev = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = lib.literalExpression ''[ "~/Developer" ]'';
      description = "Directories that hold several projects, scanned for the root patterns.";
    };

    projects = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Projects always listed, whether or not they were opened recently.";
    };

    patterns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = lib.literalExpression ''[ ".git" "flake.nix" ]'';
      description = "Files or folders that mark a directory as a project root.";
    };

    recent = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Also list roots inferred from recently opened files.";
    };

    keymaps = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            key = lib.mkOption {
              type = lib.types.str;
              description = "Key sequence this mapping binds.";
            };

            action = lib.mkOption {
              type = lib.types.str;
              example = "pick_project";
              description = "Function the key calls: pick_project, load_dirsession, or save_dirsession.";
            };

            description = lib.mkOption {
              type = lib.types.str;
              description = "What the mapping does.";
            };
          };
        }
      );
      default = { };
      description = "Project mappings.";
    };
  };

  config = lib.mkIf (cfg.enable && projects.enable) {
    xdg.configFile.${projects.relativePath}.text = lua.renderSpecs [
      {
        __positional = [ projects.plugin ];

        opts.picker.enabled = true;
      }

      {
        __positional = [ "AstroNvim/astrocore" ];

        opts = lua.raw projectsLua;
      }
    ];
  };
}
