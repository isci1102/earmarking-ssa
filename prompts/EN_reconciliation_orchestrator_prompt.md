{COUNTRY}: [ZAF]
Read reconciliation_prompt.md and reconciliation_rules.md in governing_docs_reconciliation.
Apply them exactly as written. Do not modify them. Where this prompt and those
files differ, those files govern, except on the four stack-level points fixed below
(§B) — which they do not cover because they assume a single-document corpus.
A. STACK FIRST, RECONCILE ONCE
1. Inventory every file matching
   countries/{COUNTRY}/outputs/extract/{COUNTRY}_*_EXTRACT_whole.json
   Report the count, then one line per file: document_id, document_year,
   document_type, row count.
   Cross-check against the manifest: a document marked extracted with no
   EXTRACT_whole.json is a STOP, not a silent gap.
2. Validate on load. Any failure → stop and name the file:
   - identical v0.5 schema across all files
   - instrument_id, pair_id null everywhere
   - (document_id, evidence_id) unique across the whole corpus
3. Make evidence_id globally unique BEFORE reconciling.
   Rewrite every evidence_id to {document_id}::{evidence_id}.
   evidence_ids restart at 1 in each file; without this, R4(e), R5 and R8
   suffixing collide silently. Keep the original in a new column
   evidence_id_source. Nothing else is edited.
4. Union all rows into one in-memory evidence table, changing no other field.
   Assert count(stacked) = Σ rows per file. Report the number. Every later
   count reconciles back to it.
5. Run reconciliation_prompt.md ONCE over the stacked table — not per file.
   The corpus is now all documents together: R2 identity, R3 pair keys,
   R5 duplicate sources and R6 repeals all match ACROSS documents. That is
   the point of this pass; an anglophone earmark has its source levy in one
   Act and its assignment clause in another.
B. STACK-LEVEL CONVENTIONS (declare each in rules_applied)
1. Document precedence — extends R4/R5, applied before the earliest-id
   tie-break, never before a substantive criterion:
     (i)  principal Act beats amending or subsidiary Act
     (ii) then higher document_year
     (iii) then earliest evidence_id (now arbitrary; mark provisional)
   Read (i) from document_type in the manifest, not from the name.
2. R6 across documents. A later Act naming and replacing a levy instituted
   in an earlier Act in this corpus closes that instrument. Record the
   repealing document_id and article in the decision. Predecessor named but
   absent from the corpus → lineage signal only, remove nothing.
3. intra_document_conflict is computed over the STACKED corpus, so a
   conflict may now be cross-document. Do not rename the column. State the
   scope change in reconciliation_summary and, for every flagged instrument,
   record whether the conflict is within one document or across documents.
4. Output naming. {DOC} = ALL.
   File: countries/{COUNTRY}/outputs/reconcile/{COUNTRY}_ALL_RECONCILED.json
   In reconciliation_summary set document_id = "ALL" and add
   source_documents = [document_id, ...] and rows_in_by_document.
C. OUTPUT
Two top-level keys exactly as reconciliation_prompt.md specifies.
Run the output checks in reconciliation_rules.md and state that they hold,
plus: count(evidence_table) + count(rows_removed) = count(stacked).
Then report inline: files read, rows stacked, headline counts, the
beneficiary_type × share_level breakdown, instruments whose source and
allocation rows came from DIFFERENT documents (count them — it is the
anglophone-specific finding), decisions and what each turned on, the
conflict-flag breakdown, and anything unsettled.