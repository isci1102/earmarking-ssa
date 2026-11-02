# INSTRUMENT × DESTINATION TABLE — SPEC (v1.2)

**Built by** `build_instrument_destination.py`, deterministically. No LLM step.

**Inputs per country:**
- `{ISO3}_EARMARK_ALLOCATIONS.json` (allocation prompt v1.2 or later)
- `{ISO3}_INSTRUMENTS.json` (instrument prompt v1.0)
- `benefit_link_concordance.csv` (signed off by the researcher)
- optional `benefit_link_overrides.csv`

**Output:** `{COUNTRY_FOLDER}/outputs/derived/{ISO3}_INSTRUMENT_DESTINATION.csv`. Optionally, one stacked file for all countries.

```
python build_instrument_destination.py "countries/*" \
       --concordance benefit_link_concordance.csv \
       [--overrides benefit_link_overrides.csv] [--stacked ALL_INSTRUMENT_DESTINATION.csv]
```

## 1. Grain and identities

One row = one **instrument_id × allocation_id**. The join runs through `allocation_group_id`: each instrument's `allocation_group_ids` is exploded and matched to every allocation in each group.

| identity | value |
|---|---|
| rows | $\sum_g n_I(g)\cdot n_A(g)$ — equals the number of allocations only when no group is a pool |
| unique `instrument_id` | earmark-relevant instruments in the country |
| unique `allocation_id` | allocations in the country |

If any of these fail, that country is skipped and reported in the build report (the other countries are still built):
- a group has no instrument, or an instrument points to an unknown group;
- the row count differs from the identity;
- an (instrument, allocation) key is duplicated;
- an allocation or instrument is lost in the join.

**Pools.** A pool's share is applied **pro rata to each member**: 1% of "customs revenue" is read as 1% of each customs duty. This is an assumption, stated in the paper.

## 2. Columns

Carried from the two tables:
- **Keys:** `country`, `instrument_id`, `allocation_id`, `allocation_group_id`.
- **From the instrument table:** `official_name`, `row_kind`, `instrument_type`, `gfs_code`, `base_category`, `base_isic_division`, `charging_provision_in_corpus`.
- **Group size:** `is_pool`, `n_instruments_in_group`.
- **From the allocation table:** `destination_name`, `recipient_form`, `recipient_level`, `cofog_division`, `cofog_group`, `cofog_basis`, `is_purpose_restricted`, `allocation_nature`, `assignment_type`, `share_value`, `share_unit`, `share_basis`, `share_level`, `share_pool`, `covers_whole_proceeds`, `determinacy`, `deferred_to`, `legal_rank`.
- **Provenance:** `alloc_legal_reference`, `instr_legal_reference`, `alloc_document_year`, `instr_document_year`, `alloc_ai_confidence`, `instr_ai_confidence`.

Verbatim excerpts and notes stay in the source tables; join them back on the ids when needed.

The derived columns are defined below.

### 2.1 `leg_class` — the economic role of the allocation (row level)

The rules are applied in order; the first match wins.

| value | rule |
|---|---|
| `general_budget` | `recipient_form = general_budget` |
| `refund_reserve` | `allocation_nature = refund_reserve` |
| `cost_recovery` | `allocation_nature = cost_recovery` |
| `staff_payment` | `recipient_form = staff_personal_payment` |
| `restricted` | `is_purpose_restricted = 1` (and none of the above) |
| `unrestricted` | otherwise (e.g. a tier's general budget) |

Cost-recovery shares, staff payments and refund reserves are **administrative retentions**. They are never earmarks themselves, and they are **neutral for exclusivity**: they neither make an instrument an earmark nor prevent it from being exclusive. Only a `general_budget` or `unrestricted` leg diverts proceeds.

### 2.2 `earmark_class` — a property of the instrument

The E-class is computed **per instrument, over all allocations of all groups the instrument belongs to**, and repeated on each of its rows. It is never an allocation-level classification; `leg_class` is the allocation-level column.

First, each group's level-1 key is profiled. Level 1 partitions gross proceeds; deeper levels only subdivide a level-1 share.

| group status | condition |
|---|---|
| `complete` | restricted legs at level 1, no level-1 `general_budget` / `unrestricted` leg, and `covers_whole_proceeds = 1` |
| `partial` | restricted legs exist, and either a level-1 `general_budget` / `unrestricted` leg exists or `covers_whole_proceeds = 0` (only a part is assigned; the rest stays in the general budget) |
| `unknown` | restricted legs exist only below level 1 (the level-1 key is not observed) |
| `no_restricted` | no restricted leg in the group |

`covers_whole_proceeds` is the group-level field set at extraction (allocation prompt v1.1, §4.5). It is binary and never null: 1 when the clause assigns the whole proceeds (no limiting word, a residual or whole-proceeds leg, or stated shares summing to 100); 0 by default and whenever a partitive or limiting word appears. **The E-class does not depend on share determinacy.** Whole proceeds assigned to restricted destinations with the split deferred or unstated is exclusive; the imprecision is recorded in `determinacy` and `commitment_strength`, not in the E-class.

Then the profiles of all groups the instrument belongs to are aggregated:

| class | rule | `earmark_class_determinate` |
|---|---|---|
| **E3** exclusive | proceeds net of administrative retentions are all restricted: some group is `complete`, and no group diverts proceeds (no `partial` group; no other group with a `general_budget` / `unrestricted` leg) | 1; 0 if another group is `unknown` |
| **E2** partial | restricted legs exist, and a `general_budget` / `unrestricted` leg or a silent remainder takes part of the proceeds | 1; 0 if a group is also `complete` (conflicting keys) |
| E2, indeterminate | restricted legs exist, but every restricted group is `unknown` (rare: restricted legs only below level 1) | **0** |
| **E1** assigned, unrestricted | no restricted leg; at least one `unrestricted` leg (e.g. a commune's general budget) | 1 |
| **E4** cost recovery only | no restricted or unrestricted leg; only `cost_recovery` / `staff_payment` legs, possibly beside a general-budget residual | 1 |
| **E0** | only a `refund_reserve` leg (the assignment nets the tax) | 1 |

Earmarked instruments = **E2 + E3**. Robustness check: re-estimate on `earmark_class_determinate = 1` only.

Examples:

| key | class |
|---|---|
| 5% cost recovery + 95% Forest Fund | E3 |
| 10% staff bonuses + the rest to the Universal Service Fund | E3 |
| 20% Tobacco Fund + 80% general budget | E2 |
| 50% commune road fund + 50% commune general budget | E2 |
| 30% Airport Fund + 10% cost recovery, remainder silent | E2 |
| "le produit est affecté au Fonds X et à l'Agence Y, selon une clé fixée par arrêté" | E3 (determinacy `share_deferred`, commitment `soft`) |
| "une quote-part fixée par décret est affectée au Fonds d'éducation", no other leg | E2 |
| 100% to communes' general budgets | E1 |
| 5% collection costs to the DGI + rest to the Treasury | E4 |

**`restricted_share_total`.** The sum of the level-1 restricted pct shares (administrative retentions excluded: 95 in the Forest Fund example), when the instrument has a single restricted group whose shares can be totalled; 100 for a `whole_proceeds_implied` leg. For a complete group whose split among restricted legs is unknown, it is 100 minus the stated administrative retentions (100 when there are none). Otherwise null. This is the dedication ratio for §6.6.

### 2.3 `commitment_strength` (row level)

How costly the assignment is to undo, read from the law alone (hard vs soft earmarking: McCleary 1991; Brett & Keen 2000; Marsiliani & Renström 2000).

| value | rule |
|---|---|
| `none` | `leg_class ≠ restricted` |
| `soft` | restricted, and `determinacy ≠ determinate` or `legal_rank ∈ {regulation, other}` |
| `hard` | restricted, determinate, **dedicated vehicle** (`fund`, `agency`, `special_account`, `social_security_institution`, `subnational_government`, `supranational_body`, `foreign_government`, `non_government_body`), and `legal_rank ∈ {constitution, organic_law, ordinary_law}` |
| `firm` | restricted, determinate, but routed through a `ministry_or_vote` / `program_or_purpose`, or enacted only in a `finance_law` |

An instrument's commitment is the **maximum** over its restricted legs (none < soft < firm < hard), computed at analysis.

### 2.4 `benefit_link` (row level)

Six classes plus `not_applicable`, tested in order (first match wins):

| # | class | definition | anchor |
|---|---|---|---|
| 1 | `corrective` | the base causes a harm; the destination mitigates it | Pigou; WHO health taxes |
| 2 | `compensatory` | the destination is restricted to the territory or population bearing the local costs of the taxed activity | resource-revenue-sharing derivation logic |
| 3 | `benefit` | payers, as individuals or users, consume the financed service | Buchanan 1963; McCleary strong Type A |
| 4 | `sectoral` | the destination serves the taxed sector as a whole (regulation, promotion, research, development) | parafiscal levies "in an economic interest" |
| 5 | `general_revenue` | broad base (`general_income`, `general_consumption`, `general_trade`, `general_revenue_class`) and no class 1–4 applies | McCleary Type C |
| 6 | `unlinked` | specific base, unrelated destination | McCleary Type B (non-corrective) |
| — | `not_applicable` | `leg_class ≠ restricted` | |

**How it is computed.**
1. `leg_class ≠ restricted` → `not_applicable`.
2. A restricted leg with `cofog_division = unallocated` → **null**, with `benefit_link_basis = function_unallocated` (the function is unknown, so the link is undefined).

   The non-functional codes `general_budget`, `subnational_unrestricted`, `external_unrestricted` and `refund_reserve` only occur on non-restricted legs, so those legs are `not_applicable` at step 1. `unallocated` is the only non-functional code that signals a coding gap. Report its share as a data-quality indicator.
3. Look up `(base_category, cofog_group)` in the concordance, then `(base_category, cofog_division)`.
4. A `corrective` hit is final.
5. Otherwise a restricted `assignment_type = derivation_transfer` → `compensatory` (`derivation_rule`).
6. Otherwise the concordance hit.
7. Otherwise a broad base → `general_revenue` (`broad_base_rule`).
8. Otherwise → `unlinked` (`residual_rule`).

Only the primary COFOG function is used; `cofog_secondary` is ignored.

**Concordance** (`benefit_link_concordance.csv`). Columns: `base_category, cofog_code, benefit_link, rationale`. `cofog_code` is a division (`707`) or a group (`7074`); a group row takes precedence over a division row. Only classes 1–4 are listed; every cell not listed falls to rule 7 or 8. **This file is the only place where judgment enters the classification.** It is signed off once and versioned.

**Overrides** (`benefit_link_overrides.csv`). Columns: `instrument_id, allocation_id, benefit_link, reason`. An override applies to exactly one row and is recorded as `benefit_link_basis = "override: {reason}"`. Use overrides for cell-level exceptions, never to recode a whole concordance cell (change the concordance instead).

## 3. Units of analysis (to state with every statistic)

| question | unit | how |
|---|---|---|
| number and types of earmarked instruments, E-class shares | instrument | `drop_duplicates("instrument_id")` |
| source composition | instrument × `base_category` / `instrument_type` | instrument level |
| destination functions | instrument × `cofog_division` | deduplicate on (`instrument_id`, `cofog_division`) over restricted legs |
| recipient architecture, routing, determinacy, legal rank | allocation | `drop_duplicates("allocation_id")` — a pool counts once per destination |
| Sankey source → destination | instrument × `cofog_division`, restricted legs | flows weighted by count of instrument–function links |
| benefit link | instrument × `cofog_division`, restricted legs | one link value per pair; report the share of pairs |
| commitment | instrument (max over legs), or allocation | say which |
| country indicators (exclusive share, dedicated-vehicle incidence, determinacy share) | instrument-level ratios within the E2+E3 subset | the denominator is $n^{E}_c$ (ANALYSIS_SPEC §0), not a census |

`class_placeholder` instruments (e.g. "total tax revenue") are one instrument each. Report results with and without them.
