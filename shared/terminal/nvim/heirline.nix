# shared/terminal/nvim/heirline.nix

# =====================================================================
# NEOVIM: HEIRLINE
#
# Dynamic Gruvbox statusline matching the WezTerm tabline palette
# =====================================================================

{ config, lib, ... }:

{
  config = lib.mkIf config.ven.features.terminal.nvim.enable {
    xdg.configFile."nvim/lua/plugins/heirline.lua".text = ''
      return {
        {
          "rebelot/heirline.nvim",

          opts = function(_, opts)
            local colors = {
              bg0 = "#282828",
              bg1 = "#3c3836",
              fg1 = "#ebdbb2",
              gray = "#a89984",
              yellow = "#fabd2f",
              orange = "#fe8019",
              aqua = "#83a598",
              green = "#b8bb26",
              red = "#fb4934",
            }

            local language_cache = {}

            local languages = {
              nix = { name = "Nix", icon = "" },
              lua = { name = "Lua", icon = "" },
              ts = { name = "TypeScript", icon = "" },
              tsx = { name = "TypeScript", icon = "" },
              js = { name = "JavaScript", icon = "" },
              jsx = { name = "JavaScript", icon = "" },
              py = { name = "Python", icon = "" },
              go = { name = "Go", icon = "" },
              rs = { name = "Rust", icon = "" },
              sh = { name = "Shell", icon = "" },
              bash = { name = "Shell", icon = "" },
              zsh = { name = "Shell", icon = "" },
              fish = { name = "Fish", icon = "󰈺" },
              html = { name = "HTML", icon = "" },
              css = { name = "CSS", icon = "" },
              scss = { name = "SCSS", icon = "" },
              vue = { name = "Vue", icon = "" },
              svelte = { name = "Svelte", icon = "" },
              md = { name = "Markdown", icon = "" },
            }

            local function project_root()
              local buffer = vim.api.nvim_get_current_buf()
              local filename = vim.api.nvim_buf_get_name(buffer)
              local start = filename ~= "" and vim.fs.dirname(filename) or vim.fn.getcwd()

              return vim.fs.root(start, {
                ".git",
                "flake.nix",
                "package.json",
                "Cargo.toml",
                "go.mod",
                "pyproject.toml",
              }) or vim.fn.getcwd()
            end

            local function dominant_language()
              local root = project_root()

              if language_cache[root] then
                return language_cache[root]
              end

              local counts = {}
              local files = {}

              if vim.fn.executable("git") == 1 and vim.uv.fs_stat(root .. "/.git") then
                files = vim.fn.systemlist({
                  "git",
                  "-C",
                  root,
                  "ls-files",
                  "--cached",
                  "--others",
                  "--exclude-standard",
                })
              end

              for index, name in ipairs(files) do
                if index > 1500 then
                  break
                end

                local extension = name:match("%.([^./]+)$")

                if extension then
                  extension = extension:lower()

                  if languages[extension] then
                    counts[extension] = (counts[extension] or 0) + 1
                  end
                end
              end

              local winner
              local winner_count = 0

              for extension, count in pairs(counts) do
                if count > winner_count then
                  winner = extension
                  winner_count = count
                end
              end

              if not winner then
                local filetype = vim.bo.filetype
                local fallback = languages[filetype]

                language_cache[root] = fallback or {
                  name = filetype ~= "" and filetype or "Text",
                  icon = "󰈙",
                }

                return language_cache[root]
              end

              language_cache[root] = languages[winner]
              return language_cache[root]
            end

            local function segment(text, icon, foreground, background, next_background, click)
              local component = {
                {
                  provider = function()
                    local value = type(text) == "function" and text() or text
                    local glyph = type(icon) == "function" and icon() or icon

                    if not value or value == "" then
                      return ""
                    end

                    if glyph and glyph ~= "" then
                      return " " .. glyph .. " " .. value .. " "
                    end

                    return " " .. value .. " "
                  end,

                  hl = {
                    fg = foreground,
                    bg = background,
                    bold = true,
                  },
                },
              }

              if next_background then
                table.insert(component, {
                  provider = "",
                  hl = {
                    fg = background,
                    bg = next_background,
                  },
                })
              end

              if click then
                component.on_click = click
              end

              return component
            end

            local function reverse_segment(text, icon, foreground, background, previous_background, click)
              local component = {
                {
                  provider = "",
                  hl = {
                    fg = background,
                    bg = previous_background,
                  },
                },
                {
                  provider = function()
                    local value = type(text) == "function" and text() or text
                    local glyph = type(icon) == "function" and icon() or icon

                    if not value or value == "" then
                      return ""
                    end

                    if glyph and glyph ~= "" then
                      return " " .. glyph .. " " .. value .. " "
                    end

                    return " " .. value .. " "
                  end,

                  hl = {
                    fg = foreground,
                    bg = background,
                    bold = true,
                  },
                },
              }

              if click then
                component.on_click = click
              end

              return component
            end

            local user = segment(
              function() return vim.env.USER or vim.env.USERNAME or "user" end,
              "",
              colors.bg0,
              colors.yellow,
              colors.orange,
              {
                name = "heirline_user_click",
                callback = function()
                  local value = vim.env.USER or vim.env.USERNAME or ""
                  vim.fn.setreg("+", value)
                  vim.notify("Copied user: " .. value)
                end,
              }
            )

            local shell = segment(
              function()
                local shell_path = vim.env.SHELL or vim.o.shell or "shell"
                return vim.fs.basename(shell_path)
              end,
              function()
                local shell_path = vim.env.SHELL or vim.o.shell or "shell"
                local shell_name = vim.fs.basename(shell_path)

                return ({
                  fish = "󰈺",
                  zsh = "",
                  bash = "",
                })[shell_name] or ""
              end,
              colors.bg0,
              colors.orange,
              colors.aqua,
              {
                name = "heirline_shell_click",
                callback = function()
                  vim.cmd("botright split | terminal " .. vim.o.shell)
                end,
              }
            )

            local language = segment(
              function() return dominant_language().name end,
              function() return dominant_language().icon end,
              colors.bg0,
              colors.aqua,
              colors.green,
              {
                name = "heirline_language_click",
                callback = function()
                  language_cache[project_root()] = nil
                  vim.cmd("redrawstatus")
                end,
              }
            )

            local lsp = segment(
              function()
                local clients = vim.lsp.get_clients({ bufnr = 0 })

                if #clients == 0 then
                  return "No LSP"
                end

                local names = {}

                for _, client in ipairs(clients) do
                  table.insert(names, client.name)
                end

                table.sort(names)

                if #names == 1 then
                  return names[1]
                end

                return names[1] .. " +" .. (#names - 1)
              end,
              "",
              colors.bg0,
              colors.green,
              colors.bg0,
              {
                name = "heirline_lsp_click",
                callback = function()
                  local clients = vim.lsp.get_clients({ bufnr = 0 })

                  if #clients == 0 then
                    vim.notify("No LSP client is attached to this buffer")
                    return
                  end

                  local lines = { "Active LSP clients:" }

                  for _, client in ipairs(clients) do
                    table.insert(lines, "• " .. client.name)
                  end

                  vim.notify(table.concat(lines, "\n"))
                end,
              }
            )

            lsp.update = {
              "LspAttach",
              "LspDetach",
              "BufEnter",
            }

            local fill = {
              provider = "%=",
              hl = {
                fg = colors.fg1,
                bg = colors.bg0,
              },
            }

            local host = reverse_segment(
              function() return vim.fn.hostname():gsub("%.local$", "") end,
              "󰒋",
              colors.bg0,
              colors.yellow,
              colors.bg0,
              {
                name = "heirline_host_click",
                callback = function()
                  local hostname = vim.fn.hostname():gsub("%.local$", "")
                  vim.fn.setreg("+", hostname)
                  vim.notify("Copied host: " .. hostname)
                end,
              }
            )

            local clock = reverse_segment(
              function() return os.date("%H:%M") end,
              "",
              colors.bg0,
              colors.orange,
              colors.yellow,
              {
                name = "heirline_clock_click",
                callback = function()
                  vim.notify(os.date("%A, %d %B %Y — %H:%M:%S"))
                end,
              }
            )

            clock.update = {
              "CursorHold",
              "CursorHoldI",
              "BufEnter",
            }

            opts.statusline = {
              hl = {
                fg = colors.fg1,
                bg = colors.bg0,
              },

              user,
              shell,
              language,
              lsp,
              fill,
              host,
              clock,
            }

            -- Dropbar owns the winbar; keep AstroNvim's existing tabline.
            opts.winbar = nil

            vim.opt.laststatus = 3
          end,
        },
      }
    '';
  };
}
