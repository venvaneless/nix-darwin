# darwin/terminal/cli-tuis/tessera.nix
#
# =====================================================================
# TESSERA / WTFUTIL
#
# Custom macOS monitoring dashboard showing:
# - Processes and their CPU/RAM use
# - RAM and swap
# - Mounted disks and removable media
# - Per-process network activity
# - CPU history
#
# The upstream executable is currently named "wtfutil".
# =====================================================================

{ config, lib, pkgs, ... }:

let
  # -------------------------------------------------------------------
  # TOGGLES
  # -------------------------------------------------------------------

  enableTessera = true;
  enableGruvboxTheme = true;

  # -------------------------------------------------------------------
  # DASHBOARD COMMANDS
  # -------------------------------------------------------------------

  processMonitor = pkgs.writeShellScript "tessera-processes" ''
    printf "%-7s %-7s %-7s %s\n" "PID" "CPU%" "RAM%" "PROCESS"

    /bin/ps \
      -axo pid=,pcpu=,pmem=,comm= \
      -r |
      /usr/bin/head -n 35 |
      /usr/bin/awk '
        {
          pid = $1
          cpu = $2
          mem = $3

          $1 = ""
          $2 = ""
          $3 = ""

          sub(/^[[:space:]]+/, "", $0)

          printf "%-7s %-7s %-7s %s\n", pid, cpu, mem, $0
        }
      '
  '';

  memoryMonitor = pkgs.writeShellScript "tessera-memory" ''
    page_size=$(/usr/sbin/sysctl -n hw.pagesize)

    /usr/bin/vm_stat |
      /usr/bin/awk \
        -v page_size="$page_size" '
          function pages_to_gib(pages) {
            return pages * page_size / 1024 / 1024 / 1024
          }

          /Pages free/ {
            gsub(/\./, "", $3)
            free = $3
          }

          /Pages active/ {
            gsub(/\./, "", $3)
            active = $3
          }

          /Pages inactive/ {
            gsub(/\./, "", $3)
            inactive = $3
          }

          /Pages speculative/ {
            gsub(/\./, "", $3)
            speculative = $3
          }

          /Pages wired down/ {
            gsub(/\./, "", $4)
            wired = $4
          }

          /Pages occupied by compressor/ {
            gsub(/\./, "", $5)
            compressed = $5
          }

          END {
            used = active + inactive + speculative + wired + compressed

            printf "RAM used:       %6.2f GiB\n", pages_to_gib(used)
            printf "RAM free:       %6.2f GiB\n", pages_to_gib(free)
            printf "Active:         %6.2f GiB\n", pages_to_gib(active)
            printf "Inactive:       %6.2f GiB\n", pages_to_gib(inactive)
            printf "Wired:          %6.2f GiB\n", pages_to_gib(wired)
            printf "Compressed:     %6.2f GiB\n", pages_to_gib(compressed)
          }
        '

    printf "\n"

    /usr/sbin/sysctl vm.swapusage |
      /usr/bin/sed \
        -E \
        's/^vm.swapusage: /Swap\n/; s/  +/\n/g'
  '';

  diskMonitor = pkgs.writeShellScript "tessera-disks" ''
    printf "%-22s %-9s %-9s %-7s %s\n" \
      "FILESYSTEM" \
      "SIZE" \
      "USED" \
      "USE%" \
      "MOUNT"

    /bin/df -H |
      /usr/bin/awk '
        NR > 1 {
          printf "%-22s %-9s %-9s %-7s %s\n", $1, $2, $3, $5, $9
        }
      '

    printf "\nConnected physical media\n"
    printf "────────────────────────\n"

    /usr/sbin/diskutil list physical 2>/dev/null
  '';

  networkMonitor = pkgs.writeShellScript "tessera-network" ''
    printf "%-7s %-22s %-12s %-12s\n" \
      "PID" \
      "PROCESS" \
      "RX BYTES" \
      "TX BYTES"

    /usr/bin/nettop \
      -P \
      -L 1 \
      -J pid,command,bytes_in,bytes_out \
      -x \
      2>/dev/null |
      /usr/bin/awk -F, '
        NR > 1 && $1 ~ /^[0-9]+$/ {
          printf "%-7s %-22.22s %-12s %-12s\n", $1, $2, $3, $4
        }
      ' |
      /usr/bin/head -n 8
  '';

  cpuMonitor = pkgs.writeShellScript "tessera-cpu" ''
    /usr/bin/top \
      -l 2 \
      -n 0 \
      -stats cpu \
      2>/dev/null |
      /usr/bin/grep \
        -E \
        "CPU usage|Load Avg|PhysMem|VM:"
  '';

  tesseraConfig =
    if enableGruvboxTheme then
      ''
        wtf:
          colors:
            background: "transparent"

            border:
              focusable: "#928374"
              focused: "#fabd2f"
              normal: "#504945"

            checked: "#b8bb26"

            highlight:
              fore: "#282828"
              back: "#fabd2f"

            labels: "#d79921"
            text: "#ebdbb2"
            title: "#fabd2f"

            rows:
              even: "#ebdbb2"
              odd: "#bdae93"

            subheading: "#d3869b"

          grid:
            columns:
              - 22
              - 22
              - 22
              - 22
              - 22
              - 22

            rows:
              - 16
              - 12
              - 7

          refreshInterval: 1s

          mods:
            processes:
              type: cmdrunner
              title: " Processes — CPU / RAM "
              enabled: true
              focusable: false
              cmd: "${processMonitor}"
              refreshInterval: 2s
              maxLines: 40

              position:
                top: 0
                left: 0
                width: 6
                height: 1

            memory:
              type: cmdrunner
              title: " RAM / Swap "
              enabled: true
              focusable: false
              cmd: "${memoryMonitor}"
              refreshInterval: 3s
              maxLines: 30

              position:
                top: 1
                left: 0
                width: 3
                height: 1

            disks:
              type: cmdrunner
              title: " Disks / Connected Media "
              enabled: true
              focusable: false
              cmd: "${diskMonitor}"
              refreshInterval: 10s
              maxLines: 50

              position:
                top: 1
                left: 3
                width: 3
                height: 1

            network:
              type: cmdrunner
              title: " Network by Process "
              enabled: true
              focusable: false
              cmd: "${networkMonitor}"
              refreshInterval: 3s
              maxLines: 10

              position:
                top: 2
                left: 0
                width: 2
                height: 1

            cpu:
              type: cmdrunner
              title: " CPU / System Activity "
              enabled: true
              focusable: false
              cmd: "${cpuMonitor}"
              refreshInterval: 2s
              maxLines: 10

              position:
                top: 2
                left: 2
                width: 4
                height: 1
      ''
    else
      ''
        wtf:
          grid:
            columns:
              - 22
              - 22
              - 22
              - 22
              - 22
              - 22

            rows:
              - 16
              - 12
              - 7

          refreshInterval: 1s

          mods:
            processes:
              type: cmdrunner
              title: " Processes — CPU / RAM "
              enabled: true
              focusable: false
              cmd: "${processMonitor}"
              refreshInterval: 2s

              position:
                top: 0
                left: 0
                width: 6
                height: 1

            memory:
              type: cmdrunner
              title: " RAM / Swap "
              enabled: true
              focusable: false
              cmd: "${memoryMonitor}"
              refreshInterval: 3s

              position:
                top: 1
                left: 0
                width: 3
                height: 1

            disks:
              type: cmdrunner
              title: " Disks / Connected Media "
              enabled: true
              focusable: false
              cmd: "${diskMonitor}"
              refreshInterval: 10s

              position:
                top: 1
                left: 3
                width: 3
                height: 1

            network:
              type: cmdrunner
              title: " Network by Process "
              enabled: true
              focusable: false
              cmd: "${networkMonitor}"
              refreshInterval: 3s

              position:
                top: 2
                left: 0
                width: 2
                height: 1

            cpu:
              type: cmdrunner
              title: " CPU / System Activity "
              enabled: true
              focusable: false
              cmd: "${cpuMonitor}"
              refreshInterval: 2s

              position:
                top: 2
                left: 2
                width: 4
                height: 1
      '';
in
{
  config = lib.mkIf enableTessera {
    home.packages = [
      pkgs.wtf
    ];

    xdg.configFile."wtf/config.yml".text = tesseraConfig;

    programs.fish.functions.tessera = {
      description = "Open the Tessera system dashboard";

      body = ''
        command wtfutil \
          --config "$HOME/.config/wtf/config.yml"
      '';
    };
  };
}