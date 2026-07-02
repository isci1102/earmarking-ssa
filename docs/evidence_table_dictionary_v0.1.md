# Evidence Table — Data Dictionary (v0.1, provisional)

> **Status.** Working draft, to be revised on contact with real clauses. Version bumps (v0.2, …) when a column is added/dropped/retyped. This is the schema for the **only hand-authored layer** of the CIV earmark database.

---

## 1. What the table is

The evidence table is the single source of truth from which everything else is derived (the instrument entity, the budget-amounts join, the panel). Its **defining invariant**: *every row carries a verbatim excerpt and a page anchor.* No row exists without a quotable clause to audit it against. Amounts (budgeted envelopes) are **not** here — they come from a table cell, not a clause, and live in the separate budget-amounts table.

## 2. Grain — what one row is

**One row = one (clause × the single fact it establishes).**

A single sentence can produce several rows. The telecom clause assigning five shares → one `source` row (the tax exists) + five `allocation` rows (one per destination-share), all sharing `document_id`, `legal_article`, `official_name`, `verbatim_excerpt`, differing only in the fact isolated. This decomposition makes each destination-share independently sourced and auditable, and supplies the natural keys reconciliation groups on.

## 3. Identity handling — id-free extraction

Extraction assigns **no synthetic ids**. `instrument_id` / `pair_id` are blank at extraction and assigned later in a single reconciliation pass over the *complete* country evidence set (all mentions visible before any identity call). During extraction, identity is carried by the **natural keys** — `document_id`, `legal_article`, `official_name` (verbatim), `verbatim_excerpt` — which are therefore mandatory (non-null). Id-free ≠ context-free.

`row_type ∈ {source, allocation}` only.

---

## 4. Variable dictionary

| # | Variable | Type | Null? | Applies to | Description / decision-rule note |
|---|----------|------|-------|------------|----------------------------------|
| 1 | `evidence_id` | string PK | no | all | Sequential row id (`CIV_EV_0001`). No semantics. |
| 2 | `row_type` | enum | no | all | `{source, allocation}`. `source` = clause establishing the tax exists/is levied. `allocation` = clause establishing a destination (± share). |
| 3 | `country` | ISO3 | no | all | `CIV`. Kept for eventual multi-country stacking. |
| 4 | `instrument_id` | string FK | yes (pre-recon) | all | Synthetic parent key; assigned in reconciliation. Blank at extraction. |
| 5 | `pair_id` | string FK | yes | allocation | Synthetic child key `(instrument × destination)`. Null on `source`; assigned in reconciliation. |
| 6 | `document_id` | string | **no** | all | Natural key. Stable per file (`AF2025`, `LF2026`, `CGI2026`). |
| 7 | `document_type` | enum | no | all | `{annexe_fiscale, loi_finances_initiale, cgi}`. (rectificative excluded per coverage map.) |
| 8 | `document_year` | int (stored text) | no | all | Year of the **document**, not the earmark. The ONLY temporal field here; all earmark-dating is computed downstream in the panel. |
| 9 | `legal_article` | string | yes | all | Natural key. `Article 22`, `Art. 1137 bis`. Null only if no article (rare; note it). |
| 10 | `page_start` | int | **no** | all | Page anchor. Non-negotiable. |
| 11 | `page_end` | int | **no** | all | `= page_start` if single page. |
| 12 | `official_name` | string (verbatim) | **no** | all | Natural key. Name **as written in source**, verbatim. Cross-doc variants are reconciliation input, not errors. |
| 13 | `tax_instrument` | enum | yes | source (primary) | `{VAT, excise, fuel_levy, telecom_levy, environmental_tax, payroll_tax, resource_revenue, redevance, parafiscal_contribution, fine, other}`. Null if clause names a destination but not the instrument type. |
| 14 | `tax_base_detail` | string | yes | source | Verbatim/near-verbatim base ("5% du chiffre d'affaires HT"). Null if not stated. |
| 15 | `rate_value` | numeric | yes | source | Rate magnitude. Null if not in this clause. |
| 16 | `rate_type` | enum | yes | source | `{ad_valorem_pct, per_unit_fcfa, fixed_fcfa}`. Pairs with `rate_value`; prevents coercing a specific tax into a percentage. |
| 17 | `destination` | string (verbatim) | yes | allocation | Assigned recipient, verbatim (`Fonds d'Appui à la Jeunesse`). Null on `source`. |
| 18 | `beneficiary_type` | enum | yes | allocation | `{fund, agency, ministry, collectivite_territoriale, sector, program, supranational, general_budget}`. `general_budget` marks the non-earmarked residual (kept so shares sum to 100%; excluded from earmark analysis). |
| 19 | `share_value` | numeric | yes | allocation | Share magnitude. **Null when a destination is named but no share stated** (e.g. quote-part deferred to arrêté). |
| 20 | `share_type` | enum | yes | allocation | `{pct, per_unit_fcfa, fixed_fcfa}`. Pairs with `share_value`. |
| 21 | `mechanism` | enum | yes | all | `{legal_statutory, budgetary, fund_based, formula_based, informal}`. **Provisional at this grain** — may be a property of the instrument entity, not the clause; watch whether real clauses populate it row-by-row, else move downstream. |
| 22 | `change_type` | enum | yes | all | `{new, amendment_rate, amendment_base, amendment_key, merger, split, replacement, repeal, none}`. What the clause does relative to prior law, **as the text asserts**. Provisional at extraction; finalized in reconciliation. |
| 23 | `structural_break` | bool | yes | all | 1 if base redefinition / merger / split / replacement (see decision rules). Provisional at extraction; finalized in reconciliation. |
| 24 | `predecessor_ref` | string | yes | all | Free-text reference to prior instrument(s) the clause cites as merged/split/replaced (`loi 2013-908`). Resolved to `predecessor_id` in reconciliation. |
| 25 | `change_from_previous` | string | yes | all | Short description of the break; populated iff `structural_break = 1`. |
| 26 | `enabling_reference` | string | yes | all | Founding/citing legal text referenced (`décret 12 juin 2024 (FNDS)`, `ord. 61-183`). CGI is the main source. |
| 27 | `verbatim_excerpt` | string | **no** | all | Exact clause text. **Load-bearing field.** For `allocation` rows must literally contain assignment language (`au profit de`, `réparti`, `affecté`…). |
| 28 | `ai_confidence` | enum | no | all | `{high, medium, low}`. `medium` is correct when e.g. the destination fund is not named in-source (no-invention). |
| 29 | `human_validation_status` | enum | no | all | `{unchecked, validated, corrected, rejected}`. Default `unchecked`. |
| 30 | `notes` | string | yes | all | Adjudication flags, cross-doc links to verify, stated ambiguities. Uncertainty is recorded, never silently resolved. |

---

## 5. Provisional-field watchlist (revisit after first annexe)

- **`mechanism` (21):** likely instrument-level, not clause-level. If real clauses don't support row-by-row population, move to the derived instrument entity.
- **`change_type` / `structural_break` / `change_from_previous` (22–25):** correctly populatable only when the *prior* state is visible, which id-free extraction often lacks at row-creation. Set provisionally at extraction, mark `human_validation_status = unchecked`, finalize in reconciliation once an instrument's full time-series is assembled.

## 6. Hard-rule reminders (from decision rules & assumptions register)

- **No invention.** Destination not named in-source → `destination` null, `ai_confidence = medium`. Never write a plausible-but-unstated fund (the FNLS/tobacco trap).
- **Null over coercion.** Share deferred to arrêté → `share_value` null. Fixed-amount tax/share → use `*_type = per_unit_fcfa`/`fixed_fcfa`, never fake a percentage.
- **`general_budget` rows** are recorded (100%-sum check) but excluded from earmark analysis.
- **`document_year` ≠ earmark year.** All four earmark-temporal concepts (established/modified/repealed/evidence_status) are derived in the panel, never stored here.
- **Fund-agnostic retrieval.** Candidate detection anchors on assignment grammar + section structure, never a known-fund allow-list (preserves discovery).

---

## 7. First-session test

Populate this schema end-to-end for one clean annexe (2024 or 2025). Deliverables: (1) the rows; (2) a **schema-stress list** — every clause that didn't fit a column, forced an unanticipated null, or needed a judgment the decision rules don't cover. Then score the rows against the AF-anchored gold-standard cases (recall + any invented fields). If a real clause won't fit, revise to v0.2 *before* scaling to the rest of the batch.
