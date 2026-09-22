You once said:

```
"If shared/packages.nix only ever installs system packages, there's no problem. The unused "home" branch in the helper and the header comment in shared/packages.nix:10-12 ("standalone Linux Home Manager modules do not import it yet") are leftovers from before your Linux machines were planned as NixOS. The only real gap is that NixOS doesn't load the file, which is the same decision as question 2."
```

What do you mean by "The unused "home" branch in the helper and the header comment are leftovers from before your Linux machines were planned as NixOS"? Do you mean a specific package or service from `packages.nix` will not work on Linux even if it's in `shared/`? if it's a package that belongs to Home Manager, then it should go to `shared/home/packages.nix`, if it's a service to `shared/home/services.nix`, but any packages from the `shared/` should work on all machines regardless of the system.
