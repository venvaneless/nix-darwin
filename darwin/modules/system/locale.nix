# darwin/modules/system/locale.nix
{ ... }:

{
  environment.variables = {
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };
}