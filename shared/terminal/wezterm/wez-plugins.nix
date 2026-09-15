# shared/terminal/wezterm/wez-plugins.nix
#
# =====================================================================
# WEZTERM: PLUGIN CACHE OWNERSHIP
#
# WezTerm plugins are loaded by their HTTPS URLs in the embedded Lua
# modules. WezTerm owns the resulting Git checkouts under its user
# data directory; the Nix store must not replace those checkouts.
# =====================================================================

{ ... }:

{
	config.home.shared.terminal.wezterm.plugins = {
		# ------------------------------------------------------------
		# Plugin loading
		# ------------------------------------------------------------
		modules = [ "resurrect" "smart_workspace_switcher" "sessions" "tabline" ];

		resurrect.url = "https://github.com/MLFlexer/resurrect.wezterm";

		sessions = {
			url = "https://github.com/abidibo/wezterm-sessions";
			autoSaveIntervalSeconds = 30;
			gitBranchWarn = true;
		};

		smartWorkspaceSwitcher.url = "https://github.com/MLFlexer/smart_workspace_switcher.wezterm";

		# ------------------------------------------------------------
		# Tabline settings and colors
		# ------------------------------------------------------------
		tabline = {
			url = "https://github.com/michaelbrusegard/tabline.wez";
			theme = "Gruvbox Dark (Gogh)";
			iconsEnabled = true;
			tabsEnabled = true;

			cwd = {
				maximumLength = 23;
				padding = { left = 1; right = 1; };
			};

			process.padding = { left = 1; right = 1; };
			hostname.padding = { left = 1; right = 1; };
			datetime.padding = { left = 1; right = 1; };
			battery.padding = { left = 1; right = 1; };

			window = {
				enableTabBar = true;
				fancyTabBar = false;
				atBottom = true;
				maximumWidth = 28;
			};

			sectionSeparators = { left = ""; right = ""; };
			componentSeparators = { left = ""; right = ""; };
			tabSeparators = { left = ""; right = ""; };

			palette = {
				bg0 = "#282828";
				bg1 = "#3c3836";
				bg2 = "#504945";
				bg3 = "#665c54";
				fg0 = "#fbf1c7";
				fg1 = "#ebdbb2";
				gray = "#a89984";
				yellow = "#fabd2f";
				orange = "#fe8019";
				red = "#fb4934";
				aqua = "#8ec07c";
				blue = "#83a598";
			};

			colors = {
				active = { fg = "#282828"; bg = "#fabd2f"; };
				inactive = { fg = "#a89984"; bg = "#3c3836"; };
				inactiveHover = { fg = "#ebdbb2"; bg = "#504945"; };
			};

			# Tabline section palette roles
			sectionColors = {
				background = "bg0";
				tabActive.divider = { foreground = "yellow"; background = "bg0"; };
				tablineX = {
					divider = { foreground = "yellow"; background = "bg0"; };
					content = { foreground = "bg0"; background = "yellow"; };
				};
				tablineY = {
					divider = { foreground = "orange"; background = "yellow"; };
					content = { foreground = "bg0"; background = "orange"; };
				};
				tablineZ = {
					divider = { foreground = "bg0"; background = "orange"; };
					content = { foreground = "yellow"; background = "bg0"; };
				};
			};

			processIcons = {
				docker = "md_docker";
				git = "dev_git";
				nix = "linux_nixos";
				zsh = "dev_terminal";
				bash = "cod_terminal_bash";
				fish = "md_fish";
				node = "md_nodejs";
				javascript = "dev_javascript";
				typescript = "dev_typescript";
				python = "dev_python";
				go = "md_language_go";
				html = "dev_html5";
				css = "dev_css3";
				scss = "dev_sass";
				vue = "dev_vuejs";
				angular = "dev_angular";
				default = "md_application";
			};
		};
	};
}
