# Reconciliation Prompt

Paste with `reconciliation_rules.md` and the country's `{COUNTRY}_{DOC}_EXTRACT_whole.json` attached.

---

Reconcile the attached id-free extraction into a counted snapshot. Apply the rules in `reconciliation_rules.md` — R1 to R9 and the conventions — without modification or country-specific adaptation.

**Apply R1 pool/container classification conservatively.** A name is a pool only when it enumerates or aggregates several levies that are themselves identifiable. If in doubt, classify it as an instrument and say so — over-classifying pools silently removes levies from the count.

**Read the flags before deciding anything.** The extraction has already marked most contradictions, repeals and boundary cases. `notes`, `source_internal_inconsistency`, `predecessor_ref`, `predecessor_relation`, `share_pool` and `ai_confidence` are the evidence for the rulings; use them rather than re-reading the law from the excerpts.

**Decide, don't ask.** Where the rules leave a case open, settle it on the standing conventions — consolidation, renvoi precedence, norm hierarchy, general-rule-vs-special-regime — apply the decision, and report it with its basis. Do not return an unanswered question and do not ask for external verification of anything settleable from the document. Where two rows genuinely disagree and no rule separates them, keep one, mark it provisional, and say so.

**Output one JSON file**, `{COUNTRY}_{DOC}_RECONCILED.json`, with exactly two top-level keys.

`evidence_table` — array of row objects. The v0.5 schema in dictionary order, unchanged, with:
- `instrument_id` assigned on every row;
- `pair_id` assigned on allocation rows only (null on source rows, per dictionary col. 5);
- `pair_row_role` — `governing` / `restatement`, empty on source rows and single-row channels;
- `base_scope` — the sub-scope qualifier stripped at R1 absorption (segment, branch, territorial or payer-class variant), empty on parent rows; it is part of the pair key;
- `intra_document_conflict` appended last.

**Retain every row.** Duplicate statements of one channel share a `pair_id` and are marked by `pair_row_role`; they are not deleted. Only R5 duplicate source rows and R6 repealed rows leave the table.

Nothing else is altered. `is_purpose_restricted`, `assignment_type`, `allocation_nature` and `beneficiary_type` pass through exactly as extracted.

`reconciliation_summary` — object with:
- `country`, `document_id`, `schema`
- `counts` — rows before/after with the source and allocation split; rows removed; revenue instruments, countable instruments, pool/containers; instruments with source+allocation, allocation-only, source-only; allocation channels, channels to a general budget, earmarked channels; `composition_by_tax_instrument`; `earmarked_by_beneficiary_type_x_share_level`; `subsets_inside_earmarked` (cost_recovery_component, collectivite_territoriale, collectivite_territoriale_unrestricted, equalization_transfer); `instruments_by_conflict_flag`
- `rules_applied` — the rules as applied in this run
- `rows_removed` — `{evidence_id, row_type, official_name, legal_article, reason, kept_instead, belongs_to}`
- `decisions` — `{decision, instrument, rule, detail, evidence_ids}` for every merge, absorption, pool exclusion and repeal
- `duplicate_channels` — `{pair_id, instrument, recipient, share_level, n_rows, governing_evidence_id, restatement_evidence_ids, rule, values_by_row, status}`
- `duplicate_sources` — `{instrument_id, instrument, n_source_rows, kept, removed, articles}`
- `instruments_flagged` — `{instrument_id, instrument, flag, detail}` for every instrument with `intra_document_conflict ≠ none`

**Before reporting, verify the output checks in the rules file** — the conflict-flag totals must agree between `counts` and `instruments_flagged`, and allocation rows minus channels must equal the restatement count. State that they hold.

**Then report inline, in the reply, not in the file:** the headline counts, the `beneficiary_type × share_level` breakdown, the decisions made and what each turned on, the conflict-flag breakdown by value, and anything the rules could not settle. Keep it short enough to read in one pass.
