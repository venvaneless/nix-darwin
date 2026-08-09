# shared/terminal/cli-tuis/btop.nix
#
# =====================================================================
# BTOP
#
# Resource monitor for:
# - Processes and their CPU/RAM use
# - CPU usage graphs
# - RAM and swap
# - Disks and connected physical media
# - Network traffic
#
# Installation, settings, and theme are managed through Home Manager.
# =====================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.ven.features.terminal.cliTuis.btop;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # -------------------------------------------------------------------
  # TOGGLES
  # -------------------------------------------------------------------

  # Use the declarative Gruvbox Dark theme below.
  enableGruvboxTheme = true;
in
{
  options.ven.features.terminal.cliTuis.btop.enable = lib.mkEnableOption "Btop resource monitor";

  config = lib.mkIf cfg.enable {
    programs.btop = {
      enable = true;

      settings = {
        # ---------------------------------------------------------------
        # GENERAL
        # ---------------------------------------------------------------

        # Use the custom Gruvbox theme when its toggle is enabled.
        color_theme = if enableGruvboxTheme then "ven-gruvbox" else "Default";

        # Use the terminal or btop background
        theme_background = true;

        # Use full 24-bit terminal colors.
        truecolor = true;

        # Redraw once per second.
        update_ms = 1000;

        # Do not let interactive changes rewrite the declarative config.
        save_config_on_exit = false;

        # Rounded panel corners.
        rounded_corners = true;

        # Enable mouse interaction.
        disable_mouse = false;

        # Enable mouse support.
        vim_keys = false;

        # ---------------------------------------------------------------
        # LAYOUT
        # ---------------------------------------------------------------

        # Display all four standard monitoring boxes
        shown_boxes = "cpu mem net proc";

        # Put the process list on the left
        proc_left = true;

        # Put the CPU graph across the bottom instead of the top
        cpu_bottom = true;

        # Keep memory/disks above network in the right-hand column
        mem_below_net = false;

        # One CPU graph instead of two stacked CPU graphs
        # This helps keep the bottom CPU section smaller
        cpu_single_graph = true;

        # Show CPU power usage in watts
        show_cpu_watts = true;

        # Show battery power usage in watts
        selected_battery = "Auto";
        show_battery_watts = true;

        # ---------------------------------------------------------------
        # GRAPH APPEARANCE
        # ---------------------------------------------------------------

        graph_symbol = "braille";
        graph_symbol_cpu = "braille";
        graph_symbol_mem = "braille";
        graph_symbol_net = "braille";
        graph_symbol_proc = "braille";

        # ---------------------------------------------------------------
        # PROCESS LIST
        # ---------------------------------------------------------------

        # Start sorted by the processes consuming the most CPU.
        proc_sorting = "cpu direct";

        # Highest usage first.
        proc_reversed = false;

        # Flat list showing all processes.
        proc_tree = false;

        # Use the Gruvbox process gradient.
        proc_colors = true;
        proc_gradient = true;

        # CPU percentage represents total CPU capacity rather than one core.
        proc_per_core = false;

        # Show process memory as a percentage.
        proc_mem_bytes = false;

        # Show a tiny CPU activity graph beside each process.
        proc_cpu_graphs = true;

        # Do not use the Linux-only, expensive smaps reading.
        proc_info_smaps = false;

        # Do not hide system processes.
        proc_filter_kernel = false;

        # Keep the selected process visible when opening details.
        proc_follow_detailed = true;

        # Do not merge child-process usage into parents.
        proc_aggregate = false;

        # ---------------------------------------------------------------
        # CPU
        # ---------------------------------------------------------------

        # Show system uptime.
        show_uptime = true;

        # Show CPU frequency where macOS exposes it.
        show_cpu_freq = true;

        # Show available temperature information.
        check_temp = true;
        show_coretemp = true;

        # Do not invert the lower graph.
        cpu_invert_lower = false;

        # Keep updating data while menus are open.
        background_update = true;

        # ---------------------------------------------------------------
        # MEMORY AND SWAP
        # ---------------------------------------------------------------

        # Use graphs rather than only meters.
        mem_graphs = true;

        # Show swap usage.
        show_swap = true;

        # Keep swap in the memory section rather than pretending it is a disk.
        swap_disk = false;

        # ---------------------------------------------------------------
        # DISKS AND CONNECTED MEDIA
        # ---------------------------------------------------------------

        # Split the memory box to include disks.
        show_disks = true;

        # Show physical disks, including attached external media.
        only_physical = true;

        # Show disk I/O activity.
        show_io_stat = true;

        # Display separate disk read/write activity.
        io_mode = false;
        io_graph_combined = false;

        # ---------------------------------------------------------------
        # NETWORK
        # ---------------------------------------------------------------

        # Automatically scale network traffic graphs.
        net_auto = true;

        # Keep upload and download graphs on the same scale.
        net_sync = true;

        # Initial graph ceilings; automatic scaling can increase them.
        net_download = 100;
        net_upload = 100;

        # ---------------------------------------------------------------
        # BATTERY
        # ---------------------------------------------------------------

        # Show battery state when available.
        show_battery = true;
      }
      // lib.optionalAttrs isDarwin {
        # macOS does not use /etc/fstab as the source of mounted media.
        # Linux keeps btop's native fstab behavior.
        use_fstab = false;
      };

      # -----------------------------------------------------------------
      # GRUVBOX DARK THEME
      # -----------------------------------------------------------------

      themes.ven-gruvbox = ''
        # Main background.
        # Empty allows terminal transparency when theme_background is false.
        theme[main_bg]="#282828"

        # Main foreground.
        theme[main_fg]="#EBDBB2"

        # Panel titles.
        theme[title]="#EBDBB2"

        # Shortcut and accent text.
        theme[hi_fg]="#FABD2F"

        # Selected rows.
        theme[selected_bg]="#504945"
        theme[selected_fg]="#FBF1C7"

        # Disabled and inactive text.
        theme[inactive_fg]="#665C54"

        # Text drawn over graphs.
        theme[graph_text]="#A89984"

        # Empty portions of meters.
        theme[meter_bg]="#3C3836"

        # Process details and miniature process graphs.
        theme[proc_misc]="#B8BB26"

        # Panel borders.
        theme[cpu_box]="#FABD2F"
        theme[mem_box]="#B8BB26"
        theme[net_box]="#83A598"
        theme[proc_box]="#D3869B"

        # Divider lines.
        theme[div_line]="#504945"

        # Temperature gradient.
        theme[temp_start]="#83A598"
        theme[temp_mid]="#FABD2F"
        theme[temp_end]="#FB4934"

        # CPU graph gradient.
        theme[cpu_start]="#B8BB26"
        theme[cpu_mid]="#FABD2F"
        theme[cpu_end]="#FB4934"

        # Free-memory gradient.
        theme[free_start]="#83A598"
        theme[free_mid]="#8EC07C"
        theme[free_end]="#B8BB26"

        # Cached-memory gradient.
        theme[cached_start]="#689D6A"
        theme[cached_mid]="#8EC07C"
        theme[cached_end]="#B8BB26"

        # Available-memory gradient.
        theme[available_start]="#458588"
        theme[available_mid]="#83A598"
        theme[available_end]="#8EC07C"

        # Used-memory and disk gradient.
        theme[used_start]="#FABD2F"
        theme[used_mid]="#FE8019"
        theme[used_end]="#FB4934"

        # Network download gradient.
        theme[download_start]="#458588"
        theme[download_mid]="#83A598"
        theme[download_end]="#8EC07C"

        # Network upload gradient.
        theme[upload_start]="#B16286"
        theme[upload_mid]="#D3869B"
        theme[upload_end]="#FB4934"

        # Process CPU/RAM usage gradient.
        theme[process_start]="#B8BB26"
        theme[process_mid]="#FABD2F"
        theme[process_end]="#FB4934"
      '';
    };
  };
}
