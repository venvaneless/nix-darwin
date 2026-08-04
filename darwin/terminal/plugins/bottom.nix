# darwin/terminal/plugins/bottom.nix



{ config, lib, pkgs, ... }:

{
  programs.bottom = {
    enable = true;

    settings = {
      flags = {
        # Refresh every second.
        rate = "1s";

        # Start focused on the process table.
        default_widget_type = "proc";

        # Show battery information when bottom can read it.
        battery = true;

        # Celsius.
        temperature_type = "c";

        # Cleaner process list.
        tree = false;
        hide_table_gap = true;
      };

      cpu = {
        # Keep the total CPU row visible.
        hide_avg_cpu = false;

        # Put CPU labels on the left.
        left_legend = true;
      };

      processes = {
        columns = [
          "pid"
          "name"
          "cpu%"
          "mem%"
          "read"
          "write"
        ];

        default_sort = "cpu";
        show_command = true;
        group_processes = false;
        disable_advanced_kill = false;
      };

      # Only show:
      #
      # ┌───────────────────────────────────────┐
      # │ CPU usage                            │
      # ├───────────────────┬───────────────────┤
      # │ RAM and swap      │ Process list      │
      # │                   │ CPU / RAM columns │
      # └───────────────────┴───────────────────┘
      row = [
        {
          ratio = 35;

          child = [
            {
              type = "cpu";
            }
          ];
        }

        {
          ratio = 65;

          child = [
            {
              ratio = 35;
              type = "mem";
            }

            {
              ratio = 65;
              type = "proc";
              default = true;
            }
          ];
        }
      ];

      # Gruvbox Dark palette.
      styles = {
        cpu = {
          all_entry_colour = "#d79921";
          avg_entry_colour = "#fb4934";

          cpu_core_colours = [
            "#fe8019"
            "#fabd2f"
            "#b8bb26"
            "#8ec07c"
            "#83a598"
            "#d3869b"
            "#fb4934"
            "#689d6a"
          ];
        };

        memory = {
          ram_colour = "#b8bb26";
          cache_colour = "#8ec07c";
          swap_colour = "#fe8019";

          # Used for GPU memory on platforms where bottom supports it.
          gpu_colours = [
            "#83a598"
            "#d3869b"
            "#fabd2f"
            "#fb4934"
          ];
        };

        battery = {
          high_battery_colour = "#b8bb26";
          medium_battery_colour = "#fabd2f";
          low_battery_colour = "#fb4934";
        };

        tables = {
          headers = {
            colour = "#fabd2f";
            bold = true;
          };
        };

        graphs = {
          graph_colour = "#928374";

          legend_text = {
            colour = "#bdae93";
          };
        };

        widgets = {
          border_colour = "#504945";
          selected_border_colour = "#fabd2f";

          widget_title = {
            colour = "#ebdbb2";
            bold = true;
          };

          text = {
            colour = "#ebdbb2";
          };

          selected_text = {
            colour = "#282828";
            bg_colour = "#fabd2f";
            bold = true;
          };

          disabled_text = {
            colour = "#665c54";
          };

          bg_colour = "#282828";
        };
      };
    };
  };
}