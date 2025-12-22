# darwin/modules/system/locale.nix
{ ... }:

{
  launchd.user.env = {
    LANG   = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };
}
