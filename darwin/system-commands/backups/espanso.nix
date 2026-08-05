# darwin/system-commands/backups/espanso.nix
# Espanso backup command: `espanso-backup`.

{ lib, pkgs, ... }:

let
  espansoBackup = import ./app-backup-helper.nix {
    inherit lib pkgs;
    appName = "Espanso";
    appSlug = "espanso";
    sources = [
      { path = "/Users/ven/.config/espanso"; destination = "user-config/espanso"; }
      { path = "/Users/ven/Library/Preferences/com.federicoterzi.espanso.plist"; destination = "com.federicoterzi.espanso.plist"; }
    ];
  };
in
{
  environment.systemPackages = [ espansoBackup ];
}
