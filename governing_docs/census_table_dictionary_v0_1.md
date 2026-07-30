# Census Table — Data Dictionary (v0.1 — DRAFT, one open item)

> **Status.** v0.1, drafted against CENSUS CORE N1–N10. Not a freeze candidate: `instrument_nature` (col 14a) is an OPEN ITEM pending inspection of the pilot corpus (N10.1), and `evidence_status = referenced_not_enacted_here` (col 35) is a proposed extension pending ratification (N10.2). Everything else is a deliberate subset of the evidence dictionary v0.5, reused verbatim for homogeneity.
>
> **Design rule — no independent schema.** Every column below that also exists in evidence dictionary v0.5 keeps its v0.5 name, type, domain, and semantics **unchanged**. This is not a new schema; it is the source-half of v0.5 plus two fields. Any divergence in a shared column is a defect, not a variant: the two tables must remain union-compatible on their natural keys.

---

## 1. What the table is

The census table is the hand-authored enumeration of **every** source instrument present in a corpus document (CENSUS CORE N1), recorded from that document's enacting text alone.

**Invariants (non-negotiable):** every row carries a verbatim excerpt and a page anchor. No synthetic ids at extraction. The table contains no destination, share, or assignment fields.

**What this table is NOT.** Not a tax history, not a panel, not a claim about a country's tax system. It is a per-document enumeration. Cross-document instrument identity is never established here (N6).

## 2. Grain

**One row = one (clause × one distinct source instrument)** at N4 decomposition. A container provision bundling three instruments → three rows, each independently anchored. Grain is fixed corpus-wide and may not vary per document (N4).

## 3. Identity handling — id-free extraction

No synthetic ids at extraction; `instrument_id` blank. Identity carried by natural keys (`document_id`, `legal_article`, `official_name` verbatim, `verbatim_excerpt`), which are mandatory. There is no reconciliation pass: `instrument_id` remains blank unless a later, separate analysis assigns it (N6).

## 4. Columns record document-local facts only

Every field in this schema is populated from the document in front of the extractor. No field records a property of an instrument that would have to be established outside this document (N7 corollary). Where a downstream analysis needs such a property, it is appended as a new column after extraction closes — never populated during it.

---

## 5. Variable dictionary

Column numbering follows evidence dictionary v0.5 for shared fields, so a reader of one table can read the other. Gaps in the sequence are deliberate: they are v0.5 fields not used here (see §6).

| # | Variable | Type | Null? | Note |
|---|----------|------|-------|------|
| 1 | `evidence_id` | string PK | no | Sequential, country-prefixed, **census-namespaced** to prevent collision with evidence-table ids (e.g. `CIV_CEN_0001`). |
| 2 | `row_type` | enum | no | `{source}` — constant. Retained rather than dropped, for schema compatibility (N5). |
| 3 | `country` | ISO3 | no | ISO3 country code (e.g. `CIV`). |
| 4 | `instrument_id` | string FK | yes | Blank at extraction and thereafter (N6). No reconciliation pass. |
| 6 | `document_id` | string | **no** | Natural key (e.g. `AF2026`, `CGI2026`). |
| 7 | `document_type` | enum | no | v0.5 domain, unchanged: `{annexe_fiscale, loi_finances_initiale, cgi}`. Extend additively per jurisdiction (N9); do not add speculatively. |
| 8 | `document_year` | int (text) | no | Year of the **document**. Only temporal field here. |
| 9 | `legal_article` | string | yes | Natural key. |
| 10 | `page_start` | int | **no** | Page anchor. |
| 11 | `page_end` | int | **no** | Page anchor. |
| 12 | `official_name` | string (verbatim) | **no** | Natural key. Verbatim; cross-document variants expected and not normalized. |
| 13 | `tax_instrument` | enum | yes | v0.5 domain, unchanged: `{VAT, excise, fuel_levy, telecom_levy, environmental_tax, payroll_tax, resource_revenue, redevance, parafiscal_contribution, fine, other}`. **Functional type** — what the instrument is levied *on*. Orthogonal to `instrument_nature` (14a), which is its legal/definitional character. Both are needed: this field answers "a charge on what," 14a answers "what kind of charge." |
| 14 | `tax_base_detail` | string | yes | Verbatim/near-verbatim base. Load-bearing for N1(b): the base is part of what makes an instrument distinct. |
| 14a | `instrument_nature` | **OPEN — see below** | yes | **[CENSUS NEW] OPEN ITEM (N10.1).** The legal/definitional character of the instrument, carrying the narrow-vs-broad population boundary so it is a filter downstream, not an exclusion at extraction (N2). **Until the enum is closed: record the verbatim term the document itself uses, plus a provisional tag.** No row is lost; the enum is imposed retrospectively without re-extraction. Closing it is an empirical question about the corpus, not an a-priori one. |
| 15 | `rate_value` | numeric | yes | **Strictly scalar.** Null when banded/scheduled (see 15a–15b). Never holds text. |
| 15a | `rate_is_schedule` | bool | yes | 1 if the rate is banded/scheduled. Explains why `rate_value` is null. |
| 15b | `rate_schedule_detail` | string | yes | Full verbatim schedule when `rate_is_schedule = 1`. Parsed into a child table later; kept out of `rate_value` to preserve its numeric type. |
| 16 | `rate_type` | enum | yes | `{ad_valorem_pct, per_unit_amount, fixed_amount}`. Amount recorded as written; currency lives in `verbatim_excerpt`; no normalization at extraction. |
| 16a | `rate_basis` | enum | yes | v0.5 domain, unchanged: `{stated, banded, deferred_arrete, cross_reference, not_applicable}`. **Load-bearing here beyond its v0.5 role:** the presence of a rate concept is often what confirms a provision *institutes* an instrument rather than defining a term or citing one — it supports the N1(a) and N1(c) calls. `not_applicable` is itself a signal and requires a boundary-log entry (N8). |
| 24 | `change_type` | enum | yes | v0.5 domain, unchanged. **Provisional and document-local only** (N6). Records whether this document *institutes* the instrument or *amends* an existing one — a distinction visible in the text and needed downstream, but never a lineage judgment. |
| 27 | `predecessor_ref` | string | yes | Free-text reference to a prior instrument/article **the clause itself names**; null otherwise, never guessed. Not resolved (no reconciliation pass). |
| 27a | `predecessor_relation` | enum | yes | `{amends, replaces, merges, splits, none}` — what the text says the relationship IS. A recorded textual signal, not a judgment. |
| 29 | `enabling_reference` | string | yes | Founding/citing legal text referenced. |
| 30 | `verbatim_excerpt` | string | **no** | Exact clause text. **Load-bearing.** Must contain the language by which the text institutes the instrument. |
| 31 | `source_internal_inconsistency` | string | yes | Records a drafting inconsistency in the source itself. Preserves the anomaly without contaminating other fields. |
| 32 | `ai_confidence` | enum | no | `{high, medium, low}`. |
| 33 | `human_validation_status` | enum | no | `{unchecked, validated, corrected, rejected}`. Default `unchecked`. |
| 34 | `notes` | string | yes | Flags, stated ambiguities, handoff signals. |
| 35 | `evidence_status` | enum | no | **[CENSUS NEW]** `{attested, referenced_not_enacted_here}`. `attested` = instituted or provided for in this document's enacting text (N1(c) satisfied). `referenced_not_enacted_here` = named only by cross-reference to an instrument enacted elsewhere. The register values `interpolated`/`unobserved` do not arise in a per-document census — there is nothing to interpolate across, and an absent document is simply not swept. **Proposed extension pending ratification (N10.2).** |

## 6. v0.5 fields not used here (and why)

Absence is by design, not omission — the census records the source instrument and stops there (N5).

| v0.5 field | Why absent |
|---|---|
| 5 `pair_id` | A pair is (instrument × destination). The census records no destinations. |
| 17 `destination`, 18 `beneficiary_type` | Destination-side. |
| 18a `allocation_nature` | A property of a destination row. The census carries `instrument_nature` (14a) — a property of the *source*. These are different fields with different subjects and must not be conflated. |
| 19–20c `share_*` | Destination-side. |
| 21 `is_purpose_restricted`, 22 `assignment_type` | Classify a source–destination relation. No such relation is recorded here. |
| 23 `mechanism` | Instrument-level, derived; not populated at extraction in v0.5 either. |
| 25 `structural_break`, 28 `change_from_previous` | Cross-document judgments, finalized only in reconciliation. There is no reconciliation pass (N6). |
| 26 `partial_key` | Concerns allocation keys split across documents. |

**Consequence.** The omitted fields are the judgment-heavy ones. Census extraction is not merely fewer columns than a full evidence extraction — it is lower-judgment per row, which is what makes its coverage claims tight and its independence credible.

## 7. Hard-rule reminders

- **No invention.** An instrument not instituted in the *enacting* text → no row. Motivational, explanatory, and definitional text is not enacting text. A named-only-by-cross-reference instrument → row with `evidence_status = referenced_not_enacted_here`, never a silent entry.
- **Null over coercion.** Deferred/banded rate → null + flag, never a fabricated scalar, never text in a numeric column.
- **`document_year` ≠ instrument year.** The census makes no temporal claim about instruments.
- **Instrument-agnostic retrieval.** Anchor on the grammar by which a text institutes a charge, plus the document's own section structure — never a known-instrument checklist (N7).
- **Grain parity.** Grain is fixed corpus-wide; a per-document variation is a defect (N4).
- **Independence.** No other extraction output or result set is consulted during census extraction (N7).

## 8. Serialization contract

Identical in structure to evidence dictionary v0.5 §8: one canonical structure, two renderings (`xlsx` / `json`) selected by `output_format`; the schema is identical in both; an `xlsx → json → xlsx` round-trip must reproduce the original.

**One document = one output unit.** Sheets/keys:

| workbook sheet | json key | json shape |
|---|---|---|
| `RUN_META` | `run_meta` | object, nested: `{parameters, a6_gate, id_discipline}` (as v0.5 §8) |
| `census_table` | `census_rows` | array of row objects, §5 columns as keys, in §5 order |
| `COVERAGE_CERTIFICATE` | `coverage_certificate` | array of `{division, page_range, unit_range_examined, swept_in_full, instruments_found, certified_finding}` |
| `BOUNDARY_CALL_LOG` | `boundary_call_log` | array of `{census_rows, call_class, excerpt, call_made, for_signoff}` |
| `RECALL_AUDIT` | `recall_audit` | array of `{pages, grammar_hit, status, reason}` |
| `CONFIDENCE_REASONS` | `confidence_reasons` | array of `{census_rows, confidence, type, reason}` |
| `SCHEMA_STRESS_NOTE` | `schema_stress_note` | string (empty string if none) |

`census_rows` is the only key consumed downstream; every row carries `document_id`, so rows remain self-identifying once pulled out of the envelope. The other keys are the audit envelope that travels with the data.

`boundary_call_log.call_class ∈ {instrument_nature, container_decomposition, referenced_not_enacted, rate_absent}` — the four N1/N8 judgment classes. Every entry carries its verbatim excerpt and is flagged for human sign-off.

**Output filename.** `{country}_{document_id}_CENSUS_{scope_slug}.{ext}`, same `scope_slug` rules as v0.5 §8 (REQUIRED; multi-batch documents produce one file per batch and the close-out globs `{country}_{document_id}_CENSUS_*.{ext}` to union). The `CENSUS` token keeps census output from colliding with other output families for the same document. Illustration — CIV: `CIV_CGI2026_CENSUS_LivreIII.json`, `CIV_AF2026_CENSUS_whole.json`.

## 9. Open items (to be closed before freeze)

1. **`instrument_nature` (14a) enum — OPEN (N10.1).** Extraction proceeds with verbatim term + provisional tag; the enum is imposed retrospectively once the corpus's actual natures are known. No re-extraction required.
2. **`evidence_status = referenced_not_enacted_here` (35) — proposed extension pending ratification (N10.2).**
3. **`tax_instrument` (13) vs `instrument_nature` (14a) overlap — watch.** v0.5's `tax_instrument` already contains `redevance` and `parafiscal_contribution`, which are *natures*, not functional types — a latent inconsistency in v0.5, inherited here. Once 14a is closed, check whether those two values should be deprecated from 13. Do not act before 14a is closed; record the resolution in the assumptions register.
