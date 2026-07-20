# /Users/ven/.config/nix/nix-config/darwin/modules/terminal/aliases/shell-aliases.nix
# 
# =====================================================================
# SHELL: ALIASES
# =====================================================================
{ ... }:

{
  programs.fish.shellAliases = {
    # ---------- Core ---------- #

    # --- freload -> reload Fish config
    ## Reload the generated Fish config in the current shell
    freload = "exec fish -l";
    
    # --- cat -> bat
    ## Use bat instead of cat for syntax highlighting and nicer output
    cat = "bat";

    # --- ccx -> clear
    ## Clear the terminal screen quickly
    ccx = "clear";

    # --- cd -> z
    ## Use zoxide for smarter directory jumping in Fish
    cd = "z";

    # --- fishcfg -> edit Fish config
    ## Open the generated Fish config in micro
    fishcfg = "micro /Users/ven/.config/fish/config.fish";

    # --- reloadfish -> reload Fish config
    ## Reload the generated Fish config in the current shell
    reloadfish = "source /Users/ven/.config/fish/config.fish";

    # --- ff -> fastfetch
    ## Run fastfetch manually
    ff = "fastfetch";

    # --- hgrep -> history | rg
    ## Search through command history with ripgrep
    hgrep = "history | rg";

    # --- hist -> history
    ## Show shell history quickly
    hist = "history";

    # --- nano -> micro
    ## Use micro instead of nano
    nano = "micro";

    # --- please -> sudo
    ## Funny sudo alias
    please = "sudo";

    # --- smicro -> sudo micro with user config
    ## Open files with sudo while keeping your micro config
    smicro = "sudo micro -config-dir ~/.config/micro";


    # ---------- Files and Folders ---------- #

    # --- cp -> cp -i
    ## Ask before overwriting when copying files
    cp = "cp -i";

    # --- mv -> mv -i
    ## Ask before overwriting when moving files
    mv = "mv -i";

    # --- rm -> rm -i
    ## Ask before deleting files
    rm = "rm -i";

    # ---------- Additional replacements ---------- #


    # --- localip -> ifconfig | grep 'inet '
    ## Show local IP addresses from network interfaces
    localip = "ifconfig | grep 'inet '";

    # --- mkdir -> mkdir -pv
    ## Create parent directories as needed and print what gets created
    mkdir = "mkdir -pv";

    # --- mkpv -> mkdir -pv
    ## Create parent directories as needed and print what gets created
    mkpv = "mkdir -pv";

    # --- myip -> curl -4 ifconfig.me
    ## Show public IPv4 address
    myip = "curl -4 ifconfig.me";

    # ---------- Processes ---------- #

    # --- kpid -> kill -9
    ## Force-kill a process by PID
    kpid = "kill -9";

    # --- kpname -> pkill -i
    ## Kill processes by name, case-insensitively
    kproc = "pkill -i";

    # --- pfind -> pgrep -ifl
    ## Find processes by name with PID and command line
    pfind = "pgrep -ifl";

    # --- psa -> ps aux
    ## Show running processes
    psa = "ps aux";

    # --- psg -> ps aux | grep -i
    ## Search running processes by name
    psg = "ps aux | grep -i";

    # --- psmem
    ## Show processes sorted by RAM usage
    psmem = "ps aux | sort -nr -k 4";

    # --- psmem10
    ## Show the top 10 RAM-hungry processes
    psmem10 = "ps aux | sort -nr -k 4 | head -10";

    # ---------- System ---------- #

    # --- cpuinfo -> sysctl -n machdep.cpu.brand_string
    ## Show CPU model name
    cpuinfo = "sysctl -n machdep.cpu.brand_string";

    # --- meminfo -> vm_stat
    ## Show virtual memory statistics
    meminfo = "vm_stat";

    # --- osinfo -> sw_vers
    ## Show macOS version information
    osinfo = "sw_vers";

    # --- sysinfo -> system_profiler SPSoftwareDataType
    ## Show macOS software/system overview
    sysinfo = "system_profiler SPSoftwareDataType";

    # --- syshw -> system_profiler SPHardwareDataType
    ## Show Mac hardware summary
    syshw = "system_profiler SPHardwareDataType";

    # --- upd -> softwareupdate -ia
    ## Install all available macOS software updates
    upd = "softwareupdate -ia";

    # ---------- Better disk usage shortcuts ---------- #

    # --- biggest -> du -ah . | sort -hr | head -40
    ## Show the 40 biggest files/directories from the current directory downward
    biggest = "du -ah . | sort -hr | head -40";

    # --- dfh -> df -h
    ## Show mounted filesystem usage in human-readable format
    dfh = "df -h";

    # --- duh -> du -sh ...
    ## Show folder sizes in the current directory sorted by size
    duh = "du -sh ./* .[^.]* 2>/dev/null | sort -h";

    # ---------- Archiving ---------- #

    # --- rardir -> rar archive helper
    ## Create a .rar archive named after the target folder
    rardir = ''
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

# --- unrar -> extract rar
## Extract a .rar archive into the current directory and keep the original archive
unrar = "unrar x";

# --- unrard -> extract rar and delete archive
## Extract a .rar archive into the current directory and delete the original archive
unrard = ''
  function _unrard
    unrar x $argv[1]

    and rm -f $argv[1]
  end

  _unrard
'';

# --- zipdir -> zip archive helper
## Create a .zip archive named after the target folder
zipdir = ''
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

# --- unzipf -> extract zip
## Extract a .zip archive into the current directory and keep the original archive
unzipf = "unzip";

# --- unzipd -> extract zip and delete archive
## Extract a .zip archive into the current directory and delete the original archive
unzipd = ''
  function _unzipd
    unzip $argv[1]

    and rm -f $argv[1]
  end

  _unzipd
'';

    # --- wget -> wget -c
    ## Continue partial downloads automatically
    wget = "wget -c ";



    # ---------- Helpers ---------- #

    # --- helpme
    ## Remind yourself to use tldr for quick command help
    helpme = "echo \"To print basic information about a command use tldr <command>\"";

    # --- tb
    ## Pipe text to termbin for quick sharing
    tb = "nc termbin.com 9999";

    # ---------- Eza Navigation ---------- #

    # --- ls -> eza listing
    ## List non-hidden files with icons
    ls = "eza -l --color=always --group-directories-first --icons";

    # --- l. -> Show all files, including hidden entries
    ## List hidden files in long format with icons
    "l." = "eza -la --color=always --group-directories-first --icons";

    # --- la -> eza -A
    ## List files, including hidden ones except . and ..
    la = "eza -A --color=always --group-directories-first --icons";

    # --- lh -> eza -la
    ## List files in long format with human-readable size
    lh = "eza -lah --color=always --group-directories-first --icons";

    # --- ll -> eza long listing
    ## Long listing with icons
    ll = "eza -l --color=always --group-directories-first --icons";

    # --- lt -> eza tree
    ## Show directory tree with icons
    lt = "eza -T --color=always --group-directories-first --icons";

    # --- lt. -> eza hidden tree
    ## Show directory tree including hidden files
    "lt." = "eza -aT --color=always --group-directories-first --icons";


    # ---------- Directory Shortcuts ---------- #

    # --- .. -> parent directory
    ## Go up one directory
    ".." = "cd ..";

    # --- ... -> two levels up
    ## Go up two directories
    "..." = "cd ../..";

    # --- .... -> three levels up
    ## Go up three directories
    "...." = "cd ../../..";

    # --- ..... -> four levels up
    ## Go up four directories
    "....." = "cd ../../../..";

    # --- ...... -> five levels up
    ## Go up five directories
    "......" = "cd ../../../../..";

    # ---------- Tools ---------- #

    # --- dir
    ## Colorized dir output
    dir = "dir --color=auto";

    # --- erg
    ## Use ripgrep for extended regex searches
    erg = "rg --color=auto";

    # --- fgrep
    ## Fixed-string searches
    fgrep = "rg -F --color=auto";

    # --- frg
    ## Use ripgrep for fixed-string searches
    frg = "rg -F --color=auto";

    # --- grep
    ## Use ripgrep instead of grep
    grep = "rg --color=auto";

    # --- ip -> ifconfig
    ## Use ifconfig for network interface inspection on macOS
    ip = "ifconfig";

    # --- vdir
    ## Colorized vdir output
    vdir = "vdir --color=auto";
  };

  programs.fish.shellAbbrs = {
    # ---------- Files and Folders ---------- #

    # --- msd -> SUDO_EDITOR=micro sudoedit
    ## Open system files with micro user config
    msd = "SUDO_EDITOR=micro sudoedit";

    # --- unhide -> chflags nohidden
    ## Remove the macOS hidden flag from files/folders
    unhide = "chflags nohidden";

    # ---------- Additional replacements ---------- #

    # --- - -> cd -
    ## Jump back to the previous directory
    "-" = "cd -";
  };
}
