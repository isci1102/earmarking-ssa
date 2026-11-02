# INSTRUMENT TABLE EXTRACTION — PROMPT (v1.0)

**Input.**

- `COUNTRY_FOLDER = C:/Users/alexa/Documents/earmarking-ssa/countries/GNQ/` .
- Read-only inputs:
  - the allocation table `{COUNTRY_FOLDER}/outputs/allocations/{ISO3}_EARMARK_ALLOCATIONS.json`;
  - the legal documents: **every file in `{COUNTRY_FOLDER}/source_pdfs/`, subfolders included, and nothing else**;
  - the text cache `outputs/_cache/`, if present.

**Output.** One file: `{COUNTRY_FOLDER}/outputs/instruments/{ISO3}_INSTRUMENTS.json` (format in §6).

This prompt is self-contained. If the allocation table is missing, **STOP** and say so.

---

## 1. What the table is

One row = **one revenue instrument** whose proceeds appear in at least one allocation group of the allocation table.

- A single-instrument group maps to one row.
- A **pool** maps to one row per member instrument.
- An instrument that appears in several groups (on its own, and as a member of a pool) is **one row** listing every group in `allocation_group_ids`.
- No instrument is recorded unless it is linked to an allocation group. This is **not** a census of the tax system.

The table describes the instrument's **source side only**: what it is, what it taxes, how it is charged. The destination is in the allocation table. The two are joined later on `allocation_group_id`.

## 2. Blind coding (binding)

Code `instrument_type`, `gfs_code`, `base_category` and `base_isic_division` **from the charging provision only**: the clause that imposes the charge and defines its base. Never from the destination, the allocation clause, or the name of the fund it feeds.

For example, a "contribution au développement de l'électrification rurale" levied on telecom operators' turnover is `telecom_ict_postal`, not `fuel_energy`.

The benefit link between source and destination is computed afterwards, mechanically. Coding the destination into the base would make that link true by construction.

## 3. Procedure

1. **Load the allocation table.** List its groups with `allocation_group_id`, `instrument_name`, `is_pool`, `pool_members`, `source_reference`, `legal_reference` and `document_sources`. Hash the file; it must be unchanged at the end.
2. **Text.** Reuse `outputs/_cache/`. If a document is not cached, apply the gate:

   - the file opens;
   - the text is clean (no mojibake, accents and ligatures intact), and a mid-document sample is coherent;
   - if the layout is double-column, a passage reads as contiguous text, otherwise use column-aware extraction or page images.

   Cache the text. Read long documents along their own divisions.
3. **Find each instrument's charging provision.**

   - **Single-instrument group:** start from `source_reference`. If it is null, search the corpus for the instrument by name and base, using charging grammar:
     - fr: *il est institué / créé, est perçu(e), est dû(e), sont soumis à, le taux est fixé à*;
     - en: *there shall be levied / imposed / charged, shall be payable, is hereby imposed*;
     - pt: *é criado / instituído o imposto / a taxa, fica(m) sujeito(s) a, é devido(a), incide sobre, a taxa é de*;
     - es: *se establece / se crea el impuesto / la tasa, estarán sujetos a, se devengará, es exigible, el tipo será de*.
   - **Pool** — expand it under §4.1, then find the charging provision of each member.
4. **Extract the fields (§5).** Base and rate must come from the **current-law** text (§4.6).
5. **Consolidate.** One row per distinct instrument (§4.2). Every group that draws on it goes in `allocation_group_ids`.
6. **Assign `instrument_id`:** `{ISO3}_I{nnn}`, numbered in order of the lowest linked `allocation_group_id`.
7. **Run the checks (§7)** with Python. Fix a failure by re-reading the source; never patch a value without reading the source. Write the output atomically: temporary file, then replace.
8. **Report in chat (≤ 8 lines):**

   - instruments, and class placeholders;
   - counts by `instrument_type` and by `base_category`;
   - instruments whose charging provision is not in the corpus (corpus gaps);
   - the number of rows with `ai_confidence ≠ high`;
   - every `SCHEMA:` note.

## 4. Rules

### 4.1 Expanding pools

- **Enumerated pool.** `pool_members` is non-null, or the clause lists the instruments. Create or link one row per member.
- **Class pool** (e.g. "droits de douane", "the levies imposed under this Act", "taxes collected by the Revenue Authority"):
  - Expand it **only** when a provision in the corpus defines the class or lists its components (e.g. the customs code lists the duties and charges levied on imports; the Act imposes identifiable levies). Cite that provision in `notes`.
  - Otherwise create **one** row with `row_kind = class_placeholder`. `official_name` holds the class as written. `instrument_type` is the class's type if the class is homogeneous (customs duties → `trade_tax`), else `mixed_class`.
- **Whole-revenue classes are never expanded:** "total tax revenue", "recettes fiscales", "all revenue of the State", "les recettes du budget général". They are always one `class_placeholder` row with `instrument_type = mixed_class`, `base_category = general_revenue_class`. Expanding them would require a census.

### 4.2 One instrument = one row

- **Identity is the charging provision and the thing taxed.** Two mentions that share the charging provision and the base are one instrument, whatever the names used in different groups.
- **Different thing taxed = different instrument.** A charge applied to two distinct goods or activities is two rows. A charge owed *in addition to* another, rather than *instead of* it, is another row. The domestic and imported forms of one good are separate if the law taxes them separately.
- **A different tariff line is not a different instrument.** One charge scaled by class, size or category is one row; the schedule goes in `rate_verbatim`.
- **Fold into the parent, no separate row:** a minimum, an advance, a creditable withholding, and interest or penalties assigned together with the parent (as the allocation table records). A penalty assigned separately is its own row, `instrument_type = fine_penalty`, and takes the base of the activity it regulates.
- **Additional points or centimes** added to another tax are their own instrument. `tax_base_detail` names the parent tax.

### 4.3 `official_name` and `instrument_label_verbatim`

- **`official_name`:** the full designation with every distinguishing qualifier (good taxed, origin, payer class, territory), from the charging provision.
  - Never a truncated stem.
  - Never a bare generic word.
  - Never named after its destination unless the law names it that way.
  - If the law names the charge only generically, use the most specific name the corpus gives: the clause, then the definitions, then the section heading, then the generic term plus the Act's short title.
- **`instrument_label_verbatim`:** the term the law uses (*impôt, taxe, droit, redevance, contribution, prélèvement, duty, levy, fee, royalty, cess, imposto, taxa, contribuição, emolumento, impuesto, tasa, contribución, canon, arancel …*). Pure transcription.

### 4.4 `instrument_type` and `gfs_code` (GFSM 2014, Table 5.1)

Classify the instrument's **economic nature**, not its label. A *redevance* can be a tax, and a *taxe* can be a fee.

| `instrument_type`          | GFS code(s)                                                                             | includes                                                                                                                                                                                                                                                                                                               |
| ---------------------------- | --------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `income_profits_tax`       | 111 (1111, 1112, 1113)                                                                  | taxes on income, profits and capital gains of individuals or enterprises; profit-based resource taxes; presumed-income regimes                                                                                                                                                                                         |
| `payroll_tax`              | 112                                                                                     | levies on payroll or workforce **that do not entitle payers to social benefits** (training levies, payroll housing levies)                                                                                                                                                                                       |
| `property_tax`             | 113 (1131, 1132, 1133, 1135, 1136)                                                      | recurrent taxes on immovable property, net wealth, estates and gifts, capital levies                                                                                                                                                                                                                                   |
| `general_consumption_tax`  | 1141 (11411 VAT, 11412 sales, 11413 turnover, 11414 financial and capital transactions) | VAT; sales and turnover taxes; taxes on transfers of property, securities and payments (11414)                                                                                                                                                                                                                         |
| `excise`                   | 1142                                                                                    | product-specific taxes on a limited range of goods: alcohol, tobacco, motor fuels and hydrocarbons, sugar and other specific products, **and use of utilities** (water, electricity, gas, energy). A tax on imports that the same law also applies to comparable domestic goods is an excise, not an import duty |
| `specific_services_tax`    | 1144                                                                                    | taxes on payments for specific services: transport (incl. airport and passenger taxes), insurance, banking, telecom services, entertainment, restaurants, advertising, **gambling and betting stakes**, entry to casinos and races                                                                               |
| `use_permission_tax`       | 1145 (11451 motor vehicles; 11452 other)                                                | motor vehicle taxes; business and professional licences; pollution taxes; radio and TV licences; hunting and fishing licences not tied to use of a State-owned resource; permits to conduct extraction operations                                                                                                      |
| `other_goods_services_tax` | 1143, 1146                                                                              | profits of fiscal monopolies; taxes on extraction from deposits **not owned by the receiving government**; other taxes on goods and services                                                                                                                                                                     |
| `trade_tax`                | 115 (1151 import, 1152 export, 1153–1155, 1156 other)                                  | customs and other import duties; export taxes and levies; taxes based exclusively on international travel (1156)                                                                                                                                                                                                       |
| `other_tax`                | 116 (1161, 1162)                                                                        | poll, head or capitation taxes; general stamp taxes not tied to one class of transaction; taxes on unidentifiable bases                                                                                                                                                                                                |
| `social_contribution`      | 12 (121, 122)                                                                           | contributions paid **to secure entitlement to social benefits**, levied on earnings, payroll or number of employees                                                                                                                                                                                              |
| `resource_rent`            | 1415                                                                                    | royalties, felling fees, surface rents and other payments for extraction or use of natural resources **owned by the receiving government**; rent on land                                                                                                                                                         |
| `administrative_fee`       | 1422                                                                                    | fees for compulsory licences and administrative services where the government performs a **proper regulatory or service function** proportionate to the fee: driving licences, passports, visas, court fees, certificates                                                                                        |
| `sales_user_charge`        | 1421, 1423                                                                              | sales of services by government units, including **tolls** for roads, bridges and tunnels, and port or airport service charges                                                                                                                                                                                   |
| `fine_penalty`             | 143                                                                                     | fines, penalties and forfeits imposed for violations of laws or administrative rules                                                                                                                                                                                                                                   |
| `other_nontax`             | 141 (other than 1415), 144, 145                                                         | interest, dividends, transfers n.e.c., premiums of compulsory guarantee schemes proportional to the service                                                                                                                                                                                                            |
| `mixed_class`              | null                                                                                    | class placeholders spanning several types (§4.1)                                                                                                                                                                                                                                                                      |

**Boundary rules (GFSM 2014 §5.73–5.74, 5.96, 5.133, 5.143):**

- **Tax vs fee.**
  - A licence or permit granted automatically, with little or no control by government, is a **tax** (1145).
  - A fee for a proper regulatory function (control of the activity, checking qualifications) is an **administrative fee** (1422) — unless it is clearly out of all proportion to the cost, in which case it is a tax.
- **A fee is a tax** when:
  - the payer is not the receiver of the benefit (a levy on slaughterhouses financing services to farmers);
  - no specific service commensurate with the levy is provided;
  - the benefits go to the payers as a group but not in proportion to individual payments (a marketing levy on producers used to promote the product). Most sectoral parafiscal levies are taxes under this rule, classified by their base.
- **Social contribution vs payroll tax.** Only payments that secure entitlement to social benefits are social contributions. A payroll levy funding a training or housing fund with no individual entitlement is `payroll_tax`.
- **Resource payments.**
  - On a State-owned resource: rent (1415).
  - Profit-based: 111.
  - Based on the gross value of production from deposits not owned by the receiving government: 1146.
  - Licence to conduct extraction operations: 1145.
- **Penalties on overdue taxes** that cannot be separated from the tax stay with the tax (§4.2).

**`gfs_code`:** the finest code in the table above that the charging provision supports (e.g. `11411`, `1142`, `11451`, `1415`), as a string. Never deeper than the table lists. It must fall within its `instrument_type`'s codes. Null only for `mixed_class`.

### 4.5 `base_category` — what bears the charge

**The question:** what object or activity is taxed? Not who collects, not who receives, not the type of tax. Read it from `tax_base_detail`. Choose one value; if the base spans two, take the dominant one and name the other in `notes`.

**Broad bases** (no specific taxed object):

| value                     | the base is                                                                                                                                                                                  |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `general_income`        | income, profits, capital gains, turnover or presumed income of persons or enterprises **in general**; general business licences (*patente*) and minimum taxes of general application |
| `general_consumption`   | consumption or transactions **in general**: VAT, general sales and turnover taxes, stamp duties of general application                                                                 |
| `general_trade`         | imports or exports **in general**: customs duties of general application, statistical fees, community levies on all imports                                                            |
| `general_revenue_class` | class placeholders covering several bases ("total tax revenue"). `class_placeholder` rows only                                                                                             |

**Specific bases:**

| value                                | the base is                                                                                                                                    |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `payroll_employment`               | wages, payroll, number of employees, employment of foreign workers, social-contribution earnings                                               |
| `property_land`                    | ownership, occupation, transfer or registration of land and buildings; land rent; real-estate transactions                                     |
| `financial_insurance`              | banking operations, financial transactions, securities, money transfers, mobile money, insurance premiums or contracts                         |
| `harmful_consumption`              | tobacco, alcohol, sugar-sweetened beverages and other products taxed as harmful to health                                                      |
| `fuel_energy`                      | petroleum products, gas, coal, electricity — production, supply or consumption                                                                |
| `motor_vehicles_road`              | ownership or use of motor vehicles, driving, road tolls, axle load, vehicle inspection                                                         |
| `air_maritime_rail_transport`      | passengers, tickets, airports, ports, freight, shipping, rail                                                                                  |
| `telecom_ict_postal`               | telecom services, operators' turnover, SIM cards, international calls, internet, postal services                                               |
| `media_advertising`                | broadcasting, radio and TV sets or licences, advertising, press, cinema, audiovisual                                                           |
| `extractive_resources`             | mining, quarrying, oil and gas — production, exports, titles, permits, royalties                                                              |
| `forestry_wildlife_fisheries`      | timber, logging, forest concessions, wood exports, hunting, wildlife, fishing licences and catch                                               |
| `agricultural_commodities`         | crops, livestock and agricultural produce, including their exports (cocoa, coffee, cotton, cashew …)                                          |
| `water`                            | water abstraction, supply and sanitation                                                                                                       |
| `pollution_waste_environment`      | emissions, polluting activities or products (e.g. plastics), waste, environmental permits and impact assessments                               |
| `gambling_lotteries`               | betting, gaming, lotteries, casinos, winnings                                                                                                  |
| `tourism_hospitality`              | hotels, tourist stays and nights, restaurants and bars, tourist entries                                                                        |
| `construction_urban`               | building permits, construction works, cement, urban land development and planning                                                              |
| `health_education_services`        | pharmaceutical products, medical acts, health establishments, school and examination fees                                                      |
| `public_administrative_acts`       | passports, identity documents, visas, residence permits, civil status, court and legal acts, certificates, legalisation                        |
| `regulated_activities_professions` | licences or registrations for specific trades or professions not listed above (security firms, arms, regulated professions, specific commerce) |
| `persons`                          | persons as such: poll, capitation or per-person levies not based on income                                                                     |
| `other_specific`                   | a specific base not listed above; describe it in `notes`                                                                                     |

**Rules:**

1. **The collector and the recipient are irrelevant.** A local tax on markets is not `general_consumption` just because a commune collects it.
2. **A specific good under a general tax keeps the general base:** VAT on fuel is `general_consumption`. A specific tax on a good takes the good's category: the fuel levy is `fuel_energy`.
3. **A penalty takes the base of the activity it regulates:** illegal logging → `forestry_wildlife_fisheries`; late VAT → `general_consumption`.
4. **A tax on imports of a specific good** takes the good's category (tobacco imports → `harmful_consumption`). Only duties of general application are `general_trade`.
5. **Additional points or centimes** take the base of the parent tax.

**`base_isic_division`** (optional): the ISIC Rev.4 two-digit division of the industry producing or supplying the taxed good or service, when the base is confined to one industry — e.g. `06` oil and gas extraction, `12` tobacco products, `61` telecommunications, `92` gambling. Null for broad bases, persons and administrative acts. It is auxiliary; `base_category` governs.

### 4.6 Current law and evidence

- **Latest text in force governs.**
  - Base and rate come from the most recent enacting text in `source_pdfs/` that states them, unless a later text amends or repeals them. Order by document date; within a year, an amending text beats the text it amends.
  - Superseded values are described in `legal_change_note`, never kept as rows.
  - An instrument the corpus records as **repealed** is still recorded if a current allocation group refers to it, with the repeal stated in `legal_change_note` and `ai_confidence = medium`. That situation signals an inconsistency to review.
- **`tax_base_detail`:** the base, verbatim or near-verbatim, as the charging provision states it. Mandatory. Where the text states no base, say so in words.
- **`rate_verbatim`:** the rate or tariff as written, briefly ("10 % de la valeur en douane"; "FCFA 25 par litre"; "fixed by arrêté"). For a schedule, give the structure and range (e.g. "banded by engine capacity, FCFA 25,000–150,000"). Null for class placeholders.
- **`charging_provision_in_corpus`:**
  - `1` when the charging provision was found in `source_pdfs/`.
  - `0` when it was not (the charge is imposed in an Act that is not in `source_pdfs/`). Then:
    - `legal_reference` is null;
    - `verbatim_excerpt` is the text in the corpus that best identifies the instrument (usually the allocation clause);
    - the base and type are coded from what that text states about the base;
    - `ai_confidence ≠ high`, and `notes` names the missing Act.
- **`legal_reference`:** the charging provision, as `{short title or text} {unit}`, e.g. `CGI 2024 art. 410`, `Act 91 of 1964 s 47(1)`. If a later text amends it, cite the governing text first and the others after `;`.
- **`verbatim_excerpt`:** the exact text of the charging provision (the clause that imposes the charge and states its base), never summarised. For a class placeholder, the clause that names the class.
- **`document_sources`:** a list of file names (no paths) from which any value in this row was taken.
- **`document_year`:** the year of the most recent document in `document_sources`, taken from the allocation table's `documents` list where available.

### 4.7 Change note, confidence and notes

- **`legal_change_note`** (≤ 2 sentences or null): an explicit amendment, replacement or repeal of the instrument; conflicting statements between documents; a drafting inconsistency; a stale cross-reference; any difficulty in reading the legal system. State the fact.
- **`ai_confidence`:** `high`, `medium` or `low`.
- **`notes`** (≤ 2 sentences): mandatory when `ai_confidence ≠ high`, saying whether the problem lies in the document or in the schema. Also used for the secondary base, the provision that defines an expanded class, and folds.
- **Schema gap.** Code the closest values, set `ai_confidence = medium`, and start `notes` with `SCHEMA:`. Never invent a field or an enum value.

## 5. Column dictionary

Fill every field, in this order. Use JSON `null` for empty values, never `""`.

| #  | field                            | type            | null? | rule                                          |
| -- | -------------------------------- | --------------- | ----- | --------------------------------------------- |
| 1  | `instrument_id`                | string          | no    | `{ISO3}_I{nnn}` (§3 step 6)                |
| 2  | `country`                      | ISO3            | no    |                                               |
| 3  | `allocation_group_ids`         | list of strings | no    | every group drawing on this instrument; ≥ 1  |
| 4  | `row_kind`                     | enum            | no    | `instrument`, `class_placeholder` (§4.1) |
| 5  | `official_name`                | string          | no    | §4.3                                         |
| 6  | `instrument_label_verbatim`    | string          | no    | §4.3                                         |
| 7  | `instrument_type`              | enum            | no    | §4.4                                         |
| 8  | `gfs_code`                     | string          | yes   | §4.4; null only for `mixed_class`          |
| 9  | `tax_base_detail`              | string          | no    | §4.6                                         |
| 10 | `base_category`                | enum            | no    | §4.5                                         |
| 11 | `base_isic_division`           | string          | yes   | §4.5                                         |
| 12 | `rate_verbatim`                | string          | yes   | §4.6                                         |
| 13 | `charging_provision_in_corpus` | 0/1             | no    | §4.6                                         |
| 14 | `legal_reference`              | string          | yes   | §4.6; null only when field 13 = 0            |
| 15 | `verbatim_excerpt`             | string          | no    | §4.6                                         |
| 16 | `document_sources`             | list of strings | no    | §4.6                                         |
| 17 | `document_year`                | integer         | no    | §4.6                                         |
| 18 | `legal_change_note`            | string          | yes   | §4.7                                         |
| 19 | `ai_confidence`                | enum            | no    | §4.7                                         |
| 20 | `notes`                        | string          | yes   | §4.7                                         |

## 6. Output format

```json
{
  "country": "XXX",
  "prompt_version": "instrument_v1.0",
  "rows": [
    {
      "instrument_id": "XXX_I004",
      "country": "XXX",
      "allocation_group_ids": ["XXX_G004"],
      "row_kind": "instrument",
      "official_name": "taxe spécifique sur les tabacs",
      "instrument_label_verbatim": "taxe",
      "instrument_type": "excise",
      "gfs_code": "1142",
      "tax_base_detail": "cigarettes, cigares et tabacs fabriqués, importés ou produits localement ; assise sur le prix de vente hors TVA",
      "base_category": "harmful_consumption",
      "base_isic_division": "12",
      "rate_verbatim": "45 % du prix de vente hors TVA",
      "charging_provision_in_corpus": 1,
      "legal_reference": "CGI 2024 art. 410",
      "verbatim_excerpt": "Il est institué une taxe spécifique sur les cigarettes, cigares et tabacs fabriqués …",
      "document_sources": ["CGI_2024.pdf"],
      "document_year": 2024,
      "legal_change_note": null,
      "ai_confidence": "high",
      "notes": null
    }
  ]
}
```

*(Illustrative values only.)*

## 7. Final checks (Python, read-only — fix any failure by re-reading the source)

1. Every `instrument_id` is unique and matches `{ISO3}_I\d{3}`. Every row has all 20 fields in order. The non-null fields of §5 are non-null.
2. Every enum value is listed in this prompt. `gfs_code` falls within its `instrument_type`'s codes (§4.4 table).
3. **Coverage.**
   - Every `allocation_group_id` in the allocation table appears in at least one row.
   - Every id in `allocation_group_ids` exists in the allocation table.
4. **Groups with `is_pool = 0`** are linked to exactly one row, and that row has `row_kind = instrument`.
5. **Pools.**
   - A group with `is_pool = 1` and non-null `pool_members` is linked to one row per member; any members merged as one instrument are explained in `notes`.
   - A `class_placeholder` row is linked only to groups with `is_pool = 1`.
   - `base_category = general_revenue_class` ⇔ `row_kind = class_placeholder` and `instrument_type = mixed_class`.
6. `charging_provision_in_corpus = 0` ⇒ `legal_reference` null, `ai_confidence ≠ high`, and `notes` non-null.
7. **No instrument twice.** No two rows share (normalised `official_name`, `tax_base_detail`).
8. `official_name` is not a bare generic word (`tax`, `levy`, `fee`, `duty`, `charge`, `taxe`, `redevance`, `droit`, `contribution`, `imposto`, `taxa`, `contribuição`, `impuesto`, `tasa`, `contribución`, alone or with an article).
9. `notes` is non-null on every row with `ai_confidence ≠ high`.
10. Every file in `document_sources` is in `source_pdfs/`. `document_year` equals the latest year among them.
11. The allocation table's hash is unchanged.

## 8. Hard rules

- Write only `outputs/instruments/{ISO3}_INSTRUMENTS.json` and `outputs/_cache/`. Never modify the allocation table or the source documents.
- Record only instruments linked to an allocation group.
- Code the source side from the charging provision only; never from the destination.
- Enacting text only. Verbatim and anchored. Never invent a base, a rate or a member of a pool. Never fill a field from general knowledge or the web.
- Uncertainty goes in `notes`; it is never resolved silently.
