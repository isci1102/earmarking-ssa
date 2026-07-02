# Processing Plan — CIV earmark extraction

**Principle.** The file on disk is the memory, not the chat. Each document is processed in a focused, bounded pass and its evidence written out immediately, so no single analysis step holds more than one or two documents at once. Accumulated knowledge lives in the growing evidence table, not in conversational context. This keeps every pass small enough to stay accurate across ~26 documents and possibly multiple sessions.

---

## 1. Per-document-type contribution (what each type can and cannot populate)

Established by direct inspection of one document of each type.

| Type | Populates | Does NOT populate | Retrieval mode |
|------|-----------|-------------------|----------------|
| **Annexe fiscale** | current-year allocation-key clauses, rate changes, modification *timing*; cleanest verbatim assignment grammar | standing earmarks unchanged that year (they don't appear); envelopes | article-level chunks; open assignment-grammar sweep |
| **CGI** | standing assignment clauses, founding legal references, consolidated **amendment chains** (date changes even for missing years); resolves pre-window earmarks | current-year-only reforms not yet codified | open assignment-grammar sweep over full text + TOC/heading pass; two-column disentangling required |
| **Loi de finances initiale** | CST destination accounts; `amount_budgeted` per account-year; for 2025–2026, labels also name source instruments and surface earmarks absent from annexes (e.g. VOD tax, VAT-to-electricity) | source assignment clauses for most accounts (destination side only, mostly) | structural extraction of the CST recap table + targeted search of the rest |
| **Loi de finances rectificative** | (nothing for de-jure structure) | earmark creation/repeal/re-keying — inspected: amount revisions only | excluded first pass |

---

## 2. Extraction order (batched by type, file-first, with checkpoints)

Process in batches; write evidence rows and inspect after **each document**, so errors are caught early rather than compounding across the corpus.

1. **Annexes (clean: 2023–2026 first).** Where the cleanest clauses and the gold standard live. One annexe per focused pass → write `evidence_source` + `evidence_allocation` rows → you inspect → next.
2. **Annexes (OCR: 2012, 2017).** Only after the §3-pre-processing gate produces verified clean text.
3. **CGI 2026.** Open assignment-grammar sweep across all 273 pp + TOC/heading pass (see §3). Resolves standing earmarks (FER, FSPDF/forestier, FDFP, FNLS/PNLTA links).
4. **Loi-de-finances CST tables (all held years).** Structural table extraction → the separate **budget-amounts table** (account × year × `amount_budgeted`), not the evidence table.
5. **Reconciliation pass.** Over the *complete* id-free evidence set: assign `instrument_id`/`pair_id` from natural keys; flag hard identity cases for human adjudication (see decision-rules doc).
6. **Derive** the instrument entity (completeness check) and, later, the panel.

Each batch ends at a checkpoint you inspect before continuing. You never verify a 26-document megafile at the end; you verify document by document.

---

## 3. Retrieval discipline — three layers, fund-agnostic (protects discovery)

Candidate detection must **never** be anchored on a list of funds already known — that would only confirm known earmarks and systematically miss new ones (confirmation bias in retrieval). Anchor on the *grammar of assignment*, which is destination-agnostic:

- **Layer 1 — assignment-grammar sweep (open).** Sweep the full document for the *act of assignment*, regardless of destination name: `affecté/affectation`, `au profit de`, `réparti/répartition`, `quote-part`, `quotité`, `produit de la taxe`, `est financé par le produit de`, `reversé`, `alimente`, `compte spécial dénommé`, `au profit du Fonds`. Include source-side cues (`produit de`, `recouvré`, `perçu`) and destination-side cues (`fonds`, `bénéficiaire`, `compte d'affectation`) so an earmark must evade *all* patterns to be missed. The fund name is the **output** of the search, never the **input**.
- **Layer 2 — structural/heading pass.** Read the table of contents and section titles; pull every section whose *title* signals assignment (`répartition`, `affectation`, `fonds`, names a special account). Catches earmarks whose body phrasing is idiosyncratic and evades Layer 1.
- **Layer 3 — human recall audit (pilot only).** Skim all section headings once to confirm nothing whole was missed; spot-check ambiguous titles. Affordable at pilot scale; validates the automated sweep for the methods section.

The same fund-agnostic principle applies to annexes and budget laws, not only the CGI.

---

## 4. Non-negotiable per-row requirements (the entity-resolution substrate)

Because extraction is **id-free** (synthetic ids assigned later in reconciliation), every evidence row must record the **natural keys** that let reconciliation group correctly:
`document_id`, `document_type`, `document_year`, `legal_article`, `page_start`/`page_end`, `official_name` (verbatim), and the full `verbatim_excerpt`. These are non-null-required. Id-free ≠ context-free: defer the id number, never the identity evidence.
