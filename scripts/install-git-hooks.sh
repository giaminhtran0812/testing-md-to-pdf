#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

git config core.hooksPath .githooks
chmod +x .githooks/pre-commit
chmod +x scripts/build-staged-markdown-pdfs.sh
chmod +x scripts/build-revision.sh

echo "Git hooks installed for this repository."
echo "Revisioned Markdown PDFs will be rebuilt and staged automatically before each commit."
