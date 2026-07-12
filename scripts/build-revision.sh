#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 FILE.md REVISION" >&2
  echo "Example: $0 path/to/document.md 001" >&2
}

if [[ $# -ne 2 ]]; then
  usage
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

export PATH="/opt/homebrew/bin:/usr/local/bin:/c/Program Files/Pandoc:/c/ProgramData/chocolatey/bin:$HOME/scoop/shims:$HOME/.cargo/bin:$PATH"

md_file="$1"
revision="$2"
pdf_engine="${PDF_ENGINE:-tectonic}"

if [[ ! -f "$md_file" || ! -s "$md_file" ]]; then
  echo "Markdown input must exist and contain content: $md_file" >&2
  exit 1
fi

if [[ ! "$revision" =~ ^[0-9]{3}$ ]]; then
  echo "Revision must contain exactly three digits (000, 001, ...): $revision" >&2
  exit 1
fi

for tool in pandoc "$pdf_engine"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "$tool is required." >&2
    exit 1
  fi
done

doc_dir="$(dirname "$md_file")"
doc_filename="$(basename "$md_file")"
doc_stem="${doc_filename%.md}"
output_stem="$doc_dir/${doc_stem}-Rev${revision}"
output_pdf="$output_stem.pdf"
resource_path=".:$doc_dir"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

revision_md="$tmp_dir/$doc_filename"
python3 - "$md_file" "$revision_md" "$revision" <<'PY'
import pathlib
import re
import sys

source, output, revision = sys.argv[1:]
text = pathlib.Path(source).read_text(encoding="utf-8")
if text.startswith("---\n"):
    end = text.find("\n---", 4)
    if end != -1:
        front = text[4:end]
        if re.search(r"(?m)^revision\s*:", front):
            front = re.sub(r"(?m)^revision\s*:.*$", f'revision: "{revision}"', front)
        else:
            front += f'\nrevision: "{revision}"'
        text = "---\n" + front + text[end:]
pathlib.Path(output).write_text(text, encoding="utf-8")
PY

if [[ "$revision" == "000" ]]; then
  echo "Building clean baseline PDF: $output_pdf"
  pandoc "$revision_md" \
    --from=markdown+fenced_divs+link_attributes+table_captions \
    --template=Pandoc/template.tex \
    --lua-filter=Pandoc/style-filter.lua \
    --pdf-engine="$pdf_engine" \
    --resource-path="$resource_path" \
    --syntax-highlighting=tango \
    -o "$output_pdf"
else
  baseline_branch="${BASELINE_BRANCH:-main}"
  if ! git show-ref --verify --quiet "refs/heads/$baseline_branch"; then
    echo "Baseline branch does not exist locally: $baseline_branch" >&2
    exit 1
  fi

  base_commit="$(git merge-base HEAD "$baseline_branch")"
  baseline_path="$md_file"

  # When a document is moved in the current commit, find its old path at the
  # branch point so the first build after the move still has the right baseline.
  if ! git cat-file -e "$base_commit:$baseline_path" 2>/dev/null; then
    while IFS=$'\t' read -r status old_path new_path; do
      if [[ "$status" == R* && "$new_path" == "$md_file" ]]; then
        baseline_path="$old_path"
        break
      fi
    done < <(git diff --cached --name-status --find-renames "$base_commit" --)
  fi

  if ! git cat-file -e "$base_commit:$baseline_path" 2>/dev/null; then
    echo "Approved baseline document was not found at branch point $base_commit." >&2
    echo "Expected path: $baseline_path" >&2
    exit 1
  fi

  baseline_md="$tmp_dir/baseline.md"
  git show "$base_commit:$baseline_path" > "$baseline_md"
  scripts/build-comparison-pdf.sh "$baseline_md" "$revision_md" "$md_file" "$output_pdf"
fi

echo "Built revision $revision: $output_pdf"
