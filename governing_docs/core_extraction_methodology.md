# CORE Extraction Methodology (FROZEN — document-agnostic, country-agnostic)

> **What this is.** The invariant core of the earmark-extraction method: the definitions, decision rules, grain, schema, and audit requirements that are IDENTICAL for every document and every country. This is the reproducible method — the thing cited in the paper's methodology section. It is applied to every document unchanged; only the *retrieval adapter* (a separate, thin, parameterized layer) varies. Reproducibility lives HERE, not in the retrieval prompt.
>
> **Layering.** Every extraction run = this CORE + one RETRIEVAL ADAPTER instantiated with the document's structural parameters. Never duplicate the core into a per-document prompt (duplication drifts → breaks reproducibility). Refine the core in ONE place; all runs inherit it.

---

## C1. Operative test (binding)
An earmark requires BOTH (a) a source levy/tax/charge/contribution of any kind (including civil-law forms such as redevance, prélèvement, parafiscal charge) AND (b) a verbatim clause assigning its proceeds — in whole or in part — to a specific named recipient. A fund merely existing is not sufficient. The ENACTING text governs; motivational/explanatory text (exposé des motifs, preamble, memorandum) is motivation, not assignment — never infer an unnamed destination.

## C2. Scope — extract-broad, filter-later
Record EVERY assignment to a specific named recipient (fund, organism, ministry, tier of government, sector, programme, supranational body), marking `is_purpose_restricted` (1 = earmark subset; 0 = general-purpose recipient, e.g. a tier's general budget — still recorded, filtered at analysis). Only the pure general-State-budget residual uses `beneficiary_type = general_budget`. The earmark-vs-not decision is a recorded FIELD applied at analysis, never an extraction-time exclusion.

## C3. Cost-recovery / user-charge vs earmark
§11: a split pricing the service the payer is consuming (administrative cost-recovery, processing-officer remuneration) is `allocation_nature = cost_recovery_component`, not an earmark. §11.1: a collecting body's retained share is `cost_recovery_component` only if it funds administering that specific levy, else `proceeds_share`. Benefit-principle test: does the share fund the service the payer is transacting for (cost-recovery) or something the payer is not a party to (earmark)?

## C4. Unit of analysis — the INSTRUMENT, not the container
Legal drafting bundles several unrelated taxes under one article/section (one provision creating a general-budget tax AND an earmarked tax). Decompose each container to its distinct instruments; classify per instrument, never per container. (Language-agnostic: applies to French articles, Anglophone sections, budget-law line items alike.)

## C5. Grain & row types
One row = one (clause × the single fact it establishes). Source and allocation are distinct row types — independently-attested halves of the pipe: a source may have no stated destination; a destination clause may sit apart from its source (even in another document). Record each as it appears; reconciliation joins them. Multi-destination clause → one source row + one allocation row per destination-share.

## C6. Id-free extraction
No synthetic ids at extraction. `instrument_id`/`pair_id` blank; assigned in a later reconciliation pass over the complete evidence set. Identity is carried by the NATURAL KEYS (document_id, legal reference, official_name verbatim, verbatim_excerpt, page) — mandatory on every row. Lineage signals (`predecessor_ref`, `predecessor_relation`) captured ONLY from what the text states; no cross-document judgment at extraction (§9). `change_type`/`structural_break` provisional; `human_validation_status = unchecked`.

## C7. Schema (v0.5) — apply in full
Every row uses the v0.5 evidence dictionary. Key mechanics: rate/share as value + type + basis (never a bare %, never text in a numeric field); banded → scalar null + `*_is_schedule` + `*_schedule_detail`; deferred → scalar null + `*_basis = deferred_arrete`; cross-reference rate → `rate_basis = cross_reference`; nested keys → `share_level` + `share_pool` (self-contained descriptor, not a row-pointer); `allocation_nature`; `is_purpose_restricted`; `assignment_type`; `source_internal_inconsistency` for self-inconsistent text. (Enum *values* may need jurisdiction extension — see C10 — but the *structure* is invariant.)

## C8. No-invention & null discipline
Destination not named in the enacting clause → destination null, `ai_confidence = medium`, never a plausible-but-unstated fund. Deferred/banded value → scalar null + the appropriate flag, never fabricated. `general_budget` residual rows recorded for the 100%-sum check, excluded from earmark analysis. Uncertainty is RECORDED in notes, never silently resolved.

## C9. Mandatory audits (the reproducibility guarantee)
Completeness is VERIFIED, not promised. Every run must produce:
- **Coverage report** — the document's own divisions (articles/sections/livres) enumerated as a checklist, each accounted for (produced row(s) OR "checked — no earmark clause"). Total = enumerated count. Proves the whole document was read end to end. (This is how "no attention loss over a long document" is *verified* — the architecture prevents it via sectioning C-adapter; the coverage report proves it.)
- **Recall audit** — every assignment-grammar hit from the sweep either captured as a row or dismissed with a one-line reason. No hit unaccounted.
- **Field-exercise note** — which fields fired; flag every judgment-sensitive call (`allocation_nature`/§11.1, cross_reference/banded, `is_purpose_restricted = 0`, `share_level = 2`) for human sign-off.
- **Schema-stress note** — only genuinely NEW gaps; a real one means STOP and revise the schema before continuing the corpus (keeps the corpus homogeneous).
- **Confidence reasons** — per non-high-confidence row, typed as document problem vs schema problem.
- **Gold scoring** — against any gold cases anchored in this document.

## C10. Cross-jurisdiction invariance & extension points
The core is country-agnostic. When extending beyond Francophone-UEMOA:
- **Invariant:** C1–C9 hold unchanged (the operative test, grain, id-free architecture, audits are universal).
- **Extension points (additive, never rewrite):** (a) `assignment_type` enum may gain values for non-UEMOA structures; (b) `rate_basis = deferred_arrete` generalizes to "deferred to a subsidiary instrument" (arrêté/statutory-instrument/regulation) — the concept is invariant, the instrument name varies; (c) the retrieval grammar (French assignment terms) is NOT in the core — it lives in the adapter and is swapped per language.
Record any enum extension in the assumptions register with the country/document that forced it.
