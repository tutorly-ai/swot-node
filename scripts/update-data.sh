#!/usr/bin/env bash
#
# Updates the `data` git submodule to the latest commit on the upstream
# JetBrains/swot default branch (master) and stages the change.
#
# Usage:  npm run update-data
#
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Fetching latest JetBrains/swot master into the data submodule..."
# --init   : clone the submodule if it isn't checked out yet
# --remote : move it to the tip of the branch tracked in .gitmodules (master)
git submodule update --init --remote data

echo ""
echo "==> data submodule is now at:"
git -C data log --oneline -1

echo ""
echo "==> Staging the submodule pointer..."
git add data

if git diff --cached --quiet -- data; then
  echo "Nothing changed — the dataset was already up to date."
else
  echo "Done. The submodule bump is staged."
  echo "Next: commit it, then run 'npm run release' to build & publish."
fi
