# ANALYSIS SPEC — Paper 1 (v1.0, 1 Nov 2026)

*Replaces the analysis parts of `long_outline.md` (deprecated: it assumed a census). Input: the frozen `analysis_data\created-data\ssa_earmarks_instrument_destination_prelim_2026-11.csv`, built by `build_instrument_destination.py`; definitions in `DERIVED_TABLE_SPEC.md`. Analysis in R.*

## 0. Conventions

- **Scope.** 43 SSA countries (Eritrea, Mauritania, Somalia, South Sudan and Sudan are not covered), *de jure*, current law, a single cross-section. No census, so there is **no prevalence** (earmarked ÷ all instruments). Instruments whose only assignment is to the central general budget are not in the data.
- **Two instrument sets** (E-classes: DERIVED_TABLE_SPEC §2.2), per country $c$:
  - **earmarked set** $\mathcal{E}_c$ = E2 + E3 (at least one restricted leg), size $n^{E}_c$. This is the main set.
  - **assigned set** $\mathcal{A}_c$ = E1 + E2 + E3 (proceeds assigned somewhere other than the central general budget, restricted or not), size $n^{A}_c$. Secondary: it gives the E1, E2 and E3 shares of assigned revenue; E1 is mostly unrestricted sharing with subnational tiers.
  - E4 (administrative retentions) and E0 (refund reserves) are in neither set.
- **Social contributions** (`instrument_type = social_contribution`, GFS 12) are excluded from both sets in the headline results and included in a robustness check. They buy entitlement to benefits, their per-country counts depend on how the law splits branches, and none appear in BWA, COM, GIN, MDG and NER (BWA has no contributory scheme as far as known; the other four are probably corpus gaps, to be verified). Taxes assigned to social-security bodies (e.g. a VAT share for health insurance) stay in. Table A1 reports the count of social contributions in its own column.
- **Every statistic states its unit**: instrument, instrument × COFOG division, allocation, or country (DERIVED_TABLE_SPEC §3).
- **Share levels: main results use each group's top level.** `top_level = 1` on the allocations at the shallowest `share_level` of their group: level 1, or the shallowest level present for the few groups with no level-1 row. All main statistics (A1–A5, A7, B) use `top_level = 1` rows. Reasons: level 1 says where the **gross** proceeds go; mixing levels counts the same money twice (a fund at level 1 and its sub-accounts at level 2); a level-2 share is a share of the parent's share, not of the proceeds.
  - The E-class is unaffected: it already reads every level (a general-budget or unrestricted leg at any level makes the instrument E2).
  - Deeper levels (`share_level ≥ 2`, 153 of 2,980 groups, 5%) are used as detail only: in A6 (territorial channels, where most sub-keys sit), and in one appendix line on how many groups have sub-keys and how many of those add a function absent from level 1. Report the number of E2 instruments whose only diverting leg is below their top level (40).
  - Shares are never compared or added across levels. An effective share (the product down the chain) is computed only when every parent share is stated.
  - Instrument-level indicators of earmarked instruments (vehicle, commitment, benefit link) use the instrument's restricted top-level legs, the top level being defined per group. An instrument with no restricted top-level leg in any of its groups uses its restricted legs at the shallowest level where it has one: 27 earmarked instruments in 13 countries (social contributions excluded). Table A1 reports their number per country (`n_earmarked_no_top_restricted`).
- **Class placeholders** (`row_kind = class_placeholder`, about 11% of instruments): one row standing for a class of charges the corpus does not enumerate. Use `row_kind` directly; no extra flag.
  - The instrument unit is labelled "instruments and classes of charges".
  - Main results are reported with and without placeholders.
  - Whole-revenue classes (`base_category = general_revenue_class`) are excluded from B1 exposure, and the number excluded is reported.
  - Report the placeholder share per country before comparing countries (every country has some; the share exceeds 25% in COM, SWZ, NGA and GMB).
- **Weights.** Composition shares are **country-equal** by default: compute within each country, then average across countries. Pooled shares are a robustness check, because pooled shares are dominated by countries with many instruments.
- **Ratios over counts.** Country comparisons use ratios **within** the earmarked set (denominator $n^{E}_c$, the size of the earmarked set). Raw counts depend on corpus completeness and on how each legal system splits charges, so they are shown as context only.
- **Legal snapshot year.** For each country, report `law_year_max` (latest `document_year` among the documents that produced rows) and `law_year_median` (median `alloc_document_year` over allocations). The text says "law in force as of the latest text in the corpus". It never says "2026".
- **External data window.** The latest 3 available years, averaged (WoRLD: 2022–2024), whatever the country's law year. Revenue structure moves slowly, and so does earmarking architecture, so a 1–3 year gap is second-order; robustness uses the single latest year. PEFA: the latest assessment under the 2016 framework, with the year reported, plus a robustness check restricted to assessments from 2018 or later.
- **Country groups** (`analysis_data\supporting-data\country_groups.csv`, signed off 2 Nov 2026): `iso3`; `legal_family` (francophone_civil / anglophone_common / lusophone_civil / hispanophone_civil / mixed), coded by the origin of public-finance and tax law, with regional harmonisation left to `cfa_zone`; `mixed` = RWA, ETH; `cfa_zone` (UEMOA / CEMAC / none); `rec`, one primary community: a customs union applied (ECOWAS, EAC, SACU), else SADC, else ECCAS, else COMESA; AES for BFA, MLI, NER (ECOWAS exit effective 29 Jan 2025, before their `law_year_max`); `rec_all` (all memberships, "a; b"); `resource_rich` and `resource_group` (IMF REO Sub-Saharan Africa, April 2026: oil exporters, other resource-intensive, non-resource-intensive); `notes` (reason for each debatable call); `design_group`, the A7 grouping, derived from `legal_family` × `cfa_zone`: `uemoa_francophone`, `cemac_francophone`, `francophone_noncfa`, `anglophone_common`, `lusophone_noncfa`, `cfa_nonfrancophone` (GNB, GNQ), `mixed` (RWA, ETH).
- **Folders** (root `C:\Users\alexa\Documents\earmarking-ssa\`):
  - `analysis_data\supporting-data\`: raw external downloads (WoRLD, GRD, PEFA) and the hand-built `country_groups.csv`. Never modified by scripts;
  - `analysis_data\created-data\`: every dataset a script creates (stacked CSV, `.rds` files);
  - names state content, scope, status and date, e.g. `ssa_earmarks_instrument_destination_prelim_2026-11.csv`. Replace `prelim` with `validated` after §4;
  - one `paths.R` sets these folders, so no script hard-codes a path.
- **Status.** Results are preliminary until validation (§4) is done. Freeze the stacked CSV in `analysis_data\created-data\` under a dated, self-explanatory name, e.g. `ssa_earmarks_instrument_destination_prelim_2026-11.csv`. Every output regenerates from it with one command.

## 1. Descriptive overview (section D)

**D1. Table 1: the database at a glance.**
- Countries.
- Documents read.
- Instruments, allocation groups, allocations and unique destinations, each with mean, median, min and max per country.
- Instruments by E-class (E0–E4) and by `row_kind`.
- Share of rows with `ai_confidence ≠ high`.
- Share of restricted legs with `cofog_division = unallocated`.

**D2. Appendix Table A1: one row per country.**
- Legal family and CFA zone.
- Number of documents, and `law_year_max` / `law_year_median`.
- Instruments and allocations.
- Counts of E3, E2, E1, E4 and E0.
- Exclusive share, fund-or-agency share, benefit-linked share, hard-commitment share (defined in §2).

Note for the text: the E1, E4 and E0 counts are incidental. They count only instruments the corpus happens to assign in those ways, not every such instrument.

## 2. Analysis on the database (section A)

| # | Question | Exhibit | Unit | Main measure |
|---|---|---|---|---|
| A1 | How much earmarking, and where? | Dot plot of countries: E2 + E3 instruments and allocations, coloured by legal family | instrument | $n^{E}_c$; E3 share $= n^{E3}_c/n^{E}_c$; secondary: E1, E2 and E3 shares of $n^{A}_c$ |
| A2 | What finances earmarks, and what do they finance? | **(a) Core heatmap** of `base_group` (12 rows, below) × COFOG division. Each cell shows the number of instrument–function links, labelled with the number of countries. **(b) Recipient-form shares.** **(c) One Sankey per country**, `base_group` → COFOG division, restricted legs, flows = number of links (not money). In the main text: 3–4 contrasting countries (e.g. one UEMOA, one CEMAC, one anglophone, one lusophone). All countries in an appendix of country profiles. **(d)** `instrument_type` (GFS) composition of earmarked instruments, country-equal and pooled (table): what kind of charges the counts are made of | instrument × division; (d) instrument | link counts; country-equal shares |
| A3 | Is there an economic rationale? | Stacked bars of `benefit_link` (corrective / compensatory / benefit / sectoral / general_revenue / unlinked), overall and by legal family | instrument × division | share of links in each class |
| A4 | How binding are earmarks? | Design table: E3 vs E2; `commitment_strength` (instrument maximum); vehicle; `legal_rank`; `determinacy` | instrument (commitment, E-class); allocation (vehicle, rank, determinacy) | country-equal shares |
| A5 | Which earmarks are reform candidates? | Cross-table of benefit link × commitment strength. Highlight "unlinked or general revenue, and hard": rigid with no economic rationale | instrument × division | share of links in each cell |
| A6 | Territorial and regional channels | Short subsection: derivation, equalization, subnational sharing; regional community levies (ECOWAS, UEMOA, CEMAC, SACU) | allocation | counts; country incidence |
| A7 | Do legal traditions shape the design? | Groups: `design_group` (§0), which separates legal tradition from CFA harmonisation. Main contrasts: UEMOA and CEMAC vs non-CFA francophone (harmonisation within one tradition); non-CFA francophone vs anglophone (tradition outside the CFA zone). GNB, GNQ (CFA without the French tradition) and RWA, ETH (mixed) are labelled points, never group bars. **(a)** Recipient-form composition by group, read as legal forms as written (vehicle note below). **(b)** Design profile: E3 share, hard-commitment share, share enacted in finance laws, benefit-linked share, fund-or-agency share. Country dots with the group median and n; context columns: the country's share of finance-law documents in its corpus (`{ISO3}_corpus.csv`, `doc_type`) and `law_year_median`; with and without class placeholders. **(c)** One pre-specified check: country-level fractional logit of each design share on group dummies, `resource_group` and log documents, HC3 errors; read as an association | (a), (b) instrument and allocation (labelled); (c) country | country-level values; group medians |

**Base groups** (`base_group`, added in `00_load.R`; used by A2a, A2c and A7). `base_category` records what is taxed; GFS (`instrument_type`) records the economic nature of the charge and is used in A2d and B1. Order as listed:

| base_group | base_category |
|---|---|
| broad_bases | general_income, general_consumption, general_trade, general_revenue_class |
| extractive | extractive_resources |
| fuel_energy | fuel_energy |
| forestry_fisheries_agriculture | forestry_wildlife_fisheries, agricultural_commodities |
| environment_water | pollution_waste_environment, water |
| telecom_media | telecom_ict_postal, media_advertising |
| transport | motor_vehicles_road, air_maritime_rail_transport |
| financial_insurance | financial_insurance |
| harmful_consumption | harmful_consumption |
| gambling_tourism | gambling_lotteries, tourism_hospitality |
| payroll_property | payroll_employment, property_land, construction_urban |
| services_acts_other | health_education_services, regulated_activities_professions, public_administrative_acts, persons, other_specific |

harmful_consumption is its own row although small (35 earmarked instruments, 16 countries), because it is the corrective case readers look for.

**Vehicle definitions** (allocation level, restricted legs):
- *fund-or-agency vehicle* = `fund`, `agency`, `social_security_institution`, `non_government_body`;
- *on-budget vehicle* = `special_account`, `ministry_or_vote`, `program_or_purpose`;
- *territorial and external* = `subnational_government`, `supranational_body`, `foreign_government`, kept separate.

The country's fund-or-agency share is the share of its earmarked instruments with at least one restricted leg to a fund-or-agency vehicle.

These are legal forms as written (`fund` is any recipient the text calls a fund), not budget status, so the measure is not read as extrabudgetary. A `budget_status` variable for fund rows (on-budget / off-budget / unknown) is built before B2.

The legal-family grouping (`legal_family`) runs through A1–A5 as a breakdown wherever it is informative. A7 uses `design_group`.

## 3. Analysis with external data (section B)

**B1. Revenue exposed to earmarking** (WoRLD; ICTD-UNU-WIDER GRD as a check).

- **(i) Exposure.**
  $$\text{Exposure}_c=\sum_k \frac{R_{ck}}{R_c}\,\mathbf 1\{\exists\, i\in E2\cup E3 \text{ in } c:\ \text{gfs}(i)\in k\}$$
  Here $k$ is the most detailed revenue category WoRLD provides; map the instrument `gfs_code`s onto it and document the mapping. It is an **upper bound**: one small levy flags its whole category. Exhibit: exposure by country, and the share of countries with an earmark in each category.
- **(ii) Big-ticket earmarks.** When instrument $i$ *is* its category $k$ (VAT, PIT, CIT, import duties, social contributions):
  $$\text{ER}_{ci}=s_i\cdot R_{ck}/\text{GDP}_c$$
  where $s_i$ = `restricted_share_total`. Use single-instrument groups only, and report pool cases separately (the pro-rata pool assumption). Exhibit: a short table of the largest statutory earmarks as % of GDP and % of revenue.

**B2. Earmarking and budget comprehensiveness** (PEFA PI-6).
- Off-budget vehicle share (from `budget_status`) vs PI-6.2 (revenue outside financial reports) and PI-6.3 (reports of extrabudgetary units). Grades are ordinal.
- Exhibit: a labelled scatter or grouped dot plot, Spearman ρ, a leave-one-out check, the number of countries.
- Read as an association.

**B3. Resource revenue and compensatory design** (WoRLD resource revenue).
- Resource revenue share vs the share of compensatory or derivation links among earmarks on `extractive_resources` bases.
- Same reporting as B2.

Interpretation rule for B: associations only. Legal family, CFA membership and colonial history are confounded with every institutional variable.

## 4. Second stage (after the first results)

1. **Validation** (PROJECT_STATE §5.2), run after a first full pass of §1–§3:
   - recall on 2–3 hand-coded countries;
   - precision and κ on a sample of about 150 rows;
   - stability on 2 re-runs;
   - a corpus-completeness index per country, and its correlation with WGI government effectiveness.

   **This must come before any institutional result is written up.**
2. **Survey of IMF country teams.** Send each country's table to the desk or FAD contacts and ask: (a) which funds or levies are missing (an expert recall check that feeds the validation); (b) whether entries are wrong or out of date; (c) amounts collected or transferred, where known.
3. **B4 magnitudes for a subset**: amounts to identified destinations over total revenue, from survey answers and budget tables (special-account tables of the loi de finances, consigned-revenue tables of the Orçamento, fund accounts). A lower bound.
4. **Robustness** (four checks):
   - drop class placeholders (now in main results, §0);
   - keep only instruments with `earmark_class_determinate = 1`;
   - keep only well-covered countries;
   - pooled instead of country-equal weights;
   - include social contributions (§0).

## 5. Cut from the old outline

- **Needs the census:** prevalence and within-source propensity.
- **Replaced:** the A/B/C eligibility grades (by the completeness index) and the ten-table data engineering (by the build script).
- **Out of scope:** North Africa and the European comparators.
- **Dropped:** OBS, WGI as an outcome, Afrobarometer and fiscal-rules correlations; clustering.
- **Appendix only:** 4-digit COFOG.
- **Possible:** WOFI decentralisation, as one paragraph in A6 only if subnational channels turn out large.

## 6. R scripts

| script | content |
|---|---|
| `theme_earmark.R` | colours, ggplot theme and `save_fig()` for every figure (rules in `PLOT_STYLE.md`); sourced after `paths.R` |
| `00_load.R` | read the stacked CSV; set factor orders (E-class, benefit link, commitment); split the "a; b" list cells; add `top_level` (§0); add the flags `earmarked`, `assigned` and `social_contribution` (§0); join `country_groups.csv`; save `ssa_earmarks_analysis_prelim_2026-11.rds` |
| `01_descriptives.R` | D1, D2 |
| `02_composition.R` | A1, A2a–b, A3 |
| `03_sankey.R` | A2c: one PDF page per country (ggalluvial) |
| `04_design.R` | A4, A5, A7 |
| `05_territorial.R` | A6 |
| `qmd/first_results_database.qmd` | first preliminary report: assembles the D and A outputs with comments; reads saved outputs only and computes nothing new |
| `10_external_prepare.R` | reads the raw downloads (WoRLD, GRD, PEFA PI-6; resource revenue) from `analysis_data\supporting-data\` → `ssa_external_indicators_prelim_2026-11.rds`, one row per country, with the source and years recorded for each variable |
| `11_exposure.R` | B1 |
| `12_associations.R` | B2, B3 |
| `qmd/first_results_external.qmd` | second preliminary report: the B outputs |
| `run_all.R` | regenerates every table and figure from the two `.rds` files |

Order: `00`–`05` → `first_results_database.qmd` → download the external data → `10`–`12` → `first_results_external.qmd`. Both reports are preliminary.
