# Census Table — Data Dictionary (v0.11)

## 1. What the table is

One hand-authored row per **distinct revenue instrument** a document institutes or provides for — earmarked or not. Recorded from the document's enacting text alone, in a single run over the whole document.

**Invariants:** every row carries a verbatim excerpt and page anchor. `instrument_id` is blank at extraction. The table has no destination, share, or assignment fields.

**Not** a tax history, a panel, or a claim about a country's tax system. A per-document enumeration.

## 2. Grain — one row = one instrument

**One row = one distinct instrument.** A tax instituted, amended, or repeated across several articles is **one row**, anchored to its instituting article, with the other articles folded into `additional_mentions` (30a). So `count(rows)` is the instrument count directly.

**A different tariff line is not a different instrument.** One charge scaled by class of payer, size, capacity or category is **one row** with `rate_is_schedule = 1` and the whole table verbatim in `rate_schedule_detail` — however many lines it runs to and however many sub-headings it is printed under. But **a different thing taxed is a different instrument**: a charge stated once and applied to two distinct goods or activities is two rows, and so is a charge a payer owes *in addition to* another rather than *instead of* it.

**No instrument is recorded twice.** Where the same instrument appears in two divisions of the document — a code article cross-referencing an appended text, the same subsidiary act printed twice — keep the row that states the base and the rate and fold the other into it.

**What `count(rows)` counts.** Instruments the document **provides for**, including those it records as repealed. The count in force is `count(rows WHERE in_force = 1)` (12a). Any published figure must say which of the two it is.

**Fold into the parent (not a separate row):** a minimum, floor, advance, or withholding **that is creditable against, or discharges, the parent's liability**. These are collection or computation modalities, not instruments. Record them in the parent's `additional_mentions`.

**Its own row:** a charge with **its own base and its own rate**, distinct from any parent. Where one article bundles several such charges, each is its own row.

**Two rows (do not merge):** where the text creates a genuinely new instrument — `change_type ∈ {replacement, split, merger}`. A replaced tax is the old plus the new.

Merge and fold decisions are made on the natural key (`official_name` + `tax_base_detail`) and recorded on the surviving row: `instrument_merge` in `boundary_calls` (34a), the reasoning in `notes`, and the absorbed articles in `additional_mentions` (30a). The completeness rule on `official_name` (col 12) is what keeps a merge from wrongly joining two siblings — and, read the other way, is what reveals that several rows forced to share one truncated stem were never siblings at all.

## 3. Identity — id-free

No synthetic ids at extraction; `instrument_id` blank. Identity is the natural key (`document_id`, `legal_article`, `official_name` verbatim, `verbatim_excerpt`, page anchors), mandatory on every row. No reconciliation pass — `instrument_id` stays blank unless a later analysis assigns it.

**Page-anchor convention (binding).** `page_start` and `page_end` are **1-based indices of the canonical source PDF**, never the printed folio. A run that reads a slice must re-base its anchors to the canonical file before output; a slice-relative anchor is not a valid value.

> Stated rather than assumed because page anchors are load-bearing in the natural key — `legal_article` alone is not unique, since annexes re-number from 1 — so a systematic offset false-fails key matching on *every* row instead of failing loudly on one, and its sign cannot be inferred after the fact.

## 4. Every field is a fact from this document

No field records a property that must be established outside this document. This fixes `base_sector` (14f): the sector of the taxed *base* is in the clause; the sector the proceeds *reach* is a destination property, not recorded here.

---

## 5. Variable dictionary

> **On the column numbers.** They are **not** contiguous: 5, 17–23 and 25–28 are absent, and lettered suffixes sit between integers. This is deliberate — the integers are the evidence table's column numbers, kept identical so a census row and an evidence row can be unioned without a mapping table, and the gaps are the destination-side columns the census does not carry (§6). Do not renumber to close the gaps.

| # | Variable | Type | Null? | Note |
|---|----------|------|-------|------|
| 1 | `evidence_id` | string PK | **no** | `{country}_{document_id}_CEN_{NNNN}`. Filled on every row. |
| 2 | `row_type` | enum | no | `{source}` — constant. |
| 3 | `country` | ISO3 | no | ISO3 country code. |
| 4 | `instrument_id` | string FK | yes | **Blank at extraction.** Not the document stem (that names the document, not the instrument). Assigned only if a later analysis reconciles the census. |
| 6 | `document_id` | string | **no** | Natural key (e.g. `CGI2025`, `AF2026`). |
| 7 | `document_type` | enum | no | `{annexe_fiscale, loi_finances_initiale, cgi}`. Extend additively per jurisdiction. |
| 8 | `document_year` | int (text) | no | Year of the **document**. Only temporal field. |
| 9 | `legal_article` | string | yes | Natural key — the instituting article. |
| 10 | `page_start` | int | **no** | Page anchor (§3). |
| 11 | `page_end` | int | **no** | Page anchor (§3). |
| 12 | `official_name` | string (verbatim) | **no** | Natural key. **Completeness rule (binding):** the full designation with every distinguishing qualifier — taxed good, origin, taxpayer class, territory — never a truncated stem, because a country may separately tax the domestic and the imported form of one good and a shortened name would merge them. If the text names the instrument only generically, record the generic name, set `official_name_underspecified = 1` (12b), and put the disambiguating detail from `tax_base_detail` in `notes` — never invent a qualifier (§7). |
| 12a | `in_force` | bool | **no** | `0` where **this document's own text** records the instrument as repealed, abolished or suspended — including where the article is retained as a struck heading with the repeal noted, and including a marker of repeal the volume uses in place of the word (a bracketed *obsolete*, *replaced by …*). `1` otherwise. Document-local and observational: what the document says, never an outside judgment about whether a levy is still collected. A `0` row is **kept**, with the repealing text in `verbatim_excerpt` or `additional_mentions` — the repeal is itself a finding. Distinct from `change_type = repeal` (24), which records that *this* document performs the repeal; `in_force = 0` also covers an instrument repealed earlier and merely echoed here. Where both fire they must agree. |
| 12b | `official_name_underspecified` | bool | **no** | `1` where the document names the instrument only generically, so col 12 is not self-disambiguating; the distinguishing detail goes in `notes`. It fires on a majority of rows in some documents, so it is a column rather than a flag. Do **not** also list it in `boundary_calls`. |
| 13 | `tax_instrument` | enum | yes | `{VAT, excise, fuel_levy, telecom_levy, environmental_tax, payroll_tax, resource_revenue, redevance, parafiscal_contribution, fine, other}`. **DO NOT ANALYSE.** Schema compatibility only: it returns `other` too often to carry a classification and no published figure may be cut on it. |
| 14 | `tax_base_detail` | string | **no** | Verbatim or near-verbatim statement of the base, as the clause gives it. **Mandatory.** It is the principal evidence the classification pass reads, so a null here is a row that cannot be classified downstream. Record what the document says and nothing more; where the clause genuinely states no base, say so verbatim rather than leaving the cell empty. |
| 14a | `instrument_label_verbatim` | string (verbatim) | **no** | The term the document uses (*impôt*, *taxe*, *redevance*, *duty*, *levy*, *fee*…). **Pure transcription.** Never normalized, translated, or merged with a tag. |
| 14b | `instrument_nature` | string / enum | yes | **OPEN.** The instrument's character as a short tag (`corporate_income_tax`, `stamp_duty`, `mining_royalty`, `broadcasting_levy`…). Free text until the enum closes; imposed retrospectively, never re-extracted; never drawn from the destination. |
| 14f | `base_sector` | enum | yes | **The ISIC Rev.4 section (A–U) of the activity that is TAXED**, read from the base as the clause states it. Values and mapping rules in §5B, plus `general_economy_wide` and `not_applicable`. **The BASE's sector, never the destination's** — a mining royalty funding a health fund is `B_mining_quarrying`; a local tax on public entertainment is `R_arts_entertainment`. Single-valued: where the base spans two sections, record the dominant one, name the other in `notes`, add `base_sector` to `boundary_calls`. Null only where the document states no base, or no leg dominates. |
| 14f2 | `base_division` | string | yes | The **ISIC 2-digit division** (01–99) where the clause makes it readable — `11` beverage manufacture, `47` retail sale, `61` telecoms, `92` gambling. Null where only the section is determinable. Must belong to the section in 14f (§5B). |
| 14g | `is_penalty` | bool | **no** | `1` if the charge is a penalty, fine, non-compliance surcharge or forfeit **as this document's own text characterises it** — typically a label of *amende*, *pénalité*, *majoration*, *astreinte*, *peine*, *fine*, *penalty*, *surcharge*, or a clause whose trigger is a failure to comply. An **observation** from the wording, not a corollary of any classification. Penalties stay in the table and are the largest single denominator filter — a third or more of rows in some documents. Their `base_sector` is the sector of the activity they regulate (§5B rule 5). Penalties attached to **distinct obligations** are distinct instruments however uniform their amount (§2). |
| 15 | `rate_value` | numeric | yes | **Strictly scalar.** Null when banded, scheduled, deferred, or floor/ceiling-delegated. Never text. Under `ceiling_delegated` it is an upper bound, under `floor_delegated` a lower bound — in neither case an applied rate. |
| 15a | `rate_is_schedule` | bool | yes | `1` if the rate is banded or scheduled. Explains a null `rate_value`. |
| 15b | `rate_schedule_detail` | string | yes | Full verbatim schedule when `rate_is_schedule = 1`. Not an overflow field — a per-monetary-unit rate uses 16b. |
| 16 | `rate_type` | enum | yes | `{ad_valorem_pct, per_unit_amount, fixed_amount, amount_per_unit_of_base, rate_point_increment}`. `per_unit_amount` = per physical unit (litre, kg). `amount_per_unit_of_base` = per monetary unit of base (3 per 1,000); quantum in 16b; no normalizing to % at extraction. `rate_point_increment` = points added to another instrument's rate; parent in 16c. |
| 16a | `rate_basis` | enum | yes | `{stated, banded, deferred_subordinate_act, cross_reference, ceiling_delegated, floor_delegated, increment_on_other_instrument, not_applicable}`. **`ceiling_delegated`** = the statute fixes a maximum and the operative rate is set below it. **`floor_delegated`** = the statute fixes a minimum and the operative rate is set above it by a subordinate act, convention or agreement. In both, `rate_value` holds the bound and the row is **excluded from applied/average-rate computations**. `not_applicable` requires a boundary-log entry. |
| 16b | `rate_base_quantum` | numeric | yes | Monetary quantum to which `rate_value` applies when `rate_type = amount_per_unit_of_base` (3 per 1,000 → `rate_value = 3`, `rate_base_quantum = 1000`). % derived at analysis. Null otherwise. |
| 16c | `rate_reference_instrument` | string (verbatim) | yes | For `rate_point_increment`, the verbatim name of the incremented parent. A self-contained descriptor, not a row pointer. Null otherwise. |
| 24 | `change_type` | enum | yes | `{new, amendment_rate, amendment_base, amendment_key, merger, split, replacement, repeal, none}`. Provisional and document-local: does this document *institute* the instrument or *amend* an existing one? Not a lineage judgment. |
| 29 | `enabling_reference` | string | yes | Founding or citing legal text the clause itself names; null otherwise, never guessed. |
| 30 | `verbatim_excerpt` | string | **no** | Exact clause text of the instituting or primary mention. **Load-bearing.** |
| 30a | `additional_mentions` | list | yes | Every other article mentioning or amending the same instrument, or folding a minimum, advance or creditable withholding of it (§2). Each entry: `{legal_article, page_start, page_end, change_type, excerpt}`. Null when the instrument appears once. This is what makes `count(rows)` correct. **A fold recorded here does not update the rate fields — check both.** |
| 31 | `source_internal_inconsistency` | string | yes | A drafting inconsistency in the source itself, preserved without contaminating other fields. |
| 32 | `ai_confidence` | enum | no | `{high, medium, low}`. |
| 33 | `human_validation_status` | enum | no | `{unchecked, validated, corrected, rejected}`. Default `unchecked`. |
| 34 | `notes` | string | yes | **The reasoning field.** Stated ambiguities, secondary base-sector reach, and **the reason behind every entry in `boundary_calls`**, written so the call can be reviewed without reading the clause again. Non-null wherever `boundary_calls` is non-empty (§10.10). |
| 34a | `boundary_calls` | list | yes | The judgment classes that fired on **this row**, e.g. `["base_sector","fold_into_parent"]`. Empty where the row was self-evident. Domain: `{instrument_merge, fold_into_parent, container_decomposition, base_sector, is_penalty, referenced_not_enacted, rate_bound, in_force}`. `official_name_underspecified` is **not** a member — it has its own column (12b). |
| 35 | `evidence_status` | enum | no | `{attested, referenced_not_enacted_here}`. `attested` = instituted in this document's enacting text. `referenced_not_enacted_here` = named only by cross-reference to an instrument enacted elsewhere. |

---

## 5A. Rate-representation stresses (resolved additively)

| Gap | Resolution |
|---|---|
| Amount per monetary unit of base — normalizing to a % is prohibited | `rate_type = amount_per_unit_of_base` + `rate_base_quantum` (16b) |
| Points added to another instrument's rate | `rate_type = rate_point_increment`, `rate_basis = increment_on_other_instrument`, parent in 16c |
| Delegated statutory **ceiling** (*may not exceed*) | `rate_basis = ceiling_delegated`; `rate_value` = the ceiling |
| Delegated statutory **floor** (rate set by convention or subordinate act, floored by statute) | `rate_basis = floor_delegated`; `rate_value` = the floor |

A ceiling is not a rate; neither is a floor. Both record the bound and are excluded from applied/average-rate analysis.

**Not yet representable** — record verbatim in `rate_schedule_detail`, set `rate_is_schedule = 1`, and raise it in `run_meta`: a two-sided statutory band (*between 15 % and 20 %*), a monetary floor under an ad valorem penalty, and a multiplier of another charge (*the duty is trebled*).

---

## 5B. `base_sector` — ISIC Rev.4 sections

**The question: which economic activity bears the charge?** Not who levies it, not who receives it, not what kind of tax it is. Sections and divisions are ISIC Rev.4 (UN Statistical Papers M/4/Rev.4).

| | `base_sector` | Divisions | What is taxed, in these codes |
|---|---|---|---|
| **A** | `A_agriculture_forestry_fishing` | 01–03 | crops, livestock, **timber and logging (02)**, fishing (03) |
| **B** | `B_mining_quarrying` | 05–09 | mining, **petroleum and gas extraction (06)**, quarries (08) |
| **C** | `C_manufacturing` | 10–33 | **production** of beverages (11), tobacco (12), refined petroleum (19), cement (23) |
| **D** | `D_electricity_gas` | 35 | electricity and gas supply |
| **E** | `E_water_waste` | 36–39 | **water abstraction and supply (36)**, sewerage (37), waste (38) |
| **F** | `F_construction` | 41–43 | building works, civil engineering |
| **G** | `G_trade` | 45–47 | wholesale (46), **retail sale (47)**, motor-vehicle trade (45), markets, traders |
| **H** | `H_transport_storage` | 49–53 | road (49), water (50), air (51) transport; ports and warehousing (52) |
| **I** | `I_accommodation_food` | 55–56 | hotels (55), **restaurants, bars, on-premise drink sales (56)** |
| **J** | `J_information_communication` | 58–63 | **telecoms (61)**, broadcasting (60), publishing (58), audiovisual (59) |
| **K** | `K_financial_insurance` | 64–66 | banks (64), insurance (65), money transfer and exchange (66) |
| **L** | `L_real_estate` | 68 | property holding and occupation, letting, land and building transactions |
| **M** | `M_professional_technical` | 69–75 | notaries and lawyers (69), architects and engineers (71), **advertising (73)** |
| **N** | `N_admin_support` | 77–82 | equipment rental and leasing (77), travel agencies (79), security (80) |
| **O** | `O_public_administration` | 84 | administrative acts — passports, identity documents, criminal records, legalisation |
| **P** | `P_education` | 85 | education and training provision |
| **Q** | `Q_health_social` | 86–88 | health care (86), pharmacy, social work (88) |
| **R** | `R_arts_entertainment` | 90–93 | **gambling and betting (92)**, public entertainment (90), sport and amusements (93) |
| **S** | `S_other_services` | 94–96 | membership and professional bodies (94), other personal services (96) |
| **T** | `T_households_employers` | 97–98 | domestic employment |
| **U** | `U_extraterritorial` | 99 | activities of international bodies |

**Two non-ISIC values:**

| value | when — and only then |
|---|---|
| `general_economy_wide` | The base is **not confined to any one section**: VAT, general income and profits taxes, general business licences, stamp duty of general application, and local taxes whose **base** is general (a general local business charge, a local development levy, additional percentage points of general application). |
| `not_applicable` | The base is **not an economic activity at all**: a charge on persons as such (a poll or civic tax), or on the State itself. Expected to be **rare** — a handful per document, never a residual. |

**Mapping rules.**

1. **The collecting authority is irrelevant.** A local tax on markets is `G_trade`; a local tax on public entertainment is `R_arts_entertainment`. Only a local tax whose *base* is general is `general_economy_wide`. Same discipline as the destination rule.
2. **Beverages split by activity.** Manufacture → **C (11)**. Retail sale → **G (47)**. Bars and on-premise consumption → **I (56)**.
3. **Advertising is M (73); media and broadcasting are J (58–60).**
4. **Gambling is R (92); entertainment and sport are R (90, 93).** Same section — `base_division` is what keeps them apart.
5. **A penalty takes the sector of the activity it regulates.** Illegal logging → `A`; breach of mining rules → `B`; late VAT → `general_economy_wide`. The penalty character is carried by `is_penalty` (14g), not here.
6. **Recurrent property taxes are `L_real_estate`.** ISIC L covers real-estate activity; property holding and occupation belong there rather than in `not_applicable`.

---

## 6. Fields the census does not carry

**No destination-side field.** No destination, beneficiary, share, allocation or purpose-restriction column exists here. The census stops at the source.

**No classification column.** `revenue_class`, `tax_type` and `economic_type` are not recorded at extraction; they are produced later from this table's stored fields. Do not create them, and do not let a classification question change what is recorded.

## 7. Hard rules

- **No invention.** Not instituted in the *enacting* text → no row. Motivational, explanatory and definitional text is not enacting text. **A structural heading is not enacting text** — a chapter titled *"…for the benefit of local authorities"* institutes nothing; the enacting clause governs. Named only by cross-reference → a row with `evidence_status = referenced_not_enacted_here`.
- **Fold, don't multiply.** A minimum, advance, or **creditable** withholding of an existing tax → the parent's `additional_mentions`, not a new row (§2). A **final, non-creditable** levy takes its own row.
- **A tariff line is not an instrument** — one charge scaled by class is one row with `rate_is_schedule = 1`; a different thing taxed, or a charge owed in addition rather than instead, is another row (§2).
- **No instrument twice.** The same instrument printed in two divisions is one row (§2).
- **A repeal is recorded, not dropped** — `in_force = 0`, row kept (12a).
- **Null over coercion.** Deferred, banded, floored or capped → scalar null plus flag. No rate normalization: 3 per 1,000 stays 3 per 1,000.
- **A bound is not a rate** — `ceiling_delegated` and `floor_delegated` both hold a bound, excluded from rate computations.
- **Sector is the base's sector** (14f), never the destination's.
- **`document_year` ≠ instrument year.**
- **Instrument-agnostic retrieval** — anchor on the grammar that institutes a charge plus the document's own structure, never a checklist of expected instruments.

## 8. Output — one file per document

**One whole-document run produces one file.** The document is read in full (in internal parts if long, but merged before output); there is no per-section file and no `scope_slug`.

**Filename:** `{country}_{document_id}_CENSUS.{ext}`, `ext ∈ {xlsx, json}` by `output_format`.

**One structure, two renderings** (`xlsx` = workbook, `json` = one object); an `xlsx → json → xlsx` round-trip reproduces the original.

| workbook sheet | json key | shape |
|---|---|---|
| `census_table` | `census_rows` | array of row objects, §5 columns in order — **the deliverable** |
| `COVERAGE_CHECK` | `coverage_check` | array of `{division, page_range, read, instruments_found, finding}` — **one row per top-level division only** (a book, or the document's highest structural unit), confirmed read, with its instrument count including zeros. Do **not** descend to sub-divisions: the check proves the sweep, and enumerating every sub-division costs far more than it proves. **Each appended text — parafiscal schedules, sectoral codes, annexes — counts as one top-level division**, listed and swept like a book. |
| `RUN_META` | `run_meta` | `{parameters, read_check, open_items}` — the manifest row; one line confirming the canonical file was certified and read as contiguous text (and whether a column crop was applied); and any contestable call or schema gap resolved to finish the run, each with the count it would have produced the other way |

`census_rows` is the deliverable; `coverage_check` proves the whole document was read. One file is the complete census for the document.

---

## 9. Open item

**`instrument_nature` (14b) enum — OPEN.** Free-text tags until it closes. `base_sector` (14f) is **CLOSED**: the 21 ISIC sections plus `general_economy_wide` and `not_applicable` (§5B).

---

## 10. Validation — the file is not shipped unless every hard check passes

**Hard checks. Any failure blocks output.**

1. `evidence_id` unique and matching `{country}_{document_id}_CEN_{NNNN}`; `row_type = source` on every row.
2. Mandatory fields non-null on every row: `evidence_id`, `row_type`, `country`, `document_id`, `document_type`, `document_year`, `page_start`, `page_end`, `official_name`, `official_name_underspecified`, `in_force`, **`tax_base_detail`**, `instrument_label_verbatim`, `is_penalty`, `verbatim_excerpt`, `ai_confidence`, `human_validation_status`.
3. Every enum-valued field holds a listed value. An unlisted `base_sector` is a failure, not a licence to extend mid-run. `base_division`, where non-null, belongs to the section in 14f.
4. `is_penalty ∈ {0,1}` and, where `is_penalty = 1`, `notes` or `verbatim_excerpt` carries the characterising language — in whatever word the document itself uses.
5. `base_sector` null ⇒ `base_sector` appears in that row's `boundary_calls` **and** `notes` states whether the document gives no base or no leg dominates.
6. `page_start ≤ page_end`, both within the canonical PDF's page count, both 1-based PDF indices (§3). A slice-relative anchor is a failure.
7. **Rate coherence.** `rate_value` non-null ⇒ `rate_basis ∈ {stated, ceiling_delegated, floor_delegated}`. `rate_is_schedule = 1` ⇒ `rate_value` null and `rate_schedule_detail` non-null. `rate_basis ∈ {banded, deferred_subordinate_act, cross_reference, increment_on_other_instrument}` ⇒ `rate_value` null. `rate_basis ∈ {ceiling_delegated, floor_delegated}` ⇒ `rate_value` non-null **and** `rate_bound` in `boundary_calls`.
8. `rate_base_quantum` non-null ⟺ `rate_type = amount_per_unit_of_base`. `rate_reference_instrument` non-null ⟺ `rate_type = rate_point_increment`.
9. `instrument_id` blank on every row. `rate_basis = not_applicable` ⇒ `rate_bound` in that row's `boundary_calls`.
10. **Judgments are recorded on the row.** Every null `base_sector` carries the matching value in `boundary_calls`; every row with a non-empty `boundary_calls` has non-null `notes`; every value in `boundary_calls` is in the 34a domain; `official_name_underspecified` does **not** appear in it.
11. **Coverage closes.** Every top-level division appears in `coverage_check` with `read = true`, including zero-instrument ones, and `sum(instruments_found) = count(census_rows)`. Counts are **recomputed from the final rows**, never carried over from the sweep that produced them — a carried-over count is stale the moment anything merges. Assign each row to the **narrowest** division containing its `page_start`: divisions that begin and end on the same page nest inside longer siblings by accident, and a literal containment test leaves rows in no division at all.
12. `in_force = 0` ⇒ the repealing language appears in `verbatim_excerpt` or an `additional_mentions` entry — including a bracketed repeal marker the volume uses in place of the word. `change_type = repeal` ⇒ `in_force = 0`.
13. **No instrument recorded twice.** No two rows state the same base for the same charge. A row that names a charge but defers its rate elsewhere (`rate_value` null with `rate_basis = cross_reference`) is the common form: merge it into the row that states the tariff, or carry `instrument_merge` or `container_decomposition` in `boundary_calls` with `notes` saying why it stands alone. Likewise two rows in one division sharing an identical `official_name` under `official_name_underspecified = 1`. **The failure is leaving it unaddressed, not the flag.**

**Soft warnings — recorded, not blocking.** Null `base_sector`; `ai_confidence = low`; `official_name_underspecified = 1`; an instrument with `additional_mentions` spanning more than three articles (a possible failed merge); a division reporting zero instruments over more than twenty pages (a possible failed sweep).
