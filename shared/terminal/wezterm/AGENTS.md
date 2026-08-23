- Wezterm .nix equivalents to their original .lua files have the same relative paths, so for example if a .lua file was here:
```
/Users/ven/.config/wezterm/plugins/helpers.lua
```
... it's nix equivalent should be:
```
shared/terminal/wezterm/plugins/wez-helpers.lua
```

- Wezterm's equivalent for wezterm.lua is:
```
shared/terminal/wezterm/default.nix
```

- The same .lua files that importet lua files, should import them in their nix equivalents, so if a file:
```
fileA.lua
```
imported:
```
fileB.lua
```

... then their nix equivalent:
```
fileA.nix
```

... should import:
```
fileB.nix
```

- Nix equivalents have "wez-" in their filename prefix to distinguish them from similiar files for other apps
- Wezterm should no longer be a homebrew installed app (so it should be removed from homebrew.nix), it should be directly installed through Nix. Since Nix installs the Mac apps in Applications/Nix Apps, I want it symlinked back to /Applications/Programming

- Since Wezterm is an app I will use on all my machines it should be installed through this:
```
shared/packages.nix
```

It should have toggles so I can easily install and unistall it separately for each machine. Every entry in that file carries its own `enable` flag and an `installOn = { darwin; linux; }` toggle. See the same file for examples:
```
shared/packages.nix
```

