# Evidence Table — Data Dictionary (v0.5 — FREEZE CANDIDATE)

> **Status.** v0.5 revised after the AF2026 production run. Changes from v0.1 **[v0.2]**; v0.2 **[v0.3]**; v0.3 **[v0.4]**; v0.4 **[v0.5]**. **This is the intended freeze version:** after AF2024/AF2025/AF2026, the schema has handled flat keys, banded rates and shares, cross-references, collector-shares, cost-recovery splits, and (now) nested keys — the full structural vocabulary observed across three documents. No further structural additions before reconciliation unless a genuinely new pattern forces one.
>
> **[v0.5] change (one, structural): nested/multi-level allocation keys.** AF2026 Art. 40 surfaced a two-level split — the droit de trafic goes 90% to a DGAM pool, and *that 90% pool* is then split 80/9/1/4/3/3. A flat `share_value` cannot say whether "80%" is 80% of the gross instrument or 80% of a sub-pool; leaving the distinction in `notes` is lossy (un-machine-readable, forces a source re-read at reconciliation). v0.5 adds `share_level` (24a) and `share_pool` (24b) — a **self-contained descriptor**, NOT a row-pointer, so extraction stays id-free (a pointer would force premature id assignment). Reconciliation resolves `share_pool` (verbatim parent-pool name) to the parent row by natural-key matching, exactly as it resolves instrument identity. Flat documents (AF2024, AF2025) are all `share_level = 1`, `share_pool = null` — backfillable without re-extraction.
>
> **[v0.4] changes (two, both driven by recurring cross-document/cross-country patterns — hence fixed before production freeze):** (1) added `cross_reference` to the `rate_basis` domain — for a rate set by statutory renvoi to another instrument's schedule (AF2024 Art. 15 publicité mobile; recurs heavily in Ghana/Kenya where renvoi is common), previously mis-bucketed as `deferred_arrete`. (2) extended the §11 cost-recovery rule with the **collector-share sub-rule** (decision rules §11): a collecting body's *retained* share is `cost_recovery_component` only when it funds the *administration of that specific levy*, and `proceeds_share` when it funds the collector's *substantive mandate* (e.g. CIAPOL's 20% of the environmental levy funds pollution-control activity, not the cost of collecting the levy → `proceeds_share`). Governs a recurring pattern (collector-that-is-also-beneficiary: revenue authorities, sector regulators, marketing boards). Both additions are low-risk and spot-checked on the first production document (the CGI, where both appear immediately) rather than via a dedicated confirmation run.

---

## 1. What the table is

The evidence table is the single hand-authored source of truth from which everything else derives (instrument entity, budget-amounts join, panel). **Invariant:** every row carries a verbatim excerpt and a page anchor. Amounts (budgeted envelopes) are NOT here — they live in the separate budget-amounts table (provenance is a table cell, not a clause).

## 2. Grain

**One row = one (clause × the single fact it establishes).** A multi-destination clause → one `source` row + one `allocation` row per destination-share (decomposed, independently sourced). `row_type ∈ {source, allocation}`.

## 3. Identity handling — id-free extraction

No synthetic ids at extraction. `instrument_id`/`pair_id` blank; assigned in a later reconciliation pass over the complete country evidence set. Identity is carried by the **natural keys** (`document_id`, `legal_article`, `official_name` verbatim, `verbatim_excerpt`), which are mandatory.

---

## 4. Variable dictionary

| # | Variable | Type | Null? | Applies to | Note |
|---|----------|------|-------|------------|------|
| 1 | `evidence_id` | string PK | no | all | Sequential, country-prefixed (e.g. `CIV_EV_0001`). |
| 2 | `row_type` | enum | no | all | `{source, allocation}`. |
| 3 | `country` | ISO3 | no | all | ISO3 country code (e.g. `CIV`). |
| 4 | `instrument_id` | string FK | yes (pre-recon) | all | Assigned in reconciliation. Blank at extraction. |
| 5 | `pair_id` | string FK | yes | allocation | Null on `source`; assigned in reconciliation. |
| 6 | `document_id` | string | **no** | all | Natural key (e.g. `AF2025`, `CGI2026`). |
| 7 | `document_type` | enum | no | all | `{annexe_fiscale, loi_finances_initiale, cgi}` — Francophone-UEMOA values (CIV/Chad). Extend additively per jurisdiction (CORE C10), e.g. Anglophone corpora add finance-act / establishing-act values when those documents are actually extracted; do not add speculatively. |
| 8 | `document_year` | int (text) | no | all | Year of the **document**, not the earmark. Only temporal field here. |
| 9 | `legal_article` | string | yes | all | Natural key. |
| 10 | `page_start` | int | **no** | all | Page anchor. |
| 11 | `page_end` | int | **no** | all | Page anchor. |
| 12 | `official_name` | string (verbatim) | **no** | all | Natural key. Verbatim, cross-doc variants expected. |
| 13 | `tax_instrument` | enum | yes | source | `{VAT, excise, fuel_levy, telecom_levy, environmental_tax, payroll_tax, resource_revenue, redevance, parafiscal_contribution, fine, other}`. |
| 14 | `tax_base_detail` | string | yes | source | Verbatim/near-verbatim base. |
| 15 | `rate_value` | numeric | yes | source | **[v0.2] Strictly scalar.** Null when the rate is banded/scheduled (see 15a–15b). Never holds text. |
| 15a | `rate_is_schedule` | bool | yes | source | **[v0.2 NEW]** 1 if the rate is banded/scheduled (by price, substance, star-rating, population band, etc.). Explains why `rate_value` is null. |
| 15b | `rate_schedule_detail` | string | yes | source | **[v0.2 NEW]** Full verbatim schedule when `rate_is_schedule = 1`. Parsed into a child table later in R; kept out of `rate_value` to preserve its numeric type. |
| 16 | `rate_type` | enum | yes | source | `{ad_valorem_pct, per_unit_amount, fixed_amount}`. For `per_unit_amount`/`fixed_amount`, the amount is recorded as written; its currency is not stored in the type (it is always present in `verbatim_excerpt`). A dedicated `currency` column may be added later if analysis requires it; do not convert or normalize amounts at extraction. |
| 16a | `rate_basis` | enum | yes | source | **[v0.3, domain extended v0.4]** `{stated, banded, deferred_arrete, cross_reference, not_applicable}`. Symmetric to `share_basis` (20a). Disambiguates why `rate_value` is null: `stated` (scalar present); `banded` (schedule — pairs with `rate_is_schedule = 1` and `rate_schedule_detail`); `deferred_arrete` (rate exists in law but value is set by a future subsidiary legal instrument — an *arrêté* in Francophone civil-law systems, a statutory instrument/regulation elsewhere; the value name is historical and generalizes, cf. CORE C10; illustration — CIV AF2024 Art. 6); **`cross_reference`** [v0.4] (rate fixed by statutory cross-reference — *renvoi* in civil-law drafting — to another instrument's existing schedule; value lives in a cited instrument, neither stated in-clause nor deferred to a future act; illustration — CIV AF2024 Art. 15 publicité mobile "dans les mêmes conditions que la taxe … au niveau du District"); `not_applicable` (no rate concept). |
| 17 | `destination` | string (verbatim) | yes | allocation | Recipient, verbatim. Null on `source`. |
| 18 | `beneficiary_type` | enum | yes | allocation | `{fund, agency, ministry, collectivite_territoriale, sector, program, supranational, general_budget}`. `program` covers functional-purpose destinations (a named activity/purpose, not a proper-noun body). `general_budget` = non-earmarked residual (kept for 100% check, excluded from earmark analysis). |
| 18a | `allocation_nature` | enum | yes | allocation | **[v0.3 NEW]** `{proceeds_share, cost_recovery_component}`. Distinguishes a genuine division of *collected proceeds* to a recipient (`proceeds_share` — a real earmark candidate, e.g. Art. 18 env. tax → FNE 50%) from a *component of the price of a service the payer is consuming* (`cost_recovery_component` — NOT an earmark, e.g. Art. 12 registration duty split to the processing office / registration officers). Benefit-principle test: does the share fund the *service the payer is transacting for* (cost-recovery) or something the payer is *not a party to* (earmark)? `cost_recovery_component` rows are recorded for completeness, excluded from the earmark subset, and **never enter the allocation-share panel** (so a re-priced service fee cannot masquerade as an earmark-reform event). Soft boundary case (log with excerpt): general administrative cost-recovery not tied to the specific taxed transaction — resolve toward `cost_recovery_component`. |
| 19 | `share_value` | numeric | yes | allocation | Scalar. Null when destination named but no share stated. |
| 19a | `share_is_schedule` | bool | yes | allocation | **[v0.2 NEW]** 1 if the share/quotité is banded (e.g. 15–25% by population band). Explains null `share_value`. |
| 19b | `share_schedule_detail` | string | yes | allocation | **[v0.2 NEW]** Full verbatim schedule when `share_is_schedule = 1`. |
| 20 | `share_type` | enum | yes | allocation | `{pct, per_unit_amount, fixed_amount}`. Same currency convention as `rate_type` (16): amount as written, currency in `verbatim_excerpt`, no normalization at extraction. |
| 20a | `share_basis` | enum | yes | allocation | **[v0.2 NEW]** `{stated, whole_proceeds_implied, deferred_arrete}`. Disambiguates: an explicit % (`stated`); a "paid/reversed in full to X" clause implying 100% with no number (`whole_proceeds_implied`; French cue "reversé à X", equivalents in other systems); a share deferred to a future subsidiary instrument — an *arrêté* in Francophone systems (`deferred_arrete`; value name historical, generalizes per CORE C10). Resolves the "both null" collapse of v0.1. |
| 20b | `share_level` | int | yes | allocation | **[v0.5 NEW]** Depth of the share in a multi-level allocation key. `1` = a share of the gross instrument proceeds (the default; set 1 on every row of a flat key). `2` = a share of a named sub-pool (a level-1 destination that is itself re-split). `3+` if deeper. A `share_level = 2` row's `share_value` is a fraction of its `share_pool`, NOT of the gross instrument — so the 100%-sum check applies *within* a level and pool, never across levels. |
| 20c | `share_pool` | string (verbatim) | yes | allocation | **[v0.5 NEW]** For `share_level ≥ 2`, the verbatim name of the parent pool this share is a fraction of (illustration — CIV: "part de la Côte d'Ivoire (90 % du droit de trafic, part DGAM)"). Null for `share_level = 1`. This is a **self-contained descriptor, not a row-pointer** — extraction stays id-free; reconciliation matches `share_pool` to the level-1 parent row by natural key (the same mechanism used for instrument identity). Never assign a synthetic id here at extraction. |
| 21 | `is_purpose_restricted` | bool | yes | allocation | **[v0.2 — scope gate, extract-broad rule]** 1 if the destination is a specific/purpose-restricted use (in the earmark subset); 0 if a general-purpose recipient / unrestricted devolution to a tier's general budget. **Both values are EXTRACTED AND RECORDED — a `0` row is NOT dropped.** The scope filter is applied in *analysis*, not extraction: every revenue assignment to a specific named recipient (fund, organism, tier, programme) enters the table; `is_purpose_restricted` marks whether it belongs to the earmark subset. Criterion: purpose-restriction of *use*, not recipient identity. Illustration — CIV: a property tax (impôt foncier) → Communes' *general budget* is recorded with `is_purpose_restricted = 0`; the same tax → a Communes' *earmarked road fund* is recorded with `is_purpose_restricted = 1`. Only pure general-State-budget residual shares (the 90% in a 90/10 key) use `beneficiary_type = general_budget` and are the non-earmarked accounting residual. |
| 22 | `assignment_type` | enum | yes | allocation | **[v0.2]** Sub-classification of the recipient relationship: `{earmark_functional, hybrid_devolved_earmark, equalization_transfer, community_levy_external, tax_sharing_specific, tax_sharing_general}`. Recorded for ALL specific-recipient rows (both `is_purpose_restricted` values); `tax_sharing_general` pairs with `is_purpose_restricted = 0`. Enables later analytical filtering of the earmark subset vs. the broader specific-assignment population. **OPEN ITEM for manager meeting** — the exact analytical boundary (which tax-sharing categories count as earmark-adjacent) is to be ratified; the *data* records everything so the boundary is a downstream filter, not an extraction-time exclusion. |
| 23 | `mechanism` | — | — | — | **[v0.2] MOVED to the derived instrument entity.** Confirmed instrument-level, not clause-level (zero clause-level variance in the validating document — illustration — CIV AF2025, all `legal_statutory`). Not populated at extraction. |
| 24 | `change_type` | enum | yes | all | `{new, amendment_rate, amendment_base, amendment_key, merger, split, replacement, repeal, none}`. Provisional at extraction; finalized in reconciliation. |
| 25 | `structural_break` | bool | yes | all | 1 for base redefinition / merger / split / replacement. Provisional; finalized in reconciliation. |
| 26 | `partial_key` | bool | yes | allocation | **[v0.2 NEW]** 1 if the clause restates only amended tiers of a larger allocation key (remainder in another source document, e.g. a consolidated tax code such as the CIV CGI). Tells reconciliation to pull the full split before enforcing the 100% check. |
| 27 | `predecessor_ref` | string | yes | all | Free-text reference to a prior instrument/article the clause names (`art. 1133`, `loi 2013-908`). Populated **only when the text itself cites a prior instrument**; null otherwise (never guessed). Resolved to `predecessor_id` in reconciliation. |
| 27a | `predecessor_relation` | enum | yes | all | **[v0.2 NEW]** What the text says the relationship IS: `{amends, replaces, merges, splits, none}`. A *recorded textual signal*, not a judgment — distinguishes continuity-amendment ("l'article X est modifié" → same instrument, a rate/base change) from discontinuity ("la taxe X est supprimée et remplacée par…" → new instrument + predecessor link). Captured at extraction so reconciliation need not re-read the source to tell amendment from replacement. `amends` pairs with `change_type = amendment_*` and does NOT create a predecessor_id; `replaces`/`merges`/`splits` are true lineage. |
| 28 | `change_from_previous` | string | yes | all | Short description of the break; populated iff `structural_break = 1`. |
| 29 | `enabling_reference` | string | yes | all | Founding/citing legal text referenced. |
| 30 | `verbatim_excerpt` | string | **no** | all | Exact clause text. **Load-bearing.** For `allocation` rows must contain the assignment language. |
| 31 | `source_internal_inconsistency` | string | yes | all | **[v0.2 NEW]** Records a drafting inconsistency in the source itself (illustration — CIV AF2025 Art 41: heading says "1137 bis"/"1137 quater" while the enacting text creates "1137 ter"). Preserves the anomaly without contaminating other fields. |
| 32 | `ai_confidence` | enum | no | all | `{high, medium, low}`. |
| 33 | `human_validation_status` | enum | no | all | `{unchecked, validated, corrected, rejected}`. Default `unchecked`. |
| 34 | `notes` | string | yes | all | Flags, cross-doc links, stated ambiguities. |

---

## 5. The tax-sharing / revenue-splitting matrix (v0.2 handling)

Multi-tax × multi-beneficiary tables — a *rétrocession* matrix in Francophone budget drafting (illustration — CIV AF2025 Art 27) — are recorded as ordinary `allocation` rows — one row per (tax × named beneficiary) cell — **gated by `is_purpose_restricted`**:
- Cell → a purpose-restricted destination (a named fund or organism with a restricted mandate; illustration — CIV: FER, an assainissement fund) → `is_purpose_restricted = 1`, sub-classified in `assignment_type`. **In scope.**
- Cell → a tier's general budget (a sub-national government or the central State, unrestricted; illustration — CIV: Communes, Régions, État) → `is_purpose_restricted = 0`, `assignment_type = tax_sharing_general`. **Recorded, out of scope**, retained for manager review.
This keeps everything in one table (no separate matrix table for now) while the scope gate carries the earmark-vs-devolution distinction. Do not hand-expand the residual general-budget cells beyond what is needed to document the matrix; the 100% check is relaxed for matrix rows (flag in `notes`).

## 6. Provisional-field watchlist 

- `change_type` / `structural_break` — finalized only in reconciliation (prior state not visible at id-free extraction). Mark `unchecked`.
- Banded `share`/`rate` child-table extraction is deferred (parse the `*_schedule_detail` fields); extraction only sets the flag + detail text.

## 7. Hard-rule reminders

- **No invention.** Destination not named in the *enacting* text → null, medium (even if the motivational/explanatory text names an intended beneficiary — the *exposé des motifs* in Francophone drafting, the memorandum/preamble in other systems; illustration — CIV AF2025 Art 35 ANAGED, Art 1 CNRA exemption). That text is motivation, not assignment.
- **Null over coercion.** Deferred/ banded → null + flag, never a fabricated scalar and never text in a numeric column.
- **`document_year` ≠ earmark year.** All earmark-temporal concepts derived in the panel.
- **Fund-agnostic retrieval.** Anchor on assignment grammar + section structure, never a known-fund list.
