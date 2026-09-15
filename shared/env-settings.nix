# shared/env-settings.nix
#
# =====================================================================
# SHARED: ENVIRONMENT SETTING KNOBS
# =====================================================================
#
# The values here apply to every Home Manager host. Their option shape,
# platform selection, validation, and file generation live in
# options/env-settings/default.nix.
# =====================================================================

{ paths, ... }:

{
  home.shared.envSettings.markdownlint = {
    # ------------------------------------------------------------
    # ------ MARKDOWNLINT CONFIGURATION ------ #
    # The Markdownlint extensions for Zed and VS Code discover this
    # real configuration file for every Markdown file they open.

    createSymlink = {
      darwin = true;
      linux = true;
    };

    pathSymlink = {
      darwin = paths.darwin.home.markdownlint;
      linux = paths.linux.home.markdownlint;
    };
  };
}
