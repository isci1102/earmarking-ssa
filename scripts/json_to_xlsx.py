#!/usr/bin/env python3
"""
json_to_xlsx.py — convert extraction JSON outputs to Excel workbooks for quick reading.

Usage:
    python json_to_xlsx.py input.json [output.xlsx]
    python json_to_xlsx.py "countries/*/outputs/*.json"     # batch: each foo.json -> foo.xlsx

Shapes handled:
  1. Current outputs ({ISO3}_EARMARK_ALLOCATIONS.json, {ISO3}_INSTRUMENTS.json):
     {"country", "prompt_version", ["documents"], "rows"}
       -> sheet 'allocations' / 'instruments' (the table, first)
          sheet 'documents'   (the corpus file list, if present)
          sheet 'info'        (country, prompt version, any other scalar)
  2. Old nine-key EXTRACT object (run_meta + evidence_rows + audit keys) -> one sheet per key.
  3. A bare list of row objects -> a single 'evidence_table' sheet.

Reading aids: header row frozen, filters on, column widths set, long text wrapped.
Lists in a cell are shown as "a; b; c". Control characters copied from PDFs (which
Excel refuses) are removed. Working files in outputs/_work and outputs/_cache are skipped.
"""

import glob
import json
import re
import sys
from pathlib import Path

import openpyxl
from openpyxl.cell.cell import ILLEGAL_CHARACTERS_RE
from openpyxl.styles import Alignment, Font
from openpyxl.utils import get_column_letter

# Old nine-key format: canonical sheet order and names
NINE_KEY_ORDER = [
    "run_meta", "evidence_rows", "coverage_report", "recall_audit",
    "locate_reconciliation", "gold_scoring", "field_exercise_note",
    "confidence_reasons", "schema_stress_note",
]
SHEET_NAMES = {
    "run_meta": "RUN_META", "evidence_rows": "evidence_table", "coverage_report": "COVERAGE_REPORT",
    "recall_audit": "RECALL_AUDIT", "locate_reconciliation": "LOCATE_RECONCILIATION",
    "gold_scoring": "GOLD_SCORING", "field_exercise_note": "FIELD_EXERCISE_NOTE",
    "confidence_reasons": "CONFIDENCE_REASONS", "schema_stress_note": "SCHEMA_STRESS_NOTE",
}
# Columns holding long text: wide and wrapped
LONG_TEXT = {"verbatim_excerpt", "notes", "note", "legal_change_note", "share_detail", "tax_base_detail",
             "rate_verbatim", "title", "destination_name", "instrument_name", "official_name",
             "pool_members", "reason", "detail"}
MAX_WIDTH, LONG_WIDTH = 40, 70


def _clean(v):
    """Excel-safe cell value: lists of scalars -> 'a; b'; nested -> JSON; strip control chars."""
    if isinstance(v, list) and all(not isinstance(x, (list, dict)) for x in v):
        v = "; ".join("" if x is None else str(x) for x in v)
    elif isinstance(v, (list, dict)):
        v = json.dumps(v, ensure_ascii=False)
    if isinstance(v, str):
        v = ILLEGAL_CHARACTERS_RE.sub(" ", v)
        if len(v) > 32000:                      # Excel's cell limit is 32,767 characters
            v = v[:32000] + " …[truncated]"
    return v


def _flatten(obj, prefix=""):
    """Flatten a nested dict/list into [(dotted_key, value), ...]."""
    rows = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            key = f"{prefix}{k}"
            rows += _flatten(v, f"{key}.") if isinstance(v, (dict, list)) else [(key, v)]
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            key = f"{prefix}{i}"
            rows += _flatten(v, f"{key}.") if isinstance(v, (dict, list)) else [(key, v)]
    else:
        rows.append((prefix.rstrip("."), obj))
    return rows


def _format_table(ws):
    """Freeze header, add filters, set widths, wrap long-text columns."""
    if ws.max_row < 1 or ws.max_column < 1:
        return
    for c in ws[1]:
        c.font = Font(bold=True)
    ws.freeze_panes = "A2"
    if ws.max_row > 1:
        ws.auto_filter.ref = ws.dimensions
    wrap = Alignment(wrap_text=True, vertical="top")
    top = Alignment(vertical="top")
    for j, head in enumerate(ws[1], start=1):
        name = str(head.value or "")
        letter = get_column_letter(j)
        sample = [len(str(ws.cell(i, j).value or "")) for i in range(1, min(ws.max_row, 200) + 1)]
        long_col = name in LONG_TEXT
        ws.column_dimensions[letter].width = LONG_WIDTH if long_col else min(max(sample + [8]) + 2, MAX_WIDTH)
        for i in range(2, ws.max_row + 1):
            ws.cell(i, j).alignment = wrap if long_col else top


def _write_table(ws, records):
    header, seen = [], set()
    for r in records:
        for k in r:
            if k not in seen:
                seen.add(k)
                header.append(k)
    ws.append(header)
    for r in records:
        ws.append([_clean(r.get(h)) for h in header])
    _format_table(ws)


def _write_any(wb, name, value, key):
    ws = wb.create_sheet(name[:31])
    if isinstance(value, list) and value and isinstance(value[0], dict):
        _write_table(ws, value)
    elif isinstance(value, list):
        ws.append([key])
        for v in value:
            ws.append([_clean(v)])
    elif isinstance(value, dict):
        ws.append(["field", "value"])
        for k, v in _flatten(value):
            ws.append([k, _clean(v)])
        _format_table(ws)
    else:
        ws.append([key])
        for line in str(value if value is not None else "").split("\n"):
            ws.append([_clean(line)])


def _table_name(path: Path) -> str:
    stem = path.stem.upper()
    if "ALLOCATION" in stem:
        return "allocations"
    if "INSTRUMENT" in stem:
        return "instruments"
    return "rows"


def convert(in_path: Path, out_path: Path) -> Path:
    # Explicit UTF-8: on Windows, read_text() defaults to cp1252 (é -> Ã©).
    doc = json.loads(in_path.read_text(encoding="utf-8"))
    wb = openpyxl.Workbook()
    wb.remove(wb.active)

    if isinstance(doc, list):                                   # bare list of rows
        _write_table(wb.create_sheet("evidence_table"), doc)
    elif isinstance(doc, dict) and isinstance(doc.get("rows"), list):   # current outputs
        _write_table(wb.create_sheet(_table_name(in_path)), doc["rows"])
        if isinstance(doc.get("documents"), list) and doc["documents"]:
            _write_table(wb.create_sheet("documents"), doc["documents"])
        info = wb.create_sheet("info")
        info.append(["field", "value"])
        info.append(["source_file", in_path.name])
        info.append(["rows", len(doc["rows"])])
        for k, v in doc.items():
            if k in ("rows", "documents"):
                continue
            if isinstance(v, (dict, list)):
                _write_any(wb, k, v, k)
            else:
                info.append([k, _clean(v)])
        _format_table(info)
    elif isinstance(doc, dict):                                 # old nine-key object
        keys = [k for k in NINE_KEY_ORDER if k in doc] + [k for k in doc if k not in NINE_KEY_ORDER]
        for k in keys:
            _write_any(wb, SHEET_NAMES.get(k, k), doc[k], k)
    else:
        raise ValueError("Unsupported JSON top-level type")

    if not wb.sheetnames:
        wb.create_sheet("evidence_table")
    wb.save(out_path)
    return out_path


def _expand(args):
    """Expand glob patterns ourselves (PowerShell/cmd do not), and skip working files."""
    out = []
    for a in args:
        matches = glob.glob(a) if any(ch in a for ch in "*?[") else [a]
        if not matches:
            print(f"no files match: {a}")
        out.extend(m for m in matches if not re.search(r"[\\/]_(work|cache)[\\/]", m))
    return out


def main():
    args = _expand(sys.argv[1:])
    if not args:
        print(__doc__)
        sys.exit(1)
    if len(args) == 2 and args[0].endswith(".json") and args[1].endswith(".xlsx"):
        print(f"wrote {convert(Path(args[0]), Path(args[1]))}")
        return
    for a in args:
        p = Path(a)
        if p.suffix.lower() != ".json":
            print(f"skip (not .json): {a}")
            continue
        try:
            print(f"wrote {convert(p, p.with_suffix('.xlsx'))}")
        except Exception as e:  # one bad file never stops a batch
            print(f"FAILED {a}: {type(e).__name__}: {e}")


if __name__ == "__main__":
    main()
