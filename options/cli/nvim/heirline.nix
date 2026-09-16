# options/cli/nvim/heirline.nix
#
# =====================================================================
# OPTIONS: NEOVIM STATUSLINE
#
# Declares the statusline knobs and writes their Lua file. Each segment
# takes its colours from the palette and its own knobs.
# =====================================================================

{ config, lib, ... }:

let
  lua = import ./lua.nix { inherit lib; };

  cfg = config.home.shared.terminal.nvim;
  bar = cfg.statusline;

  colour = name: bar.palette.${name} or name;

  # " icon " when there is a glyph, a single space when there is not.
  glyph = icon: if icon == "" then " " else " ${icon} ";

  segment = name: bar.segments.${name};

  # Colours are resolved here, so the Lua only ever sees hex values.
  colours = lua.render "  " (lib.mapAttrs (_: value: colour value) bar.palette);

  languages = lua.render "  " (
    lib.mapAttrs (_: language: { inherit (language) name icon; }) bar.languages
  );

  shellIcons = lua.render "        " bar.shellIcons;

  ignoredClients = lua.render "  " (
    lib.listToAttrs (map (name: lib.nameValuePair name true) bar.ignoredLspClients)
  );

  # A left-hand segment: text, then the separator into the next colour.
  leftSegment = name: body: ''
    local ${name} = segment(
      ${body},
      "${(segment name).icon}",
      colors.${(segment name).foreground},
      colors.${(segment name).background},
      colors.${(segment name).nextBackground},
      ${(segment name).click}
    )
  '';

  # A right-hand segment: the separator first, then the text.
  rightSegment = name: body: ''
    local ${name} = reverse_segment(
      ${body},
      "${(segment name).icon}",
      colors.${(segment name).foreground},
      colors.${(segment name).background},
      colors.${(segment name).previousBackground},
      ${(segment name).click}
    )
  '';

  statuslineLua = ''
    function(_, opts)
      local colors = ${colours}

      local language_cache = {}

      local languages = ${languages}

      local function project_root()
        local buffer = vim.api.nvim_get_current_buf()
        local filename = vim.api.nvim_buf_get_name(buffer)
        local start = filename ~= "" and vim.fs.dirname(filename) or vim.fn.getcwd()

        return vim.fs.root(start, ${lua.render "    " bar.projectRootPatterns}) or vim.fn.getcwd()
      end

      -- project_root() also matches flake.nix and friends, but Telescope's
      -- Git pickers need an actual repository.
      local function git_root()
        local buffer = vim.api.nvim_get_current_buf()
        local filename = vim.api.nvim_buf_get_name(buffer)
        local start = filename ~= "" and vim.fs.dirname(filename) or vim.fn.getcwd()

        return vim.fs.root(start, ".git")
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
          if index > ${toString bar.scannedFileLimit} then
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
            name = filetype ~= "" and filetype or "${bar.fallbackLanguage.name}",
            icon = "${bar.fallbackLanguage.icon}",
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
            provider = "${bar.separator}",
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
            provider = "${bar.reverseSeparator}",
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

      ${leftSegment "user" ''function() return vim.env.USER or vim.env.USERNAME or "user" end''}

      local shell = segment(
        function()
          local shell_path = vim.env.SHELL or vim.o.shell or "shell"
          return vim.fs.basename(shell_path)
        end,
        function()
          local shell_path = vim.env.SHELL or vim.o.shell or "shell"
          local shell_name = vim.fs.basename(shell_path)

          return (${shellIcons})[shell_name] or "${(segment "shell").icon}"
        end,
        colors.${(segment "shell").foreground},
        colors.${(segment "shell").background},
        colors.${(segment "shell").nextBackground},
        ${(segment "shell").click}
      )

      local language = segment(
        function() return dominant_language().name end,
        function() return dominant_language().icon end,
        colors.${(segment "language").foreground},
        colors.${(segment "language").background},
        colors.${(segment "language").nextBackground},
        ${(segment "language").click}
      )

      -- Copilot registers a real LSP client, but it is a completion source
      -- rather than a language server, so it is hidden here.
      local ignored_lsp_clients = ${ignoredClients}

      local function attached_lsp_clients()
        local names = {}

        for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
          if not ignored_lsp_clients[client.name] then
            table.insert(names, client.name)
          end
        end

        table.sort(names)

        return names
      end

      ${leftSegment "lsp" ''
        function()
            local names = attached_lsp_clients()

            if #names == 0 then
              return "${bar.noLspText}"
            end

            if #names == 1 then
              return names[1]
            end

            return names[1] .. " +" .. (#names - 1)
          end''}

      lsp.update = ${lua.render "  " (segment "lsp").updateEvents}

      -- Gitsigns publishes the repository, branch, and diff counts in
      -- b:gitsigns_status_dict.
      local function git_status()
        return vim.b.gitsigns_status_dict
      end

      local function git_is_dirty()
        local status = git_status()

        if not status then
          return false
        end

        return ((status.added or 0) + (status.changed or 0) + (status.removed or 0)) > 0
      end

      local function diff_provider(key, prefix)
        return function()
          local status = git_status()
          local count = status and status[key] or 0

          if count == 0 then
            return ""
          end

          return " " .. prefix .. count
        end
      end

      -- The last saved file's age sits beside the repository context.
      local function relative_file_mtime()
        local filename = vim.api.nvim_buf_get_name(0)

        if filename == "" or vim.bo.buftype ~= "" then
          return nil
        end

        if vim.bo.modified then
          return "${bar.git.unsavedText}"
        end

        local stat = vim.uv.fs_stat(filename)

        if not stat or not stat.mtime then
          return nil
        end

        local elapsed = math.max(0, os.time() - stat.mtime.sec)

        if elapsed < 60 then
          return "${bar.git.justNowText}"
        end

        if elapsed < 3600 then
          return math.floor(elapsed / 60) .. "m ago"
        end

        if elapsed < 86400 then
          return math.floor(elapsed / 3600) .. "h ago"
        end

        return math.floor(elapsed / 86400) .. "d ago"
      end

      local git = {
        {
          provider = function()
            return "${glyph bar.git.repositoryIcon}" .. vim.fs.basename(project_root()) .. " "
          end,

          hl = {
            fg = colors.${bar.git.repositoryColour},
            bg = colors.${bar.git.background},
            bold = true,
          },
        },

        -- The branch turns ${bar.git.dirtyColour} while the worktree has changes.
        {
          provider = function()
            local status = git_status()

            if not status or not status.head or status.head == "" then
              return "${bar.git.noRepositoryText}"
            end

            return "${glyph bar.git.branchIcon}" .. status.head
          end,

          hl = function()
            return {
              fg = git_is_dirty() and colors.${bar.git.dirtyColour} or colors.${bar.git.branchColour},
              bg = colors.${bar.git.background},
              bold = true,
            }
          end,
        },

        ${
          lib.concatStringsSep "\n        " (
            lib.mapAttrsToList (key: counter: ''
              {
                  provider = diff_provider("${key}", "${counter.prefix}"),
                  hl = {
                    fg = colors.${counter.colour},
                    bg = colors.${bar.git.background},
                    bold = true,
                  },
                },'') bar.git.diffCounters
          )
        }

        {
          provider = function()
            local value = relative_file_mtime()

            if not value then
              return ""
            end

            return "${glyph bar.git.modifiedIcon}" .. value
          end,

          hl = {
            fg = colors.${bar.git.modifiedColour},
            bg = colors.${bar.git.background},
            bold = true,
          },
        },

        {
          provider = " ",
          hl = {
            bg = colors.${bar.git.background},
          },
        },
        {
          provider = "${bar.separator}",
          hl = {
            fg = colors.${bar.git.background},
            bg = colors.${bar.background},
          },
        },

        on_click = {
          name = "heirline_git_click",
          callback = function()
            local root = git_root()

            -- Neovim's cwd is often the home directory, so each picker is
            -- scoped to the buffer's own repository.
            if not root then
              vim.notify(
                "This buffer is not inside a Git repository",
                vim.log.levels.WARN
              )
              return
            end

            local telescope = require("telescope.builtin")

            local actions = {
              ${
                lib.concatStringsSep "\n              " (
                  lib.mapAttrsToList (_: action: ''
                    {
                      label = "${action.label}",
                      run = function()
                        telescope.${action.picker}({ cwd = root })
                      end,
                    },'') bar.git.actions
                )
              }
            }

            vim.ui.select(actions, {
              prompt = vim.fs.basename(root) .. " — Git",
              format_item = function(action)
                return action.label
              end,
            }, function(choice)
              if choice then
                choice.run()
              end
            end)
          end,
        },

        update = ${lua.render "  " bar.git.updateEvents},
      }

      local fill = {
        provider = "%=",
        hl = {
          fg = colors.${bar.foreground},
          bg = colors.${bar.background},
        },
      }

      ${rightSegment "host" ''function() return vim.fn.hostname():gsub("%.local$", "") end''}

      ${rightSegment "clock" ''function() return os.date("${bar.clockFormat}") end''}

      clock.update = ${lua.render "  " (segment "clock").updateEvents}

      opts.statusline = {
        hl = {
          fg = colors.${bar.foreground},
          bg = colors.${bar.background},
        },

        ${lib.concatStringsSep ",\n        " bar.order},
      }

      -- Dropbar owns the winbar; AstroNvim keeps the tabline.
      opts.winbar = nil

      vim.opt.laststatus = ${toString bar.lastStatus}
    end
  '';

  segmentType = lib.types.submodule {
    options = {
      icon = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Glyph drawn before the segment's text.";
      };

      foreground = lib.mkOption {
        type = lib.types.str;
        default = "bg0";
        description = "Palette name for the segment's text.";
      };

      background = lib.mkOption {
        type = lib.types.str;
        default = "bg0";
        description = "Palette name for the segment's background.";
      };

      nextBackground = lib.mkOption {
        type = lib.types.str;
        default = "bg0";
        description = "Background of the segment to its right, used by the separator.";
      };

      previousBackground = lib.mkOption {
        type = lib.types.str;
        default = "bg0";
        description = "Background of the segment to its left, for right-hand segments.";
      };

      updateEvents = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Events that redraw this segment.";
      };

      click = lib.mkOption {
        type = lib.types.lines;
        default = "nil";
        description = "Lua table describing what a click does, or nil.";
      };
    };
  };
in
{
  options.home.shared.terminal.nvim.statusline = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Draw the heirline statusline.";
    };

    plugin = lib.mkOption {
      type = lib.types.str;
      default = "rebelot/heirline.nvim";
      description = "Plugin drawing the statusline.";
    };

    relativePath = lib.mkOption {
      type = lib.types.str;
      default = "nvim/lua/plugins/heirline.lua";
      description = "Config-relative Lua file these knobs are written to.";
    };

    palette = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Named colours the statusline uses.";
    };

    foreground = lib.mkOption {
      type = lib.types.str;
      default = "fg1";
      description = "Palette name for the statusline's own text.";
    };

    background = lib.mkOption {
      type = lib.types.str;
      default = "bg0";
      description = "Palette name for the statusline's own background.";
    };

    separator = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Glyph between a segment and the one on its right.";
    };

    reverseSeparator = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Glyph before a right-hand segment.";
    };

    order = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "user" "shell" "language" "lsp" "git" "fill" "host" "clock" ];
      description = "Segments, left to right. fill pushes the rest to the right.";
    };

    segments = lib.mkOption {
      type = lib.types.attrsOf segmentType;
      default = { };
      description = "Icon, colours, and click behaviour of each segment.";
    };

    languages = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Language name shown in the statusline.";
            };

            icon = lib.mkOption {
              type = lib.types.str;
              description = "Glyph shown beside the name.";
            };
          };
        }
      );
      default = { };
      example = lib.literalExpression ''{ nix = { name = "Nix"; icon = ""; }; }'';
      description = "Language shown for each file extension.";
    };

    fallbackLanguage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Text";
        description = "Name shown when no language is recognised.";
      };

      icon = lib.mkOption {
        type = lib.types.str;
        default = "󰈙";
        description = "Glyph shown when no language is recognised.";
      };
    };

    shellIcons = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''{ fish = "󰈺"; }'';
      description = "Glyph shown for each shell.";
    };

    projectRootPatterns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Files or folders that mark a project root.";
    };

    scannedFileLimit = lib.mkOption {
      type = lib.types.int;
      default = 1500;
      description = "How many files are counted when guessing a project's language.";
    };

    ignoredLspClients = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "LSP clients left out of the statusline, such as completion sources.";
    };

    noLspText = lib.mkOption {
      type = lib.types.str;
      default = "No LSP";
      description = "Text shown when no language server is attached.";
    };

    clockFormat = lib.mkOption {
      type = lib.types.str;
      default = "%H:%M";
      description = "Time format in the clock segment.";
    };

    lastStatus = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = "Neovim's laststatus. 3 draws one statusline for all windows.";
    };

    git = {
      background = lib.mkOption {
        type = lib.types.str;
        default = "bg1";
        description = "Palette name behind the Git section.";
      };

      repositoryIcon = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Glyph before the repository name.";
      };

      repositoryColour = lib.mkOption {
        type = lib.types.str;
        default = "yellow";
        description = "Palette name for the repository name.";
      };

      branchIcon = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Glyph before the branch name.";
      };

      branchColour = lib.mkOption {
        type = lib.types.str;
        default = "fg1";
        description = "Palette name for a clean worktree's branch.";
      };

      dirtyColour = lib.mkOption {
        type = lib.types.str;
        default = "orange";
        description = "Palette name for a branch with uncommitted changes.";
      };

      noRepositoryText = lib.mkOption {
        type = lib.types.str;
        default = "no repo";
        description = "Text shown outside a repository.";
      };

      diffCounters = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              prefix = lib.mkOption {
                type = lib.types.str;
                description = "Character before the count, such as + or -.";
              };

              colour = lib.mkOption {
                type = lib.types.str;
                description = "Palette name for this counter.";
              };
            };
          }
        );
        default = { };
        description = "Added, changed, and removed line counters.";
      };

      modifiedIcon = lib.mkOption {
        type = lib.types.str;
        default = "󰃭";
        description = "Glyph before the file's age.";
      };

      modifiedColour = lib.mkOption {
        type = lib.types.str;
        default = "gray";
        description = "Palette name for the file's age.";
      };

      unsavedText = lib.mkOption {
        type = lib.types.str;
        default = "unsaved";
        description = "Text shown instead of an age while the buffer is modified.";
      };

      justNowText = lib.mkOption {
        type = lib.types.str;
        default = "now";
        description = "Text shown for a file saved less than a minute ago.";
      };

      updateEvents = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Events that redraw the Git section.";
      };

      actions = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              label = lib.mkOption {
                type = lib.types.str;
                description = "Entry shown in the menu.";
              };

              picker = lib.mkOption {
                type = lib.types.str;
                example = "git_branches";
                description = "telescope.builtin picker the entry opens.";
              };
            };
          }
        );
        default = { };
        description = "Menu shown when the Git section is clicked.";
      };
    };
  };

  config = lib.mkIf (cfg.enable && bar.enable) {
    xdg.configFile.${bar.relativePath}.text = lua.renderSpecs [
      {
        __positional = [ bar.plugin ];

        opts = lua.raw statuslineLua;
      }
    ];
  };
}
