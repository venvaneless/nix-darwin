# /Users/ven/.config/nix/nix-darwin/darwin/modules/terminal/aliases/test-aliases.nix

{ lib, ... }:

{
  programs.zsh.shellAliases = {
    # ---------- Core ---------- #

    # Use bat instead of cat for syntax highlighting and nicer output.
    cat = "bat";

    # Use zoxide for smarter directory jumping in Zsh.
    cd = "z";

    # Clear the terminal screen quickly.
    ccx = "clear";

    # Jump from the current shell into zsh.
    ess = "exec zsh";

    # Run fastfetch manually.
    ff = "fastfetch";

    # List files, including hidden ones except . and ...
    la = "ls -A";

    # List files in long format with human-readable sizes.
    lh = "ls -lah";

    # Use micro instead of nano.
    nano = "micro";

    # Funny sudo alias.
    please = "sudo";

    # Launch yazi file manager.
    yy = "yazi";



    # ---------- Shell ---------- #

    # Open the main Fish config in micro.
    fishcfg = "micro /home/ven/.config/terminal/fish/config-ven.fish";

    # Search through command history with grep.
    hgrep = "history | grep";

    # Show shell history quickly.
    hist = "history";

    # Reload the main Fish config in the current shell.
    reloadfish = "source /home/ven/.config/terminal/fish/config-ven.fish";

    # Reload the main Zsh config in the current shell.
    reloadzsh = "source /home/ven/.config/terminal/zsh/.zshrc";

    # Open the main Zsh config in micro.
    zshcfg = "micro /home/ven/.config/terminal/zsh/.zshrc";



    # ---------- Packages ---------- #

    # Show installed packages sorted by installed size.
    big = "expac -H M \"%m\\t%n\" | sort -h | nl";

    # Remove stale pacman lock file.
    fixpacman = "sudo rm /var/lib/pacman/db.lck";

    # Count installed -git packages.
    gitpkg = "pacman -Q | grep -i \"\\-git\" | wc -l";

    # Show the 200 most recently installed packages.
    rip = "expac --timefmt=\"%Y-%m-%d %T\" \"%l\\t%n %v\" | sort | tail -200 | nl";

    # Remove a package without dependency checks.
    rmpkg = "sudo pacman -Rdd";

    # Run Garuda update tool.
    garuda -u = "/usr/bin/garuda-update";



    # ---------- System ---------- #

    # Colorized dir output.
    dir = "dir --color=auto";

    # Regenerate GRUB config.
    grubup = "sudo update-grub";

    # Show short hardware summary.
    hw = "hwinfo --short";

    # Show recent boot errors from the journal.
    jctl = "journalctl -p 3 -xb";

    # Colorized vdir output.
    vdir = "vdir --color=auto";

    # Continue partial downloads automatically.
    wget = "wget -c ";



    # ---------- Network and sources ---------- #

    # Use colorized ip output.
    ip = "ip -color";

    # Show local IP addresses from network interfaces.
    localip = "ip addr show | grep \"inet \"";

    # Refresh mirrors using a balanced reflector preset.
    mirror = "sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist";

    # Refresh mirrors sorted by age.
    mirrora = "sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist";

    # Refresh mirrors sorted by delay.
    mirrord = "sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist";

    # Refresh mirrors sorted by score.
    mirrors = "sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist";

    # Show public IPv4 address.
    myip = "curl -4 ifconfig.me";

    # Pipe text to termbin for quick sharing.
    tb = "nc termbin.com 9999";



    # ---------- Processes ---------- #

    # Show running processes in tree-like format.
    psa = "ps auxf";

    # Search running processes by name.
    psg = "ps aux | grep -i";

    # Show processes sorted by RAM usage.
    psmem = "ps auxf | sort -nr -k 4";

    # Show the top 10 RAM-hungry processes.
    psmem10 = "ps auxf | sort -nr -k 4 | head -10";



    # ---------- Disk and files ---------- #

    # Jump back to the previous directory.
    "-" = "cd -";

    # Go up one directory.
    ".." = "cd ..";

    # Go up two directories.
    "..." = "cd ../..";

    # Go up three directories.
    "...." = "cd ../../..";

    # Go up four directories.
    "....." = "cd ../../../..";

    # Go up five directories.
    "......" = "cd ../../../../..";

    # Show the 40 biggest files/directories from the current directory downward.
    biggest = "du -ah . | sort -hr | head -40";

    # Ask before overwriting when copying files.
    cp = "cp -i";

    # Show mounted filesystem usage in human-readable format.
    dfh = "df -h";

    # Show folder sizes in the current directory sorted by size.
    duh = "du -sh ./* .[^.]* 2>/dev/null | sort -h";

    # List hidden files in long format with icons.
    "l." = "eza -ald --color=always --group-directories-first --icons .*";

    # Long listing with icons.
    ll = "eza -l --color=always --group-directories-first --icons";

    # Use eza instead of ls with hidden files shown.
    ls = "eza -al --color=always --group-directories-first --icons";

    # Show directory tree with icons.
    lt = "eza -aT --color=always --group-directories-first --icons";

    # Create parent directories as needed and print what gets created.
    mkdir = "mkdir -pv";

    # Ask before overwriting when moving files.
    mv = "mv -i";

    # Ask before deleting files.
    rm = "rm -i";



    # ---------- Navigation ---------- #

    # This section is intentionally kept for future non-file navigation aliases.

    # ---------- UGREP ---------- #

    # Use ugrep for extended regex searches.
    egrep = "ugrep -E --color=auto";

    # Use ugrep for fixed-string searches.
    fgrep = "ugrep -F --color=auto";

    # Use ugrep instead of grep.
    grep = "ugrep --color=auto";



    # ---------- Archives ---------- #

    # Quick archive creation helper.
    tarnow = "tar -acf ";

    # Quick extract helper for .tar.gz style archives.
    untar = "tar -zxvf ";

    # ---------- Helpers ---------- #

    # Remind yourself to use tldr for quick command help.
    helpme = "echo \"To print basic information about a command use tldr <command>\"";

    # Run pacdiff with meld as the diff tool.
    pacdiff = "sudo -H DIFFPROG=meld pacdiff";
  };
}