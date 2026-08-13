# shared/terminal/nvim/notify.nix

# =====================================================================
# NEOVIM: NOTIFICATIONS
#
# Styling for the snacks.nvim notifier, which AstroNvim already uses as
# the vim.notify handler. nvim-notify is deliberately not installed;
# adding it would compete with this for the same job.
#
# Colours follow the same Gruvbox palette as the heirline statusline.
# =====================================================================

{ config, lib, ... }:

{
  config = lib.mkIf config.ven.features.terminal.nvim.enable {
    xdg.configFile."nvim/lua/plugins/notify.lua".text = ''
      return {
        {
          "folke/snacks.nvim",

          opts = {
            notifier = {
              enabled = true,

              -- ---- TIMING ---- #

              -- Default lifetime in milliseconds. Individual calls can
              -- override this, and 0 keeps a notification until dismissed.
              timeout = 3000,

              -- Do not redraw more often than this.
              refresh = 50,

              -- ---- GEOMETRY ---- #

              -- Fractions are a share of the editor, integers are cells.
              width = { min = 40, max = 0.4 },
              height = { min = 1, max = 0.6 },

              -- Keep clear of the right-hand edge. The statusline and
              -- tabline are already accounted for automatically.
              margin = { top = 0, right = 1, bottom = 0 },

              padding = true,
              gap = 1,

              -- ---- BEHAVIOUR ---- #

              -- "compact" borders the icon and title, "fancy" is the
              -- nvim-notify look, "minimal" drops the border entirely.
              style = "compact",

              -- Stack downward from the top right.
              top_down = true,

              -- Newest first within each severity.
              sort = { "level", "added" },

              -- Everything is recorded in history regardless of level.
              level = vim.log.levels.TRACE,

              -- Timestamp shown on each notification.
              date_format = "%R",

              more_format = " ↓ %d lines ",

              -- Hold notifications open while the command line is active
              -- so they are not missed mid-command.
              keep = function()
                return vim.fn.getcmdpos() > 0
              end,

              -- ---- ICONS ---- #

              icons = {
                error = " ",
                warn = " ",
                info = " ",
                debug = " ",
                trace = " ",
              },
            },

            -- ---- WINDOW STYLES ---- #
            styles = {
              notification = {
                border = "rounded",

                wo = {
                  -- Solid background rather than blended, so the Gruvbox
                  -- colours below are not washed out by the buffer behind.
                  winblend = 0,
                  wrap = true,
                },
              },

              notification_history = {
                border = "rounded",
                title = " Notifications ",
                title_pos = "center",
              },
            },
          },
        },

        {
          "AstroNvim/astrocore",

          opts = function(_, opts)
            opts.mappings = opts.mappings or {}
            opts.mappings.n = opts.mappings.n or {}

            -- Scrollable log of everything that has been notified.
            opts.mappings.n["<Leader>fn"] = {
              function()
                require("snacks").notifier.show_history()
              end,

              desc = "Find notifications",
            }

            -- Clear whatever is currently on screen.
            opts.mappings.n["<Leader>un"] = {
              function()
                require("snacks").notifier.hide()
              end,

              desc = "Dismiss notifications",
            }

            return opts
          end,
        },

        {
          "ellisonleao/gruvbox.nvim",

          opts = function(_, opts)
            -- ---- GRUVBOX NOTIFIER COLOURS ---- #
            -- Same palette as the statusline in heirline.nix.
            local colors = {
              bg1 = "#3c3836",
              fg1 = "#ebdbb2",
              gray = "#a89984",
              yellow = "#fabd2f",
              aqua = "#83a598",
              green = "#b8bb26",
              red = "#fb4934",
              purple = "#d3869b",
            }

            -- snacks derives per-level groups from these names. Setting a
            -- group snacks does not use is harmless, so the list is
            -- deliberately exhaustive.
            local levels = {
              Error = colors.red,
              Warn = colors.yellow,
              Info = colors.aqua,
              Debug = colors.gray,
              Trace = colors.purple,
            }

            local function apply()
              for level, colour in pairs(levels) do
                -- Message body stays readable; the accents carry the colour.
                vim.api.nvim_set_hl(0, "SnacksNotifier" .. level, {
                  fg = colour,
                  bg = colors.bg1,
                })

                for _, part in ipairs({ "Icon", "Title", "Border", "Footer" }) do
                  vim.api.nvim_set_hl(0, "SnacksNotifier" .. part .. level, {
                    fg = colour,
                    bg = colors.bg1,
                    bold = part == "Title",
                  })
                end
              end

              vim.api.nvim_set_hl(0, "SnacksNotifierHistory", {
                fg = colors.fg1,
                bg = colors.bg1,
              })
            end

            -- Re-apply whenever the colorscheme is loaded, since loading
            -- one clears every custom highlight group.
            vim.api.nvim_create_autocmd("ColorScheme", {
              desc = "Gruvbox colours for snacks notifications",
              callback = apply,
            })

            vim.schedule(apply)

            return opts
          end,
        },
      }
    '';
  };
}
