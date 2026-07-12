#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

export PATH="/opt/homebrew/bin:/usr/local/bin:/c/Program Files/Pandoc:/c/ProgramData/chocolatey/bin:$HOME/scoop/shims:$HOME/.cargo/bin:$PATH"

markdown_files=()
while IFS= read -r md_file; do
  markdown_files+=("$md_file")
done < <(git diff --cached --name-only --diff-filter=AMR -- '*.md')

if [[ "${#markdown_files[@]}" -eq 0 ]]; then
  echo "No staged Markdown files to build."
  exit 0
fi

for md_file in "${markdown_files[@]}"; do
  if [[ ! -f "$md_file" ]]; then
    echo "Skipping missing Markdown file: $md_file"
    continue
  fi

  if [[ ! -s "$md_file" ]]; then
    echo "Skipping empty Markdown file: $md_file"
    continue
  fi

  revision="$(sed -nE 's/^revision:[[:space:]]*["'\'']?([0-9]{3})["'\'']?[[:space:]]*$/\1/p' "$md_file" | head -n 1)"
  if [[ -z "$revision" ]]; then
    echo "Skipping $md_file: YAML revision must be exactly three digits (000, 001, ...)." >&2
    continue
  fi

  scripts/build-revision.sh "$md_file" "$revision"
  metadata_output="$(python3 - "$md_file" <<'PY'
import pathlib
import re
import sys
import unicodedata

text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")

def value(key):
    match = re.search(rf"(?m)^{re.escape(key)}\s*:\s*(.*)$", text)
    return match.group(1).strip().strip("\"'") if match else ""

def slug(value):
    value = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode("ascii")
    return re.sub(r"[^A-Za-z0-9]+", "-", value).strip("-")

print(slug(value("doc_number")))
full_title = " ".join(part for part in (value("title"), value("subtitle")) if part)
print(slug(full_title))
PY
)"
  doc_number="$(printf '%s\n' "$metadata_output" | sed -n '1p')"
  title_slug="$(printf '%s\n' "$metadata_output" | sed -n '2p')"
  output_stem="$(dirname "$md_file")/${doc_number}-${revision}-${title_slug}"

  git add "$output_stem.pdf"
  if [[ "$revision" != "000" ]]; then
    git add "$output_stem-change-marked.pdf"
  fi
done
