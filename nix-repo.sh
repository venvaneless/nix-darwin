#!/usr/bin/env bash
set -eu

# FORCE script into the nix repo always
NIX="/Users/ven/dotfiles/nix"
MSG="/Users/ven/dotfiles/nix-commitmsg.txt"
BRANCHFILE="$NIX/.last-branch"

cd "$NIX"

echo
echo "=== NIX REPO STATUS ==="
git status
echo

# Ask what to stage
echo "What do you want to stage?"
echo "[A] Add all changes"
echo "[S] Select individual files (fzf)"
echo "[N] Do not stage anything (already staged)"
printf "> "
read choice

case "$choice" in
  A|a)
    git add -A
    ;;

  S|s)
    files=$(git status --porcelain | sed 's/^.. //' | fzf --multi)
    [ -z "$files" ] && { echo "Nothing selected"; exit 0; }

    echo "$files" | while IFS= read -r f; do
      git add -- "$f"
    done
    ;;

  N|n)
    echo "Skipping staging."
    ;;
esac

echo
echo "=== CURRENT STAGE (git diff --cached --name-only) ==="
git diff --cached --name-only
echo

# Ask for commit message
echo "Commit message:"
echo "[F] Use nix-commitmsg.txt"
echo "[T] Type manually"
printf "> "
read cm

case "$cm" in
  F|f)
    message=$(cat "$MSG" 2>/dev/null || echo "")
    if [ -z "$message" ]; then
      echo "Message file empty, type manually:"
      read -r message
    fi
    ;;

  *)
    echo "Type your commit message:"
    read -r message
    ;;
esac

echo
echo "Attempting commit..."
if ! git commit -m "$message"; then
  echo "Nothing to commit."
  exit 0
fi

# Sync dotfiles pointer
cd /Users/ven/dotfiles
git add nix
if git diff --cached --quiet; then
  echo "Dotfiles pointer not changed."
else
  git commit -m "nix – $message"
fi

# Push?
echo
echo "Push now? [yes/no]"
read push
if [ "$push" = "yes" ]; then
  cd "$NIX"
  git push
  cd /Users/ven/dotfiles
  git push || true
fi

echo
echo "Switch nix repo back to main? [yes/no]"
read mm
if [ "$mm" = "yes" ]; then
  cd "$NIX"
  git checkout main || true
  echo "main" > "$BRANCHFILE"
fi

echo "Done."
