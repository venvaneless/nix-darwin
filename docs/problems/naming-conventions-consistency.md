- Since there's need for consistency and we already have similiarly named settings, shouldn't the format be

```nix
system.darwin.services.<purpose>.<packageorapp>
```

so

```nix
system.,darwin.services.backups.terminals.wezterm
system.,darwin.services.backups.apps.vscode
system.,darwin.services.backups.certificates.mkcert
```

instead of:

```nix
services.backups.apps.mkcert
```

?
