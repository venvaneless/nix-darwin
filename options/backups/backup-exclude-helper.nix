# options/backups/backup-exclude-helper.nix
# Shared exclusions, run logs, encryption, and iCloud copies for every backup runner.

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

  # Needs $exit_status. Flushes the error log and drops it when empty; with
  # logOnlyOnErrors, a successful run without errors leaves no logs at all.
  mkRunLogClose = { pkgs, cfg }: ''
    exec 2>&4
    wait "$error_log_pid" 2>/dev/null || true
    if [ ! -s "$error_log_file" ]; then
      ${pkgs.coreutils}/bin/rm -f -- "$error_log_file"
${lib.optionalString cfg.logOnlyOnErrors ''
      if [ "$exit_status" -eq 0 ]; then
        ${pkgs.coreutils}/bin/rm -f -- "$log_file"
      fi
''}
    fi
  '';

  # ---- ENCRYPTION
  # The public key is read from the identity file on every run, so no key
  # is stored in the repository.
  archiveSuffix = cfg: lib.optionalString cfg.encrypt ".age";

  # Fails before any copying when the identity file is missing. Needs fail.
  mkEncryptionPreflight = { pkgs, cfg }:
    lib.optionalString cfg.encrypt ''
      age_identity_file=${lib.escapeShellArg cfg.encryptionIdentityFile}
      if [ ! -r "$age_identity_file" ]; then
        fail "age identity file is missing or unreadable: $age_identity_file"
      fi
      age_recipient="$(${pkgs.age}/bin/age-keygen -y "$age_identity_file")" \
        || fail "could not read the public key from: $age_identity_file"
    '';

  # Encrypts a verified archive in place, then proves it decrypts back to
  # the same bytes. Needs log, fail, and mkEncryptionPreflight run first.
  mkEncryptArchive = { pkgs, cfg, archivePath }:
    lib.optionalString cfg.encrypt ''
      log "ENCRYPT archive with age"
      ${pkgs.age}/bin/age -r "$age_recipient" -o "${archivePath}.encrypting" "${archivePath}" \
        || fail "could not encrypt archive: ${archivePath}"
      log "VERIFY encrypted archive decrypts to the original"
      ${pkgs.age}/bin/age -d -i "$age_identity_file" "${archivePath}.encrypting" \
        | ${pkgs.diffutils}/bin/cmp -s - "${archivePath}" \
        || fail "encrypted archive does not decrypt to the original: ${archivePath}"
      ${pkgs.coreutils}/bin/mv -f -- "${archivePath}.encrypting" "${archivePath}"
    '';

  # ---- ICLOUD COPY
  # Copies a finished archive into <iCloudRoot>/<appName in lowercase> and
  # optionally prunes that folder to the newest iCloudBackupsToKeep files.
  # Needs log, fail, $show_progress, and the archive path and name.
  mkICloudCopy = { pkgs, cfg, archivePath, archiveName }:
    lib.optionalString cfg.storeiCloud ''
      icloud_dir=${lib.escapeShellArg "${cfg.iCloudRoot}/${lib.toLower cfg.appName}"}
      icloud_temporary="$icloud_dir/.${archiveName}.$$.incomplete"

      if [ ! -d "$icloud_dir" ]; then
        log "ICLOUD create folder: $icloud_dir"
        ${pkgs.coreutils}/bin/mkdir -p -- "$icloud_dir" || fail "could not create iCloud folder: $icloud_dir"
      fi

      log "ICLOUD copy ${archiveName} -> $icloud_dir"
      if [ "$show_progress" -eq 1 ]; then
        ${pkgs.pv}/bin/pv -N "$app_slug iCloud" -- "${archivePath}" 2>&4 > "$icloud_temporary" \
          || fail "could not copy archive to iCloud: $icloud_dir"
      else
        ${pkgs.coreutils}/bin/cp -- "${archivePath}" "$icloud_temporary" \
          || fail "could not copy archive to iCloud: $icloud_dir"
      fi
      ${pkgs.coreutils}/bin/mv -- "$icloud_temporary" "$icloud_dir/${archiveName}"
      log "ICLOUD stored $icloud_dir/${archiveName}"
${lib.optionalString cfg.cleanOldestiCloud ''
      ${pkgs.findutils}/bin/find "$icloud_dir" -maxdepth 1 -type f ! -name '.*' -printf '%T@\t%p\n' \
        | ${pkgs.coreutils}/bin/sort -rn \
        | ${pkgs.coreutils}/bin/tail -n +${toString (cfg.iCloudBackupsToKeep + 1)} \
        | ${pkgs.coreutils}/bin/cut -f2- \
        | while IFS= read -r old_icloud_backup; do
            log "ICLOUD remove old backup: $old_icloud_backup"
            ${pkgs.coreutils}/bin/rm -f -- "$old_icloud_backup"
          done
''}
    '';
in
{
  inherit
    defaultMetadataExcludePatterns
    mkRsyncExcludeArguments
    mkZipExcludeArguments
    mkRunLogSetup
    mkRunLogClose
    mkICloudCopy
    archiveSuffix
    mkEncryptionPreflight
    mkEncryptArchive
    ;
}
