# darwin/system-commands/backups/backup-exclude-helper.nix
# Shared rsync exclusions for every backup runner.

{ lib }:

let
  # ---- DEFAULT METADATA EXCLUSIONS
  # macOS metadata and archive wrapper files are recreated automatically and
  # never belong in a backup archive or mirror.
  defaultMetadataExcludePatterns = [
    ".DS_Store"
    "._*"
    ".AppleDouble"
    ".DocumentRevisions-V100"
    ".fseventsd"
    ".LSOverride"
    ".Spotlight-V100"
    ".TemporaryItems"
    ".Trashes"
    ".Trash"
    ".Trash-*"
    "__MACOSX"
  ];

  mkRsyncExcludeArguments = patterns:
    lib.concatMapStringsSep "\n" (pattern: ''
      --exclude=${lib.escapeShellArg pattern}
    '') patterns;

  mkZipExcludeArguments = patterns:
    lib.concatMapStringsSep " " (pattern: "-x ${lib.escapeShellArg "*/${pattern}"}") patterns;
in
{
  inherit defaultMetadataExcludePatterns mkRsyncExcludeArguments mkZipExcludeArguments;
}
