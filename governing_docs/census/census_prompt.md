# CENSUS EXTRACTION PROMPT

Read one legal document in full and return **one row per revenue instrument in it**. That single list is the deliverable.

**Read first and apply as written:**
- `census_table_dictionary_v0_11.md` — every column and every rule
- `retrieval_adapter_parameterized.md` — A0, A1, A6

**Parameters:** the manifest row for this document.

This prompt gives the procedure. Where it and the dictionary appear to differ, **the dictionary governs**.

---

## Step 1 — Certify the file, then read it once

**Certify the canonical file first (A6):** format, page count, encoding, replacement-character count, one mid-document sample. Corrupt encoding and a font with no Unicode map produce silent false nulls, not visible errors. Any failure → stop and say why.

**Extract the character data once and cache it to disk.** Every later step reads the cache. Never re-extract.

Set the parameter vector (A0). Then handle columns (A1) as three separate jobs — conflating them is what fails:

1. **Learn the text margins** from the distribution of line-start positions, computed **once per page parity**. A bound volume shifts its text block on alternate leaves, so a single margin pair misclassifies half the document.
2. **Decide single or double column per page**, not per document. Test the candidate gutter both for emptiness and for how many lines cross it, and take the union of the criteria: a running header spans the gutter on every page, and columns whose lines share a baseline defeat any line-start test.
3. **Split characters by position before grouping them into lines.** Grouping into lines first splices a left-column clause onto a right-column one *inside a single line*, where no line-level test can see it.

**Canary.** Read a body page and confirm contiguous prose — then **list every page classified single-column and check it**. One canary passing does not mean the document reads cleanly.

Record one line: certified, read cleanly, crop applied or not.

## Step 2 — Split by division, once

List the document's **top-level divisions**: each book or highest structural unit, and each appended text as one. This list is fixed now and is both the **unit of work** and the **unit of coverage**. Where a division is too long to sweep in one pass, split it into contiguous page ranges that never straddle a division boundary — so every piece of work belongs to exactly one division and the mapping back is unambiguous.

**Launch every sweep at once**, not in waves. A wave ends only when its slowest member ends.

## Step 3 — Sweep each division

Find every instrument. Anchor on the language that *institutes a charge* — fr: *il est institué / créé / perçu / dû*, *sont soumis à*, *le taux est fixé à*; en: *there shall be levied / imposed / charged*, *shall be payable*, *is hereby imposed*. Never work from a checklist of expected taxes; the list is the output.

Apply the grain rule (dictionary §2) to decide what is one row, what folds into a parent, and what stays separate.

Fill every column per §5, using §5B for `base_sector` and `base_division` and §5A for rates. Two reminders, because both are easy to get backwards:

- **`base_sector` is the sector that is TAXED** — never the destination, never the authority that levies or receives.
- **No classification.** `revenue_class`, `tax_type` and `economic_type` are not columns here; they are produced later. Do not create them, and do not let a classification question change what you record.

Each sweep returns its rows and its own instrument count.

## Step 4 — Assemble, merge, check

**Assemble, then merge.** An instrument printed in two divisions is one instrument (§2) — a code article cross-referencing an appended text, the same subsidiary act printed twice, a sectoral code referring back to the common law. Keep the row that states the base and the rate, fold the other into its `additional_mentions`, and assert `final = assembled − absorbed`.

**Recompute `coverage_check`** from the merged rows: one entry per division with its count, including zeros. A count carried over from the sweep that produced it is stale the moment anything merges.

**Run the hard checks (§10).** If any fails, do not write the output file — report the failures. Re-sweep only a division whose check fails, and only that division.

**One completeness check.** Build a cue list from the document's own index or table of contents — sources that name charges without being enacting text — and reconcile it against the rows. It is the only check with power against omission.

That is the whole verification budget: one sweep per division, one merge, one completeness check.

## Output

**One file: `{country}_{document_id}_CENSUS.{ext}`** — `census_rows`, `coverage_check`, `run_meta`.

`run_meta` is the manifest row, the one line from step 1, and any contestable call or schema gap you had to resolve to finish. Nothing else.

## Close-out

One line: instruments found, how many `in_force = 1`, divisions with zero, validation result, any STOP.
