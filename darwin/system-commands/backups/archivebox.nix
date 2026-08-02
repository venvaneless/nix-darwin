# darwin/system-commands/backups/archivebox.nix
#
# Backs up ArchiveBox container data to iCloud Drive. The SQLite database
# is copied with SQLite's online backup API before the ZIP is created.

{
  config,
  lib,
  pkgs,
  ...
}:

import ./mk-container-backup.nix {
  inherit config lib pkgs;

  appName = "ArchiveBox";
  appSlug = "archivebox";
  sourceDir = config.services.archivebox.dataDir;

  prepareArchive = ''
    staging_dir="$(
      ${pkgs.coreutils}/bin/mktemp -d "/private/tmp/archivebox-backup.XXXXXX"
    )"
    archive_source_parent="$staging_dir"
    archive_source_name="$source_name"
    staged_source="$staging_dir/$source_name"

    ${pkgs.coreutils}/bin/mkdir -p -- "$staged_source"
    ${pkgs.rsync}/bin/rsync -a \
      --exclude='index.sqlite3' \
      --exclude='index.sqlite3-shm' \
      --exclude='index.sqlite3-wal' \
      -- "$source_dir/" "$staged_source/"

    if [ ! -f "$source_dir/index.sqlite3" ]; then
      fail "ArchiveBox SQLite database does not exist: $source_dir/index.sqlite3"
    fi

    ${pkgs.coreutils}/bin/timeout 300 \
      ${pkgs.sqlite}/bin/sqlite3 \
      "$source_dir/index.sqlite3" \
      ".backup '$staged_source/index.sqlite3'"
  '';
}
