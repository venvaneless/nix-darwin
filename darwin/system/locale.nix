# darwin/system/locale.nix
#
# =====================================================================
# SYSTEM LOCALE: SETTINGS
# =====================================================================

{ ... }:

{
  environment.variables = {
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };
}