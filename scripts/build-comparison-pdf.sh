#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 OLD_REF NEW_REF FILE.md [OUTPUT.pdf]" >&2
  echo "Use NEW_REF=WORKTREE to compare OLD_REF with the current working tree file." >&2
}

if [[ $# -lt 3 || $# -gt 4 ]]; then
  usage
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

export PATH="/opt/homebrew/bin:/usr/local/bin:/c/Program Files/Pandoc:/c/ProgramData/chocolatey/bin:$HOME/scoop/shims:$HOME/.cargo/bin:$PATH"

old_ref="$1"
new_ref="$2"
md_file="$3"
pdf_engine="${PDF_ENGINE:-tectonic}"

if [[ ! "$md_file" == *.md ]]; then
  echo "Comparison input must be a Markdown file: $md_file" >&2
  exit 1
fi

if ! command -v pandoc >/dev/null 2>&1; then
  echo "pandoc is required to build comparison PDFs." >&2
  exit 1
fi

if ! command -v "$pdf_engine" >/dev/null 2>&1; then
  echo "$pdf_engine is required to build comparison PDFs." >&2
  exit 1
fi

safe_old="${old_ref//[^A-Za-z0-9._-]/-}"
safe_new="${new_ref//[^A-Za-z0-9._-]/-}"
output_pdf="${4:-${md_file%.md}-comparison-${safe_old}-to-${safe_new}.pdf}"
resource_path=".:$(dirname "$md_file")"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

old_md="$tmp_dir/old.md"
new_md="$tmp_dir/new.md"
comparison_md="$tmp_dir/comparison.md"

if [[ -f "$old_ref" ]]; then
  cp "$old_ref" "$old_md"
else
  git show "${old_ref}:${md_file}" > "$old_md"
fi

if [[ -f "$new_ref" ]]; then
  cp "$new_ref" "$new_md"
elif [[ "$new_ref" == "WORKTREE" ]]; then
  if [[ ! -f "$md_file" ]]; then
    echo "Working tree file does not exist: $md_file" >&2
    exit 1
  fi
  cp "$md_file" "$new_md"
else
  git show "${new_ref}:${md_file}" > "$new_md"
fi

python3 - "$old_md" "$new_md" "$comparison_md" "$md_file" "$old_ref" "$new_ref" <<'PY'
import difflib
import pathlib
import re
import sys

old_path, new_path, out_path, md_file, old_ref, new_ref = sys.argv[1:]


def read_text(path):
    return pathlib.Path(path).read_text(encoding="utf-8").splitlines()


def split_front_matter(lines):
    if lines and lines[0].strip() == "---":
        for i in range(1, len(lines)):
            if lines[i].strip() == "---":
                return lines[1:i], lines[i + 1 :]
    return [], lines


def metadata_value(front_matter, key, default=""):
    pattern = re.compile(rf"^{re.escape(key)}\s*:\s*(.*)$")
    for line in front_matter:
        match = pattern.match(line)
        if match:
            value = match.group(1).strip()
            if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
                value = value[1:-1]
            return value
    return default


def latex_escape(text):
    replacements = {
        "\\": r"\textbackslash{}",
        "{": r"\{",
        "}": r"\}",
        "$": r"\$",
        "&": r"\&",
        "#": r"\#",
        "%": r"\%",
        "_": r"\_",
        "~": r"\textasciitilde{}",
        "^": r"\textasciicircum{}",
    }
    return "".join(replacements.get(ch, ch) for ch in text)


def visible_line(text):
    if text == "":
        return r"\textit{blank line}"
    return latex_escape(text)


def inline_change(text, color, strike):
    escaped = visible_line(text)
    if strike:
        return rf"\textcolor{{{color}}}{{\sout{{{escaped}}}}}"
    return rf"\textcolor{{{color}}}{{{escaped}}}"


def is_table_row(text):
    stripped = text.strip()
    if not (stripped.startswith("|") and stripped.endswith("|")):
        return False
    return stripped.count("|") >= 2


def is_table_rule(text):
    stripped = text.strip().strip("|").strip()
    return bool(stripped) and all(ch in "-:| " for ch in stripped)


def emit_table_change(text, color, strike):
    stripped = text.strip()
    if is_table_rule(stripped):
        return stripped

    cells = stripped.strip("|").split("|")
    marked = [inline_change(cell.strip(), color, strike) for cell in cells]
    return "| " + " | ".join(marked) + " |"


def emit_block_change(text, color, strike):
    if is_table_row(text):
        return emit_table_change(text, color, strike)
    return rf"\noindent {inline_change(text, color, strike)}\par"


old_lines_all = read_text(old_path)
new_lines_all = read_text(new_path)
new_front, new_body = split_front_matter(new_lines_all)
old_front, old_body = split_front_matter(old_lines_all)

title = metadata_value(new_front, "title", pathlib.Path(md_file).stem)
subtitle = metadata_value(new_front, "subtitle", "Markdown comparison")
doc_number = metadata_value(new_front, "doc_number", "")
revision = metadata_value(new_front, "revision", "")
date = metadata_value(new_front, "date", "")
copyright_year = metadata_value(new_front, "copyright_year", "2026")
confidentiality = metadata_value(new_front, "confidentiality", "Baker Hughes Confidential")
new_revision = metadata_value(new_front, "revision", new_ref)
old_revision = metadata_value(old_front, "revision", old_ref)

result = [
    "---",
    f'title: "Comparison: {title}"',
    f'subtitle: "{subtitle}"',
    f'doc_number: "{doc_number}"',
    f'revision: "{revision}"',
    'author: "Comparison build"',
    f'date: "{date}"',
    f'copyright_year: "{copyright_year}"',
    f'confidentiality: "{confidentiality}"',
    "---",
    "",
    "::: {.note}",
    f"Changes from Revision {old_revision} to Revision {new_revision}.",
    "",
    r"\textcolor{BHRed}{\sout{Red strikethrough text was deleted.}}",
    "",
    r"\textcolor{DiffGreen}{Green text was added.}",
    ":::",
    "",
]

matcher = difflib.SequenceMatcher(a=old_body, b=new_body, autojunk=False)
has_changes = False
for tag, i1, i2, j1, j2 in matcher.get_opcodes():
    if tag == "equal":
        result.extend(new_body[j1:j2])
        continue

    has_changes = True
    old_chunk = old_body[i1:i2]
    new_chunk = new_body[j1:j2]
    table_change = any(is_table_row(line) for line in old_chunk + new_chunk)

    if tag in ("replace", "delete"):
        for line in old_chunk:
            if line != "":
                result.append(emit_block_change(line, "BHRed", True))

    if tag in ("replace", "insert"):
        for line in new_chunk:
            if line != "":
                result.append(emit_block_change(line, "DiffGreen", False))

    if not table_change:
        result.append("")

if not has_changes:
    result.insert(14, r"\noindent No content changes were detected.\par")

result.append("")
pathlib.Path(out_path).write_text("\n".join(result), encoding="utf-8")
PY

echo "Building comparison PDF: $output_pdf"
pandoc "$comparison_md" \
  --from=markdown+fenced_divs+link_attributes+table_captions+raw_tex \
  --template=Pandoc/template.tex \
  --lua-filter=Pandoc/style-filter.lua \
  --pdf-engine="$pdf_engine" \
  --resource-path="$resource_path" \
  --syntax-highlighting=tango \
  -o "$output_pdf"

echo "Comparison PDF written to $output_pdf"
