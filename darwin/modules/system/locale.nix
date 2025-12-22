# darwin/modules/system/locale.nix
{ ... }:

{
  launchd.user.environment = {
    LANG   = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };
}