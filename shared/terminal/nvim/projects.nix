# shared/terminal/nvim/projects.nix

# =====================================================================
# NEOVIM: PROJECTS
#
# Zed-style project switching built on two plugins AstroNvim already
# installs:
#
# - snacks.nvim   provides the project picker
# - resession.nvim provides AstroNvim's per-directory sessions
#
# Picking a project saves the current dirsession, changes directory,
# then restores that project's dirsession, so buffers and layout come
# back exactly as they were left.
# =====================================================================

{ config, lib, ... }:

{
  config = lib.mkIf config.ven.features.terminal.nvim.enable {
    xdg.configFile."nvim/lua/plugins/projects.lua".text = ''
      return {
        {
          "folke/snacks.nvim",

          opts = {
            picker = {
              enabled = true,
            },
          },
        },

        {
          "AstroNvim/astrocore",

          opts = function(_, opts)
            opts.mappings = opts.mappings or {}
            opts.mappings.n = opts.mappings.n or {}

            -- ---- SESSION HELPERS ---- #
            -- AstroNvim stores per-directory sessions under the
            -- "dirsession" resession directory.
            local function save_dirsession()
              pcall(function()
                require("resession").save(vim.uv.cwd(), {
                  dir = "dirsession",
                  notify = false,
                })
              end)
            end

            local function load_dirsession()
              pcall(function()
                require("resession").load(vim.uv.cwd(), {
                  dir = "dirsession",
                  silence_errors = true,
                })
              end)
            end

            -- ---- PROJECT SWITCH ---- #
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

            -- ---- PROJECT PICKER ---- #
            local function pick_project()
              require("snacks").picker.projects({
                -- Directories that contain multiple projects. Each entry is
                -- scanned for the root patterns below.
                dev = {
                  "~/.config",
                  "~/Developer",
                  "~/Projects",
                },

                -- Always list these, whether or not they were opened recently.
                projects = {
                  "~/.config/nix/nix-config",
                },

                -- What marks a directory as a project root.
                patterns = {
                  ".git",
                  "flake.nix",
                  "package.json",
                  "Cargo.toml",
                  "go.mod",
                  "pyproject.toml",
                },

                -- Include roots inferred from recently opened files.
                recent = true,

                confirm = function(picker, item)
                  picker:close()

                  if not item then
                    return
                  end

                  switch_to(item.file or item.dir)
                end,
              })
            end

            -- Open the project list.
            opts.mappings.n["<Leader>fp"] = {
              pick_project,
              desc = "Find projects",
            }

            -- Reload the session for the directory already open.
            opts.mappings.n["<Leader>fP"] = {
              load_dirsession,
              desc = "Reload project session",
            }

            return opts
          end,
        },
      }
    '';
  };
}
