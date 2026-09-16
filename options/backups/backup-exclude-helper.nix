# options/backups/backup-exclude-helper.nix
# Shared exclusions and run logs for every backup runner.

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
    lib.concatMapStringsSep " " (pattern: "-x ${lib.escapeShellArg pattern} -x ${lib.escapeShellArg "*/${pattern}"}") patterns;

  # ---- RUN LOGS
  # Needs $app_slug set first. Defines $log_file and $error_log_file, sends
  # stderr to the error log, and keeps the terminal's stderr on fd 4.
  mkRunLogSetup = { pkgs, cfg }: ''
    log_directory=${lib.escapeShellArg cfg.logDirectory}
    log_timestamp="$(${pkgs.coreutils}/bin/date ${lib.escapeShellArg "+${cfg.logTimestampFormat}"})"
    log_name_template=${lib.escapeShellArg cfg.logFilenameTemplate}
    error_log_name_template=${lib.escapeShellArg cfg.errorLogFilenameTemplate}
    log_name="''${log_name_template//\{timestamp\}/$log_timestamp}"
    log_name="''${log_name//\{appSlug\}/$app_slug}"
    error_log_name="''${error_log_name_template//\{timestamp\}/$log_timestamp}"
    error_log_name="''${error_log_name//\{appSlug\}/$app_slug}"
    log_file="$log_directory/$log_name"
    error_log_file="$log_directory/$error_log_name"

    ${pkgs.coreutils}/bin/mkdir -p -- "$log_directory"
    exec 4>&2
    exec 2> >(${pkgs.coreutils}/bin/tee -a -- "$error_log_file" >&4)
    error_log_pid=$!
  '';

  # Flushes the error log and drops it when the run wrote no errors.
  mkRunLogClose = { pkgs }: ''
    exec 2>&4
    wait "$error_log_pid" 2>/dev/null || true
    if [ ! -s "$error_log_file" ]; then
      ${pkgs.coreutils}/bin/rm -f -- "$error_log_file"
    fi
  '';
in
{
  inherit
    defaultMetadataExcludePatterns
    mkRsyncExcludeArguments
    mkZipExcludeArguments
    mkRunLogSetup
    mkRunLogClose
    ;
}
