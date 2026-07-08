# RUN PROMPTS (universal — all documents, all countries)

> **Supersedes the single-body template.** There are TWO prompts, because locate and extract are genuinely different operations (shallow recall-first scan vs. deep precision-first extraction). Both share ONE preamble (parameters + governing-doc reference + tripwire + preprocessing + retrieval lexicon); they differ in the MODE BODY. A single run_note cannot toggle between them — that framing is deprecated.
>
> **When to use which:**
> - `earmark_density: concentrated` + `length_class: short` (typical annexe / Finance Act) → use the EXTRACT prompt ALONE, fed the whole document. No locate pass needed; the document is short and dense enough that enumerate-and-extract in one pass, verified by the coverage report, is safe.
> - `earmark_density: sparse` OR `length_class: long` (CGI, long codes, merged loi+annexe) → use LOCATE first (whole document, shallow), then EXTRACT per section (bounded feed). The locate pass maps the sparse earmarks; the extract pass goes deep on bounded input to avoid attention-shallowing.
>
> Same governing files (CORE C1–C10, ADAPTER A0–A7, decision rules §1–§12, dictionary v0.5, coverage map, gold standard) drive both. Reproducibility: the method lives in those files; these prompts are thin entry points. Scale: only the RUN PARAMETERS block changes per document/country.

---

## SHARED PREAMBLE (identical in both prompts — never edited except the parameter values)

**RUN PARAMETERS — the only values you edit per run**
- country: `[CIV]`
- document_id: `[CGI2026]`
- document_type: `[cgi | annexe_fiscale | loi_finances_initiale | act | other]`
- document_year: `[2026]`
- structural_vector: `{language: [fr|en], column_layout: [single|double|detect], length_class: [short|long], earmark_density: [concentrated|sparse|detect], content_form: [prose_clauses|table|mixed], numbering: [article|section|livre+article|line-item]}`
- gold_standard_file: `[CIV_gold_standard_v2]`
- section_scope: `[whole document | Livre III | Articles 140–200 | …]`  ← for EXTRACT, the bounded slice fed this run; for LOCATE, normally "whole document"
- file(s): attached

**Governing method (read and apply from the project files):** CORE extraction methodology (C1–C10 — invariant method, grain, id-free discipline, audits), RETRIEVAL ADAPTER (A0–A7 — instantiate with the structural_vector), evidence dictionary v0.5 (schema), decision rules (§1–§12), assumptions register, the country's coverage map and gold standard. Do not reopen settled decisions.

**Tripwire (binding even if file retrieval is imperfect):** an earmark requires BOTH (a) a source levy/tax/redevance/contribution/prélèvement/parafiscal charge AND (b) a verbatim clause in the ENACTING text assigning its proceeds — in whole or in part — to a specific named recipient. A fund merely existing is not sufficient; explanatory/motivational text is not assignment; never infer an unnamed destination. Unit of analysis = the INSTRUMENT, not the article/section.

**Preprocessing gate (Adapter A6 — certify the CANONICAL file, STOP on failure):** confirm format (%PDF or state actual — the app-upload path can decompose a searchable PDF into a zip-of-images, so certify the source file), clean UTF-8 with accents intact (mojibake breaks the grammar sweep → silent false nulls), internal year matches document_year, mid-document sample legible. If `column_layout` is `double` or `detect`: run the canary — extract one known/representative assignment passage and confirm it reads as a contiguous clause; if interleaved, read from page images and never extract shares from interleaved text.

**Retrieval lexicon (Adapter A2, fund-agnostic — the recipient is the OUTPUT of the search, never the input; NO known-fund checklist):**
- fr: affecté/affectation, au profit de, réparti/répartition, quote-part, quotité, produit de la taxe/du droit, est financé par le produit de, reversé, alimente, ristourne, compte spécial / compte d'affectation.
- en: earmarked/dedicated/allocated/appropriated to, paid into, credited to, retained by, "X% shall be transferred to", established fund, levied for the purpose of.

--- END SHARED PREAMBLE ---

═══════════════════════════════════════════
## PROMPT A — LOCATE  (shallow, whole-document, recall-first; used when sparse/long)
═══════════════════════════════════════════

[Paste the SHARED PREAMBLE above, then:]

**MODE = LOCATE. Do NOT populate any v0.5 schema field** — no rates, shares, allocation_nature, is_purpose_restricted, beneficiary_type, nothing. The only outputs are the inventory and the coverage certificate below.

Sweep the ENTIRE `section_scope` using the fund-agnostic lexicon. **Optimise for RECALL over precision:** flag every passage containing assignment grammar even if it may later prove to be tax-sharing, cost-recovery, or general-budget. Classification is EXTRACT's job; your job is to miss nothing. Because this is a shallow locating scan (not field extraction), it is safe over a long document — but you must certify full coverage (below).

**Output 1 — PASSAGE INVENTORY** (clean table, saveable; this is the interface to the EXTRACT pass and, later, the API JSON contract): one row per flagged passage with columns `{unit_ref (livre+article / section / line), page_start, page_end, trigger_cue (the exact assignment-grammar words found), instrument_hint (the levy, verbatim short), recipient_hint (the destination as written), prelim_flag (earmark_candidate | tax_sharing_candidate | cost_recovery_candidate | ambiguous)}`. `prelim_flag` is a NON-binding triage hint for sequencing EXTRACT, not a classification.

**Output 2 — SWEEP-COVERAGE CERTIFICATE:** per division (livre/chapter/section-range), state the article/section range examined and certify it was swept in full, so a division with zero flagged passages is a CERTIFIED absence, not an unswept gap. This is the proof the whole `section_scope` was scanned front to back — the guard against silent shallowing.

Do not extract, classify definitively, or summarise the document. Locate and inventory only.

═══════════════════════════════════════════
## PROMPT B — EXTRACT  (deep, bounded-input, precision-first)
═══════════════════════════════════════════

[Paste the SHARED PREAMBLE above, then:]

**MODE = EXTRACT.** Populate the full v0.5 evidence table for every earmark-bearing clause in `section_scope`. If a LOCATE pass was run, its passage inventory (in this chat, or attached) is the worklist — extract each located passage; but still run your own recall check on `section_scope` so nothing outside the inventory is missed.

Apply CORE C1–C9 and all v0.5 mechanics: id-free (natural keys + verbatim excerpt + page on every row; instrument_id/pair_id blank); source and allocation as distinct row types; rate/share as value+type+basis (banded → scalar null + `*_is_schedule` + `*_schedule_detail`; deferred → `*_basis = deferred_arrete`; renvoi → `rate_basis = cross_reference`); nested keys → `share_level` + `share_pool` (self-contained descriptor, not a row-pointer); `allocation_nature` per §11/§11.1 (cost-recovery/user-charge vs earmark; collector-share sub-rule); `is_purpose_restricted` (extract-broad, filter-later — record general-budget recipients too); `assignment_type`; lineage signals `predecessor_ref`/`predecessor_relation` ONLY from what the text states (§9), no cross-document judgment; `change_type`/`structural_break` provisional, `human_validation_status = unchecked`. No-invention/null discipline throughout (unnamed destination → null + medium; never fabricate).

**Output — .xlsx** (v0.5 column order, plain formatting, no decorative fills) + the CORE C9 audit set inline:
(1) COVERAGE REPORT — every division in `section_scope` accounted for (rows produced OR "checked — no earmark clause"); if working from a LOCATE inventory, every inventory entry either extracted or dismissed with reason.
(2) RECALL AUDIT — every assignment-grammar hit in `section_scope` captured or dismissed with a one-line reason.
(3) FIELD-EXERCISE NOTE — flag every judgment-sensitive call (§11.1 collector-share, cross_reference, banded, `is_purpose_restricted = 0`, `share_level = 2`) for sign-off.
(4) SCHEMA-STRESS NOTE — genuinely new gaps only; a real one → STOP before continuing the corpus.
(5) CONFIDENCE REASONS — per non-high row, document problem vs schema problem.
(6) GOLD SCORING — open gold_standard_file, identify cases anchored to this document_id (and within section_scope), score recall + invented fields; state if none anchored here.

Extract verbatim and anchored; never summarise; record uncertainty in notes, never resolve it silently.

---

## Usage patterns

- **Annexe fiscale (short, concentrated):** PROMPT B alone, `section_scope: whole document`. No locate pass.
- **CGI (long, sparse):** PROMPT A on whole document → save inventory → PROMPT B per livre (`section_scope: Livre N`, fed that livre's pages). Deep pass stays bounded.
- **Loi de finances (mixed, table):** PROMPT B with `content_form: table` handling; locate optional if long.
- **New country (e.g. Ghana Act, en):** same two prompts, edit `language: en`, `numbering: section`, swap gold_standard_file + coverage map. Method unchanged.
