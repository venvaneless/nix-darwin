# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/aliases/shell-aliases.nix

{ ... }:

{
  programs.zsh.shellAliases = {
    # ---------- Core ---------- #

    # --- ccx -> clear
    ## Clear the terminal screen quickly
    ccx = "clear";

    # --- cd -> z
    ## Use zoxide for smarter directory jumping in Zsh
    cd = "z";

    # --- ess -> exec zsh
    ## Jump from the current shell into zsh
    ess = "exec zsh";

    # --- ff -> fastfetch
    ## Run fastfetch manually
    ff = "fastfetch";

    # --- la -> ls -A
    ## List files, including hidden ones except . and ...
    la = "ls -A";

    # --- lh -> ls -lah
    ## List files in long format with human-readable sizes
    lh = "ls -lah";

    # --- nano -> micro
    ## Use micro instead of nano
    nano = "micro";

    # --- please -> sudo
    ## Funny sudo alias
    please = "sudo";

    # --- yy -> yazi
    ## Launch yazi file manager
    yy = "yazi";

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

    # ---------- Additional replacements ---------- #

    # --- - -> cd -
    ## Jump back to the previous directory
    "-" = "cd -";

    # --- hgrep -> history | grep
    ## Search through command history with grep
    hgrep = "history | grep";

    # --- hist -> history
    ## Show shell history quickly
    hist = "history";

    # --- localip -> ifconfig | grep 'inet '
    ## Show local IP addresses from network interfaces
    localip = "ifconfig | grep 'inet '";

    # --- mkdir -> mkdir -pv
    ## Create parent directories as needed and print what gets created
    mkdir = "mkdir -pv";

    # --- myip -> curl -4 ifconfig.me
    ## Show public IPv4 address
    myip = "curl -4 ifconfig.me";

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

    # ---------- Eza Navigation ---------- #

    # --- l. -> show hidden entries with eza
    ## List hidden files in long format with icons
    "l." = "eza -ald --color=always --group-directories-first --icons .*";

    # --- ll -> eza long listing
    ## Long listing with icons
    ll = "eza -l --color=always --group-directories-first --icons";

    # --- ls -> eza all listing
    ## Use eza instead of ls with hidden files shown
    ls = "eza -al --color=always --group-directories-first --icons";

    # --- lt -> eza tree
    ## Show directory tree with icons
    lt = "eza -aT --color=always --group-directories-first --icons";

    # ---------- Helpers ---------- #

    # --- helpme
    ## Remind yourself to use tldr for quick command help
    helpme = "echo \"To print basic information about a command use tldr <command>\"";

    # --- tb
    ## Pipe text to termbin for quick sharing
    tb = "nc termbin.com 9999";

    # ---------- Archiving ---------- #

    # --- targz -> tar -czvf
    ## Create a .tar.gz archive from the current folder or a chosen folder
    targz = "tar -czvf ";

    # --- tarbz2 -> tar -cjvf
    ## Create a .tar.bz2 archive from the current folder or a chosen folder
    tarbz2 = "tar -cjvf ";

    # --- tarnow -> tar -acf
    ## Create an archive and auto-select compression from the file extension
    tarnow = "tar -acf ";

    # --- tarxz -> tar -cJvf
    ## Create a .tar.xz archive from the current folder or a chosen folder
    tarxz = "tar -cJvf ";

    # --- ungz -> gunzip -k
    ## Extract a .gz file and keep the original compressed file
    ungz = "gunzip -k ";

    # --- untar -> tar -xzvf
    ## Extract a .tar.gz style archive
    untar = "tar -xzvf ";

    # --- untarbz2 -> tar -xjvf
    ## Extract a .tar.bz2 archive
    untarbz2 = "tar -xjvf ";

    # --- untarxz -> tar -xJvf
    ## Extract a .tar.xz archive
    untarxz = "tar -xJvf ";

    # --- unzipf -> unzip
    ## Extract a .zip archive into the current directory
    unzipf = "unzip ";

    # --- wget -> wget -c
    ## Continue partial downloads automatically
    wget = "wget -c ";

    # --- zipdir -> zip -r
    ## Create a .zip archive from the current folder or a chosen folder
    zipdir = "zip -r ";

    # ---------- Processes ---------- #

    # --- kpid -> kill -9
    ## Force-kill a process by PID
    kpid = "kill -9";

    # --- kpname -> pkill -i
    ## Kill processes by name, case-insensitively
    kpname = "pkill -i";

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

    # ---------- Safe replacements ---------- #

    # --- cp -> cp -i
    ## Ask before overwriting when copying files
    cp = "cp -i";

    # --- mv -> mv -i
    ## Ask before overwriting when moving files
    mv = "mv -i";

    # --- rm -> rm -i
    ## Ask before deleting files
    rm = "rm -i";

    # ---------- Shell ---------- #

    # --- reloadzsh -> reload Zsh config
    ## Reload the main Zsh config in the current shell
    reloadzsh = "source /Users/ven/.config/zsh/.zshrc";

    # --- zshcfg -> edit Zsh config
    ## Open the main Zsh config in micro
    zshcfg = "micro /Users/ven/.config/terminal/zsh/.zshrc";

    # ---------- Tools ---------- #

    # --- dir
    ## Colorized dir output
    dir = "dir --color=auto";
    
    # --- fgrep
    ## fixed-string searches
    fgrep = "rg -F --color=auto";

    # --- ip -> ifconfig
    ## Use ifconfig for network interface inspection on macOS
    ip = "ifconfig";

    # --- vdir
    ## Colorized vdir output
    vdir = "vdir --color=auto";
  };
}
