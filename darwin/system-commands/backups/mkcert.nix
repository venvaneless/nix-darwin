# darwin/system-commands/backups/mkcert.nix
#
# =====================================================================
# MKCERT BACKUP
#
# Mirrors the mkcert CA directory to the external backup volume as
# `mkcert-backup`.
#
# - No archive and no timestamped copies: the destination is a plain
#   mirror, so restoring is a straight copy back.
# - Nothing is written when the certificates have not changed, whether
#   the command runs manually or from a schedule.
# - With encrypt on, every file is mirrored as <name>.age and changes are
#   detected from a checksum list, since age output differs on every run.
# =====================================================================

{ backupExcludeHelper, config, paths, lib, pkgs, ... }:

let
  # ---- SHARED PATHS ---- #
  # The CA root, the backup volume layout, and the mount check come from
  # the centralized path definitions.
  backupPaths = paths.darwin.backups;
  excludeHelper = backupExcludeHelper;

  # ---- BACKUP PATHS
  # ** Certificates live beside the other data backups rather than under
  # ** app-backups, because this is a mirror and not an application
  # ** archive. Change the location in options/paths.nix.
  sourceDir = paths.darwin.home.mkcert;
  destinationDir = backupPaths.certificates;
  showProgress = true;
  stageInDownloads = true;
  encrypt = true;
  encryptionIdentityFile = paths.darwin.home.sopsAgeKeys;
  cfg = config.services.appBackups.mkcert;
  progressEnabled = config.services.appBackups.mkcert.showProgress;
  defaultMetadataExcludes = excludeHelper.mkRsyncExcludeArguments excludeHelper.defaultMetadataExcludePatterns;

  mkcertBackup = pkgs.writeShellApplication {
    name = "mkcert-backup";
    runtimeInputs = with pkgs; [ age cpulimit coreutils diffutils findutils gnugrep rsync ];
    text = ''
      set -euo pipefail

      source_dir="${sourceDir}"
      destination_dir="${destinationDir}"
      external_backup_volume="${backupPaths.volume}"
      cpu_limit_percent=10
      transfer_limit_kibps=4096
      show_progress=${if progressEnabled then "1" else "0"}
      stage_in_downloads=${if config.services.appBackups.mkcert.stageInDownloads then "1" else "0"}
      staging_dir="${backupPaths.staging}/mkcert"
      encrypt=${if cfg.encrypt then "1" else "0"}
      age_identity_file=${lib.escapeShellArg cfg.encryptionIdentityFile}
      encrypted_work_dir=""
      checksum_file_name=".source-sha256"
      rsync_progress_args=()
      if [ "$show_progress" -eq 1 ]; then
        rsync_progress_args+=(--info=progress2 --no-inc-recursive)
      fi
      exclude_args=(
${defaultMetadataExcludes}
      )
      global_lock_dir="${backupPaths.archiveLock}"
      global_lock_acquired=0

      backup_process() {
        ${pkgs.coreutils}/bin/nice -n 20 ${pkgs.cpulimit}/bin/cpulimit -l "$cpu_limit_percent" -- "$@"
      }

      fail() {
        echo "[mkcert backup] ERROR $*" >&2
        exit 1
      }

      release_backup_lock() {
        ${pkgs.coreutils}/bin/rm -rf -- "$staging_dir" 2>/dev/null || true
        if [ -n "$encrypted_work_dir" ]; then
          ${pkgs.coreutils}/bin/rm -rf -- "$encrypted_work_dir" 2>/dev/null || true
        fi
        ${pkgs.coreutils}/bin/rmdir -- "${backupPaths.staging}" 2>/dev/null || true
        if [ "$global_lock_acquired" -eq 1 ]; then
          ${pkgs.coreutils}/bin/rm -f -- "$global_lock_dir/pid" 2>/dev/null || true
          ${pkgs.coreutils}/bin/rmdir -- "$global_lock_dir" 2>/dev/null || true
        fi
      }

      acquire_backup_lock() {
        if ! ${pkgs.coreutils}/bin/mkdir -- "$global_lock_dir" 2>/dev/null; then
          previous_pid=""
          if [ -r "$global_lock_dir/pid" ]; then
            IFS= read -r previous_pid < "$global_lock_dir/pid" || true
          fi
          if [ -n "$previous_pid" ] && kill -0 "$previous_pid" 2>/dev/null; then
            fail "another backup is already running"
          fi
          ${pkgs.coreutils}/bin/rm -f -- "$global_lock_dir/pid"
          ${pkgs.coreutils}/bin/rmdir -- "$global_lock_dir" || fail "refusing to replace an unexpected backup lock"
          ${pkgs.coreutils}/bin/mkdir -- "$global_lock_dir"
        fi

        printf '%s\n' "$$" > "$global_lock_dir/pid"
        global_lock_acquired=1
      }

      trap release_backup_lock EXIT
      trap 'exit 130' INT TERM

      # ---- PREREQUISITES ---- #

      if [ ! -d "$source_dir" ]; then
        echo "[mkcert backup] ERROR missing source: $source_dir" >&2
        exit 1
      fi

      # ** An unmounted volume leaves a writable empty directory at the
      # ** same path, so the mount itself has to be verified.
      if [ ! -d "$external_backup_volume" ] || ! ${paths.darwin.system.bin.mount} | ${pkgs.gnugrep}/bin/grep -Fq " on $external_backup_volume "; then
        echo "[mkcert backup] ERROR external backup volume is not mounted" >&2
        exit 1
      fi

      if [ "$encrypt" -eq 1 ]; then
        if [ ! -r "$age_identity_file" ]; then
          fail "age identity file is missing or unreadable: $age_identity_file"
        fi
        age_recipient="$(${pkgs.age}/bin/age-keygen -y "$age_identity_file")" \
          || fail "could not read the public key from: $age_identity_file"
      fi

      acquire_backup_lock
      ${pkgs.coreutils}/bin/mkdir -p -- "$destination_dir"

      if [ "$encrypt" -eq 1 ]; then
        # ---- ENCRYPTED MIRROR ---- #
        source_checksums="$(
          cd -- "$source_dir"
          ${pkgs.findutils}/bin/find . -type f ! -name '.DS_Store' ! -name '._*' -print0 \
            | ${pkgs.coreutils}/bin/sort -z \
            | ${pkgs.findutils}/bin/xargs -0 -r ${pkgs.coreutils}/bin/sha256sum
        )"

        if [ -f "$destination_dir/$checksum_file_name" ] \
          && [ "$source_checksums" = "$(${pkgs.coreutils}/bin/cat -- "$destination_dir/$checksum_file_name")" ]; then
          echo "[mkcert backup] SKIP no certificate changes since the last backup"
          exit 0
        fi

        if [ "$stage_in_downloads" -eq 1 ]; then
          encrypted_work_dir="$staging_dir"
          ${pkgs.coreutils}/bin/rm -rf -- "$encrypted_work_dir"
          ${pkgs.coreutils}/bin/mkdir -p -- "$encrypted_work_dir"
        else
          encrypted_work_dir="$(${pkgs.coreutils}/bin/mktemp -d "${backupPaths.lockRoot}/mkcert-backup.XXXXXX")"
        fi

        # Each file is encrypted, then proven to decrypt back to the original.
        while IFS= read -r -d "" relative_path; do
          relative_path="''${relative_path#./}"
          ${pkgs.coreutils}/bin/mkdir -p -- "$( ${pkgs.coreutils}/bin/dirname -- "$encrypted_work_dir/$relative_path" )"
          echo "[mkcert backup] ENCRYPT $relative_path"
          ${pkgs.age}/bin/age -r "$age_recipient" -o "$encrypted_work_dir/$relative_path.age" "$source_dir/$relative_path" \
            || fail "could not encrypt: $relative_path"
          ${pkgs.age}/bin/age -d -i "$age_identity_file" "$encrypted_work_dir/$relative_path.age" \
            | ${pkgs.diffutils}/bin/cmp -s - "$source_dir/$relative_path" \
            || fail "encrypted copy does not decrypt to the original: $relative_path"
        done < <(
          cd -- "$source_dir"
          ${pkgs.findutils}/bin/find . -type f ! -name '.DS_Store' ! -name '._*' -print0
        )
        printf '%s\n' "$source_checksums" > "$encrypted_work_dir/$checksum_file_name"

        echo "[mkcert backup] COPY $encrypted_work_dir -> $destination_dir"
        backup_process ${pkgs.rsync}/bin/rsync -a --bwlimit="$transfer_limit_kibps" --human-readable "''${rsync_progress_args[@]}" "''${exclude_args[@]}" -- "$encrypted_work_dir/" "$destination_dir/"

        # Drop plain copies left by earlier unencrypted runs.
        while IFS= read -r -d "" plain_copy; do
          if [ -f "$plain_copy.age" ]; then
            echo "[mkcert backup] REMOVE unencrypted copy: $plain_copy"
            ${pkgs.coreutils}/bin/rm -f -- "$plain_copy"
          fi
        done < <(
          ${pkgs.findutils}/bin/find "$destination_dir" -type f ! -name '*.age' ! -name "$checksum_file_name" -print0
        )

        echo "[mkcert backup] DONE $destination_dir"
        exit 0
      fi

      # ---- CHANGE DETECTION ---- #
      # A dry run lists one line per item rsync would transfer. Lines
      # beginning with a dot are items rsync is leaving alone, so they
      # are dropped and only real content changes remain.
      #
      # ** This keeps a manual run free of side effects when nothing has
      # ** changed: the mirror is not touched and its timestamps stay as
      # ** they were at the last real backup.
      pending="$(
        ${pkgs.rsync}/bin/rsync -a --itemize-changes --dry-run "''${exclude_args[@]}" \
          -- "$source_dir/" "$destination_dir/" \
          | ${pkgs.gnugrep}/bin/grep -v '^\.' || true
      )"

      if [ -z "$pending" ]; then
        echo "[mkcert backup] SKIP no certificate changes since the last backup"
        exit 0
      fi

      # ---- SYNC ---- #

      echo "[mkcert backup] CHANGED:"
      printf '%s\n' "$pending" | while IFS= read -r change; do
        echo "[mkcert backup]   $change"
      done

      # Stage a verified local copy in Downloads before touching the volume.
      sync_source="$source_dir"
      if [ "$stage_in_downloads" -eq 1 ]; then
        ${pkgs.coreutils}/bin/rm -rf -- "$staging_dir"
        ${pkgs.coreutils}/bin/mkdir -p -- "$staging_dir"
        echo "[mkcert backup] STAGE $source_dir -> $staging_dir"
        backup_process ${pkgs.rsync}/bin/rsync -a --bwlimit="$transfer_limit_kibps" --human-readable "''${rsync_progress_args[@]}" "''${exclude_args[@]}" -- "$source_dir/" "$staging_dir/"
        sync_source="$staging_dir"
      fi

      echo "[mkcert backup] COPY $sync_source -> $destination_dir"
      backup_process ${pkgs.rsync}/bin/rsync -a --bwlimit="$transfer_limit_kibps" --human-readable "''${rsync_progress_args[@]}" "''${exclude_args[@]}" -- "$sync_source/" "$destination_dir/"
      echo "[mkcert backup] DONE $destination_dir"
    '';
  };
in
{
  options.services.appBackups.mkcert = {
    showProgress = lib.mkOption {
      type = lib.types.bool;
      default = showProgress;
      description = "Show rsync transfer progress for the mkcert backup.";
    };

    stageInDownloads = lib.mkOption {
      type = lib.types.bool;
      default = stageInDownloads;
      description = "Copy the certificates to the Downloads staging folder before mirroring them to the volume.";
    };

    encrypt = lib.mkOption {
      type = lib.types.bool;
      default = encrypt;
      description = "Mirror every file as an age-encrypted <name>.age.";
    };

    encryptionIdentityFile = lib.mkOption {
      type = lib.types.str;
      default = encryptionIdentityFile;
      description = "age identity file; its public key encrypts, the file itself verifies.";
    };
  };

  config.environment.systemPackages = [ mkcertBackup ];
}
