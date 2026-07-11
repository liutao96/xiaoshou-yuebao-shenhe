param(
  [Parameter(Mandatory = $true)]
  [string]$MarkdownPath,

  [Parameter(Mandatory = $false)]
  [string]$OutputPath,

  [switch]$StrictName
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $MarkdownPath)) {
  throw "Markdown file not found: $MarkdownPath"
}

if (-not $OutputPath -or $OutputPath.Trim() -eq "") {
  $OutputPath = [System.IO.Path]::ChangeExtension($MarkdownPath, ".docx")
}

$python = @'
import argparse
import re
import sys
from pathlib import Path

from docx import Document
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Pt


def set_run_font(run, size=None, bold=None):
    run.font.name = "Microsoft YaHei"
    run._element.rPr.rFonts.set(qn("w:eastAsia"), "Microsoft YaHei")
    if size:
        run.font.size = Pt(size)
    if bold is not None:
        run.bold = bold


def set_cell_text(cell, text, bold=False):
    cell.text = ""
    p = cell.paragraphs[0]
    r = p.add_run(text.strip())
    set_run_font(r, size=9, bold=bold)


def split_table_row(line):
    line = line.strip()
    if line.startswith("|"):
        line = line[1:]
    if line.endswith("|"):
        line = line[:-1]
    return [c.strip() for c in line.split("|")]


def is_table_line(line):
    s = line.strip()
    return s.startswith("|") and s.endswith("|") and "|" in s[1:-1]


def is_separator(line):
    cells = split_table_row(line)
    return bool(cells) and all(re.fullmatch(r":?-{3,}:?", c.strip() or "") for c in cells)


def count_source_tables(lines):
    count = 0
    i = 0
    while i < len(lines) - 1:
        if is_table_line(lines[i]) and is_table_line(lines[i + 1]) and is_separator(lines[i + 1]):
            count += 1
            i += 2
            while i < len(lines) and is_table_line(lines[i]):
                i += 1
        else:
            i += 1
    return count


def normalize_filename(path):
    name = Path(path).name
    return re.search(r"[\u4e00-\u9fff]", name) and re.search(r"_20\d{2}-\d{2}_", name)


def add_paragraph_with_text(doc, text, style=None):
    p = doc.add_paragraph(style=style) if style else doc.add_paragraph()
    r = p.add_run(text)
    set_run_font(r, size=10.5)
    return p


def build_doc(markdown_path, output_path, strict_name=False):
    md_path = Path(markdown_path)
    out_path = Path(output_path)
    if strict_name and not normalize_filename(out_path):
        raise SystemExit("Official output filename must use Chinese business naming like 部门或小组_YYYY-MM_报告类型.docx")

    text = md_path.read_text(encoding="utf-8-sig")
    lines = text.splitlines()
    source_tables = count_source_tables(lines)

    doc = Document()
    styles = doc.styles
    styles["Normal"].font.name = "Microsoft YaHei"
    styles["Normal"]._element.rPr.rFonts.set(qn("w:eastAsia"), "Microsoft YaHei")
    styles["Normal"].font.size = Pt(10.5)

    i = 0
    while i < len(lines):
        line = lines[i].rstrip()
        stripped = line.strip()
        if not stripped:
            i += 1
            continue

        if is_table_line(line) and i + 1 < len(lines) and is_table_line(lines[i + 1]) and is_separator(lines[i + 1]):
            header = split_table_row(line)
            rows = []
            i += 2
            while i < len(lines) and is_table_line(lines[i]):
                row = split_table_row(lines[i])
                if len(row) < len(header):
                    row += [""] * (len(header) - len(row))
                rows.append(row[:len(header)])
                i += 1

            table = doc.add_table(rows=1, cols=len(header))
            table.style = "Table Grid"
            table.autofit = True
            for idx, cell_text in enumerate(header):
                set_cell_text(table.rows[0].cells[idx], cell_text, bold=True)
            for row in rows:
                cells = table.add_row().cells
                for idx, cell_text in enumerate(row):
                    set_cell_text(cells[idx], cell_text)
            continue

        if stripped.startswith("# "):
            p = doc.add_heading(stripped[2:].strip(), level=1)
            for run in p.runs:
                set_run_font(run, size=16, bold=True)
        elif stripped.startswith("## "):
            p = doc.add_heading(stripped[3:].strip(), level=2)
            for run in p.runs:
                set_run_font(run, size=13, bold=True)
        elif stripped.startswith("### "):
            p = doc.add_heading(stripped[4:].strip(), level=3)
            for run in p.runs:
                set_run_font(run, size=11, bold=True)
        elif re.match(r"^[-*]\s+", stripped):
            add_paragraph_with_text(doc, re.sub(r"^[-*]\s+", "", stripped), style="List Bullet")
        elif re.match(r"^\d+\.\s+", stripped):
            add_paragraph_with_text(doc, re.sub(r"^\d+\.\s+", "", stripped), style="List Number")
        else:
            add_paragraph_with_text(doc, stripped)
        i += 1

    out_path.parent.mkdir(parents=True, exist_ok=True)
    doc.save(out_path)

    check = Document(out_path)
    residual = [p.text for p in check.paragraphs if p.text.strip().startswith("|") or "|---" in p.text]
    if source_tables and len(check.tables) < source_tables:
        raise SystemExit(f"Table conversion failed: source tables={source_tables}, docx tables={len(check.tables)}")
    if residual:
        raise SystemExit("Markdown table residue remains in DOCX: " + residual[0][:120])

    print(f"Converted: {out_path}")
    print(f"Source tables: {source_tables}")
    print(f"DOCX tables: {len(check.tables)}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--markdown", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--strict-name", action="store_true")
    args = parser.parse_args()
    build_doc(args.markdown, args.output, args.strict_name)
'@

$tempPy = Join-Path ([System.IO.Path]::GetTempPath()) ("convert_monthly_audit_" + [System.Guid]::NewGuid().ToString("N") + ".py")
[System.IO.File]::WriteAllText($tempPy, $python, [System.Text.UTF8Encoding]::new($false))
try {
  $args = @($tempPy, "--markdown", $MarkdownPath, "--output", $OutputPath)
  if ($StrictName) { $args += "--strict-name" }
  python @args
} finally {
  if (Test-Path -LiteralPath $tempPy) {
    Remove-Item -LiteralPath $tempPy -Force
  }
}
