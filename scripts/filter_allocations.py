#!/usr/bin/env python3
"""
Filter a reconciled evidence table down to the analysis table of allocation rows.

WHAT IT DOES
    1. Reads the reconciled JSON and keeps only `evidence_table`
       (the reconciliation_summary is not carried over).
    2. Drops instruments that have no allocation at all — a source row with no
       destination recorded anywhere in the document.
    3. Drops instruments whose only destination is a general budget, i.e. not
       earmarked. An instrument that has a general-budget share AND at least one
       other destination is kept in full, general-budget share included.
    4. Keeps only allocation rows, and of those only the governing row of each
       channel (drops rows marked `restatement`, which repeat a channel stated
       elsewhere in the document).
    5. Writes two files: the filtered rows, and a log of the removed instruments
       with the reason each was removed.

    Restatements are excluded BEFORE steps 2 and 3 decide what to drop, not only
    at step 4 — otherwise they inflate the channel count and can contribute a
    beneficiary_type that no kept row carries.

    No value is changed and no column is added or removed. Every output row is
    byte-identical to its input row.

USAGE
    python filter_allocations.py CIV_CGI2026_RECONCILED.json
    python filter_allocations.py "countries/*/outputs/reconcile/*_RECONCILED.json"
    python filter_allocations.py BEN_CGI2025_RECONCILED.json --outdir countries/BEN/outputs/allocations

OUTPUT (in --outdir, or next to the input when --outdir is not given)
    <name>_ALLOCATIONS.json         the filtered rows
    <name>_REMOVED_INSTRUMENTS.json the removal log
"""

import argparse
import glob
import json
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# Step 2 and 3: decide which instruments to drop
# ---------------------------------------------------------------------------

def find_instruments_to_remove(rows):
    """
    Return a list of {instrument_id, official_name, reason, ...} for every
    instrument that should not appear in the allocation table.

    Two reasons:
      source_only            the instrument has no allocation row at all, so no
                             destination was recorded for it in this document
      general_budget_only    every destination it has is a general budget, so
                             the instrument is not earmarked
    """
    # Collect, per instrument: its channels, their beneficiary types, and a name
    channels = {}          # instrument_id -> set of pair_id
    types_of = {}          # instrument_id -> set of beneficiary_type
    name_of = {}           # instrument_id -> official_name (first one seen)

    for row in rows:
        instrument = row.get("instrument_id")
        name_of.setdefault(instrument, row.get("official_name"))
        channels.setdefault(instrument, set())
        types_of.setdefault(instrument, set())

        # Only allocation rows carry a destination, so only they define channels.
        # Restatements repeat a channel stated elsewhere, so they are dropped
        # here too — otherwise they inflate n_channels and can contribute a
        # beneficiary_type that the row actually kept does not have.
        if (row.get("row_type") == "allocation"
                and row.get("pair_id")
                and row.get("pair_row_role") != "restatement"):
            channels[instrument].add(row["pair_id"])
            types_of[instrument].add(row.get("beneficiary_type"))

    removed = []
    for instrument in channels:

        # Step 2 — no allocation anywhere
        if not channels[instrument]:
            reason = "source_only"
            explanation = ("The instrument has no allocation row: this document "
                           "records the levy but no destination for it.")

        # Step 3 — every destination is a general budget
        elif types_of[instrument] == {"general_budget"}:
            reason = "general_budget_only"
            explanation = ("Every destination of this instrument is a general "
                           "budget, so it is not earmarked. (An instrument with "
                           "a general-budget share plus another destination is "
                           "kept.)")
        else:
            continue  # instrument is kept

        removed.append({
            "instrument_id": instrument,
            "official_name": name_of[instrument],
            "reason": reason,
            "explanation": explanation,
            "n_channels": len(channels[instrument]),
            "beneficiary_types": sorted(t for t in types_of[instrument] if t),
        })

    # Sort so the two reasons group together and the file is stable run to run
    removed.sort(key=lambda item: (item["reason"], item["instrument_id"]))
    return removed


# ---------------------------------------------------------------------------
# Step 4: keep the allocation rows that represent one channel each
# ---------------------------------------------------------------------------

def keep_allocation_rows(rows, removed_instruments):
    """
    Keep a row only if all three hold:
      - its instrument was not removed at step 2 or 3
      - it is an allocation row (source rows have no destination)
      - it is not a restatement (a restatement repeats a channel that another
        row already carries; the governing row is the one to keep)

    `pair_row_role` is 'governing' on the chosen row of a channel stated more
    than once, and empty on a channel stated only once — so the test excludes
    'restatement' rather than keeping 'governing'.
    """
    dropped_ids = {item["instrument_id"] for item in removed_instruments}

    return [
        row for row in rows
        if row.get("instrument_id") not in dropped_ids
        and row.get("row_type") == "allocation"
        and row.get("pair_row_role") != "restatement"
    ]


# ---------------------------------------------------------------------------
# Run one file
# ---------------------------------------------------------------------------

def process_file(input_path, outdir=None):
    """
    `outdir` is where the two output files go. When it is None the files are
    written next to the input, which is the old behaviour.
    """
    input_path = Path(input_path)

    # Step 1 — read the reconciled file, keep only the evidence table
    with input_path.open(encoding="utf-8") as file:
        document = json.load(file)
    rows = document["evidence_table"] if isinstance(document, dict) else document

    # Steps 2 and 3 — which instruments go
    removed_instruments = find_instruments_to_remove(rows)

    # Step 4 — which rows stay
    kept_rows = keep_allocation_rows(rows, removed_instruments)

    # Step 5 — write both outputs, either in outdir or next to the input
    stem = input_path.stem.replace("_RECONCILED", "")
    destination = Path(outdir) if outdir else input_path.parent
    destination.mkdir(parents=True, exist_ok=True)   # create it if it is not there
    allocations_path = destination / (stem + "_ALLOCATIONS.json")
    removed_path = destination / (stem + "_REMOVED_INSTRUMENTS.json")

    with allocations_path.open("w", encoding="utf-8") as file:
        json.dump(kept_rows, file, ensure_ascii=False, indent=1)
    with removed_path.open("w", encoding="utf-8") as file:
        json.dump(removed_instruments, file, ensure_ascii=False, indent=1)

    # Step 6 — check nothing was altered along the way
    if kept_rows:
        assert set(kept_rows[0]) == set(rows[0]), "the set of columns changed"
    assert len({row["pair_id"] for row in kept_rows}) == len(kept_rows), \
        "a channel appears on more than one row"

    # Report
    n_source_only = sum(1 for i in removed_instruments if i["reason"] == "source_only")
    n_general_only = sum(1 for i in removed_instruments if i["reason"] == "general_budget_only")
    instruments_in = len({row.get("instrument_id") for row in rows})
    instruments_out = len({row.get("instrument_id") for row in kept_rows})

    print(f"{input_path.name}")
    print(f"  rows        {len(rows):>5} -> {len(kept_rows)}")
    print(f"  instruments {instruments_in:>5} -> {instruments_out}"
          f"   (removed {n_source_only} source-only, {n_general_only} general-budget-only)")
    print(f"  wrote {allocations_path} and {removed_path.name}")


# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Filter reconciled evidence tables down to allocation rows.")
    parser.add_argument("inputs", nargs="+",
                        help="reconciled JSON files; glob patterns are expanded")
    parser.add_argument("--outdir", default=None,
                        help="where to write the outputs "
                             "(default: next to each input file)")
    args = parser.parse_args()

    # Expand any glob patterns; keep plain paths as they are
    paths = []
    for pattern in args.inputs:
        matches = sorted(glob.glob(pattern))
        paths.extend(matches if matches else [pattern])

    for path in paths:
        try:
            process_file(path, args.outdir)
        except FileNotFoundError:
            print(f"not found: {path}", file=sys.stderr)
        except Exception as error:
            print(f"{path}: {error}", file=sys.stderr)


if __name__ == "__main__":
    main()
