# RUN PROMPTS (universal — all documents, all countries)

> **Supersedes the single-body template.** There are TWO prompts, because locate and extract are genuinely different operations (shallow recall-first scan vs. deep precision-first extraction). Both share ONE preamble (parameters + governing-doc reference + tripwire + preprocessing + retrieval lexicon); they differ in the MODE BODY. A single run_note cannot toggle between them — that framing is deprecated.
>
> **When to use which:**
> - `earmark_density: concentrated` + `length_class: short` (typical annexe / Finance Act) → use the EXTRACT prompt ALONE, fed the whole document. No locate pass needed; the document is short and dense enough that enumerate-and-extract in one pass, verified by the coverage report, is safe.
> - `earmark_density: sparse` OR `length_class: long` (CGI, long codes, merged loi+annexe) → use LOCATE first (whole document, shallow), then EXTRACT per section (bounded feed). The locate pass maps the sparse earmarks; the extract pass goes deep on bounded input to avoid attention-shallowing.
>
> Same governing files (CORE C1–C10, ADAPTER A0–A7, decision rules §1–§12, dictionary v0.5, coverage map, gold standard) drive both. Reproducibility: the method lives in those files; these prompts are thin entry points. Scale: only the RUN PARAMETERS block changes per document/country.
>
> **[REV-1] Restatement policy (anti-drift rule).** This prompt deliberately restates only TWO pieces of governing content inline — the tripwire (a cached copy of CORE C1, kept as a fallback against imperfect file retrieval) and the retrieval lexicon (a cached copy of Adapter A2). Both are CACHED COPIES: on any conflict, the governing file wins, and any edit to C1 or A2 must be propagated here in the same session. Nothing else from the governing docs may be duplicated into this prompt — reference, don't restate (duplication drifts; this file has already drifted twice against generalized C1/A6 and is corrected below).

---

## SHARED PREAMBLE (identical in both prompts — never edited except the parameter values)

**RUN PARAMETERS — the only values you edit per run**
- country: `[CIV]`
- document_id: `[CGI2026]`
- document_type: `[cgi | annexe_fiscale | loi_finances_initiale | other]`  ← [REV-6a] values mirror the dictionary enum (field 7); Anglophone values (e.g. `finance_act`, `establishing_act`) are added to the DICTIONARY FIRST when Ghana/Kenya extraction actually begins (per C10: extend additively, never speculatively), then mirrored here. Do not use a value the dictionary does not yet define.
- document_year: `[2026]`
- structural_vector: `{language: [fr|en], column_layout: [single|double|detect], length_class: [short|long], earmark_density: [concentrated|sparse|detect], content_form: [prose_clauses|table|mixed], numbering: [article|section|livre+article|line-item]}`
- gold_standard_file: `[CIV_gold_standard_v2]`
- section_scope: `[whole document | Livre III | Articles 140–200 | …]`  ← for EXTRACT, the bounded slice fed this run; for LOCATE, normally "whole document"
- output_format: `[xlsx | json]`  ← [REV-6b] chat workflow default `xlsx` (nine-sheet workbook); API workflow uses `json` (one object, nine keys). Both are renderings of ONE canonical structure defined in **dictionary §8 (serialization contract)** — same column evidence set, same eight C9 audits, in both. The format is transport, not schema; a `json` output missing any audit key is malformed exactly as a workbook missing an audit sheet would be.
- file(s): attached

**Governing method (read and apply from the project files):** CORE extraction methodology (C1–C10 — invariant method, grain, id-free discipline, audits), RETRIEVAL ADAPTER (A0–A7 — instantiate with the structural_vector), evidence dictionary v0.5 (schema), decision rules (§1–§12), assumptions register, the country's coverage map and gold standard. Do not reopen settled decisions.

**Tripwire (cached copy of CORE C1 — binding even if file retrieval is imperfect; C1 governs on conflict):** [REV-1] an earmark requires BOTH (a) a source levy/tax/charge/contribution of any kind (including civil-law forms such as redevance, prélèvement, parafiscal charge) AND (b) a verbatim clause in the ENACTING text assigning its proceeds — in whole or in part — to a specific named recipient. A fund merely existing is not sufficient; explanatory/motivational text is not assignment; never infer an unnamed destination. Unit of analysis = the INSTRUMENT, not the article/section.

**Preprocessing gate (Adapter A6 — certify the CANONICAL file, STOP on failure):** confirm format (%PDF or state actual — the app-upload path can decompose a searchable PDF into a zip-of-images, so certify the source file); clean UTF-8 with language-diagnostic characters intact [REV-1] (fr: accents — affecté/réparti/reversé; en: ligatures ﬁ/ﬂ, curly quotes, §/£; a font with no Unicode cmap garbles ASCII too — mojibake breaks the grammar sweep → silent false nulls); internal year matches document_year; mid-document sample legible. If `column_layout` is `double` or `detect`: run the canary — extract one known/representative assignment passage and confirm it reads as a contiguous clause; if interleaved, read from page images and never extract shares from interleaved text.

**Retrieval lexicon (cached copy of Adapter A2, fund-agnostic — the recipient is the OUTPUT of the search, never the input; NO known-fund checklist; A2 governs on conflict):** [REV-1]
- fr: affecté/affectation, au profit de, réparti/répartition, quote-part, quotité, produit de la taxe/du droit, est financé par le produit de, reversé, alimente, ristourne, compte spécial / compte d'affectation.
- en: earmarked/dedicated/allocated/appropriated to, paid into, credited to, retained by, "X% shall be transferred to", established fund, levied for the purpose of.

--- END SHARED PREAMBLE ---

═══════════════════════════════════════════
## PROMPT A — LOCATE  (shallow, whole-document, recall-first; used when sparse/long)
═══════════════════════════════════════════

[Paste the SHARED PREAMBLE above, then:]

**MODE = LOCATE. Do NOT populate any v0.5 schema field** — no rates, shares, allocation_nature, is_purpose_restricted, beneficiary_type, nothing. The only outputs are the inventory and the coverage certificate below.

Sweep the ENTIRE `section_scope` using the fund-agnostic lexicon. **Optimise for RECALL over precision:** flag every passage containing assignment grammar even if it may later prove to be tax-sharing, cost-recovery, or general-budget. Classification is EXTRACT's job; your job is to miss nothing. Because this is a shallow locating scan (not field extraction), it is safe over a long document — but you must certify full coverage (below).

**[REV-5] Table-region guard (LOCATE inherits Adapter A5).** In `content_form: table` regions (budget special-account recaps, credit tables), the recall-over-precision rule applies to CLAUSES, not to table lines: inventory only labels/rows that themselves contain assignment language (a source instrument + assignment grammar). Bare fund-name + amount lines are NOT flagged individually — they are certified in the coverage certificate as "table region pp. X–Y: N credit lines, no assignment clauses" (one certificate line, not N inventory rows). This keeps the inventory a worklist of extractable clauses, not a transcription of the budget.

**Output 1 — PASSAGE INVENTORY** (clean table, saveable; this is the interface to the EXTRACT pass and, later, the API JSON contract): one row per flagged passage with columns `{unit_ref (livre+article / section / line), page_start, page_end, trigger_cue (the exact assignment-grammar words found), instrument_hint (the levy, verbatim short), recipient_hint (the destination as written), prelim_flag (earmark_candidate | tax_sharing_candidate | cost_recovery_candidate | ambiguous)}`. `prelim_flag` is a NON-binding triage hint for sequencing EXTRACT, not a classification.

**Output 2 — SWEEP-COVERAGE CERTIFICATE:** per division (livre/chapter/section-range), state the article/section range examined and certify it was swept in full, so a division with zero flagged passages is a CERTIFIED absence, not an unswept gap. This is the proof the whole `section_scope` was scanned front to back — the guard against silent shallowing. [REV-4] The certificate must enumerate the division ranges CONTIGUOUSLY from the document's first division to its last — any numbering gap between certified ranges is itself a reportable finding (either the document skips those numbers, stated, or the sweep did — stop and re-sweep).

**Render Output 1 + Output 2 per `output_format` (dictionary §9): `xlsx` = two-sheet workbook (`PASSAGE_INVENTORY`, `SWEEP_COVERAGE_CERTIFICATE`); `json` = one object with two keys (`passage_inventory`, `sweep_coverage_certificate`).** [REV-8] Emit this as a FILE, not only an inline table — it is the interface to the EXTRACT pass and, in the API, the JSON contract the orchestrator filters to `section_scope` and passes to each extract call. Both components must be present in either rendering; the two are interconvertible without loss (§9). This is a SEPARATE output unit from the EXTRACT nine-key evidence object (§8); LOCATE populates no schema field.

Do not extract, classify definitively, or summarise the document. Locate and inventory only.

═══════════════════════════════════════════
## PROMPT B — EXTRACT  (deep, bounded-input, precision-first)
═══════════════════════════════════════════

[Paste the SHARED PREAMBLE above, then:]

**MODE = EXTRACT.** Populate the full v0.5 evidence table for every earmark-bearing clause in `section_scope`. If a LOCATE pass was run, its passage inventory (in this chat, or attached) is the worklist — extract each located passage; but still run your own recall check on `section_scope` so nothing outside the inventory is missed.

Apply CORE C1–C9 and all v0.5 mechanics: id-free (natural keys + verbatim excerpt + page on every row; instrument_id/pair_id blank); source and allocation as distinct row types; rate/share as value+type+basis (banded → scalar null + `*_is_schedule` + `*_schedule_detail`; deferred → `*_basis = deferred_arrete`; renvoi → `rate_basis = cross_reference`); nested keys → `share_level` + `share_pool` (self-contained descriptor, not a row-pointer); `allocation_nature` per §11/§11.1 (cost-recovery/user-charge vs earmark; collector-share sub-rule); `is_purpose_restricted` (extract-broad, filter-later — record general-budget recipients too); `assignment_type`; lineage signals `predecessor_ref`/`predecessor_relation` ONLY from what the text states (§9), no cross-document judgment; `change_type`/`structural_break` provisional, `human_validation_status = unchecked`. No-invention/null discipline throughout (unnamed destination → null + medium; never fabricate).

**[REV-3] Batch-boundary rule (multi-batch documents only).** When `section_scope` is a slice of a larger document, an allocation key that fails the 100%-sum check at the scope boundary is NOT a schema-stress event and must NOT trigger a STOP: set `partial_key = 1`, note "remainder outside section_scope (suspected [division])", and continue. Cross-batch key joins are reconciliation's job, not the batch's. Reserve SCHEMA-STRESS for genuinely new structural patterns, not for scope-truncation artifacts.

**Output — the evidence set + the CORE C9 audit set, rendered per `output_format` (dictionary §8): `xlsx` = nine-sheet workbook; `json` = one object with nine keys. Same content either way (v0.5 column order, plain formatting, no decorative fills); the eight audits below are carried in BOTH renderings, never dropped when emitting `json`.** The `locate_reconciliation` audit (7) is emitted in `json` as an object with first-class `{N, M, K, J}` scalars so the invariant is machine-checkable (dictionary §8).
(1) COVERAGE REPORT — every division in `section_scope` accounted for (rows produced OR "checked — no earmark clause"); if working from a LOCATE inventory, every inventory entry either extracted or dismissed with reason.
(2) RECALL AUDIT — every assignment-grammar hit in `section_scope` captured or dismissed with a one-line reason.
(3) FIELD-EXERCISE NOTE — flag every judgment-sensitive call (§11.1 collector-share, cross_reference, banded, `is_purpose_restricted = 0`, `share_level = 2`) for sign-off.
(4) SCHEMA-STRESS NOTE — genuinely new gaps only; a real one → STOP before continuing the corpus. [REV-3] Scope-truncated keys are handled by the batch-boundary rule above and do not belong here.
(5) CONFIDENCE REASONS — per non-high row, document problem vs schema problem.
(6) GOLD SCORING — open gold_standard_file, identify cases anchored to this document_id (and within section_scope), score recall + invented fields; state if none anchored here. [REV-4] This per-run scoring is a DIAGNOSTIC, not the acceptance gate — the gate is the document-level gold reconciliation (see Usage patterns).
(7) **[REV-2] LOCATE RECONCILIATION (mandatory whenever a LOCATE inventory exists for this scope):** report four counts and their identities — N inventory entries within `section_scope`; M extracted to evidence rows (map entry → evidence_id(s)); K dismissed (each with a one-line reason: not an assignment clause / cost-recovery only / duplicate of entry X / …); J evidence rows extracted from passages NOT in the inventory (each listed with unit_ref + page). **Invariant: M + K = N, every entry accounted.** If J > 0, the locate pass under-recalled: flag the inventory as INCOMPLETE and append the J passages to it (amendment logged, not silent) so the inventory remains the true coverage denominator and the valid API contract. An unreconciled inventory is an audit failure, not an acceptable residual.

Extract verbatim and anchored; never summarise; record uncertainty in notes, never resolve it silently.

---

## Usage patterns

- **Annexe fiscale (short, concentrated):** PROMPT B alone, `section_scope: whole document`. No locate pass.
- **CGI (long, sparse):** PROMPT A on whole document → save inventory → PROMPT B per livre (`section_scope: Livre N`, fed that livre's pages). Deep pass stays bounded.
- **Loi de finances (mixed, table):** PROMPT B with `content_form: table` handling; locate optional if long. [REV-5] If LOCATE is used, the table-region guard applies.
- **New country (e.g. Ghana Act, en):** same two prompts, edit `language: en`, `numbering: section`, swap gold_standard_file + coverage map. [REV-6a] First extend the dictionary `document_type` enum (per C10, logged in the assumptions register), then mirror the value here. Method unchanged.
- **[REV-4] Multi-batch close-out (mandatory final step for any document extracted in >1 batch):** after the last batch, run a DOCUMENT-LEVEL GOLD RECONCILIATION — list every gold case anchored to this document_id, state which batch recovered it (or that it was missed), and score the union of all batches. Also verify the union of batch coverage reports tiles the full division range of the document with no gap and no overlap double-counting. Per-batch gold scoring (Output 6) is diagnostic; THIS is the document's acceptance gate. (This formalizes the "all three CGI gold anchors recovered" check as a required artifact rather than an ad-hoc one.)

---

## [REV-7] API scale-up manifest (what conditions each call — decide it here, not implicitly)

In the API workflow there is no project-knowledge retrieval: the orchestration code decides exactly what each call sees. This manifest is that decision, and doubles as the methods-section answer to "what does the model condition on."

**Cached system prompt (every call, both modes):** CORE C1–C10 · dictionary v0.5 · decision rules §1–§12 · RETRIEVAL ADAPTER A0–A7 · this run-prompts file's SHARED PREAMBLE with the parameter block templated. (These are the method; every call needs all of them. Prompt caching makes the cost per call marginal.)

**Per-call variable payload:** RUN PARAMETERS values (JSON) · the document slice for `section_scope` (clean UTF-8 text + page anchors, produced by the scripted ingestion layer) · for EXTRACT calls after a LOCATE: the passage-inventory JSON filtered to `section_scope`.

**Mode-conditional:** gold standard file → attached ONLY to runs that score (Output 6) and to the document-level close-out call; not in the cached prompt (it would leak anchors into retrieval, violating fund-agnosticism A8). Coverage map → not sent to the model at all; it is the ORCHESTRATOR's routing table (which files exist, which gate they passed), consumed in code.

**Never sent:** assumptions register (analyst-facing, not extractor-facing — nothing in it changes a per-clause decision that CORE/dictionary/rules don't already encode); literature PDFs; other documents' evidence tables (extraction is per-document by design; cross-document sight would tempt cross-document judgment, which §9 defers to reconciliation).

**State handling:** all state passes via files (passage-inventory JSON, evidence-row JSON) managed by orchestration code; no reliance on model memory across calls. The LOCATE Output-1 column set IS the JSON schema of the locate→extract handoff; the EXTRACT Output-7 reconciliation is emitted as a machine-checkable block (counts + id maps) so the orchestrator can enforce M+K=N and J=0-or-amend programmatically.
