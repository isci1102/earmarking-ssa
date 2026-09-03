# CENSUS RECONCILIATION PROMPT

Read every census extract for **one country** and return **one row per distinct revenue instrument in that country**. That single stacked, deduplicated list is the deliverable.

**Read first and apply as written:**
- `census_table_dictionary_v0_11.md` — §2 grain, §3 identity, §5 columns, §10 checks

**Parameters:** `country` (ISO3), `census_folder`, `output_format ∈ {json, xlsx}`.

The dictionary governs, except on the three things it leaves to this pass and this prompt fixes: **cross-document identity**, **the survivor rule**, and **`instrument_id` assignment**.

The source PDFs are not an input. Census files are the only input; nothing is re-extracted here.

---

## Step 1 — Inventory and load

List every `{country}_*_CENSUS.{json,xlsx}` in the folder. Report the count, then one line per file: `document_id`, `document_year`, `document_type`, row count.

Reconcile against the manifest: a document with `used_for_census = yes` and no census file is a **STOP**, not a silent gap.

Validate on load — identical schema across files, `evidence_id` unique within and across files, `instrument_id` blank everywhere. Any failure → stop and say which file.

## Step 2 — Stack

Union all `census_rows`, changing no field. Assert `count(stacked) = Σ rows per file`. That number is fixed; every later step reconciles back to it.

## Step 3 — Candidate pairs

Match on the instrument's natural key, never on the document:

- normalised `official_name` (case, punctuation, articles) — **no translation, no stripping of qualifiers**
- `tax_base_detail` — the same thing taxed
- `instrument_nature`, `base_sector` + `base_division`, `is_penalty`

**A pair is a candidate only if the base matches. Name alone never matches** — the §12 completeness rule exists because a country taxes the domestic and the imported form of one good under near-identical names, and `official_name_underspecified = 1` rows share generic names by construction. Conversely, **different names with the same base are one instrument**: a charging act's *carbon tax* and a schedule's *environmental levy on carbon emissions* are the same charge collected through a second vehicle.

**Never merge:**
- a penalty and the obligation it enforces (`is_penalty` differs)
- a `rate_point_increment` and the parent named in `rate_reference_instrument`
- two charges a payer owes *in addition to* one another (§2)
- an instrument and its replacement — `change_type ∈ {replacement, split, merger}` creates a new instrument (§2)
- two rows from the **same** document. Intra-document merge happened at extraction; a duplicate found here is an extraction failure — report it, do not fix it here.

## Step 4 — Adjudicate

For each confirmed group, apply in order and **stop at the first rule that decides**:

1. `evidence_status = attested` beats `referenced_not_enacted_here`.
2. The row stating **both base and rate** beats one that defers its rate (`rate_basis = cross_reference`, or null `rate_value` with no schedule) — §2.
3. `change_type = new` beats any `amendment_*`.
4. Highest `document_year`.
5. Still tied → keep the lower `evidence_id`, flag `tie_unresolved`.

Two carve-outs:

- **`in_force` is read from the most recent document that speaks to the instrument**, not from the survivor. Where a later act repeals what the charging act instituted, the survivor stays and `in_force_reconciled = 0`, with the repealing document and article in `in_force_source`.
- **Where the rate differs across documents in a group, say so** in `reconciliation_note`. Keeping the older figure silently is the failure mode this pass exists to prevent.

Every decision is written down. A merge with no recorded reason is a failed merge.

## Step 5 — Assign `instrument_id`, change nothing else

This pass is the later analysis col 4 contemplates. On **surviving rows only**: `{country}_INS_{NNNN}`, assigned in a stable sort order (`document_year`, `document_id`, `evidence_id`). Absorbed rows keep `instrument_id` blank — they are evidence about the instrument, not the instrument.

**Surviving rows are written exactly as extracted.** Nothing is folded into `additional_mentions`, no field is edited. The reconciliation output is carried in appended columns only:

`instrument_id`, `duplicate_group_id`, `n_documents`, `source_documents` (list), `survivor_rule` (which ladder step decided), `in_force_reconciled`, `in_force_source`, `reconciliation_note`.

## Step 6 — Output

**One file: `{country}_CENSUS_MASTER.{ext}`**

| sheet | json key | shape |
|---|---|---|
| `census_master` | `census_rows` | surviving rows — §5 columns in order, reconciliation columns appended — **the deliverable** |
| `DUPLICATE_LOG` | `duplicate_log` | one row per absorbed row: `evidence_id`, `document_id`, `document_year`, `official_name`, `duplicate_group_id`, `survivor_evidence_id`, `survivor_rule`, `reason` (one sentence naming the matched base) |
| `DOCUMENT_INDEX` | `document_index` | one row per file: `document_id`, `document_year`, `document_type`, `rows_in`, `rows_surviving`, `rows_absorbed` |
| `RUN_META` | `run_meta` | parameters, the Step 1 load check, and every contestable merge **and non-merge**, each with the instrument count it would have produced the other way |

## Step 7 — Hard checks (any failure blocks output)

1. `count(census_rows) + count(duplicate_log) = count(stacked) = Σ rows_in`.
2. Every absorbed `evidence_id` appears exactly once in `duplicate_log`, and its `survivor_evidence_id` is in `census_rows`.
3. `instrument_id` non-null and unique on every surviving row; blank on every absorbed row.
4. No two surviving rows share the same (normalised `official_name`, `tax_base_detail`, `is_penalty`). Where they legitimately differ, `reconciliation_note` says how.
5. Every `duplicate_log` row names the ladder step that decided it.
6. No field of a surviving row differs from that field in its source census file, except the appended reconciliation columns.
7. Dictionary §10 checks 1–10, 12 still pass on `census_rows`.

## Close-out

One line: files read, rows stacked, instruments after reconciliation, duplicates absorbed, groups spanning more than two documents, unresolved ties, any STOP.
