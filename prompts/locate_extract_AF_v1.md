**RUN PARAMETERS — the only values you edit per run**
- country: `[CIV]`
- document_id: `[AF2025]`
- document_type: `[annexe_fiscale]` 
- document_year: `[2025]`
- structural_vector: `{language: [fr], column_layout: [single], length_class: [long], earmark_density: [concentrated], content_form: [mixed], numbering: [article]}`
- gold_standard_file: `[CIV_gold_standard_v2]`
- section_scope: `[whole document]` 
- output_format: `[json]`
- file(s): attached

**Governing method (read and apply from the project files):** CORE extraction methodology (C1–C10 — invariant method, grain, id-free discipline, audits), RETRIEVAL ADAPTER (A0–A7 — instantiate with the structural_vector), evidence dictionary v0.5 (schema), decision rules (§1–§12), assumptions register, the country's coverage map and gold standard. Do not reopen settled decisions.

**Tripwire (cached copy of CORE C1 — binding even if file retrieval is imperfect; C1 governs on conflict):** an earmark requires BOTH (a) a source levy/tax/charge/contribution of any kind (including civil-law forms such as redevance, prélèvement, parafiscal charge) AND (b) a verbatim clause in the ENACTING text assigning its proceeds — in whole or in part — to a specific named recipient. A fund merely existing is not sufficient; explanatory/motivational text is not assignment; never infer an unnamed destination. Unit of analysis = the INSTRUMENT, not the article/section.

**Preprocessing gate (Adapter A6 — certify the CANONICAL file, STOP on failure):** confirm format (%PDF or state actual — the app-upload path can decompose a searchable PDF into a zip-of-images, so certify the source file); clean UTF-8 with language-diagnostic characters intact (fr: accents — affecté/réparti/reversé; en: ligatures ﬁ/ﬂ, curly quotes, §/£; a font with no Unicode cmap garbles ASCII too — mojibake breaks the grammar sweep → silent false nulls); internal year matches document_year; mid-document sample legible. If `column_layout` is `double` or `detect`: run the canary — extract one known/representative assignment passage and confirm it reads as a contiguous clause; if interleaved, read from page images and never extract shares from interleaved text.

**Retrieval lexicon (cached copy of Adapter A2, fund-agnostic — the recipient is the OUTPUT of the search, never the input; NO known-fund checklist; A2 governs on conflict):**
- fr: affecté/affectation, au profit de, réparti/répartition, quote-part, quotité, produit de la taxe/du droit, est financé par le produit de, reversé, alimente, ristourne, compte spécial / compte d'affectation.
- en: earmarked/dedicated/allocated/appropriated to, paid into, credited to, retained by, "X% shall be transferred to", established fund, levied for the purpose of.

--- END SHARED PREAMBLE ---

═══════════════════════════════════════════
## PROMPT A — LOCATE  (shallow, whole-document, recall-first; used when sparse/long)
═══════════════════════════════════════════

[Paste the SHARED PREAMBLE above, then:]

**MODE = LOCATE. Do NOT populate any v0.5 schema field** — no rates, shares, allocation_nature, is_purpose_restricted, beneficiary_type, nothing. The only outputs are the inventory and the coverage certificate below.

Sweep the ENTIRE `section_scope` using the fund-agnostic lexicon. **Optimise for RECALL over precision:** flag every passage containing assignment grammar even if it may later prove to be tax-sharing, cost-recovery, or general-budget. Classification is EXTRACT's job; your job is to miss nothing. Because this is a shallow locating scan (not field extraction), it is safe over a long document — but you must certify full coverage (below).

**Table-region guard (LOCATE inherits Adapter A5).** In `content_form: table` regions (budget special-account recaps, credit tables), the recall-over-precision rule applies to CLAUSES, not to table lines: inventory only labels/rows that themselves contain assignment language (a source instrument + assignment grammar). Bare fund-name + amount lines are NOT flagged individually — they are certified in the coverage certificate as "table region pp. X–Y: N credit lines, no assignment clauses" (one certificate line, not N inventory rows). This keeps the inventory a worklist of extractable clauses, not a transcription of the budget.

**Output 1 — PASSAGE INVENTORY** (clean table, saveable; this is the interface to the EXTRACT pass): one row per flagged passage with columns `{unit_ref (livre+article / section / line), page_start, page_end, trigger_cue (the exact assignment-grammar words found), instrument_hint (the levy, verbatim short), recipient_hint (the destination as written), prelim_flag (earmark_candidate | tax_sharing_candidate | cost_recovery_candidate | ambiguous)}`. `prelim_flag` is a NON-binding triage hint for sequencing EXTRACT, not a classification.

**Output 2 — SWEEP-COVERAGE CERTIFICATE:** per division (livre/chapter/section-range), state the article/section range examined and certify it was swept in full, so a division with zero flagged passages is a CERTIFIED absence, not an unswept gap. This is the proof the whole `section_scope` was scanned front to back — the guard against silent shallowing. The certificate must enumerate the division ranges CONTIGUOUSLY from the document's first division to its last — any numbering gap between certified ranges is itself a reportable finding (either the document skips those numbers, stated, or the sweep did — stop and re-sweep).

**Render Output 1 + Output 2 per `output_format` (dictionary §9): `xlsx` = two-sheet workbook (`PASSAGE_INVENTORY`, `SWEEP_COVERAGE_CERTIFICATE`); `json` = one object with two keys (`passage_inventory`, `sweep_coverage_certificate`).** Emit this as a FILE, not an inline table — it is the interface to the EXTRACT pass and, in the API, the JSON contract the orchestrator filters to `section_scope` and passes to each extract call. Both components must be present in either rendering; the two are interconvertible without loss (§9). This is a SEPARATE output unit from the EXTRACT nine-key evidence object (§8); LOCATE populates no schema field.

Do not extract, classify definitively, or summarise the document. Locate and inventory only.

═══════════════════════════════════════════
## PROMPT B — EXTRACT  (deep, bounded-input, precision-first)
═══════════════════════════════════════════

[Paste the SHARED PREAMBLE above, then:]

**MODE = EXTRACT.** Populate the full v0.5 evidence table for every earmark-bearing clause in `section_scope`. If a LOCATE pass was run, its passage inventory (in this chat, or attached) is the worklist — extract each located passage; but still run your own recall check on `section_scope` so nothing outside the inventory is missed.

Apply CORE C1–C9 and all v0.5 mechanics: id-free (natural keys + verbatim excerpt + page on every row; instrument_id/pair_id blank); source and allocation as distinct row types; rate/share as value+type+basis (banded → scalar null + `*_is_schedule` + `*_schedule_detail`; deferred → `*_basis = deferred_arrete`; renvoi → `rate_basis = cross_reference`); nested keys → `share_level` + `share_pool` (self-contained descriptor, not a row-pointer); `allocation_nature` per §11/§11.1 (cost-recovery/user-charge vs earmark; collector-share sub-rule); `is_purpose_restricted` (extract-broad, filter-later — record general-budget recipients too); `assignment_type`; lineage signals `predecessor_ref`/`predecessor_relation` ONLY from what the text states (§9), no cross-document judgment; `change_type`/`structural_break` provisional, `human_validation_status = unchecked`. No-invention/null discipline throughout (unnamed destination → null + medium; never fabricate).

**Batch-boundary rule (multi-batch documents only).** When `section_scope` is a slice of a larger document, an allocation key that fails the 100%-sum check at the scope boundary is NOT a schema-stress event and must NOT trigger a STOP: set `partial_key = 1`, note "remainder outside section_scope (suspected [division])", and continue. Cross-batch key joins are reconciliation's job, not the batch's. Reserve SCHEMA-STRESS for genuinely new structural patterns, not for scope-truncation artifacts.

**Output — the evidence set + the CORE C9 audit set, rendered per `output_format` (dictionary §8): `xlsx` = nine-sheet workbook; `json` = one object with nine keys. Same content either way (v0.5 column order, plain formatting, no decorative fills); the eight audits below are carried in BOTH renderings, never dropped when emitting `json`.** The `locate_reconciliation` audit (7) is emitted in `json` as an object with first-class `{N, M, K, J}` scalars so the invariant is machine-checkable (dictionary §8).
(1) COVERAGE REPORT — every division in `section_scope` accounted for (rows produced OR "checked — no earmark clause"); if working from a LOCATE inventory, every inventory entry either extracted or dismissed with reason.
(2) RECALL AUDIT — every assignment-grammar hit in `section_scope` captured or dismissed with a one-line reason.
(3) FIELD-EXERCISE NOTE — flag every judgment-sensitive call (§11.1 collector-share, cross_reference, banded, `is_purpose_restricted = 0`, `share_level = 2`) for sign-off.
(4) SCHEMA-STRESS NOTE — genuinely new gaps only; a real one → STOP before continuing the corpus. Scope-truncated keys are handled by the batch-boundary rule above and do not belong here.
(5) CONFIDENCE REASONS — per non-high row, document problem vs schema problem.
(6) GOLD SCORING — open gold_standard_file, identify cases anchored to this document_id (and within section_scope), score recall + invented fields; state if none anchored here. 
(7) **LOCATE RECONCILIATION (mandatory whenever a LOCATE inventory exists for this scope):** report four counts and their identities — N inventory entries within `section_scope`; M extracted to evidence rows (map entry → evidence_id(s)); K dismissed (each with a one-line reason: not an assignment clause / cost-recovery only / duplicate of entry X / …); J evidence rows extracted from passages NOT in the inventory (each listed with unit_ref + page). **Invariant: M + K = N, every entry accounted.** If J > 0, the locate pass under-recalled: flag the inventory as INCOMPLETE and append the J passages to it (amendment logged, not silent) so the inventory remains the true coverage denominator.

Extract verbatim and anchored; never summarise; record uncertainty in notes, never resolve it silently.
