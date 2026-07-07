# RETRIEVAL ADAPTER (parameterized — keyed on document STRUCTURE, not document TYPE)

> **What this is.** The thin, variable Layer-3 procedure that adapts *how a document is read* to its structural properties, then feeds the invariant CORE (C1–C10). It is NOT one-adapter-per-document-type. It is ONE procedure parameterized by a small set of structural properties, because what actually varies for extraction is *structure* (columns, length, density, form, numbering), not *type label*. A one-column Ivorian CGI and a two-column Senegalese CGI differ only in the `column_layout` parameter — same procedure. This is what lets the method generalize to unseen configurations (merged loi+annexe, mixed layouts, new countries) without new prompts.

---

## A0. Structural-detection preamble (set the parameters FIRST)
Before retrieval, detect/declare and REPORT these parameters for the document. They drive every downstream choice and are recorded for auditability.

| Parameter | Values | Drives |
|-----------|--------|--------|
| `language` | fr / en / other | which assignment-grammar lexicon (A2) |
| `column_layout` | single / double / detect | linear vs column-aware extraction (A1) |
| `length_class` | short (<~80pp) / long (>~80pp) | single-pass vs sectioned (A3) |
| `earmark_density` | concentrated / sparse | enumerate-all vs locate-then-extract (A4) |
| `content_form` | prose_clauses / table / mixed | clause extraction vs structural-table extraction (A5) |
| `numbering` | article / section / livre+article / line-item / none | the coverage-report unit (C9) |

Report the parameter vector in one line, then proceed. A document type is just a typical vector, not a special case: annexe fiscale = {fr, single, short, concentrated, prose, article}; CIV CGI = {fr, double, long, sparse, prose, livre+article}; loi de finances CST = {fr, single/table, long, mixed, table+prose, line-item}; Ghana Finance Act = {en, single, medium, concentrated, prose, section}.

## A1. Column handling (from `column_layout`)
- **single** → linear text extraction is safe.
- **double** → linear extraction INTERLEAVES columns (splices unrelated clauses). Before trusting text: run the **canary test** — extract one known-earmark passage and check it reads as a contiguous clause. If interleaved → use column-aware extraction (per-column crop) OR verify every load-bearing clause against the page image. NEVER extract earmark shares from interleaved text (produces confident-wrong source/destination pairs).
- **detect** → run the canary on a representative page; set single/double from the result.

## A2. Assignment-grammar lexicon (from `language`) — the ONLY country/language-variable retrieval content
- **fr:** affecté/affectation, au profit de, réparti/répartition, quote-part, quotité, produit de la taxe, est financé par le produit de, reversé, alimente, compte spécial / compte d'affectation, ristourne; source cues (produit de, recouvré, perçu); destination cues (fonds, bénéficiaire).
- **en:** earmarked/dedicated/allocated/appropriated to, paid into, credited to, retained by, X% shall be transferred to, established fund, levied for the purpose of; source cues (levied, collected, imposed); destination cues (fund, board, authority).
- **Fund-agnostic rule (invariant):** the recipient is the OUTPUT of the search, never the input. Never use a known-fund checklist — it confirms known earmarks and misses new ones.

## A3. Sectioning (from `length_class`) — solves attention-loss STRUCTURALLY
- **short** → single-pass extraction is acceptable; the coverage report (C9) still verifies completeness.
- **long** → MUST section by the document's own divisions (`numbering`: livre / chapter / section-range). Extract batch by batch, each ≤ a tractable size, each independently anchored. Attention loss over a long document is NOT solved by prompt wording — it is solved by never processing the whole document at once. The per-section coverage report proves nothing was skipped.

## A4. Retrieval mode (from `earmark_density`)
- **concentrated** (annexes: earmarks in most assignment-signalling articles) → enumerate ALL divisions, sweep each. Coverage unit = every article.
- **sparse** (codes: earmarks scattered thin across many pages) → LOCATE-THEN-EXTRACT: first run the assignment-grammar sweep across the whole (column-verified) text to inventory earmark-bearing passages with anchors; then extract those passages in batches. Coverage unit = every division certified swept (even those with zero hits), so "sparse" never means "under-read."

## A5. Content form (from `content_form`)
- **prose_clauses** → clause extraction into the evidence table (C5–C7).
- **table** (e.g. loi de finances CST recap) → structural extraction: evidence rows ONLY for labels that themselves name a source instrument/assignment; a separate budget-amounts table (account × year × amount_budgeted) for the figures. Do NOT clause-read hundreds of budget-credit pages; do NOT manufacture evidence rows from bare fund-name lines with no assignment clause (fund existing ≠ earmark).
- **mixed** → apply both to their respective regions of the document.

## A6. Preprocessing gate (invariant across parameters — always run)
Certify the CANONICAL file (not the app-uploaded artifact, which can decompose a searchable PDF into a zip-of-images): (1) format = %PDF or state actual; (2) encoding = clean UTF-8, accents intact (mojibake → silent false nulls in the grammar sweep); (3) internal title year matches expected; (4) mid-document sample returns coherent text (corrupt font layer hazard). Any failure → STOP and report (or route to OCR: rasterize → language-appropriate OCR → preserve page anchors → verify load-bearing figures against page images).

## A7. Handoff to CORE
After A0–A6, extraction proceeds under the CORE (C1–C9) unchanged. The adapter changed only HOW the text was located and read; WHAT is extracted, the schema, the grain, the id-free discipline, and the audits are the frozen core. Every run therefore produces the same auditable outputs regardless of document type — which is the reproducibility claim, made structurally true.
