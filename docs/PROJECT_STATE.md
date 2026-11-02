# PROJECT STATE — Earmarked Instruments Extraction (as of 2 Nov 2026, v3)

*Paste this into a new chat to resume. The governing files are in the Project under `claude/`; read them rather than relying on this summary when details matter. The analysis plan is `claude/ANALYSIS_SPEC.md`. `long_outline.md` is **deprecated** (it assumed a census): do not use it.*

## 1. The project

- **Goal.** An IMF working paper and a public database: the first clause-level, *de jure* map of revenue earmarking in 43 Sub-Saharan African countries (Eritrea, Mauritania, Somalia, South Sudan and Sudan not covered), under current law. Co-authors at the IMF: Julien (my former internship supervisor) and Luc (who helps with data). The project is unpaid; I am a PhD student (Université d'Orléans), and it is not my main priority.
- **Positioning.** Unlike recent IMF LLM databases built from EIU narrative reports (e.g. Das, Furceri, Patel & Peralta-Alva, IMF WP 2026/043), ours codes **primary legal texts**: every row carries the verbatim clause, the legal reference and the source file, so every cell can be audited against the law.
- **Scope decisions.** Cross-section only (current law); no panel. No census of all instruments, so there is no instrument-count denominator. Groups assigned only to the central general budget are dropped at extraction.

## 2. Pipeline and status

| step | tool (Project file) | status |
|---|---|---|
| 1. Corpus discovery | `CORPUS_DISCOVERY_PROMPT.md` v1.4 → `{ISO3}_corpus.csv` + brief | done |
| 2. Download | `download_corpus.py` → `source_pdfs/`, `{ISO3}_download_log.csv` | done |
| 3. OCR scanned PDFs | `ocr_corpus.py` (dry run unless `--run`; `--lang fra+eng`, `por+eng`, `spa+fra+eng`) | done |
| 4. Allocation extraction | `EARMARK_ALLOCATION_PROMPT.md` v1.5 (fr/en/pt/es; batched, 1,200 pages per session) | **done, all SSA countries** |
| 5. Instrument extraction | `INSTRUMENT_PROMPT.md` v1.0 (fr/en/pt/es) | **done, all SSA countries** |
| 6. Instrument × destination + stacking | `build_instrument_destination.py`, `benefit_link_concordance.csv`, `DERIVED_TABLE_SPEC.md` v1.2 | **done 2 Nov 2026: 43/43 built, 7,571 rows** |
| 7. First analysis pass | `ANALYSIS_SPEC.md` §1–§3, in **R**, on the frozen stacked CSV (`ssa_earmarks_instrument_destination_prelim_2026-11.csv` in `analysis_data\created-data\`) | **next** (before validation) |
| 8. Validation | protocol to be written (ANALYSIS_SPEC §4.1) | to do, after the first results |
| 9. Survey of IMF country teams + magnitudes (B4) | ANALYSIS_SPEC §4.2–4.3 | second stage |

Viewing: `json_to_xlsx.py` converts any output JSON to xlsx (e.g. `python json_to_xlsx.py "countries/*/outputs/*/*.json"`).

## 3. Folder layout (per country)

```
countries/{ISO3}/
  source_pdfs/                 legal corpus (read-only for every prompt)
  {ISO3}_corpus.csv, {ISO3}_corpus_brief.md, {ISO3}_download_log.csv, {ISO3}_ocr_log.csv
  outputs/allocations/{ISO3}_EARMARK_ALLOCATIONS.json
  outputs/instruments/{ISO3}_INSTRUMENTS.json
  outputs/derived/{ISO3}_INSTRUMENT_DESTINATION.csv      (written by the build script)
  outputs/_work/, outputs/_cache/                        (allocation run state and text cache)
```

Build command (run from the `earmarking-ssa` folder; the script expands `countries/*` itself, so it works in PowerShell):

```
python scripts\build_instrument_destination.py "countries/*" --concordance scripts\benefit_link_concordance.csv [--overrides benefit_link_overrides.csv] --stacked analysis_data/created-data/ssa_earmarks_instrument_destination_prelim_2026-11.csv
```

A country that fails a check is skipped and reported; the others are built. The stacked file holds the countries that passed. `..._build_report.csv`, written next to it, lists every folder with its status, counts and error message. The exit code is 1 if any country was skipped.

## 4. Key concepts (full definitions in the Project files)

- **Allocation table** (34 columns): one row = one instrument-or-pool → one destination, under one key (`allocation_group_id`, `allocation_id`). Fields include `recipient_form` (12 forms, fixed precedence), `recipient_level`, COFOG GFSM 2014 division and group (coded from the destination side only), `is_purpose_restricted`, `allocation_nature` (proceeds_share / cost_recovery / refund_reserve), `assignment_type`, `share_value`, `share_unit`, `share_basis`, `share_level`, `share_pool`, `covers_whole_proceeds` (binary, group-level, never null), `determinacy`, `deferred_to`, `legal_rank`, verbatim evidence, `ai_confidence` and notes.
- **Instrument table**: one row per instrument linked to an allocation group (pools expanded only when the corpus lists their members; whole-revenue classes become placeholders). Coded **blind**, from the charging provision only: `instrument_type` and `gfs_code` (GFSM 2014 Table 5.1), and `base_category` (26 categories, 4 of them broad).
- **Derived table** (deterministic, no LLM). One row per instrument × allocation. The identity check is rows = Σ_g n_I(g)·n_A(g).
  - **`earmark_class`**, at instrument level:
    - E3: all proceeds restricted, net of administrative retentions (cost recovery, staff payments and refund reserves count as neutral);
    - E2: a general-budget or unrestricted leg, or a silent remainder;
    - E1: unrestricted legs only;
    - E4: administrative retentions only;
    - E0: refund reserve only.
    - Diversion is checked at every share level; `covers_whole_proceeds` decides whether the assignment is exclusive.
  - **`commitment_strength`** (hard / firm / soft / none), from determinacy, dedicated vehicles and legal rank.
  - **`benefit_link`**, tested in this order: corrective > compensatory (including derivation transfers) > benefit > sectoral > general_revenue (broad bases) > unlinked. Legs that are not restricted get `not_applicable`. It comes from the concordance (`base_category` × COFOG group, then division), plus overrides.
- **Units of analysis**: always state which unit a statistic uses (instrument, allocation, group or country); see DERIVED_TABLE_SPEC §3.

## 5. Agreed plan for the paper

Full plan: **`claude/ANALYSIS_SPEC.md`**. In short:

1. **Build and stack** the derived table for all countries. Freeze it with a dated, self-explanatory name in `analysis_data\created-data\`; every output regenerates from it.
2. **First analysis pass (R):**
   - D: descriptive overview (Table 1, per-country Table A1, E-class counts);
   - A1–A7 on the database: counts, the source × function heatmap, one Sankey per country, benefit link, design, reform candidates, territorial channels, legal tradition and CFA zone;
   - B1–B3 with external data: exposure and big-ticket earmarks from WoRLD; PEFA PI-6; resource revenue.
   - Conventions: country-equal weights; ratios within the earmarked set; external data averaged over the latest 3 years (WoRLD 2022–2024); law year reported per country (never "2026").
3. **Validation, after the first results:** recall, precision and κ, stability, a corpus-completeness index vs WGI. It comes before any institutional result is written up.
4. **Second stage:** a survey of IMF country teams (missing funds, errors, amounts), then B4 magnitudes for a subset, then the robustness checks.
5. **Release:** CSVs, codebook, versioned prompts, model and run dates, scripts, corpus lists with URLs, download dates and file hashes; DOI (Zenodo).
6. **Stated limits:** *de jure* only; a single cross-section; no prevalence; a panel and later snapshots are future work.

## 6. Constraints

- **Compute.** The full extraction used ~50–60% of a $200 Claude plan in one month, paid by me; I cannot keep paying that. Raise compute cost-sharing with Julien, and ask the lab about reimbursement. The remaining steps should be cheap: scripts and human validation.
- **Working style.**
  - Senior-economist tone; flag identification and measurement issues.
  - Clean R and Python with methodological comments; simple, uncluttered figures.
  - Outline a plan and wait for my approval on multi-step design work. But when I give an extraction prompt, run it without asking.
  - Show what will change before overwriting or deleting existing files. Never modify files outside the working folder unless I ask.
  - List the files created or modified at the end of each task.

## 7. Immediate next step

1. ~~Fix the two known issues in `build_instrument_destination.py`~~ (done 1 Nov 2026: folder patterns expanded by the script; a bad country is skipped and reported).
2. ~~Run it on all countries with `--stacked`, check the build report, freeze the stacked CSV~~ (done 2 Nov 2026). `ssa_earmarks_instrument_destination_prelim_2026-11.csv`: 43/43 countries built, none skipped; 7,571 rows × 44 columns; per-country rows, instruments and allocations match the build report; no duplicate (instrument, allocation) keys; no missing document years; `benefit_link` null only on the 155 restricted legs with `cofog_division = unallocated`. Instruments: 4,165 (E3 1,742; E2 958; E4 943; E1 510; E0 12; 140 of E2 + E3 indeterminate); 465 class placeholders (11%).
3. ~~Build and sign off `country_groups.csv`~~ (signed off 2 Nov 2026; `analysis_data\supporting-data\`; coding rules in ANALYSIS_SPEC §0).

**Decisions (2 Nov 2026, in ANALYSIS_SPEC §0):** earmarked and assigned sets; social contributions excluded from the headline sets and included as robustness; vehicle measure renamed fund-or-agency share.
4. **First preliminary pass, on the database:** `00_load.R` and the D and A scripts, then `first_results_database.qmd`.
   - `analysis\paths.R` and `analysis\00_load.R` written and run from a clean session (2 Nov 2026); every stop() check passes. `paths.R` fixes `run_date <- "2026-11-02"`, so all scripts of one pass write to `analysis\output\2026-11-02\` (tables\, figures\). Output: `ssa_earmarks_analysis_prelim_2026-11.rds` (7,571 rows; factors, `top_level`, flags `earmarked` / `assigned` / `social_contribution`, country groups joined), plus `00_load_check_by_country.csv` and `00_load_summary.csv`. Instruments: earmarked 2,700 (2,545 without the 156 social contributions); assigned 3,210 (3,055); 6,898 rows have `top_level = 1`; 15 groups have no level-1 row. Countries per `design_group`: UEMOA 7, CEMAC 5, francophone non-CFA 5, anglophone 18, lusophone 4, CFA non-francophone 2, mixed 2.
   - `analysis\01_descriptives.R` written and run from a clean session (2 Nov 2026); every stop() check passes. `paths.R` gains `dir_countries` and `file_documents_rds`. Outputs: `ssa_earmarks_documents_prelim_2026-11.rds` (1,514 country × document rows from the allocation JSONs; 1,509 read, 5 failed: 1 MUS, 4 SLE web-page assets), `01_table1.csv`, `01_tableA1.csv`, `01_tableA1_columns.csv` (unit and definition of each A1 column). Top level: 3,989 allocations (+ 397 below = 4,386), 2,980 groups, 2,235 unique destinations (country × exact name). Not-high AI confidence: 59.8% of top-level allocations, 53.5% of instruments (pooled). 87 of 2,369 restricted top-level allocations (3.7%) have `cofog_division = unallocated`.
   - Decision (2 Nov 2026, ANALYSIS_SPEC §0): A1 instrument-level indicators read the restricted legs at the shallowest level where the instrument has one. 27 earmarked instruments (13 countries) have restricted legs only below the top level. Coded as: top-level restricted legs when the instrument has any, else the shallowest `share_level`. Reason: 2 instruments (TCD_I053, TZA_I015) also sit in groups with no level-1 row, so a plain minimum over `share_level` would drop their level-2 top-level legs (TCD_I053 would go from hard to firm).
   - A1 medians over 43 countries (earmarked without social contributions, n = 2,545): exclusive 0.667, fund-or-agency 0.845, benefit-linked 0.757 (2,599 instrument × division pairs; 137 null excluded; 14 with several links take the first in test order), hard commitment 0.644.
   - 00_load_summary.csv has no group count; 01 checks groups against the full .rds instead.
   - `00_load.R`: `base_group` added (the 12 groups of ANALYSIS_SPEC §2, factor in spec order; stop() on NA or on a base_category in no group or two). Re-run 2 Nov 2026: `00_load_summary.csv` and `00_load_check_by_country.csv` byte-identical to before.
   - `analysis\helpers.R` (new): `get_indicator_legs()` (restricted legs of the instrument-level indicators, ANALYSIS_SPEC §0) and `get_link_pairs()` (instrument × cofog_division links; benefit link = first in the DERIVED_TABLE_SPEC §2.4 order; NA on unallocated). Sourced by 01 and 02. 01 re-run: `01_table1.csv`, `01_tableA1.csv`, `01_tableA1_columns.csv` byte-identical.
   - `analysis\02_composition.R` written and run from a clean session (2 Nov 2026); every stop() check passes. A1, A2a, A2b, A2d, A3 on three sets: headline (earmarked, no social contributions), `_sc` (social contributions included) and `_nopl` (headline without class placeholders); `_sc` and `_nopl` are tables only. Country-equal shares, pooled alongside. Outputs: 15 tables `02_*.csv` + `02_A1_by_country_columns.csv`; figures `02_A1_countries`, `02_A2a_heatmap`, `02_A2b_recipient_form`, `02_A3_benefit_link`.
   - Decisions (2 Nov 2026): A1 allocations = restricted top-level allocations of earmarked instruments (a pool counts once; the 7 pools shared with a social contribution stay in the headline set). Class placeholders: `_nopl` tables produced now as part of the main results (ANALYSIS_SPEC §0), not deferred to §4.4.
   - Headline results (preliminary): 2,545 earmarked instruments; 2,210 restricted top-level allocations; 2,736 instrument × division links (137 unallocated). 704 Economic affairs = 56% of links (country-equal); largest cell transport × 704 (246 links). Recipient form (allocations, country-equal): agency 36%, fund 35%, programme or purpose 12%. Instrument type: fines 18%, administrative fees 16%, use-permission taxes 13%. Benefit link (links, country-equal): sectoral 42%, unlinked 20%, benefit 19%, corrective 8%, general revenue 7%, compensatory 3%; legal-family differences of a few points; general revenue 7% → 4% without placeholders.
   - `02_A2a_zoom704` figure (2 Nov 2026): COFOG groups with no pair (7049 in the headline set) dropped from the figure only and named in the caption; the 19 `02_*.csv` tables re-run byte-identical.
   - `analysis\03_sankey.R` written and run from a clean session (2 Nov 2026); every stop() check passes (flows sum to each country's links; total 2,736 = A2a total in `02_A2a_links.csv`; 43 PDF pages; 43 country PNGs). `ggalluvial` 0.12.6 installed from CRAN; `ggrepel` (already installed) separates the labels of thin nodes. Headline set; flows = instrument × division links from `get_link_pairs()`, base group → division, node order fixed (spec order; 701–710, unallocated last). Flow colours: the 5 base groups with the most links pooled, catch-all services_acts_other excluded from the ranking (extractive 305, fuel_energy 233, forestry_fisheries_agriculture 342, telecom_media 363, transport 287); the other base groups grey as Other; the legend shows all 6 keys on every page. Outputs: `03_A2c_sankey_countries.pdf` (one page per country, by `design_group` then ISO3); one PNG per country in `figures\countries_sankey_plots\` (`03_sankey_{ISO3}.png`; folder `dir_figures_sankey` in `paths.R`); `03_A2c_sankey_{ISO3}` PDF + PNG for the main-text countries; `03_sankey_flows.csv` (880 flows), `03_sankey_candidates.csv`.
   - Main-text Sankeys, **provisional** (2 Nov 2026): NER (UEMOA, 80 links = group median), COG (CEMAC, 101 = median), ZMB (anglophone, 53; tied with SWZ 58 around the median 55.5, broken by the class-placeholder share of earmarked instruments, ZMB 13.7% vs SWZ 34.5%), CPV (lusophone, 81; tied with AGO 104 around 92.5, broken by resource variety: CPV non-resource-intensive, NER, COG and ZMB resource-rich). Tie-breaks in the `note` column of `03_sankey_candidates.csv`.
   - ~~Open point: services_acts_other coloured~~ decided 2 Nov 2026: catch-all groups (services_acts_other) are never among the coloured top 5 (PLOT_STYLE §3), so fuel_energy is coloured.
5. **External data:** download WoRLD, the ICTD-UNU-WIDER GRD and PEFA PI-6 scores (plus resource revenue) into `analysis_data\supporting-data\`. Then `10_external_prepare.R` builds one country-level table with the source and years of each variable.
6. **Second preliminary pass:** the B scripts, then `first_results_external.qmd`.

The coding is done in Claude Code, launched from the `earmarking-ssa` root, which holds a `CLAUDE.md` that holds the coding preferences (plus a sample of my code) and points to `docs/ANALYSIS_SPEC.md` and `docs/DERIVED_TABLE_SPEC.md` (copied from the Project). Each Claude Code task is a short prompt naming one or two scripts and their spec sections, reviewed before the next.

**Open issues (pending, not approved):**
- (a) A6 regional levies: community levies (ECOWAS, UEMOA, CEMAC, ECCAS, AES) are created by community acts and are almost absent from the national corpora (only LBR, GNQ, ZAF and one CIV row). Options: state it as a scope limit, or hand-code a small supranational layer mapped to members through `rec_all`.
- (b) ~~A7 regrouping~~ decided 2 Nov 2026: `design_group` added to `country_groups.csv`; A7 rewritten in ANALYSIS_SPEC §2 (labelled single points, country dots with group medians, corpus-composition context, one pre-specified conditional check).
- (c) The Project copies under `claude/` are behind `docs/` until synced.
- (d) `budget_status` of fund rows (on-budget / off-budget / unknown), to be built before B2: autonomy or legal-personality wording, a match against the finance-law special-account tables, and a hand check.
- (e) Verify whether the missing social contributions in COM, GIN, MDG and NER are corpus gaps.
- (f) Benefit-link concordance review, before A3 and A5 are written up. `unlinked` is 20% of links (country-equal; 576 links) and is the pool of A5 reform candidates, but part of it looks like concordance gaps rather than unlinked earmarks. Largest unlinked cells (base_category × COFOG group, links / countries): other_specific × 7082 (39/15), extractive × 7011 (38/8), gambling × 7081 (27/11), regulated professions × 7076 (14/6), gambling × 7041 (13/3), property × 7013 (12/4), gambling × 7047 (11/6). Gambling has a single concordance row (× 707, corrective), so a gaming regulator funded by gaming fees falls to `unlinked` (e.g. MWI Act 34 of 2022 s 28, 65). A change is made in the concordance (new version), not by overrides, and requires re-running the build and `00`–`02`.

Root layout: `CLAUDE.md`, `docs\` (specs, `PLOT_STYLE.md`, `style_example.Rmd`), `.claude\skills\`, `countries\`, `analysis_data\created-data\` and `supporting-data\`, `analysis\` (R scripts, `paths.R`, `theme_earmark.R`, `helpers.R`, `qmd\`, `output\` for tables and figures).
