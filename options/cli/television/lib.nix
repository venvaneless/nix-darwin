# shared/terminal/cli-tuis/television/lib.nix
#
# =====================================================================
# TELEVISION: NIX CHANNEL HELPERS
#
# Fish helpers own source rendering, context previews, editor actions,
# clipboard actions, Git handling, and portable recent-file ordering.
# =====================================================================

{ lib, pkgs, nixConfigDir, excludedDirectories, isDarwin }:

let
  # ---- SHARED COMMAND VALUES ---- #
  # Explicit package paths keep generated helpers independent of an
  # interactive shell's PATH on both supported platforms.
  fish = "${pkgs.fish}/bin/fish";
  fd = "${pkgs.fd}/bin/fd";
  rg = "${pkgs.ripgrep}/bin/rg";
  bat = "${pkgs.bat}/bin/bat";
  git = "${pkgs.git}/bin/git";
  find = "${pkgs.findutils}/bin/find";
  sort = "${pkgs.coreutils}/bin/sort";
  env = "${pkgs.coreutils}/bin/env";
  nvim = "${pkgs.neovim}/bin/nvim";
  zed = "${pkgs.zed-editor}/bin/zed";
  wlCopy = "${pkgs.wl-clipboard}/bin/wl-copy";
  xclip = "${pkgs.xclip}/bin/xclip";

  # ---- CENTRAL EXCLUSION RENDERING ---- #
  # fd, ripgrep, find, and Git all consume the same directory policy.
  fdExclusions = lib.concatMapStringsSep " " (
    directory: ''
      --exclude ${lib.escapeShellArg directory.name}
      --exclude ${lib.escapeShellArg "${directory.name}/**"}
      --exclude ${lib.escapeShellArg "**/${directory.name}/**"}
    ''
  ) excludedDirectories;
  rgExclusions = lib.concatMapStringsSep " " (
    directory: ''
      --glob ${lib.escapeShellArg "!${directory.name}/**"}
      --glob ${lib.escapeShellArg "!**/${directory.name}/**"}
    ''
  ) excludedDirectories;
  findPruneExpression = lib.concatStringsSep " -o " (
    map (directory: "-name ${lib.escapeShellArg directory.name}") excludedDirectories
  );
  gitExclusionCases = lib.concatMapStringsSep "\n\n" (
    directory: ''
      if string match -rq -- ${lib.escapeShellArg directory.gitPathPattern} "$path"
        return 0
      end
    ''
  ) excludedDirectories;

  # ---- FISH HELPER FACTORY ---- #
  # Helpers are immutable executables in the store; they read but never
  # modify the active Nix configuration repository or Television state.
  mkFishHelper = name: text:
    pkgs.writeTextFile {
      inherit name;
      executable = true;
      text = ''
        #!${fish}
        ${text}
      '';
    };

  # ---- COMMON FISH FUNCTIONS ---- #
  # TV passes one tab-separated result record as the first argument.
  commonFunctions = ''
    function tv_record --argument-names record
      string split \t -- "$record"
    end

    function tv_require_file --argument-names file
      if not test -f "$file"
        echo "Television: file is no longer available: $file" >&2
        return 1
      end
    end
  '';

  # ---- CLIPBOARD ACTIONS ---- #
  # macOS supplies pbcopy. Linux selects Wayland first, then X11, and
  # reports a clear failure instead of claiming success without a display.
  clipboardCopy = mkFishHelper "television-nix-copy-to-clipboard" (
    if isDarwin then
      ''
        command /usr/bin/pbcopy
      ''
    else
      ''
        set clipboard_text (string collect)

        if test -n "$WAYLAND_DISPLAY"
          if printf '%s' "$clipboard_text" | command ${wlCopy}
            exit 0
          end

          if not test -n "$DISPLAY"
            echo "Television: Wayland clipboard copy failed and no X11 display is available." >&2
            exit 1
          end

          echo "Television: Wayland clipboard copy failed; trying X11." >&2
        end

        if test -n "$DISPLAY"
          if printf '%s' "$clipboard_text" | command ${xclip} -selection clipboard
            exit 0
          end

          echo "Television: X11 clipboard copy failed." >&2
          exit 1
        end

        echo "Television: clipboard unavailable; requires WAYLAND_DISPLAY or DISPLAY." >&2
        exit 1
      ''
  );

  # ---- FILE ACTIONS ---- #
  # File records are: relative-path<TAB>absolute-path.
  filePreview = mkFishHelper "television-nix-file-preview" ''
    ${commonFunctions}
    set fields (tv_record "$argv[1]")
    set file "$fields[2]"
    tv_require_file "$file"; or exit 1
    command ${bat} --paging=never --style=numbers --color=always "$file"
  '';

  fileNvim = mkFishHelper "television-nix-file-nvim" ''
    ${commonFunctions}
    set fields (tv_record "$argv[1]")
    set file "$fields[2]"
    tv_require_file "$file"; or exit 1
    command ${nvim} "$file"
  '';

  fileZed = mkFishHelper "television-nix-file-zed" ''
    ${commonFunctions}
    set fields (tv_record "$argv[1]")
    set file "$fields[2]"
    tv_require_file "$file"; or exit 1
    command ${zed} "$file"
  '';

  fileCopyAbsolute = mkFishHelper "television-nix-file-copy-absolute" ''
    ${commonFunctions}
    set fields (tv_record "$argv[1]")
    printf '%s' "$fields[2]" | command ${clipboardCopy}
  '';

  fileCopyRelative = mkFishHelper "television-nix-file-copy-relative" ''
    ${commonFunctions}
    set fields (tv_record "$argv[1]")
    printf '%s' "$fields[1]" | command ${clipboardCopy}
  '';

  # ---- MATCH ACTIONS ---- #
  # Match records are: relative-path:line<TAB>absolute-path<TAB>line.
  matchPreview = mkFishHelper "television-nix-match-preview" ''
    ${commonFunctions}
    set fields (tv_record "$argv[1]")
    set file "$fields[2]"
    set line "$fields[3]"
    tv_require_file "$file"; or exit 1

    set start (math "max(1, $line - 8)")
    set finish (math "$line + 16")
    command ${bat} --paging=never --style=numbers --color=always \
      --line-range "$start:$finish" --highlight-line "$line" "$file"
  '';

  matchNvim = mkFishHelper "television-nix-match-nvim" ''
    ${commonFunctions}
    set fields (tv_record "$argv[1]")
    set file "$fields[2]"
    set line "$fields[3]"
    tv_require_file "$file"; or exit 1
    command ${nvim} "+$line" "$file"
  '';

  matchZed = mkFishHelper "television-nix-match-zed" ''
    ${commonFunctions}
    set fields (tv_record "$argv[1]")
    set file "$fields[2]"
    set line "$fields[3]"
    tv_require_file "$file"; or exit 1
    command ${zed} --line "$line" "$file"
  '';

  matchCopyAbsolute = mkFishHelper "television-nix-match-copy-absolute" ''
    ${commonFunctions}
    set fields (tv_record "$argv[1]")
    printf '%s' "$fields[2]" | command ${clipboardCopy}
  '';

  matchCopyRelative = mkFishHelper "television-nix-match-copy-relative" ''
    ${commonFunctions}
    set fields (tv_record "$argv[1]")
    set relative (string replace -r ':[0-9]+$' "" "$fields[1]")
    printf '%s' "$relative" | command ${clipboardCopy}
  '';

  # ---- GIT ACTIONS ---- #
  # Git records are: status<TAB>relative-path<TAB>absolute-path<TAB>old-path.
  gitFunctions = ''
    ${commonFunctions}

    function tv_git_is_deleted --argument-names status
      string match -q '*D*' -- "$status"
    end

    function tv_git_excluded --argument-names path
      ${gitExclusionCases}

      return 1
    end
  '';

  gitSource = mkFishHelper "television-nix-git-source" ''
    ${gitFunctions}
    set root ${lib.escapeShellArg nixConfigDir}
    set records (command ${git} -C "$root" status --porcelain=v1 -z --untracked-files=all | string split0)
    set index 1

    while test $index -le (count $records)
      set record "$records[$index]"
      set status (string sub --start 1 --length 2 "$record")
      set path (string sub --start 4 "$record")
      set old_path ""

      if string match -rq '[RC]' -- "$status"
        set index (math "$index + 1")
        set old_path "$records[$index]"
      end

      if not tv_git_excluded "$path"
        printf '%s\t%s\t%s\t%s\n' "$status" "$path" "$root/$path" "$old_path"
      end

      set index (math "$index + 1")
    end
  '';

  gitPreviewFile = mkFishHelper "television-nix-git-preview-file" ''
    ${gitFunctions}
    set fields (tv_record "$argv[1]")
    set status "$fields[1]"
    set file "$fields[3]"

    if tv_git_is_deleted "$status"
      echo "Deleted file: $fields[2]"
      echo "Use the Git diff preview to inspect its removed content."
      exit 0
    end

    tv_require_file "$file"; or exit 1
    command ${bat} --paging=never --style=numbers --color=always "$file"
  '';

  gitPreviewDiff = mkFishHelper "television-nix-git-preview-diff" ''
    ${gitFunctions}
    set root ${lib.escapeShellArg nixConfigDir}
    set fields (tv_record "$argv[1]")
    set status "$fields[1]"
    set relative "$fields[2]"
    set file "$fields[3]"

    if string match -q '??' -- "$status"
      command ${git} -C "$root" diff --no-index --color=always -- /dev/null "$file"; or true
    else
      command ${git} -C "$root" diff HEAD --no-ext-diff --color=always -- "$relative"
    end
  '';

  gitNvim = mkFishHelper "television-nix-git-nvim" ''
    ${gitFunctions}
    set fields (tv_record "$argv[1]")
    set status "$fields[1]"
    set file "$fields[3]"

    if tv_git_is_deleted "$status"
      echo "Television: refusing to open deleted file: $fields[2]" >&2
      exit 1
    end

    tv_require_file "$file"; or exit 1
    command ${nvim} "$file"
  '';

  gitZed = mkFishHelper "television-nix-git-zed" ''
    ${gitFunctions}
    set fields (tv_record "$argv[1]")
    set status "$fields[1]"
    set file "$fields[3]"

    if tv_git_is_deleted "$status"
      echo "Television: refusing to open deleted file: $fields[2]" >&2
      exit 1
    end

    tv_require_file "$file"; or exit 1
    command ${zed} "$file"
  '';

  gitCopyAbsolute = mkFishHelper "television-nix-git-copy-absolute" ''
    ${commonFunctions}
    set fields (tv_record "$argv[1]")
    printf '%s' "$fields[3]" | command ${clipboardCopy}
  '';

  gitCopyRelative = mkFishHelper "television-nix-git-copy-relative" ''
    ${commonFunctions}
    set fields (tv_record "$argv[1]")
    printf '%s' "$fields[2]" | command ${clipboardCopy}
  '';

  # ---- FILE SOURCE HELPERS ---- #
  # Sources retain a relative label for TV and an absolute path for actions.
  fileSource = scope: mkFishHelper "television-nix-${scope.name}-source" ''
    set root ${lib.escapeShellArg scope.path}
    command ${fd} --type f --absolute-path --hidden --no-ignore ${fdExclusions} . "$root" | while read --local file
      set relative (string replace -- "$root/" "" "$file")
      printf '%s\t%s\n' "$relative" "$file"
    end
  '';

  # ---- CONTENT SOURCE HELPERS ---- #
  # Match sources print relative path, line, source context, and absolute data.
  matchSource = name: patterns: mkFishHelper "television-nix-${name}-source" ''
    set root ${lib.escapeShellArg nixConfigDir}
    command ${rg} --line-number --no-heading --color=never --glob '*.nix' ${rgExclusions} ${patterns} "$root" | while read --local result
      set fields (string split --max 2 : -- "$result")
      set absolute "$fields[1]"
      set line "$fields[2]"
      set content "$fields[3]"
      set relative (string replace -- "$root/" "" "$absolute")
      printf '%s:%s\t%s\t%s\t%s\n' "$relative" "$line" "$absolute" "$line" "$content"
    end
  '';

  # ---- RECENT FILE SOURCE ---- #
  # GNU find and sort are Nix-provided on both platforms, avoiding BSD/GNU
  # stat differences and ordering .nix files by modification time safely.
  recentSource = mkFishHelper "television-nix-recent-source" ''
    set root ${lib.escapeShellArg nixConfigDir}
    command ${env} LC_ALL=C ${find} "$root" \( ${findPruneExpression} \) -prune -o \
      -type f -name '*.nix' -printf '%T@\t%p\n' | command ${env} LC_ALL=C ${sort} --numeric-sort --reverse | while read --local result
      set fields (string split --max 1 \t -- "$result")
      set file "$fields[2]"
      set relative (string replace -- "$root/" "" "$file")
      printf '%s\t%s\n' "$relative" "$file"
    end
  '';
in
{
  inherit excludedDirectories;

  file = {
    source = fileSource {
      name = "files";
      path = nixConfigDir;
    };
    darwinSource = fileSource {
      name = "darwin";
      path = "${nixConfigDir}/darwin";
    };
    preview = filePreview;
    nvim = fileNvim;
    zed = fileZed;
    copyAbsolute = fileCopyAbsolute;
    copyRelative = fileCopyRelative;
  };

  match = {
    filesSource = matchSource "files" "-e '.'";
    symbolsSource = matchSource "symbols" "-e 'environment\\.systemPackages' -e 'home\\.packages' -e 'imports[[:space:]]*=' -e 'programs\\.' -e 'services\\.' -e 'options\\.' -e 'config\\.'";
    importsSource = matchSource "imports" "-e 'imports[[:space:]]*=' -e '^[[:space:]]*\\.?\\.?/.*\\.nix' -e '(^|[[:space:](])(builtins\\.)?import[[:space:]]+\\(?\\.?\\.?/.*\\.nix'";
    preview = matchPreview;
    nvim = matchNvim;
    zed = matchZed;
    copyAbsolute = matchCopyAbsolute;
    copyRelative = matchCopyRelative;
  };

  recent = {
    source = recentSource;
  };

  git = {
    source = gitSource;
    previewFile = gitPreviewFile;
    previewDiff = gitPreviewDiff;
    nvim = gitNvim;
    zed = gitZed;
    copyAbsolute = gitCopyAbsolute;
    copyRelative = gitCopyRelative;
  };
}
