# Methodology for Building Country-Level Revenue Instrument and Earmark Allocation Databases in Sub-Saharan Africa

## Document purpose

This document describes the full country-level pipeline used to build two final tables:

1. **`XXX_CENSUS`**: one row per distinct revenue instrument identified in the selected legal corpus for country `XXX`.
2. **`XXX_EARMARK_ALLOCATION`**: one canonical row per statutory allocation channel retained from the earmark evidence layer.

The method is designed for legal documents that are long, heterogeneous, and difficult to read manually at scale. It combines legal-source research, structured retrieval, large-language-model extraction, rule-based reconciliation, and scripted filtering.

The database is a **de jure legal inventory**. It records what the law assigns. It does not record actual collections, transfers, disbursements, or expenditure execution.

The variable annexes follow Census Table Dictionary v0.11 and Evidence Table Dictionary v0.5, together with the fields added by reconciliation, census matching, and destination-function enrichment.

## Contents

1. Research objective and database scope
2. Units, identifiers, and table grain
3. Overall pipeline architecture
4. Country corpus construction
5. Common document-adaptation procedure
6. Database 1: revenue instrument census
7. Database 2: statutory allocation and earmark extraction
8. Francophone and Anglophone end-to-end workflows
9. Cowork and LLM execution design
10. Quality assurance and audit trail
11. Why the method is valuable
12. Interpretation and limitations
13. Annex A: `XXX_CENSUS`
14. Annex B: `XXX_EARMARK_ALLOCATION`
15. Annex C: intermediate files
16. Annex D: governing project files

---

# 1. Research objective and database scope

## 1.1 Objective

The objective is to reconstruct the legal revenue system of each country and identify which revenue instruments have a legally specified destination.

The two tables serve different purposes:

- `XXX_CENSUS` provides the **denominator**. It contains all revenue instruments in the selected legal corpus, whether earmarked or not.
- `XXX_EARMARK_ALLOCATION` provides the **allocation layer**. It records the statutory links from revenue instruments to beneficiaries or purposes.

The tables can be joined through `census_ref`. This permits a count-based measure of the prevalence of earmarking without counting one multi-beneficiary instrument several times.

## 1.2 Legal snapshot

The standard production run is a current legal snapshot based on the most recent consolidated or otherwise authoritative texts available at the extraction date.

The snapshot is not a legal history or a panel unless several dated legal corpora are deliberately assembled. `document_year` is the year of the source document. It is not automatically the year in which the instrument was first created.

## 1.3 Revenue instruments covered

The source side is intentionally broad. A revenue instrument can be an:

- tax;
- duty;
- levy;
- contribution;
- redevance;
- royalty;
- parafiscal charge;
- fee;
- fine or penalty; or
- another compulsory revenue source recognized by the legal text.

The method does not assume that every recorded instrument is a tax in the narrow economic sense. The legal label is preserved separately.

## 1.4 Operative definition of an earmark

A legally established earmark requires both:

1. a revenue source; and
2. an enacting clause assigning all or part of its proceeds to a specific named recipient or stated purpose.

A fund that merely exists is not evidence of an earmark. A preamble, memorandum, explanatory note, heading, or statement of motivation is not enough. The assignment must appear in enacting text.

The destination may be a fund, agency, ministry, territorial government, sector, programme, supranational body, public_employee or a stated functional purpose.

## 1.5 Broad construction layer and strict analytical subset

The evidence layer records more than the narrow earmark subset. It records every statutory assignment to a specific recipient, including:

- functional earmarks;
- tax sharing;
- unrestricted transfers to a territorial government;
- central-government residual shares;
- equalization arrangements;
- administrative or service-cost components; and
- other named allocations.

This follows an **extract-broad, filter-later** rule. The distinction between an earmark and another allocation is stored in variables. It is not imposed as an irreversible extraction-time exclusion.

For the strict functional earmark subset, the analytical filter is:

```text
allocation_nature == "proceeds_share"
and is_purpose_restricted == 1
```

This strict filter excludes service-cost components and unrestricted general-purpose transfers. The broader allocation table remains available for alternative definitions and sensitivity checks.

---

# 2. Units, identifiers, and table grain

The pipeline uses several related units. They must not be confused.

| Unit | Identifier | Definition | Main use |
|---|---|---|---|
| Legal document | `document_id` | One canonical legal source | Provenance and coverage |
| Located passage | no synthetic entity ID | One passage flagged by assignment grammar | Recall-oriented worklist |
| Evidence row | `evidence_id` | One clause times one fact established by that clause | Auditable source evidence |
| Revenue instrument | `instrument_id` | One distinct compulsory revenue source in the economic sense. an instrument_id could correspond to multiple census_ref| Instrument counts and continuity |
| Allocation channel | `pair_id` | One instrument-to-recipient channel at a defined level, pool, and base scope | Allocation-link counts and shares |
| Census record | census `evidence_id`, later census `instrument_id` | One distinct revenue instrument in the census | Denominator |
| Census link | `census_ref` | Array of census row IDs matching one earmark instrument | Numerator-denominator join |

## 2.1 Evidence-row grain

The earmark extraction is evidence-first.

- A source clause produces a `source` row.
- An assignment clause produces an `allocation` row for each destination.
- A clause with three beneficiaries normally produces one source row and three allocation rows.
- A destination clause may appear far from the charging clause or in another Act.

One evidence row is therefore not necessarily one instrument and not necessarily one allocation channel.

## 2.2 Instrument identity

`instrument_id` identifies the revenue source. It is stable across ordinary rate changes and base-parameter changes when the legal text signals continuity.

A new `instrument_id` is created when the text establishes a new instrument or expressly describes a merger, split, abolition, replacement, or later re-creation.

The governing principle is:

> Identity belongs in the key. Magnitude belongs in attributes. Contestable changes remain flags.

## 2.3 Allocation-channel identity

`pair_id` identifies the allocation channel. The reconciled pair key is:

```text
instrument_id
× normalized recipient
× share_level
× share_pool
× base_scope
```

A change in the percentage assigned to an existing destination does not create a new `pair_id`. A new destination creates a new pair. A dropped destination closes the existing pair.

## 2.4 Restatements

The legal corpus may state the same allocation channel several times. Reconciliation retains these statements as evidence and marks:

- one row as `governing` when several statements exist; and
- the other rows as `restatement`.

The governing row supplies the analytical share and other channel attributes. A restatement is not a second allocation channel.

## 2.5 Nested allocation keys

Some laws allocate proceeds in stages. For example, 60 percent may go to a fund, and the fund's 60-percent pool may then be divided among several bodies.

- `share_level = 1` means a share of gross instrument proceeds.
- `share_level = 2` means a share of a named level-1 pool.
- `share_level = 3` or above records deeper routing.
- `share_pool` names the parent pool for levels above one.

Shares are checked and summed within the same level and pool. Level-1 and level-2 percentages are not additive.

---

# 3. Overall pipeline architecture

```text
COUNTRY LEGAL CORPUS AND MANIFEST
│
├── DATABASE 1: REVENUE INSTRUMENT CENSUS
│   ├── certify and read each legal document
│   ├── extract one row per revenue instrument
│   ├── validate and save per-document census files
│   └── reconcile across documents when needed
│       └── XXX_CENSUS
│
└── DATABASE 2: STATUTORY ALLOCATION LAYER
    ├── LOCATE assignment-bearing passages
    ├── EXTRACT clause-level source and allocation evidence
    ├── RECONCILE instruments, channels, duplicates, and conflicts
    ├── attach census_ref
    ├── classify destination function with COFOG
    └── filter to canonical allocation rows
        └── XXX_EARMARK_ALLOCATION
```

The two branches are separate because the search problems differ.

- The census seeks every charge-creating provision.
- The earmark branch seeks relatively sparse assignment clauses and places a higher priority on avoiding false negatives.

---

# 4. Country corpus construction

## 4.1 One country at a time

Extraction is performed country by country. Each country has its own document library, manifest, intermediate outputs, reconciliation decisions, and final tables.

This isolates legal systems and prevents documents, identifiers, or decisions from one country from contaminating another.

## 4.2 Document manifest

Each legal source is registered before extraction. The manifest supplies the parameters used by the prompts and the orchestration layer.

At minimum, it records:

- `country`;
- `document_id`, unique within the country;
- `document_type`;
- `document_year`;
- canonical file name or path;
- language;
- section scope;
- whether the document is used for the census;
- whether the document is used for earmark extraction;
- structural parameters;
- extraction status; and
- whether the text is consolidated, amending, subsidiary, or otherwise limited.

A document marked for extraction but missing its output file is a hard stop during reconciliation. It is not treated as a silent zero.

## 4.3 Francophone legal corpus

For Francophone countries, the core source is normally the most recent available **Code général des impôts** or equivalent consolidated tax code.

The code often provides a broad view of the revenue system in one volume. It may also reproduce or append:

- parafiscal texts;
- sectoral tax provisions;
- local-government taxation rules;
- decrees and regulatory texts; and
- tables or schedules.

Possible extensions include:

- annexes fiscales;
- initial finance laws;
- sectoral codes;
- fund-establishing laws; and
- other legal texts needed to complete a source or allocation chain.

Rectifying finance laws are excluded from the first de jure structural pass unless inspection shows that they create, repeal, or change an allocation structure rather than only revising amounts.

## 4.4 Anglophone legal corpus

Anglophone systems commonly distribute the relevant law across several Acts. A single consolidated tax code may not provide a complete view.

The preliminary legal-library step therefore reconstructs the legislative chain. Sources can include:

- consolidated principal tax Acts;
- levy-specific Acts;
- finance Acts;
- fund or agency establishing Acts;
- tax-administration Acts;
- appropriation or budget Acts where they contain operative provisions;
- schedules;
- regulations or statutory instruments; and
- current amendments.

The most recent budget documents and revenue-administration publications are used to identify the universe of taxes and levies that must be traced. They are discovery and coverage tools. They do not replace the enacting legal evidence unless the budget law itself contains the operative charging or assignment clause.

Where a government publishes a list of earmarked revenues and destination funds, as in the Ghana budget materials used in the project, the list can reduce the number of documents that must be searched. The final database still requires legal evidence for the source and assignment.

## 4.5 Canonical files

The pipeline works from a canonical local copy of each legal source. This avoids changes caused by application uploads, decomposed PDFs, broken text layers, or inconsistent page numbering.

Every page anchor refers to the 1-based page index of the canonical file, not the printed folio.

---

# 5. Common document-adaptation procedure

The legal definition and schema remain fixed across countries. Only the reading procedure changes with document structure.

## 5.1 Structural parameter vector

Before retrieval, each document is described by the following vector.

| Parameter | Typical values | What it controls |
|---|---|---|
| `language` | `fr`, `en`, other | Search grammar |
| `column_layout` | `single`, `double`, `detect` | Reading order and cropping |
| `length_class` | short, long | Single pass or sectioned work |
| `earmark_density` | concentrated, sparse | Enumerate-all or locate-then-extract |
| `content_form` | prose, table, mixed | Clause or structural table handling |
| `numbering` | article, section, book+article, line item, none | Coverage unit |

The adapter is parameterized by structure rather than by a document-type label. Two tax codes with different column layouts use the same substantive method and different reading parameters.

## 5.2 Preprocessing gate

Every run certifies the canonical file before extraction.

The gate checks:

1. file format and page count;
2. clean and usable text encoding;
3. language-specific characters and symbols;
4. internal title and year;
5. a coherent mid-document text sample; and
6. column reading order.

A failed gate stops the run. The document is repaired, re-extracted, or routed to OCR with page anchors preserved. Load-bearing figures and clauses are then verified against page images.

## 5.3 Column handling

Double-column legal texts can interleave unrelated clauses if text is read linearly.

The pipeline therefore:

- detects margins and gutters;
- tests column structure by page rather than assuming one layout for the full document;
- handles mirror margins on odd and even pages;
- splits characters by position before assembling lines; and
- performs a canary test on a representative legal clause.

Shares and rates are never extracted from interleaved text.

## 5.4 Sectioning long documents

Long documents are divided by their own top-level structure. Examples are books, chapters, parts, section ranges, or appended texts.

The document is not treated as one unstructured prompt. Each section is processed independently and remains traceable to the fixed coverage map.

This reduces attention loss. The coverage report then verifies that all divisions were processed.

## 5.5 Language-specific retrieval grammar

The search is instrument- and fund-agnostic. The beneficiary is an output of the search, not an input checklist.

Typical French assignment cues include:

```text
affecté, affectation, au profit de, réparti, répartition,
quote-part, quotité, produit de la taxe, reversé, alimente,
ristourne, compte spécial, compte d'affectation
```

Typical English cues include:

```text
earmarked, dedicated, allocated, appropriated to, paid into,
paid over to, credited to, shall accrue to, transferred to,
retained by, used exclusively for, for the credit of,
distributed as follows, levied for the purpose of
```

The census uses charge-creation grammar rather than assignment grammar. Examples include `il est institué`, `il est créé`, `il est perçu`, `there shall be levied`, `is imposed`, `is charged`, and `shall be payable`.

## 5.6 Table regions

A bare fund name and budget amount do not establish a legal assignment.

In table regions:

- evidence rows are created only when a row or label itself contains a source instrument and assignment language;
- budget-credit lines without an assignment clause are not converted into earmark evidence;
- budgeted amounts, when collected, belong in a separate account-by-year table; and
- appropriation amounts are not treated as execution.

---

# 6. Database 1: revenue instrument census

## 6.1 Purpose and unit

The census records every distinct revenue instrument that the selected legal corpus institutes or provides for, whether earmarked or not.

The final country-level unit is:

> one distinct revenue instrument in the selected legal corpus.

The census contains no destination, beneficiary, allocation, or purpose-restriction fields. It also does not create downstream `revenue_class`, `tax_type`, or `economic_type` classifications during extraction.

## 6.2 Per-document census extraction

### Step 1. Certify and cache the file

The canonical file is certified through the preprocessing gate. Character data are extracted once and cached. Later steps read the cache rather than repeatedly extracting the PDF.

### Step 2. Fix the coverage divisions

The document's top-level divisions are listed before extraction. Each appended text is treated as a division. This list is the fixed unit of work and coverage.

Long divisions can be split into contiguous page ranges. A work unit never straddles two top-level divisions. Independent division sweeps can be launched concurrently, but they return to one document-level assembly and one output file.

### Step 3. Sweep every division

The LLM searches for charge-creating provisions and applies the census grain rules.

The main rules are:

- one distinct instrument produces one row;
- a tariff schedule is not several instruments when it varies only by class, size, category, or band;
- different goods or activities taxed separately can produce separate instruments;
- a charge owed in addition to another charge is a separate instrument;
- a creditable advance, minimum, or withholding is folded into the parent instrument;
- a final, non-creditable charge can be a separate instrument;
- a repeal is recorded with `in_force = 0`, not dropped; and
- a provision named only by cross-reference can be retained with `evidence_status = referenced_not_enacted_here`.

The taxed sector is coded from the base using ISIC Rev.4. It is never inferred from the destination or collecting authority.

### Step 4. Assemble and merge within the document

Rows from all divisions are assembled.

If the same instrument appears in several divisions, the row that best states the base and rate is kept. Other mentions are folded into `additional_mentions`.

The final division counts are recomputed after merging. They are not copied from pre-merge sweep counts.

### Step 5. Completeness check

The document's index or table of contents is used as an independent cue list. It can reveal charge names that were missed during the body sweep.

Index entries are not themselves enacting evidence. They are used only to test omission.

### Step 6. Validation

The census file is not written unless the hard checks pass. Checks cover:

- unique identifiers;
- mandatory fields;
- valid categories;
- page-anchor ranges;
- rate coherence;
- penalty evidence;
- sector coding;
- recorded boundary judgments;
- closed coverage totals;
- repeal consistency; and
- absence of unaddressed duplicate instruments.

### Per-document output

Each document produces:

```text
{country}_{document_id}_CENSUS.json
```

with three objects:

- `census_rows`;
- `coverage_check`; and
- `run_meta`.

The equivalent spreadsheet rendering uses `census_table`, `COVERAGE_CHECK`, and `RUN_META` sheets.

## 6.3 Country-level census reconciliation

Country-level reconciliation is required when several legal documents were used for the census. This is especially important in Anglophone systems. Reconciliation reads the completed census files only; it does not reopen or re-extract the source PDFs.

### Step 1. Inventory and validate census files

All country census files are listed and checked against the manifest. The schemas must match. Extracted `instrument_id` values must still be blank.

### Step 2. Stack without changing source rows

All `census_rows` are concatenated. The stacked count must equal the sum of input row counts.

### Step 3. Generate candidate matches

Cross-document identity uses:

- normalized full name;
- taxed base;
- instrument nature;
- ISIC sector and division; and
- penalty status.

Name alone never establishes identity. A base match is required.

The following are never automatically merged:

- a penalty and the obligation it enforces;
- a rate-point increment and its parent;
- charges owed cumulatively;
- an instrument and its legal replacement; and
- two rows from the same document, because intra-document merging should already have occurred.

### Step 4. Select the surviving country record

For confirmed duplicate groups, the first decisive rule is used:

1. `attested` evidence beats `referenced_not_enacted_here`;
2. a row stating the base and rate beats a row that only defers or cross-refers;
3. a newly instituted row beats an amendment-only row;
4. the most recent document year wins; and
5. a stable evidence-ID tie-break is used only if the earlier rules do not decide.

`in_force_reconciled` is determined from the most recent document that speaks to the instrument, even when another row is selected as the survivor.

### Step 5. Assign country instrument IDs

Surviving rows receive:

```text
{country}_INS_{NNNN}
```

The original extracted fields remain unchanged. Reconciliation information is appended in new columns.

### Step 6. Save the country census

The multi-document output is:

```text
{country}_CENSUS_MASTER.json
```

For cross-country analysis, this master table is the country `XXX_CENSUS` table.

It contains:

- one surviving row per distinct country instrument;
- a duplicate log;
- a document index; and
- run metadata with contestable merges and non-merges.

## 6.4 Denominator construction

A count-based denominator must state its filters.

A common current-instrument denominator is:

```text
count(distinct census instrument_id)
where in_force_reconciled == 1
```

When no multi-document reconciliation was needed, `in_force` is used instead of `in_force_reconciled`.

Additional choices must be explicit, especially:

- whether penalties are included;
- whether `referenced_not_enacted_here` rows are included;
- whether repealed instruments are included; and
- whether the document library is sufficiently complete for the country.

A count from an incomplete source universe is not interpreted as the complete tax system.

---

# 7. Database 2: statutory allocation and earmark extraction

## 7.1 Why the task is split into stages

Allocation clauses are often sparse, legally complex, and separated from the source provision. A direct full-schema extraction from several hundred pages has a high false-negative risk.

The pipeline separates:

1. passage location;
2. field extraction;
3. entity reconciliation;
4. census matching;
5. destination-function coding; and
6. final filtering.

Each stage has a narrow task and its own audit output.

## 7.2 LOCATE: high-recall passage inventory

### Objective

The LOCATE stage searches the entire document for possible assignment clauses. It optimizes recall over precision.

It does not populate the evidence schema. It does not decide whether a passage is a functional earmark, tax sharing, cost recovery, or a false positive.

### Procedure

The LLM sweeps every division using assignment grammar. It flags passages that may concern:

- an earmark;
- tax sharing;
- a retained collection share;
- a general-budget allocation;
- a cost-recovery component; or
- an ambiguous transfer.

The worklist is fund-agnostic. Known recipients are not used as an allow-list.

### Table-region guard

In budget or appropriation tables, bare fund-name and amount lines are not individually inventoried. The coverage certificate records that the region was examined and contained no assignment clause.

### LOCATE outputs

Each document produces:

```text
{country}_{document_id}_LOCATE.json
```

with:

1. `passage_inventory`; and
2. `sweep_coverage_certificate`.

The passage inventory records:

- legal unit reference;
- pages;
- exact trigger cue;
- source-instrument hint;
- recipient hint;
- non-binding preliminary flag; and
- handoff notes.

The coverage certificate lists contiguous divisions from the start to the end of the scope. A division with no hits is recorded as checked, not silently omitted.

## 7.3 EXTRACT: clause-level evidence table

### Objective

The EXTRACT stage converts legal clauses into the full evidence schema.

The LOCATE inventory is the worklist, but EXTRACT performs an independent recall check. This permits recovery of passages missed by LOCATE.

### Core extraction rules

The extraction applies the following rules:

- enacting text only;
- one row per clause and fact;
- separate `source` and `allocation` rows;
- one allocation row per destination;
- instrument rather than article as the substantive unit;
- no synthetic `instrument_id` or `pair_id` during extraction;
- verbatim excerpt and page anchor on every row;
- no invented destination, share, rate, or legal relationship;
- uncertainty recorded in notes and confidence fields;
- lineage signals captured only when stated in the text; and
- provisional change flags finalized later.

### Rate and share representation

Rates and shares are represented by separate value, type, and basis fields.

Examples:

- an explicit 5 percent share: `share_value = 5`, `share_type = pct`, `share_basis = stated`;
- full proceeds assigned with no number: `share_value = null`, `share_basis = whole_proceeds_implied`;
- a share set by a later regulation: `share_value = null`, `share_basis = deferred_arrete`;
- a banded rate: scalar value null, schedule flag one, schedule copied verbatim; and
- an amount per litre: amount preserved as written, not converted to a percentage.

### Cost recovery

A component that pays for the service the payer is receiving is classified as:

```text
allocation_nature = cost_recovery_component
```

A share that finances an external fund, programme, sector, or an agency's substantive mandate is:

```text
allocation_nature = proceeds_share
```

When the collector is also a beneficiary, the question is whether the retained amount finances collection of that specific levy or the body's substantive mandate.

### Purpose restriction

The destination is classified by use restriction, not recipient form.

- `is_purpose_restricted = 1`: proceeds are restricted to a function, fund, programme, or specific use.
- `is_purpose_restricted = 0`: the transfer is available for the recipient's general budget or unrestricted use.

### Batch boundaries

When a long document is extracted in sections, a partial allocation key at a section boundary does not trigger a schema failure. It receives `partial_key = 1` and a note identifying the suspected remainder.

### EXTRACT outputs and audits

Each extraction output contains the evidence rows and the audit envelope.

```text
{country}_{document_id}_EXTRACT_{scope_slug}.json
```

The audit components are:

- `coverage_report`;
- `recall_audit`;
- `locate_reconciliation`;
- `gold_scoring`;
- `field_exercise_note`;
- `confidence_reasons`;
- `schema_stress_note`; and
- `run_meta`.

The LOCATE reconciliation uses:

- `N`: inventory entries in scope;
- `M`: entries extracted;
- `K`: entries dismissed with reasons; and
- `J`: extracted passages not present in the inventory.

The required identity is:

```text
M + K = N
```

If `J > 0`, the LOCATE inventory is marked incomplete and amended. The amendment is logged.

## 7.4 Reconciliation of earmark evidence

Reconciliation assigns entity IDs only after the complete evidence set is visible.

### R1. Grain resolution

Rows are classified as:

- an instrument;
- a share or sub-scope of a parent instrument; or
- a pool or container that should not be counted as an additional instrument.

Pool classification is conservative. When uncertain, the row remains an instrument and the uncertainty is reported.

### R2. Instrument identity

Identity uses the normalized name, base, payer, and legal continuity signals. Name alone is weak evidence.

Hard cases are not resolved by string similarity. Conflicting excerpts are compared under the legal continuity and replacement rules.

### R3. Pair identity

Channels are assigned by instrument, normalized recipient, allocation level, parent pool, and base scope.

A Treasury account that routes money to a named beneficiary is a route, not a second destination.

### R4. Duplicate channel statements

Duplicate allocation statements share a `pair_id`.

The governing row is selected by the first decisive rule:

1. stated share beats a null share;
2. a full key beats `partial_key = 1`;
3. `stated` beats `whole_proceeds_implied`, which beats `deferred_arrete`;
4. the code body beats an annex; and
5. the earliest ID is used only as an arbitrary final tie-break.

Other rows are retained as `restatement` in the reconciled evidence file.

### R5. Duplicate source statements

One source row is kept per instrument, using the code body, completeness, and stable ID ordering. Rate differences are flagged.

### R6. Repeal and replacement

An expressly replaced predecessor present in the corpus is closed and removed with its allocations. A predecessor named but absent from the corpus is retained only as a lineage signal.

### R7. Source-only instruments

Source-only instruments remain in the reconciled evidence file. Their missing allocation can mean the destination is in an unavailable subordinate text. It is not automatically evidence of no destination.

### R8. Joint keys

When one allocation key applies jointly to two separately instituted levies, the allocation evidence is attached to both. The joint shares are not summed across the two instruments.

### R9. Legal conflict flags

Conflicts are recorded at instrument level:

- `none`;
- `competing_share`;
- `competing_rate`;
- `stated_inconsistency`; or
- combinations joined with `+`.

Differences that concern distinct base scopes are not treated as conflicts.

### Reconciled output

For a single consolidated corpus, reconciliation produces:

```text
{country}_{document_id}_RECONCILED.json
```

The output retains the evidence schema and adds:

- `instrument_id`;
- `pair_id`;
- `pair_row_role`;
- `base_scope`; and
- `intra_document_conflict`.

It also contains a reconciliation summary and decision log.

The reconciliation summary can report a broad non-general-budget channel count for internal diagnostics, with cost-recovery and unrestricted subnational channels shown separately. That diagnostic count is not automatically the strict functional-earmark numerator used in analysis. The strict analytical filter remains `allocation_nature == "proceeds_share"` and `is_purpose_restricted == 1`.

## 7.5 Anglophone stack-first reconciliation

Anglophone extraction produces several document-level evidence files. The country must be reconciled once, after stacking all files.

### Step 1. Inventory all extraction outputs

All files matching the country extraction pattern are listed and checked against the manifest.

### Step 2. Validate the stack

The following are required:

- identical evidence schemas;
- blank `instrument_id` and `pair_id` before reconciliation; and
- unique `(document_id, evidence_id)` combinations.

### Step 3. Make evidence IDs globally unique

Document-level IDs can restart at one. Before stacking, each is rewritten as:

```text
{document_id}::{evidence_id}
```

The original value is retained in `evidence_id_source`.

### Step 4. Stack all rows

All evidence rows are concatenated without changing their substantive fields. The stacked count must equal the sum of the document counts.

### Step 5. Reconcile once across the country corpus

Instrument and pair identity are resolved across Acts. This permits a charging clause in one Act to connect to an assignment clause in another.

Document precedence is used only after substantive criteria fail:

1. principal Act over amending or subsidiary Act;
2. more recent document year; and
3. earliest globally unique evidence ID as a provisional tie-break.

Conflict flags can reflect within-document or cross-document contradictions. The existing field name is retained, and the conflict scope is recorded in the summary.

### Anglophone output

The country-wide reconciled file is:

```text
{country}_ALL_RECONCILED.json
```

The summary reports the number of instruments whose source and allocation rows came from different documents. This is a substantive feature of the Anglophone legal architecture.

## 7.6 Joining the allocation layer to the census

The `census_ref` stage links each reconciled earmark instrument to its census counterpart.

### Matching unit

Matching is performed once per `instrument_id`. The same `census_ref` array is written to all source and allocation rows sharing that instrument.

### Matching evidence

The strongest evidence is:

- `tax_base_detail`;
- `verbatim_excerpt`;
- literal instrument label;
- additional legal mentions;
- enabling reference;
- rate fields; and
- base-sector information.

Article and page agreement are corroborating evidence only. The source clause and allocation clause can sit in different legal provisions or different Acts.

### Many-to-many accommodation

`census_ref` is an array because:

- one earmark instrument may correspond to several census rows when the census splits distinct bases; and
- several earmark-layer instruments may point to one census row when the census folds collection modalities into a parent.

No candidate is forced. Unmatched or tied cases are flagged for human review.

### Output

The stage produces:

```text
{country}_{document_id}_CENSUS_REF.json
```

or the equivalent country-wide Anglophone file. The evidence rows are unchanged except for the added `census_ref` field.

## 7.7 Destination-function classification

Each allocation row is classified by the function financed using four-digit COFOG groups.

The classification uses the legal document only. Later web information is not used because it could contaminate the legal snapshot.

The function is derived from the destination and the enacting excerpt.

The main rules are:

- code the function financed, not the legal form of the recipient;
- do not infer the destination function from the taxed sector;
- code regulators and administrators inside the substantive function they regulate;
- code sector-specific research and development inside that function, reserving `7014` for basic research without a sectoral purpose;
- treat a routing account as a route, not a function;
- use `general_budget` for an unrestricted central budget;
- use `local_budget` for an unrestricted territorial budget;
- use `unallocated` when no function can be identified without invention;
- use the appropriate `n.e.c.` group when the division is known but the group is not; and
- preserve multiple stated functions without splitting or inventing weights; and
- when several functions are stated, use the first function as the primary code and record the others in statement order.

Four columns are added:

- `destination_function`;
- `destination_function_basis`;
- `destination_function_multi`; and
- `destination_function_detail`.

The output is conventionally named:

```text
{country}_{document_id}_EARMARKS.json
```

This file is still the full reconciled evidence layer. It contains source rows, allocation rows, and possible restatements.

## 7.8 Final scripted filtering

`filter_allocations.py` converts the enriched evidence file into the final allocation table.

The script applies structural rather than substantive earmark filters:

```text
keep row_type == "allocation"
keep pair_row_role != "restatement"
```

This means:

- all source rows are removed;
- `governing` rows are retained;
- single-statement allocation rows, whose `pair_row_role` is blank, are retained; and
- duplicate restatement rows are removed from the analytical table.

The script writes:

```text
XXX_EARMARK_ALLOCATION.json
```

The output is broad. It still contains functional earmarks, unrestricted tax sharing, general-budget residuals, equalization arrangements, and cost-recovery components. These are distinguished by variables.

The strict earmark subset is selected later with:

```text
allocation_nature == "proceeds_share"
and is_purpose_restricted == 1
```

## 7.9 Numerator and allocation-link counts

Different questions require different counts.

### Earmarked-instrument numerator

For an instrument-prevalence ratio, count distinct census instruments linked to strict earmarks:

```text
N = count(distinct flattened census_ref)
    among strict earmark rows
```

An instrument with four earmark destinations counts once in this numerator.

### Allocation-link count

For the density of statutory routing, count:

```text
M = count(distinct pair_id)
```

This measures channels, not instruments.

### Instrument prevalence

A count-based prevalence measure is:

```text
N / D
```

where `D` is the declared census denominator.

The measure is a share of instruments. It is not a share of revenue collections. A revenue-weighted measure requires separate revenue data.

---

# 8. Francophone and Anglophone end-to-end workflows

## 8.1 Francophone end-to-end sequence

1. Create the country project, manifest, and canonical legal library.
2. Use the latest available CGI or equivalent consolidated code as the core source. Add fiscal annexes, finance laws, sectoral texts, or fund laws only when they extend the selected scope.
3. Run the whole-document census and validate `{country}_{document_id}_CENSUS`. Reconcile census files only when several overlapping source documents were used.
4. Run LOCATE over every earmark-source document and certify complete coverage.
5. Run EXTRACT on the located passages, sectioning long texts when necessary.
6. Reconcile the complete country evidence set to assign `instrument_id` and `pair_id`, resolve restatements, and record conflicts.
7. Attach `census_ref` to each reconciled instrument.
8. Add the four destination-function fields using COFOG.
9. Run `filter_allocations.py` to create `XXX_EARMARK_ALLOCATION`.
10. Apply the declared analytical filters and calculate the numerator and denominator.

## 8.2 Anglophone end-to-end sequence

1. Create the country project and reconstruct the legal ecosystem from current budget, tax-administration, and revenue lists.
2. Build a manifest of principal tax Acts, levy-specific Acts, fund Acts, finance Acts, schedules, regulations, and relevant amendments.
3. Run one census extraction per legal document. Several document jobs can be launched together as an operational batch, but each document remains separately identified and auditable.
4. Stack and reconcile the census files to produce `{country}_CENSUS_MASTER`.
5. Run LOCATE separately on each earmark-source document.
6. Run document-level EXTRACT jobs in parallel where the documents are independent.
7. Make evidence IDs globally unique, stack every extraction output, and reconcile the country once across all Acts.
8. Link the reconciled earmark instruments to the country census master through `census_ref`.
9. Add COFOG destination functions.
10. Run the allocation filter to create `XXX_EARMARK_ALLOCATION`.
11. Close the manifest, row-count, conflict, unmatched-link, and coverage checks before analysis.

## 8.3 Comparison

| Stage | Francophone workflow | Anglophone workflow |
|---|---|---|
| Core legal library | Most recent CGI or equivalent consolidated code | Several principal, levy, fund, finance, and subsidiary Acts |
| Preliminary coverage | Confirm the consolidated volume and possible extensions | Reconstruct the tax-and-fund legislative chain from budget and revenue lists |
| Census extraction | Usually one large whole-document census | One census per document, with several document jobs optionally launched as a batch |
| Census reconciliation | Limited when one consolidated corpus is used; required if extensions overlap | Required across all census files |
| LOCATE | Usually one long sparse code, sectioned by book/division | One LOCATE file per Act or document |
| EXTRACT | Often one consolidated whole-document evidence file | Several document-level evidence files, often processed in parallel |
| Earmark reconciliation | Resolve repetitions and contradictions within the consolidated corpus | Stack all Acts first, then reconcile once across the country |
| Main legal risk | Outdated annexes, duplicate provisions, nested keys, mixed layouts | Source and allocation in different Acts, overlapping amendments, inconsistent names |
| Orchestration gain | Reliable loading, local saving, and sectioned handling of a very large file | Parallel document extraction and a final country-wide stack |

The substantive definition, schema, null rules, evidence requirements, and audit requirements remain the same in both systems.

---

# 9. Cowork and LLM execution design

## 9.1 One Cowork project per country

A separate Cowork project is used for each country. The country project contains its own legal library, prompts, intermediate outputs, and reconciliation products.

This reduces cross-country contamination and keeps file references manageable.

## 9.2 One task or session per stage

A new Cowork task or LLM session is opened for each major stage or document extraction.

Examples are:

- one census extraction task;
- one LOCATE task;
- one EXTRACT task per document or batch;
- one reconciliation task;
- one census-reference task; and
- one destination-function task.

This keeps the context narrow and makes failures easier to isolate and rerun.

## 9.3 Local handling of large files

Large legal documents are uploaded once to the country project and saved locally. The canonical local copy is reused across tasks.

This reduces repeated transfer, avoids application-level file decomposition, and preserves consistent page anchors.

## 9.4 Parallel Anglophone extraction

Independent Anglophone Acts can be processed in parallel. Parallelism is used only for document-local tasks.

Country-level identity is not decided in parallel. All document outputs are stacked and reconciled once after the document-level runs finish.

## 9.5 Authority of governing files

The orchestration layer manages loading, task division, saving, and parallel execution. It does not change substantive decisions.

The authoritative hierarchy is:

1. data dictionary and core method;
2. decision and reconciliation rules;
3. stage prompt;
4. country manifest and structural parameters; and
5. orchestration instructions.

---

# 10. Quality assurance and audit trail

## 10.1 Hard-stop conditions

A run stops when it encounters a defect that would undermine comparability or evidence integrity. Examples include:

- corrupt or unreadable canonical file;
- failed column-order test;
- missing document required by the manifest;
- mismatched schemas;
- duplicate identifiers;
- non-closed coverage report;
- a genuine new schema pattern that cannot be represented;
- row-count mismatch after stacking or filtering;
- allocation rows without `pair_id` after reconciliation;
- source rows with `pair_id`;
- inconsistent `census_ref` values within one `instrument_id`; or
- an output that changes original evidence fields without authorization.

## 10.2 Human-review worklist

The pipeline records contestable cases rather than hiding them.

Review priorities include:

- `ai_confidence = medium` or `low`;
- non-empty `boundary_calls`;
- `source_internal_inconsistency`;
- non-`none` conflict flags;
- `partial_key = 1`;
- collector-share and cost-recovery judgments;
- `is_purpose_restricted = 0` boundary cases;
- `share_level > 1`;
- inferred destination functions;
- `destination_function = unallocated`; and
- unmatched or tied `census_ref` candidates.

## 10.3 No silent correction

The extraction layer preserves the legal text and records uncertainty. Reconciliation adds derived IDs and decisions. It does not rewrite the underlying evidence.

Duplicate and rejected evidence remains recoverable through logs or upstream files.

## 10.4 Completeness verification

Completeness is supported by several independent checks:

- top-level coverage maps;
- contiguous sweep certificates;
- assignment-grammar recall audits;
- LOCATE-to-EXTRACT reconciliation;
- census index reconciliation;
- row-count identities;
- manifest-to-output reconciliation; and
- optional gold-case scoring.

These checks do not mathematically prove perfect recall. They make omissions visible and reproducible.

---

# 11. Why this method is valuable

The method has six main advantages.

1. **It separates legal evidence from analytical judgment.** Every hand-built fact remains anchored to an exact clause and page.
2. **It reduces false negatives in long legal texts.** LOCATE, sectioning, and coverage certificates make the search process explicit.
3. **It is comparable across legal systems.** The substantive core remains fixed while the retrieval adapter changes with document structure.
4. **It handles common-law fragmentation.** Source and destination clauses can be connected across several Acts through country-wide reconciliation.
5. **It preserves alternative definitions.** Tax sharing, cost recovery, and functional earmarks are recorded separately rather than silently pooled or discarded.
6. **It creates a defensible denominator.** The census and `census_ref` link prevent multi-beneficiary instruments from being counted several times in the earmark prevalence ratio.

---

# 12. Interpretation and limitations

## 12.1 De jure, not de facto

The database records legal assignment. It does not show whether money was collected, transferred, spent, or used for the stated purpose.

Revenue-mobilization, additionality, and fungibility questions require separate execution and expenditure data.

## 12.2 Document availability

Coverage depends on the official or otherwise authoritative legal texts that could be obtained. Missing subordinate instruments are unobserved, not zero.

Document availability can differ systematically across countries. This must be considered in cross-country analysis.

## 12.3 Count-based prevalence

The census ratio measures the share of instruments with an earmark. It does not measure the share of total revenue that is earmarked.

## 12.4 Current snapshot

A latest-law snapshot cannot identify the historical creation date or reform path unless earlier legal corpora are added.

## 12.5 Definition sensitivity

Results depend on declared filters, especially for:

- penalties;
- equalization transfers;
- tax sharing;
- collector retention;
- administrative cost recovery; and
- unrestricted subnational transfers.

The broad construction layer permits these alternatives to be tested without re-extraction.

---

# Annex A. Output table `XXX_CENSUS`

## A.1 Unit of observation

One row represents one distinct revenue instrument in the country legal corpus after within-document and, where needed, cross-document reconciliation.

## A.2 Recommended primary key

- Multi-document country master: `instrument_id`.
- Single-document unreconciled census: `evidence_id`, with `instrument_id` blank until a later country-level reconciliation.

## A.3 Source-side role

This table is the authoritative source for:

- instrument identity;
- taxed base;
- legal label;
- sector of the taxed base;
- rate structure;
- penalty status;
- in-force status; and
- denominator construction.

It contains no allocation-side fields.

## A.4 Core variable dictionary

### A.4.1 Identifiers and legal provenance

| Variable | Type or categories | Meaning |
|---|---|---|
| `evidence_id` | string | Per-document census evidence ID: `{country}_{document_id}_CEN_{NNNN}`. |
| `row_type` | `source` | Constant in the census. |
| `country` | ISO3 | Country code. |
| `instrument_id` | string, initially null | Country-level revenue-instrument ID assigned in reconciliation. |
| `document_id` | string | Stable identifier for the canonical legal source. |
| `document_type` | enum | Core values include `annexe_fiscale`, `loi_finances_initiale`, `cgi`; Anglophone values are added consistently, such as `establishing_act`, `principal_tax_act`, `finance_act`, `consolidated_tax_act`, `tax_administration_act`, and `appropriation_act`. |
| `document_year` | integer stored as text or integer | Year of the legal document, not necessarily instrument creation year. |
| `legal_article` | string | Instituting article, section, schedule, or legal unit. |
| `page_start` | integer | First 1-based canonical-PDF page. |
| `page_end` | integer | Last 1-based canonical-PDF page. |

### A.4.2 Instrument identity and status

| Variable | Type or categories | Meaning |
|---|---|---|
| `official_name` | verbatim string | Full legal designation with distinguishing qualifiers. |
| `official_name_underspecified` | `0`, `1` | One when the legal name is generic and requires the base or notes to distinguish it. |
| `in_force` | `0`, `1` | Document-local status. Zero only when the document itself records repeal, abolition, or suspension. |
| `tax_instrument` | enum | `VAT`, `excise`, `fuel_levy`, `telecom_levy`, `environmental_tax`, `payroll_tax`, `resource_revenue`, `redevance`, `parafiscal_contribution`, `fine`, `other`. It is a compatibility tag, not the preferred analytical classification. |
| `instrument_label_verbatim` | verbatim string | Literal legal label, such as tax, duty, levy, fee, redevance, or contribution. |
| `instrument_nature` | open short tag | More specific nature, such as `corporate_income_tax`, `stamp_duty`, or `mining_royalty`. The enum remains open. |
| `is_penalty` | `0`, `1` | One when the legal text characterizes the charge as a fine, penalty, surcharge, forfeiture, or non-compliance sanction. |
| `evidence_status` | enum | `attested` or `referenced_not_enacted_here`. |

### A.4.3 Taxed base and sector

| Variable | Type or categories | Meaning |
|---|---|---|
| `tax_base_detail` | string, mandatory | Verbatim or near-verbatim description of what is taxed. |
| `base_sector` | closed enum | ISIC Rev.4 section of the taxed activity, plus two special values. The destination never determines this field. |
| `base_division` | string `01`–`99` or null | ISIC two-digit division when the legal base supports that precision. |

#### `base_sector` categories

| Code | Stored value | Coverage |
|---|---|---|
| A | `A_agriculture_forestry_fishing` | ISIC 01–03 |
| B | `B_mining_quarrying` | 05–09 |
| C | `C_manufacturing` | 10–33 |
| D | `D_electricity_gas` | 35 |
| E | `E_water_waste` | 36–39 |
| F | `F_construction` | 41–43 |
| G | `G_trade` | 45–47 |
| H | `H_transport_storage` | 49–53 |
| I | `I_accommodation_food` | 55–56 |
| J | `J_information_communication` | 58–63 |
| K | `K_financial_insurance` | 64–66 |
| L | `L_real_estate` | 68 |
| M | `M_professional_technical` | 69–75 |
| N | `N_admin_support` | 77–82 |
| O | `O_public_administration` | 84 |
| P | `P_education` | 85 |
| Q | `Q_health_social` | 86–88 |
| R | `R_arts_entertainment` | 90–93 |
| S | `S_other_services` | 94–96 |
| T | `T_households_employers` | 97–98 |
| U | `U_extraterritorial` | 99 |
| — | `general_economy_wide` | Base spans the economy, such as VAT or general profits taxation. |
| — | `not_applicable` | Base is not an economic activity, such as a poll or civic charge. |

### A.4.4 Rate variables

| Variable | Type or categories | Meaning |
|---|---|---|
| `rate_value` | numeric or null | Scalar rate or statutory bound. Null for schedules, deferrals, and cross-references. |
| `rate_is_schedule` | `0`, `1`, null | One when the rate is banded or scheduled. |
| `rate_schedule_detail` | string or null | Full schedule copied from the legal text. |
| `rate_type` | enum | `ad_valorem_pct`, `per_unit_amount`, `fixed_amount`, `amount_per_unit_of_base`, `rate_point_increment`. |
| `rate_basis` | enum | `stated`, `banded`, `deferred_subordinate_act`, `cross_reference`, `ceiling_delegated`, `floor_delegated`, `increment_on_other_instrument`, `not_applicable`. |
| `rate_base_quantum` | numeric or null | Monetary quantum when a rate is stated per monetary unit of base, for example 3 per 1,000. |
| `rate_reference_instrument` | verbatim string or null | Parent instrument when the legal rule adds rate points to another instrument. |

### A.4.5 Legal change and evidence fields

| Variable | Type or categories | Meaning |
|---|---|---|
| `change_type` | enum | `new`, `amendment_rate`, `amendment_base`, `amendment_key`, `merger`, `split`, `replacement`, `repeal`, `none`. Document-local and provisional at extraction. |
| `enabling_reference` | string or null | Founding or cited legal text named by the clause. |
| `verbatim_excerpt` | string, mandatory | Exact instituting or principal legal clause. |
| `additional_mentions` | list or null | Other articles or provisions for the same instrument, including folded collection modalities. Each item has article, pages, change type, and excerpt. |
| `source_internal_inconsistency` | string or null | Drafting inconsistency preserved without changing other fields. |
| `ai_confidence` | `high`, `medium`, `low` | Model confidence in the extracted row. |
| `human_validation_status` | `unchecked`, `validated`, `corrected`, `rejected` | Human-review status. |
| `notes` | string or null | Reasoning, ambiguity, and review explanation. |
| `boundary_calls` | list | Any of `instrument_merge`, `fold_into_parent`, `container_decomposition`, `base_sector`, `is_penalty`, `referenced_not_enacted`, `rate_bound`, `in_force`. |

## A.5 Country-reconciliation variables

These columns are appended when several document-level census files are reconciled.

| Variable | Type or categories | Meaning |
|---|---|---|
| `duplicate_group_id` | string or null | Cross-document duplicate group. |
| `n_documents` | integer | Number of source documents in the group. |
| `source_documents` | list | Documents that attest the instrument. |
| `survivor_rule` | string | First rule in the survivor ladder that decided the retained row. |
| `in_force_reconciled` | `0`, `1` | Country-level current status based on the most recent document that speaks to the instrument. |
| `in_force_source` | structured string or object | Document and legal unit supporting the reconciled status. |
| `reconciliation_note` | string | Rate disagreement, identity reasoning, or legitimate non-merge. |

## A.6 Recommended denominator fields

For current cross-country counts, the most important fields are:

- `instrument_id`;
- `in_force_reconciled` or `in_force`;
- `is_penalty`;
- `evidence_status`;
- `source_documents`; and
- country coverage metadata.

---

# Annex B. Output table `XXX_EARMARK_ALLOCATION`

## B.1 Unit of observation

The intended analytical unit is one canonical statutory allocation channel.

The primary key is `pair_id` after removing rows marked `restatement`.

A row represents:

```text
one revenue instrument
→ one recipient or purpose
at one share level
within one parent pool and base scope
```

## B.2 Inclusion rule

The script keeps:

```text
row_type == "allocation"
and pair_row_role != "restatement"
```

The table is therefore broader than the strict earmark subset.

## B.3 Relationship to the census

`census_ref` links each allocation channel to one or more census instruments.

Allocation rows can have null source-side fields because the source and assignment are separate evidence facts. The authoritative base, rate, penalty, and in-force fields should be obtained through the census join rather than inferred from the destination row.

## B.4 Variable dictionary

### B.4.1 Identifiers, provenance, and joins

| Variable | Type or categories | Meaning in the final allocation table |
|---|---|---|
| `evidence_id` | string | Evidence row retained as the canonical statement of the channel. Anglophone stacks can prefix it with `document_id::`. |
| `evidence_id_source` | string, conditional | Original document-level evidence ID before Anglophone global prefixing. |
| `row_type` | `allocation` | Constant after filtering. |
| `country` | ISO3 | Country code. |
| `instrument_id` | string | Reconciled revenue-source ID. |
| `pair_id` | string | Reconciled allocation-channel ID and recommended primary key. |
| `document_id` | string | Legal source containing the retained assignment statement. |
| `document_type` | enum | Same document categories used in the evidence schema. |
| `document_year` | integer or text | Year of the legal document. |
| `legal_article` | string | Article, section, schedule, or legal unit containing the evidence. |
| `page_start` | integer | First canonical-file page. |
| `page_end` | integer | Last canonical-file page. |
| `official_name` | verbatim string | Revenue-instrument name as stated in this evidence row. |
| `census_ref` | array of strings | Matching census evidence IDs. The array can contain several rows. |

### B.4.2 Source-side fields retained for schema compatibility

These fields are normally populated on source rows in the evidence layer. They may be null on allocation rows. They remain available for cases where the allocation clause also states source information.

| Variable | Type or categories | Meaning |
|---|---|---|
| `tax_instrument` | enum | Source classification tag: `VAT`, `excise`, `fuel_levy`, `telecom_levy`, `environmental_tax`, `payroll_tax`, `resource_revenue`, `redevance`, `parafiscal_contribution`, `fine`, `profits_surcharge`, `hydrocarbon_tax`, `stamp_duty`, `other`. |
| `tax_base_detail` | string or null | Base stated in this clause. Use the census for the canonical base. |
| `rate_value` | numeric or null | Scalar source rate if stated in the allocation evidence. |
| `rate_is_schedule` | `0`, `1`, null | Source rate schedule flag. |
| `rate_schedule_detail` | string or null | Source rate schedule. |
| `rate_type` | enum | `ad_valorem_pct`, `per_unit_amount`, `fixed_amount`. |
| `rate_basis` | enum | `stated`, `banded`, `deferred_arrete`, `cross_reference`, `not_applicable`. The historical label `deferred_arrete` generalizes to a regulation or statutory instrument. |

### B.4.3 Destination and allocation variables

| Variable | Type or categories | Meaning |
|---|---|---|
| `destination` | verbatim string | Named beneficiary, account, tier, sector, or stated purpose. |
| `beneficiary_type` | enum | `fund`, `agency`, `ministry`, `collectivite_territoriale`, `sector`, `program`, `supranational`, `general_budget`. |
| `allocation_nature` | enum | `proceeds_share` or `cost_recovery_component`. |
| `share_value` | numeric or null | Scalar statutory share or amount. |
| `share_is_schedule` | `0`, `1`, null | One when the allocation share is banded. |
| `share_schedule_detail` | string or null | Full legal share schedule. |
| `share_type` | enum | `pct`, `per_unit_amount`, `fixed_amount`. |
| `share_basis` | enum | `stated`, `whole_proceeds_implied`, `deferred_arrete`. |
| `share_level` | integer | One for gross proceeds; two or above for a sub-pool. |
| `share_pool` | verbatim string or null | Parent pool for nested shares. Null at level one. |
| `is_purpose_restricted` | `0`, `1` | One for a restricted use; zero for unrestricted general-purpose use. |
| `assignment_type` | enum | `earmark_functional`, `hybrid_devolved_earmark`, `equalization_transfer`, `community_levy_external`, `tax_sharing_specific`, `tax_sharing_general`, `derivation_transfer`. |
| `mechanism` | null at this layer | Retained for schema compatibility. The field was moved to a derived instrument entity. |

#### `beneficiary_type` categories

| Category | Meaning |
|---|---|
| `fund` | Named fund or special-purpose financing vehicle. |
| `agency` | Public body, authority, regulator, board, or office. |
| `ministry` | Ministry or ministerial department. |
| `collectivite_territoriale` | Municipality, commune, region, district, or another territorial tier. |
| `sector` | A sector named as the destination rather than a specific body. |
| `public_employees` | Employees of a public body or agency. |
| `program` | Named function, activity, or programme, including a functional destination without a proper-noun body. |
| `supranational` | Regional, international, or community body. |
| `general_budget` | Central general-budget residual or unrestricted Treasury destination. |

#### `assignment_type` categories

| Category | Operational meaning |
|---|---|
| `earmark_functional` | Proceeds restricted to a stated function, fund, agency mandate, or programme. |
| `hybrid_devolved_earmark` | Purpose-restricted allocation routed through or to a subnational tier. |
| `equalization_transfer` | Pooled or formula-based redistribution across territorial units. |
| `community_levy_external` | Assignment to a supranational or external community body. |
| `tax_sharing_specific` | Tax-sharing arrangement whose use remains specifically restricted. |
| `tax_sharing_general` | Unrestricted sharing with a general-purpose budget or tier. |
| `derivation_transfer` | Transfer based on the jurisdiction or area from which the revenue derives. |

The exact analytical boundary among earmark-adjacent assignment types is downstream. The extraction preserves all categories.

### B.4.4 Reconciliation and hierarchy variables

| Variable | Type or categories | Meaning |
|---|---|---|
| `pair_row_role` | blank or `governing` in the final table | `restatement` rows are removed by the filter. Blank means the channel had only one evidence row. |
| `base_scope` | string or blank | Territorial, payer-class, branch, or segment qualifier carried into the pair key. |
| `intra_document_conflict` | enum or combined string | `none`, `competing_share`, `competing_rate`, `stated_inconsistency`, or combinations joined with `+`. In Anglophone country stacks, the flag can also reflect a cross-document conflict. |

### B.4.5 Change, lineage, and evidence fields

| Variable | Type or categories | Meaning |
|---|---|---|
| `change_type` | enum | `new`, `amendment_rate`, `amendment_base`, `amendment_key`, `merger`, `split`, `replacement`, `repeal`, `none`. |
| `structural_break` | `0`, `1` | One for a recorded base redefinition, merger, split, or replacement. |
| `partial_key` | `0`, `1`, null | One when the row represents only part of a larger allocation key. |
| `predecessor_ref` | string or null | Prior legal instrument or article named by the text. |
| `predecessor_relation` | enum | `amends`, `replaces`, `merges`, `splits`, `none`. |
| `change_from_previous` | string or null | Short description of a confirmed break. |
| `enabling_reference` | string or null | Founding or cited legal source. |
| `verbatim_excerpt` | string, mandatory | Exact assignment clause. |
| `source_internal_inconsistency` | string or null | Drafting inconsistency observed in the source. |
| `ai_confidence` | `high`, `medium`, `low` | Confidence in the extraction or classification. |
| `human_validation_status` | `unchecked`, `validated`, `corrected`, `rejected` | Human-review status. |
| `notes` | string or null | Boundary decisions, cross-references, and unresolved issues. |

### B.4.6 Destination-function variables

| Variable | Type or categories | Meaning |
|---|---|---|
| `destination_function` | COFOG group code or non-functional value | Function financed by the allocation. |
| `destination_function_basis` | `stated`, `named_body`, `inferred` | Evidence basis for the functional code. |
| `destination_function_multi` | `0`, `1` | One when the clause names more than one function. |
| `destination_function_detail` | semicolon-separated codes or null | Additional functions in the order stated. |

#### COFOG group categories

| Division | Group categories used |
|---|---|
| 701 General public services | `7011` executive, legislative, fiscal and external affairs; `7012` foreign economic aid; `7013` general services; `7014` basic research; `7015` R&D; `7016` n.e.c.; `7017` public debt; `7018` general transfers between government levels. |
| 702 Defence | `7021` military; `7022` civil; `7023` foreign military aid; `7024` R&D; `7025` n.e.c. |
| 703 Public order and safety | `7031` police; `7032` fire; `7033` courts; `7034` prisons; `7035` R&D; `7036` n.e.c. |
| 704 Economic affairs | `7041` general economic, commercial and labour affairs; `7042` agriculture, forestry and fishing; `7043` fuel and energy; `7044` mining, manufacturing and construction; `7045` transport; `7046` communications and ICT; `7047` other industries; `7048` R&D; `7049` n.e.c. |
| 705 Environmental protection | `7051` waste; `7052` waste water; `7053` pollution abatement; `7054` biodiversity and landscape; `7055` R&D; `7056` n.e.c. |
| 706 Housing and community amenities | `7061` housing; `7062` community development; `7063` water supply; `7064` street lighting; `7065` R&D; `7066` n.e.c. |
| 707 Health | `7071` medical products; `7072` outpatient care; `7073` hospitals; `7074` public health; `7075` R&D; `7076` n.e.c. |
| 708 Recreation, culture and religion | `7081` recreation and sport; `7082` culture; `7083` broadcasting and publishing; `7084` religion and other community services; `7085` R&D; `7086` n.e.c. |
| 709 Education | `7091` pre-primary and primary; `7092` secondary; `7093` post-secondary non-tertiary; `7094` tertiary; `7095` level not definable; `7096` subsidiary services; `7097` R&D; `7098` n.e.c. |
| 710 Social protection | `7101` sickness and disability; `7102` old age; `7103` survivors; `7104` family and children; `7105` unemployment; `7106` housing support; `7107` social exclusion; `7108` R&D; `7109` n.e.c. |

Non-functional values are:

| Value | Meaning |
|---|---|
| `general_budget` | Unrestricted central-government budget or Treasury. |
| `local_budget` | Unrestricted budget of a territorial tier. |
| `unallocated` | A destination is named but no function can be coded without invention. |

## B.5 Analytical filters and counting rules

### Broad canonical allocation table

```text
row_type == "allocation"
and pair_row_role != "restatement"
```

### Strict functional earmark subset

```text
allocation_nature == "proceeds_share"
and is_purpose_restricted == 1
```

### Unrestricted tax-sharing subset

```text
assignment_type == "tax_sharing_general"
```

### Administrative or service-cost subset

```text
allocation_nature == "cost_recovery_component"
```

### Channel count

```text
count(distinct pair_id)
```

### Instrument count with a strict earmark

```text
count(distinct instrument_id)
```

### Census-aligned numerator

```text
count(distinct flattened census_ref)
```

Shares must not be summed across different `share_level` values. Restatement rows must not be counted as separate channels.

---

# Annex C. Intermediate files and their role

| File pattern | Stage | Main content | Analytical status |
|---|---|---|---|
| `{country}_{document_id}_CENSUS.json` | Census extraction | Per-document instrument rows, coverage, run metadata | Intermediate or final for a one-document corpus |
| `{country}_CENSUS_MASTER.json` | Census reconciliation | One surviving row per country instrument plus logs | Final census for a multi-document corpus |
| `{country}_{document_id}_LOCATE.json` | Passage location | Passage inventory and coverage certificate | Recall worklist, not data table |
| `{country}_{document_id}_EXTRACT_{scope}.json` | Evidence extraction | Id-free source/allocation evidence and audits | Evidence source of truth |
| `{country}_{document_id}_RECONCILED.json` | Single-corpus reconciliation | IDs, pair roles, base scope, conflicts | Reconciled evidence |
| `{country}_ALL_RECONCILED.json` | Anglophone country reconciliation | Stacked cross-document reconciled evidence | Reconciled evidence |
| `{country}_{document_id}_CENSUS_REF.json` | Census join | Reconciled evidence plus `census_ref` | Joined evidence |
| `{country}_{document_id}_EARMARKS.json` | COFOG enrichment | Joined evidence plus destination function | Enriched evidence |
| `XXX_EARMARK_ALLOCATION.json` | Scripted filter | Canonical non-restatement allocation rows | Final allocation table |

---

# Annex D. Governing project files

The methodology is implemented through the following project artifacts.

## D.1 Common method and decisions

- `core_extraction_methodology.md`
- `retrieval_adapter_parameterized.md`
- `assumptions_register.md`
- `decision_rules.md`

## D.2 Census branch

- `census_prompt.md`
- `census_table_dictionary_v0_11.md`
- `census_reconciliation_prompt.md`

## D.3 Earmark branch

- `locate_prompt.md`
- `extract_prompt.md`
- `evidence_table_dictionary_v0.5.md`
- `reconciliation_prompt.md`
- `reconciliation_rules.md`
- `EN_reconciliation_orchestrator_prompt.md`
- `census_ref_prompt.md`
- `destination_function_prompt.md`
- `filter_allocations.py`

## D.4 Example production outputs reviewed for this methodology

- `CIV_CGI2026_LOCATE.json`
- `CIV_CGI2026_EXTRACT_whole.json`
- `CIV_CGI2026_RECONCILED.json`
- `CIV_CGI2026_CENSUS.json`
- `CIV_CGI2026_CENSUS_REF.json`
- `CIV_CGI2026_EARMARKS.json`

These examples show the progression from passage inventory to evidence rows, reconciled IDs, census links, and COFOG-enriched allocation evidence.
