# shared/terminal/aliases/shell-aliases.nix
#
# =====================================================================
# SHELL: ALIASES
# =====================================================================
{ paths, pkgs, terminalAliasEntries, ... }:

let
  shellAliases = {
      # ---------- Core ---------- #

      # --- freload -> reload Fish config
      ## Reload the generated Fish config in the current shell
      freload = {
        command = "exec fish -l";
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };

      # --- cat -> bat
      ## Use bat instead of cat for syntax highlighting and nicer output

      cat = {
        command = {
          darwin = "bat";
          linux = "bat";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- ccx -> clear
      ## Clear the terminal screen quickly

      ccx = {
        command = {
          darwin = "clear";
          linux = "clear";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- cd -> z
      ## Use zoxide for smarter directory jumping in Fish

      cd = {
        command = {
          darwin = "z";
          linux = "z";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- fishcfg -> edit Fish config
      ## Open the generated Fish config in micro
      fishcfg = {
        command = {
          darwin = "micro $XDG_CONFIG_HOME/fish/config.fish";
          linux = "micro $XDG_CONFIG_HOME/fish/config.fish";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };

      # --- reloadfish -> reload Fish config
      ## Reload the generated Fish config in the current shell
      reloadfish = {
        command = {
          darwin = "source $XDG_CONFIG_HOME/fish/config.fish";
          linux = "source $XDG_CONFIG_HOME/fish/config.fish";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };

      # --- ff -> fastfetch
      ## Run fastfetch manually

      ff = {
        command = {
          darwin = "fastfetch";
          linux = "fastfetch";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- hgrep -> history | rg
      ## Search through command history with ripgrep

      hgrep = {
        command = {
          darwin = "history | rg";
          linux = "history | rg";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- hist -> history
      ## Show shell history quickly

      hist = {
        command = {
          darwin = "history";
          linux = "history";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- nano -> micro
      ## Use micro instead of nano

      nano = {
        command = {
          darwin = "micro";
          linux = "micro";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- please -> sudo
      ## Funny sudo alias

      please = {
        command = {
          darwin = "sudo";
          linux = "sudo";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- smicro -> sudo micro with user config
      ## Open files with sudo while keeping your micro config

      smicro = {
        command = {
          darwin = "sudo micro -config-dir $XDG_CONFIG_HOME/micro";
          linux = "sudo micro -config-dir $XDG_CONFIG_HOME/micro";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------- Files and Folders ---------- #

      # --- cp -> cp -i
      ## Ask before overwriting when copying files

      cp = {
        command = {
          darwin = "cp -i";
          linux = "cp -i";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- mv -> mv -i
      ## Ask before overwriting when moving files

      mv = {
        command = {
          darwin = "mv -i";
          linux = "mv -i";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- rm -> rm -i
      ## Ask before deleting files

      rm = {
        command = {
          darwin = "rm -i";
          linux = "rm -i";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------- Additional replacements ---------- #

      # --- mkdir -> mkdir -pv
      ## Create parent directories as needed and print what gets created

      mkdir = {
        command = {
          darwin = "mkdir -pv";
          linux = "mkdir -pv";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- mkpv -> mkdir -pv
      ## Create parent directories as needed and print what gets created

      mkpv = {
        command = {
          darwin = "mkdir -pv";
          linux = "mkdir -pv";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- myip -> curl -4 ifconfig.me
      ## Show public IPv4 address

      myip = {
        command = {
          darwin = "curl -4 ifconfig.me";
          linux = "curl -4 ifconfig.me";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------- Processes ---------- #

      # --- kpid -> kill -9
      ## Force-kill a process by PID

      kpid = {
        command = {
          darwin = "kill -9";
          linux = "kill -9";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- kpname -> pkill -i
      ## Kill processes by name, case-insensitively

      kproc = {
        command = {
          darwin = "pkill -i";
          linux = "pkill -i";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- pfind -> pgrep -ifl
      ## Find processes by name with PID and command line

      pfind = {
        command = {
          darwin = "pgrep -ifl";
          linux = "pgrep -ifl";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- psa -> ps aux
      ## Show running processes

      psa = {
        command = {
          darwin = "ps aux";
          linux = "ps aux";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- psg -> ps aux | grep -i
      ## Search running processes by name

      psg = {
        command = {
          darwin = "ps aux | grep -i";
          linux = "ps aux | grep -i";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- psmem
      ## Show processes sorted by RAM usage

      psmem = {
        command = {
          darwin = "ps aux | sort -nr -k 4";
          linux = "ps aux | sort -nr -k 4";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- psmem10
      ## Show the top 10 RAM-hungry processes

      psmem10 = {
        command = {
          darwin = "ps aux | sort -nr -k 4 | head -10";
          linux = "ps aux | sort -nr -k 4 | head -10";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------- Better disk usage shortcuts ---------- #

      # --- biggest -> du -ah . | sort -hr | head -40
      ## Show the 40 biggest files/directories from the current directory downward

      biggest = {
        command = {
          darwin = "du -ah . | sort -hr | head -40";
          linux = "du -ah . | sort -hr | head -40";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- dfh -> df -h
      ## Show mounted filesystem usage in human-readable format

      dfh = {
        command = {
          darwin = "df -h";
          linux = "df -h";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- duh -> du -sh ...
      ## Show folder sizes in the current directory sorted by size

      duh = {
        command = {
          darwin = "du -sh ./* .[^.]* 2>/dev/null | sort -h";
          linux = "du -sh ./* .[^.]* 2>/dev/null | sort -h";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------- Archiving ---------- #

      # ------------------------------------------------------------
      # --- rardir -> rar archive helper
      ## Create a .rar archive named after the target folder
      rardir = {
        command = ''
            function _rardir
                set target "."

                    if test (count $argv) -gt 0
            set target $argv[1]
          end

          set folder (basename (realpath $target))

          rar a "$folder.rar" "$target"
        end

        _rardir
        '';
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ------------------------------------------------------------

      # ------------------------------------------------------------
      # --- zipdir -> zip archive helper
      ## Create a .zip archive named after the target folder
      zipdir = {
        command = ''
        function _zipdir
          set target "."

          if test (count $argv) -gt 0
            set target $argv[1]
          end

          set folder (basename (realpath $target))

          zip -r "$folder.zip" "$target"
        end

        _zipdir
        '';
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ------------------------------------------------------------

      # --- wget -> wget -c
      ## Continue partial downloads automatically

      wget = {
        command = {
          darwin = "wget -c ";
          linux = "wget -c ";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------- Helpers ---------- #

      # --- helpme
      ## Remind yourself to use tldr for quick command help

      helpme = {
        command = {
          darwin = "echo \"To print basic information about a command use tldr <command>\"";
          linux = "echo \"To print basic information about a command use tldr <command>\"";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- tb
      ## Pipe text to termbin for quick sharing

      tb = {
        command = {
          darwin = "nc termbin.com 9999";
          linux = "nc termbin.com 9999";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------- Eza Navigation ---------- #

      # --- ls -> eza listing
      ## List non-hidden files with icons

      ls = {
        command = {
          darwin = "eza -l --color=always --group-directories-first --icons";
          linux = "eza -l --color=always --group-directories-first --icons";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- l. -> Show all files, including hidden entries
      ## List hidden files in long format with icons

      "l." = {
        command = {
          darwin = "eza -la --color=always --group-directories-first --icons";
          linux = "eza -la --color=always --group-directories-first --icons";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- la -> eza -A
      ## List files, including hidden ones except . and ..

      la = {
        command = {
          darwin = "eza -A --color=always --group-directories-first --icons";
          linux = "eza -A --color=always --group-directories-first --icons";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- lh -> eza -la
      ## List files in long format with human-readable size

      lh = {
        command = {
          darwin = "eza -lah --color=always --group-directories-first --icons";
          linux = "eza -lah --color=always --group-directories-first --icons";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- ll -> eza long listing
      ## Long listing with icons

      ll = {
        command = {
          darwin = "eza -l --color=always --group-directories-first --icons";
          linux = "eza -l --color=always --group-directories-first --icons";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- lt -> eza tree
      ## Show directory tree with icons

      lt = {
        command = {
          darwin = "eza -T --color=always --group-directories-first --icons";
          linux = "eza -T --color=always --group-directories-first --icons";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- lt. -> eza hidden tree
      ## Show directory tree including hidden files

      "lt." = {
        command = {
          darwin = "eza -aT --color=always --group-directories-first --icons";
          linux = "eza -aT --color=always --group-directories-first --icons";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------- Directory Shortcuts ---------- #

      # --- .. -> parent directory
      ## Go up one directory

      ".." = {
        command = {
          darwin = "cd ..";
          linux = "cd ..";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- ... -> two levels up
      ## Go up two directories

      "..." = {
        command = {
          darwin = "cd ../..";
          linux = "cd ../..";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- .... -> three levels up
      ## Go up three directories

      "...." = {
        command = {
          darwin = "cd ../../..";
          linux = "cd ../../..";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- ..... -> four levels up
      ## Go up four directories

      "....." = {
        command = {
          darwin = "cd ../../../..";
          linux = "cd ../../../..";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- ...... -> five levels up
      ## Go up five directories

      "......" = {
        command = {
          darwin = "cd ../../../../..";
          linux = "cd ../../../../..";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------- Tools ---------- #

      # --- dir
      ## Colorized dir output
      dir = {
        command = {
          linux = "dir --color=auto";
        };
        enable = true;
        installOn = {
          darwin = false;
          linux = true;
        };
      };

      # --- erg
      ## Use ripgrep for extended regex searches

      erg = {
        command = {
          darwin = "rg --color=auto";
          linux = "rg --color=auto";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- fgrep
      ## Fixed-string searches

      fgrep = {
        command = {
          darwin = "rg -F --color=auto";
          linux = "rg -F --color=auto";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- frg
      ## Use ripgrep for fixed-string searches

      frg = {
        command = {
          darwin = "rg -F --color=auto";
          linux = "rg -F --color=auto";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- grep
      ## Use ripgrep instead of grep

      grep = {
        command = {
          darwin = "rg --color=auto";
          linux = "rg --color=auto";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # --- vdir
      ## Colorized vdir output
      vdir = {
        command = {
          linux = "vdir --color=auto";
        };
        enable = true;
        installOn = {
          darwin = false;
          linux = true;
        };
      };
  };

  functions = {
    # -----------------------------------------------------------------
    # ---- cdf -> Folder picker with fzf ---- #
    # Starts from the configured home directory and adds macOS Library
    # locations only when they are configured and exist.
    # -----------------------------------------------------------------
    cdf = {
      command.cdf = {
        home.path = {
          darwin = paths.darwin.home.root;
          linux = paths.linux.home.root;
        };
        mobileDocuments.path.darwin = paths.darwin.library.mobileDocuments;
        iCloudDrive.path.darwin = paths.darwin.library.iCloudDrive;
        applicationSupport.path.darwin = paths.darwin.library.applicationSupport;
        preferences.path.darwin = paths.darwin.library.preferences;
        rootDirectories = [ "Desktop" "Documents" "Downloads" ];
        showHidden = false;
      };
      enable = true;
      installOn = { darwin = true; linux = true; };
    };

    # -----------------------------------------------------------------
    # ---- copyf -> Copy to an explicit destination path ---- #
    # -----------------------------------------------------------------
    copyf = {
      command.copyf.command = {
        darwin = "/usr/bin/ditto";
        linux = "${pkgs.coreutils}/bin/cp -a --";
      };
      enable = true;
      installOn = { darwin = true; linux = true; };
    };

    # -----------------------------------------------------------------
    # ---- copyfolder -> Copy to an explicit destination path ---- #
    # Runs copyf with the same runtime source and destination arguments.
    # -----------------------------------------------------------------
    copyfolder = {
      command.copyfolder = { };
      enable = true;
      installOn = { darwin = true; linux = true; };
    };

    # -----------------------------------------------------------------
    # ---- zz -> Pick zoxide path with fzf ---- #
    # Starts its zoxide query from Ven's home directory on each platform.
    # -----------------------------------------------------------------
    zz = {
      command.zz = {
        path = {
          darwin = paths.darwin.home.root;
          linux = paths.linux.home.root;
        };
        fzf = {
          height = "60%";
          prompt = "zoxide cd> ";
        };
      };
      enable = true;
      installOn = { darwin = true; linux = true; };
    };

    # -----------------------------------------------------------------
    # ---- unarchive -> Extract archives and optionally remove them ---- #
    # Archive paths remain runtime arguments because every invocation may differ.
    # -----------------------------------------------------------------
    unarchive = {
      command.unarchive.deleteFiles = false;
      enable = true;
      installOn = { darwin = true; linux = true; };
    };
  };

  abbreviations = {
      # ---------- Files and Folders ---------- #

      # --- msd -> SUDO_EDITOR=micro sudoedit
      ## Open system files with micro user config

      msd = {
        command = {
          darwin = "SUDO_EDITOR=micro sudoedit";
          linux = "SUDO_EDITOR=micro sudoedit";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
      # ---------- Additional replacements ---------- #

      # --- - -> cd -
      ## Jump back to the previous directory

      "-" = {
        command = {
          darwin = "cd -";
          linux = "cd -";
        };
        enable = true;
        installOn = {
          darwin = true;
          linux = true;
        };
      };
  };
in
{
  config = {
    ven.features.terminal.aliases.shell = terminalAliasEntries.mkDefaults shellAliases;

    ven.features.terminal.aliases.functions = terminalAliasEntries.mkDefaults functions;

    ven.features.terminal.aliases.abbreviations = terminalAliasEntries.mkDefaults abbreviations;
  };
}
