#!/usr/bin/env python3
"""
Filter extraction workbooks down to allocation rows.

Usage:
    python make_file_allocation.py countries/CIV/outputs/extract/*_ENRICHED.xlsx
    python make_file_allocation.py INPUT.xlsx --outdir countries/CIV/outputs/allocation
    python make_file_allocation.py INPUT.xlsx -o custom_name.xlsx   # single input only

Output naming (derived, not supplied):
    CIV_CGI2025_ENRICHED.xlsx -> CIV_CGI2025_ALLOCATION.xlsx
    anything_else.xlsx        -> anything_else_ALLOCATION.xlsx
Default output directory is the input's own directory; override with --outdir.

Behaviour per file:
  - reads only the sheet `evidence_table`
  - keeps only rows where row_type == "allocation"
  - keeps only the columns listed in COLUMNS, in that order
  - columns absent from the input are created empty (and reported)
  - writes a single-sheet workbook named `evidence_table`
"""

import argparse
import sys
from pathlib import Path

import pandas as pd

SHEET = "evidence_table"
SUFFIX_IN = "_EARMARKS"
SUFFIX_OUT = "_ALLOCATIONS"


COLUMNS = [
    "evidence_id",    "row_type",    "country",    "instrument_id",    "pair_id",
    "document_id",    "document_type",    "document_year",    "legal_article",
    "page_start",    "page_end",    "official_name",    "destination",    "beneficiary_type",  "allocation_nature",    "share_value",    "share_is_schedule",
    "share_schedule_detail",    "share_type",    "share_basis",    "share_level",    "share_pool",
    "is_purpose_restricted",    "assignment_type",  "change_type",
    "structural_break",    "partial_key",    "predecessor_ref",    "predecessor_relation",
    "change_from_previous",    "enabling_reference",    "verbatim_excerpt",    "source_internal_inconsistency",    "ai_confidence",
    "human_validation_status",    "notes",    "pair_row_role",    "base_scope",    "intra_document_conflict",   
      "census_ref",    "destination_function",    "destination_function_basis",    "destination_function_multi",    "destination_function_detail"
]



def output_path(src, outdir):
    stem = src.stem
    stem = stem[: -len(SUFFIX_IN)] if stem.endswith(SUFFIX_IN) else stem
    name = f"{stem}{SUFFIX_OUT}.xlsx"
    return (outdir or src.parent) / name


def process(src, dst):
    xl = pd.ExcelFile(src)
    if SHEET not in xl.sheet_names:
        print(f"SKIP {src.name}: no '{SHEET}' sheet (found {xl.sheet_names})")
        return False

    df = xl.parse(SHEET, dtype=object)  # dtype=object: no silent type coercion
    df.columns = [str(c).strip() for c in df.columns]

    if "row_type" not in df.columns:
        print(f"SKIP {src.name}: no 'row_type' column")
        return False

    n_in = len(df)
    mask = df["row_type"].astype(str).str.strip().str.lower() == "allocation"
    df = df.loc[mask].copy()

    missing = [c for c in COLUMNS if c not in df.columns]
    for c in missing:
        df[c] = pd.NA
    extra = [c for c in df.columns if c not in COLUMNS]
    df = df[COLUMNS]

    dst.parent.mkdir(parents=True, exist_ok=True)
    with pd.ExcelWriter(dst, engine="openpyxl") as w:
        df.to_excel(w, sheet_name=SHEET, index=False)

    print(f"{src.name}: {n_in} rows -> {len(df)} allocation rows -> {dst}")
    if missing:
        print(f"    columns created empty: {missing}")
    if extra:
        print(f"    columns dropped: {extra}")
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("inputs", nargs="+", help="source .xlsx file(s); shell glob is fine")
    ap.add_argument("--outdir", default=None,
                    help="directory for outputs (default: alongside each input)")
    ap.add_argument("-o", "--output", default=None,
                    help="explicit output path; only valid with a single input")
    args = ap.parse_args()

    if args.output and len(args.inputs) > 1:
        sys.exit("-o takes a single input; use --outdir for multiple files.")

    outdir = Path(args.outdir) if args.outdir else None
    ok = 0
    for raw in args.inputs:
        src = Path(raw)
        if not src.exists():
            print(f"SKIP {raw}: not found")
            continue
        dst = Path(args.output) if args.output else output_path(src, outdir)
        ok += process(src, dst)

    print(f"\n{ok}/{len(args.inputs)} file(s) written")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
