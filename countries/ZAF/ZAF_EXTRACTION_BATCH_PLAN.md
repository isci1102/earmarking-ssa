# South Africa legal-corpus extraction batch plan

**Source base:** `ZAF_LEGAL_CORPUS_MANIFEST.json` — legal snapshot `2026-08-13`; original 50-PDF corpus plus five full SARS/LexisNexis consolidated Acts extracted on `2026-08-16` as source-faithful Markdown transcripts.

**Recovered consolidations added by this revision**

- `ZAF_1955_estate_duty.md` — updated to Government Gazette 47827 dated 5 January 2023.
- `ZAF_1991_value_added_tax.md` — updated to Government Gazettes 54447 and 54448 dated 1 April 2026.
- `ZAF_1999_skills_development_levies.md` — updated to Government Gazette 51828 dated 24 December 2024; 30/30 viewer documents captured.
- `ZAF_2007_security_transfer.md` — updated to Government Gazette 54448 dated 1 April 2026; later 2027 amendments are printed only as pending provisions.
- `ZAF_1964_customs_and_excise.md` — updated to Government Gazette 54783 dated 5 June 2026; 208/208 viewer documents captured.

## 1. Execution order

1. Run **P0 — recovered-source canonicalisation**. Preserve each Markdown transcript unchanged, render it deterministically to a canonical PDF, record the Markdown and PDF SHA-256 values, and add the five new preferred target rows to the manifest. The rendered PDF is the extraction target; the Markdown is its audit transcript.
2. Run the **standard per-document CENSUS batches C1–C8**. Each target produces its own CENSUS JSON.
3. Run **C9** only to resolve the Electronic Communications Act boundary; include its CENSUS output only if the statutory contribution is ruled in scope.
4. Run the five newly available consolidated-Act CENSUS batches **C10–C14**. They are ordinary per-document CENSUS runs, not source-recovery tasks.
5. Assemble all verified per-document outputs into **`ZAF_CENSUS_FINAL.json`**. Resolve Act–schedule duplicates at country assembly; never suppress an otherwise valid per-document row merely because another document also states the same instrument.
6. Use the final census as the source worklist for **allocation LOCATE batches A1–A14**. All five recovered Acts are now ready targets: Skills Development Levies in A7; Estate Duty, VAT and Securities Transfer Tax in A13; Customs and Excise in A14.
7. Run EXTRACT only on documents with LOCATE hits, reconcile cross-document source/allocation evidence, then match each source group to `census_ref`. Assign final `instrument_id` and `pair_id` only after that match.

**Planned coverage:** 28 standard census-ready targets (23 in C1–C8 plus 5 in C10–C14), 1 conditional C9 review, and 34 ready LOCATE targets across A1–A14.

## 2. Rules for every Cowork batch

- One Cowork task may contain several targets, but **each target is processed independently** and produces one separate output.
- A support document may clarify terminology, cross-references, completeness, or status. **It never produces rows in the target's output and never supplies a missing target field.**
- A document that is both a target and support for another target is still processed independently.
- Historical, stale, or future-version files are navigation/comparison sources only when a preferred recovered consolidation now exists.
- Never overwrite an existing output. Stop and report the collision.

### P0 — canonicalisation rule for the five recovered Markdown Acts

The five recovered files are complete legal transcripts, but the CENSUS dictionary requires `page_start` and `page_end` to be 1-based indices of a **canonical PDF**. Do not use Markdown line numbers as fake pages and do not relax the page-anchor rule.

For each recovered Act:

1. Store the untouched transcript under `source_markdown/sars_acts/`.
2. Render a deterministic PDF under `source_pdfs/sars_extracted/`, with a one-page provenance cover followed by the complete legal text. Do not rewrite, normalise, omit pending-amendment boxes, or alter source errors.
3. Record in the manifest: logical `document_id`, canonical PDF path, transcript path, source URL, extraction date, legal-currency notice, PDF page count, both SHA-256 values, language, and structural units.
4. Use the rendered PDF for A6 certification, page anchors, CENSUS and LOCATE. Use the Markdown transcript only as a text-faithfulness and coverage audit source.
5. Treat visibly marked **pending amendments** as non-operative at the `2026-08-13` snapshot unless their own commencement text says otherwise. Preserve them in notes/additional mentions; do not let them overwrite the operative clause.

**Proposed preferred manifest IDs and canonical paths**

| document_id | Markdown audit transcript | Canonical extraction PDF | Legal currency shown by source |
|---|---|---|---|
| `CTA_ESTATEDUTY_2023` | `source_markdown/sars_acts/ZAF_1955_estate_duty.md` | `source_pdfs/sars_extracted/ZAF_1955_estate_duty_consolidated_2023.pdf` | GG 47827, 5 Jan 2023 |
| `CTA_VAT_2026` | `source_markdown/sars_acts/ZAF_1991_value_added_tax.md` | `source_pdfs/sars_extracted/ZAF_1991_value_added_tax_consolidated_2026.pdf` | GG 54447 and 54448, 1 Apr 2026 |
| `CTA_SKILLSDEVLEVIES_2024` | `source_markdown/sars_acts/ZAF_1999_skills_development_levies.md` | `source_pdfs/sars_extracted/ZAF_1999_skills_development_levies_consolidated_2024.pdf` | GG 51828, 24 Dec 2024 |
| `CTA_SECURITIESTRANSFERTAX_2026` | `source_markdown/sars_acts/ZAF_2007_security_transfer.md` | `source_pdfs/sars_extracted/ZAF_2007_securities_transfer_tax_consolidated_2026.pdf` | GG 54448, 1 Apr 2026 |
| `CTA_CUSTOMSEXCISE_2026` | `source_markdown/sars_acts/ZAF_1964_customs_and_excise.md` | `source_pdfs/sars_extracted/ZAF_1964_customs_and_excise_consolidated_2026.pdf` | GG 54783, 5 Jun 2026 |

### Reusable CENSUS batch wrapper

```text
Read governing_docs/census_prompt.md,
governing_docs/census_table_dictionary_v0_11.md,
governing_docs/retrieval_adapter_parameterized.md, and
countries/ZAF/ZAF_LEGAL_CORPUS_MANIFEST.json.

BATCH ID: [C#]

TARGET DOCUMENTS
- [document_id] | [relative_path]

SUPPORT DOCUMENTS
- [document_id] | [relative_path] | supports [target] for [purpose]
- or: none

For every target, re-read its own manifest row and run census_prompt.md independently.
Produce rows only from the target currently being processed.
Support documents may be used only for interpretation, cross-reference, completeness, or status checks.
Do not create rows from support documents and do not copy target fields from them.

Write one file per target:
countries/ZAF/outputs/census/ZAF_{document_id}_CENSUS.json

Do not combine targets and do not reconcile cross-document instruments in this task.
Do not delete or overwrite existing files; stop and report a collision.
```

## 3. CENSUS batches

### C1 — Customs duty tariff (large)

**Targets**
- `SCH_CEA_S1P1_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P1Chpt1-to-99-Schedule-No-1-Part-1-Chapters-1-to-99.pdf` (704 pp.)

**Support mapping**
- `SCH_CEA_S1GEN_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1Gen-General-Notes-to-Schedules-to-Customs-and-Excise-Act.pdf` (515 pp.) — interpretation and classification notes for Schedule 1 Part 1.

**Batch note:** Run alone because the target is 704 pages. One output only.

### C2 — Excise duties

**Targets**
- `SCH_CEA_S1P2A_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P2A-Schedule-No-1-Part-2A.pdf` (10 pp.)
- `SCH_CEA_S1P2B_2025` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P2B-Schedule-No-1-Part-2B.pdf` (11 pp.)

**Support mapping**
- `SCH_CEA_S1GEN_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1Gen-General-Notes-to-Schedules-to-Customs-and-Excise-Act.pdf` (515 pp.) — general Schedule 1 interpretation.

**Batch note:** Two short table targets; produce one CENSUS file per target.

### C3 — Environmental levies A–E

**Targets**
- `SCH_CEA_S1P3A_2024` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P3A-Schedule-No-1-Part-3A.pdf` (3 pp.)
- `SCH_CEA_S1P3B_2012` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P3B-Schedule-No-1-Part-3B.pdf` (3 pp.)
- `SCH_CEA_S1P3C_2024` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P3C-Schedule-No-1-Part-3C.pdf` (3 pp.)
- `SCH_CEA_S1P3D_2024` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P3D-Schedule-No-1-Part-3D.pdf` (4 pp.)
- `SCH_CEA_S1P3E_2022` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P3E-Schedule-No-1-Part-3E.pdf` (13 pp.)

**Support mapping**
- `SCH_CEA_S1GEN_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1Gen-General-Notes-to-Schedules-to-Customs-and-Excise-Act.pdf` (515 pp.) — general Schedule 1 interpretation.
- `SCH_CEA_S1P3_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P3-Schedule-No-1-Part-3.pdf` (1 pp.) — Part 3 notes for Sections A–E.

**Batch note:** All targets are short. Treat tariff lines as rate schedules, not automatically as separate instruments.

### C4 — Carbon, fuel and other Schedule 1 levies

**Targets**
- `SCH_CEA_S1P3F_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P3F-Schedule-No-1-Part-3F.pdf` (3 pp.)
- `CTA_CARBONTAX_2024` — `source_pdfs/sars_acts/ZAF_2019_carbon_tax.pdf` (51 pp.)
- `SCH_CEA_S1P5A_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P5A-Schedule-No-1-Part-5A.pdf` (4 pp.)
- `SCH_CEA_S1P5B_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P5B-Schedule-No-1-Part-5B.pdf` (3 pp.)
- `SCH_CEA_S1P6_2021` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P6-Schedule-No-1-Part-6.pdf` (3 pp.)
- `SCH_CEA_S1P7A_2022` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P7A-Schedule-No-1-Part-7A.pdf` (4 pp.)
- `SCH_CEA_S1P8_2010` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P8-Schedule-No-1-Part-8.pdf` (2 pp.)

**Support mapping**
- `SCH_CEA_S1GEN_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1Gen-General-Notes-to-Schedules-to-Customs-and-Excise-Act.pdf` (515 pp.) — general Schedule 1 interpretation.
- `SCH_CEA_S1P3_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P3-Schedule-No-1-Part-3.pdf` (1 pp.) — Part 3 notes for Part 3F.
- `SCH_CEA_S1P7_2019` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P7-Schedule-No-1-Part-7.pdf` (1 pp.) — Part 7 notes for Part 7A.
- `CTA_CARBONTAX_2024` — `source_pdfs/sars_acts/ZAF_2019_carbon_tax.pdf` (51 pp.) — supports interpretation of the Part 3F cross-reference; it is also processed independently as a target.
- `SCH_CEA_S1P3F_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P3F-Schedule-No-1-Part-3F.pdf` (3 pp.) — supports the Carbon Tax Act's collection/rate cross-reference; it is also processed independently as a target.

**Batch note:** Seven independent target runs in one Cowork task; one output per target.

### C5 — Trade-remedy duties

**Targets**
- `SCH_CEA_S2_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch2-Schedule-No-2.pdf` (60 pp.)

**Support mapping**
- None.

**Batch note:** Run separately because Schedule 2 is 60 pages and has its own structure.

### C6 — Income Tax Act (large)

**Targets**
- `CTA_INCOMETAX_2026` — `source_pdfs/sars_acts/ZAF_1962_income_tax.pdf` (622 pp.)

**Support mapping**
- `GUI_TAXATIONINSA_2025` — `source_pdfs/sars_acts/ZAF_2025_Taxation_in_SA.pdf` (137 pp.) — completeness/cue-list support only.
- `OTH_EMPLOYMENTTAXINCENTIVE_2025` — `source_pdfs/sars_acts/ZAF_2013_employment_tax_incentive.pdf` (19 pp.) — status context for employees' tax/PAYE only.

**Batch note:** Run alone because the target is 622 pages. Do not create rows from the guide or incentive Act.

### C7 — Short charging Acts I

**Targets**
- `CTA_TRANSFERDUTY_2025` — `source_pdfs/sars_acts/ZAF_1949_transfer_duty.pdf` (48 pp.)
- `CTA_UICONTRIBUTIONS_2024` — `source_pdfs/sars_acts/ZAF_2002_unemployment_insurance_contrinution.pdf` (11 pp.)
- `CTA_DIAMONDEXPORTLEVY_2019` — `source_pdfs/sars_acts/ZAF_2007_diamond_export_levy.pdf` (8 pp.)
- `CTA_IOPCFUNDCONTRIB_2025` — `source_pdfs/sars_acts/ZAF_2013_merchant_shipping_international_oil_pollution_compensation_fund_contributions.pdf` (3 pp.)

**Support mapping**
- `TAA_DIAMONDEXPORTLEVYADM_2017` — `source_pdfs/sars_acts/ZAF_2007_diamond_export_levy_administration.pdf` (11 pp.) — administration/completeness support for CTA_DIAMONDEXPORTLEVY_2019.
- `TAA_IOPCFUNDADM_2014` — `source_pdfs/sars_acts/ZAF_2013_merchant_shipping_international_oil_pollution_compensation_fund_adminsitration.pdf` (3 pp.) — administration/completeness support for CTA_IOPCFUNDCONTRIB_2025.

**Batch note:** Four short independent targets; one output per target.

### C8 — Short charging Acts II

**Targets**
- `CTA_MPRROYALTY_2024` — `source_pdfs/sars_acts/ZAF_2008_mineral_and_petroleum_ressources_royalty.pdf` (19 pp.)
- `PTA_GLOBALMINIMUMTAX_2024` — `source_pdfs/sars_acts/ZAF_2024_global_minimum_tax.pdf` (10 pp.)

**Support mapping**
- `TAA_MPRROYALTYADM_2008` — `source_pdfs/sars_acts/ZAF_2008_mineral_and_petroleum_ressources_royalty_administration.pdf` (11 pp.) — administration support for CTA_MPRROYALTY_2024; stale, so do not use it to establish current substantive fields.
- `TAA_GLOBALMINIMUMTAXADM_2025` — `source_pdfs/sars_acts/ZAF_2024_global_minimum_tax_administration.pdf` (6 pp.) — administration/status support for PTA_GLOBALMINIMUMTAX_2024.

**Batch note:** Two short independent targets; verify commencement notes in the royalty Act.

### C9 — Conditional census boundary review

**Targets**
- `EST_ELECTRONICCOMMS_2024` — `source_pdfs/sars_acts/ZAF_2005_electronic_communications.pdf` (95 pp.)

**Support mapping**
- None.

**Batch note:** Run first as a scope/adjudication task. If the statutory licensee contribution qualifies as an in-scope compulsory revenue source, run the ordinary CENSUS prompt and include its output in country assembly; otherwise record an exclusion decision.

## 4. Newly recovered consolidated Acts — standard CENSUS batches

These five Acts are no longer recovery candidates. After P0 creates the canonical PDFs and manifest rows, process each under the ordinary CENSUS prompt. The displayed legal-currency date must be copied into `run_meta`; it is not the Act's enactment year.

### C10 — Estate Duty Act

**Target**
- `CTA_ESTATEDUTY_2023` — `source_pdfs/sars_extracted/ZAF_1955_estate_duty_consolidated_2023.pdf` — rendered from the full SARS consolidation updated to Government Gazette 47827 dated 5 January 2023.

**Support mapping**
- `source_markdown/sars_acts/ZAF_1955_estate_duty.md` — exact audit transcript only.
- `GUI_TAXATIONINSA_2025` — status/completeness cue only; it may not supply target fields.

**Extraction-critical provisions already visible in the recovered text**
- Section 2 imposes estate duty on the dutiable amount of every qualifying deceased estate.
- Section 4A provides the R3.5 million deduction used to determine the dutiable amount.
- The First Schedule states 20% on the portion not exceeding R30 million and 25% on the portion exceeding R30 million.

**Batch note:** Run as one independent whole-Act CENSUS target. Preserve the source's 2023 currency date in `run_meta`; the file is no longer excluded for lack of a consolidation. Any post-2023 status concern is a status-validation flag, not a reason to omit estate duty.

### C11 — Value-Added Tax Act (very large)

**Target**
- `CTA_VAT_2026` — `source_pdfs/sars_extracted/ZAF_1991_value_added_tax_consolidated_2026.pdf` — rendered from the full SARS consolidation updated to Government Gazettes 54447 and 54448 dated 1 April 2026.

**Support mapping**
- `source_markdown/sars_acts/ZAF_1991_value_added_tax.md` — exact audit transcript only.
- `CTA_CUSTOMSEXCISE_2026` — cross-reference support for importation/customs terminology only; processed independently in C14.
- `GUI_TAXATIONINSA_2025` — completeness/cue-list support only.

**Extraction-critical provisions already visible in the recovered text**
- Section 7(1) levies VAT on vendor supplies, imported goods and imported services.
- The operative general rate is 15%.
- Section 7 expressly states that VAT is levied and paid for the benefit of the National Revenue Fund; this is allocation evidence for A13, not a census destination field.

**Batch note:** Run alone because the recovered Act is very long and structurally dense. Treat zero-rated and exempt supplies as base/rate architecture of VAT unless the census grain rules identify a genuinely separate charge; do not multiply VAT into one instrument per zero-rating or exemption line.

### C12 — Skills Development Levies Act

**Target**
- `CTA_SKILLSDEVLEVIES_2024` — `source_pdfs/sars_extracted/ZAF_1999_skills_development_levies_consolidated_2024.pdf` — rendered from the full SARS consolidation updated to Government Gazette 51828 dated 24 December 2024; 30/30 viewer documents captured.

**Support mapping**
- `source_markdown/sars_acts/ZAF_1999_skills_development_levies.md` — exact audit transcript only.
- `EST_SKILLSDEVELOPMENT_2015` — institutional-purpose and expenditure-use support for the National Skills Fund and SETAs; processed independently as an A7 LOCATE target.

**Extraction-critical provisions already visible in the recovered text**
- Section 3 imposes the levy on employers; the operative statutory rate is 1% of leviable remuneration, subject to the Act's exemptions and any valid gazetted variation.
- Sections 8 and 9 contain the statutory distribution: 20% to the National Skills Fund and 80% to the relevant SETA; levies from employers outside a SETA go to the National Skills Fund. The operative wording covers **levies, interest and penalties** together, so allocation extraction must preserve that joint-source scope rather than automatically assigning every amount to the levy alone.
- Section 10 separately addresses collection costs; apply the cost-recovery rule rather than treating collection costs as an earmark by default.

**Batch note:** Run a standard CENSUS in C12 and a full LOCATE in A7. Pending amendments that the source says are not proclaimed remain non-operative. This Act contains both source and allocation clauses, so the final source join is no longer pending.

### C13 — Securities Transfer Tax Act

**Target**
- `CTA_SECURITIESTRANSFERTAX_2026` — `source_pdfs/sars_extracted/ZAF_2007_securities_transfer_tax_consolidated_2026.pdf` — rendered from the full SARS consolidation updated to Government Gazette 54448 dated 1 April 2026.

**Support mapping**
- `source_markdown/sars_acts/ZAF_2007_security_transfer.md` — exact audit transcript only.
- `CTA_SECURITIESTRANSFERTAX_2027` — future-version comparison only; never a target for the 2026 snapshot.

**Extraction-critical provisions already visible in the recovered text**
- Section 2 imposes securities transfer tax on every qualifying transfer of a security and specified reallocations.
- The operative rate is 0.25% of the taxable amount.
- Section 2 states that the tax is levied and paid for the benefit of the National Revenue Fund.

**Batch note:** Run the ordinary CENSUS on the operative 2026 wording. The source visibly marks amendments commencing on 1 January 2027 as pending; preserve them in notes but do not use them to populate the snapshot row.

### C14 — Customs and Excise Act parent body (very large)

**Target**
- `CTA_CUSTOMSEXCISE_2026` — `source_pdfs/sars_extracted/ZAF_1964_customs_and_excise_consolidated_2026.pdf` — rendered from the full SARS consolidation updated to Government Gazette 54783 dated 5 June 2026; 208/208 viewer documents captured.

**Support mapping**
- `source_markdown/sars_acts/ZAF_1964_customs_and_excise.md` — exact audit transcript only.
- All current Schedule 1 and Schedule 2 targets from C1–C5, plus `SCH_CEA_S1GEN_2026` — tariff/rate and interpretation support only; each schedule remains an independent target.
- `CTA_CARBONTAX_2024` — cross-reference support for sections 54A–54AA; independently processed in C4.

**Extraction-critical provisions already visible in the recovered text**
- Section 47 requires duty to be paid for the benefit of the National Revenue Fund on imported, excisable, surcharge, environmental-levy, fuel-levy and RAF-levy goods according to Schedule No. 1.
- Section 47B institutes air passenger tax.
- Sections 54A–54F govern environmental levies and carbon-tax collection; sections 54G–54J govern the health promotion levy.
- Sections 55–57 provide the parent authority for anti-dumping, countervailing and safeguard duties in Schedule No. 2.
- Section 52 contains the customs-union fuel-levy routing rule and is allocation-relevant.

**Batch note:** Run alone. This is now a full ordinary per-document CENSUS, **not a gap-only reconstruction**. Duplicate Act–schedule presentations are expected and must remain visible until country assembly. Do not suppress a parent-Act row merely because a schedule supplies the operative tariff; represent the parent rate as `cross_reference` where appropriate, then reconcile to the schedule row later. Ignore visibly pending Customs Control/Customs Duty transition wording whose commencement date is not determined.

### Historical files superseded as extraction targets

The earlier five files remain in the corpus for comparison and provenance but produce no CENSUS or LOCATE output:

- `CTA_ESTATEDUTY_2003`
- `CTA_VAT_1991`
- `CTA_SKILLSDEVLEVIES_1999`
- `CTA_SECURITIESTRANSFERTAX_2027`
- `CTA_CUSTOMSEXCISE_1968`

### Documents still deliberately excluded from standalone extraction

- `EST_SARS_2002` — collector-establishing/administrative support only; no source or allocation extraction.
- `TAA_TAXADMIN_2011` — administration support only; no standalone CENSUS or LOCATE.
- `TAA_CUSTOMSCONTROL_2014` — not commenced at the snapshot; archive only.
- `CTA_CUSTOMSDUTY_2017` — not commenced at the snapshot; archive only.

## 5. Country-census assembly

Run this only after C1–C8 and C10–C14 are complete and C9 has been adjudicated.

**Inputs**

- All per-document CENSUS JSON files from C1–C8.
- C9 output only if the contribution is admitted to the census.
- All five recovered-consolidation CENSUS outputs from C10–C14.
- `ZAF_LEGAL_CORPUS_MANIFEST.json`, including the P0 provenance and canonical-file rows.
- `ZAF_CONTROL_WORKLIST.csv`.
- `GUI_TAXATIONINSA_2025` as a completeness/control source only.

**Assembly actions**

1. Concatenate `census_rows` from every admitted target.
2. Resolve cross-document duplicates and Act–schedule presentations. In particular, reconcile the Customs and Excise parent-Act rows in C14 to the current Schedule 1/2 rows from C1–C5 without erasing either document's evidence.
3. Select one canonical country source row and preserve all secondary legal references and `additional_mentions`.
4. Assign one final `census_ref` per distinct revenue source.
5. Reconcile every control-worklist item as mapped, aggregate, excluded, pending-current-text, or unresolved.
6. Publish `N_verified_current` using current full texts, latest-available full texts that pass the status check, and official current schedules. Keep an extended view only for genuinely unresolved control sources; the five taxes recovered here are no longer pending solely for lack of a consolidated Act.
7. Record the evidence basis for every source: `current_full_text`, `latest_available_full_text`, `official_current_schedule`, or `control_attested_pending_legal`.
8. Preserve legal-currency precision: Estate Duty is sourced from the full consolidation current to 5 January 2023 and Skills Development Levies to 24 December 2024; do not relabel those files as “2026” merely because they were extracted in 2026.

**Outputs**

- `countries/ZAF/outputs/census/ZAF_CENSUS_FINAL.json`
- `countries/ZAF/outputs/census/ZAF_CENSUS_SOURCE_CROSSWALK.json`
- `countries/ZAF/outputs/census/ZAF_CONTROL_RECONCILIATION.json`
- `countries/ZAF/outputs/census/ZAF_PENDING_SOURCE_CANDIDATES.json` — now reserved for genuinely unresolved sources, not these five recovered Acts.

## 6. Allocation LOCATE batches

Run these after `ZAF_CENSUS_FINAL.json` exists. Every listed document is a **LOCATE target**. EXTRACT is run only where LOCATE identifies assignment passages.

### A1 — Customs duty tariff closure scan (large)

**LOCATE targets**
- `SCH_CEA_S1P1_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P1Chpt1-to-99-Schedule-No-1-Part-1-Chapters-1-to-99.pdf` (704 pp.)

**Support mapping**
- `SCH_CEA_S1GEN_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1Gen-General-Notes-to-Schedules-to-Customs-and-Excise-Act.pdf` (515 pp.) — interpretation of Schedule 1 Part 1.

**Batch note:** Run LOCATE alone on the 704-page target. EXTRACT only if LOCATE finds a source-specific assignment.

### A2 — SACU common-revenue-pool allocation

**LOCATE targets**
- `AGR_SACU_2002` — `source_pdfs/sars_acts/SACU.pdf` (20 pp.)

**Support mapping**
- None from the 50-PDF corpus. Use `ZAF_CENSUS_FINAL.json` where the note requires the source worklist.

**Batch note:** Use ZAF_CENSUS_FINAL.json as the source worklist after country-census assembly. This Agreement may refer collectively to customs/excise revenue; do not force a singular census_ref if the clause is genuinely joint.

### A3 — Excise, environmental levies and carbon

**LOCATE targets**
- `SCH_CEA_S1P2A_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P2A-Schedule-No-1-Part-2A.pdf` (10 pp.)
- `SCH_CEA_S1P2B_2025` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P2B-Schedule-No-1-Part-2B.pdf` (11 pp.)
- `SCH_CEA_S1P3A_2024` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P3A-Schedule-No-1-Part-3A.pdf` (3 pp.)
- `SCH_CEA_S1P3B_2012` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P3B-Schedule-No-1-Part-3B.pdf` (3 pp.)
- `SCH_CEA_S1P3C_2024` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P3C-Schedule-No-1-Part-3C.pdf` (3 pp.)
- `SCH_CEA_S1P3D_2024` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P3D-Schedule-No-1-Part-3D.pdf` (4 pp.)
- `SCH_CEA_S1P3E_2022` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P3E-Schedule-No-1-Part-3E.pdf` (13 pp.)
- `SCH_CEA_S1P3F_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P3F-Schedule-No-1-Part-3F.pdf` (3 pp.)
- `CTA_CARBONTAX_2024` — `source_pdfs/sars_acts/ZAF_2019_carbon_tax.pdf` (51 pp.)

**Support mapping**
- `SCH_CEA_S1GEN_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1Gen-General-Notes-to-Schedules-to-Customs-and-Excise-Act.pdf` (515 pp.) — general Schedule 1 interpretation.
- `SCH_CEA_S1P3_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P3-Schedule-No-1-Part-3.pdf` (1 pp.) — Part 3 notes.
- `CTA_CARBONTAX_2024` — `source_pdfs/sars_acts/ZAF_2019_carbon_tax.pdf` (51 pp.) — supports Part 3F cross-reference; also a target.
- `SCH_CEA_S1P3F_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P3F-Schedule-No-1-Part-3F.pdf` (3 pp.) — supports Carbon Tax Act collection/rate cross-reference; also a target.

**Batch note:** LOCATE every target independently; EXTRACT only documents with hits.

### A4 — Fuel, export, health, ordinary and trade-remedy duties

**LOCATE targets**
- `SCH_CEA_S1P5A_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P5A-Schedule-No-1-Part-5A.pdf` (4 pp.)
- `SCH_CEA_S1P6_2021` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P6-Schedule-No-1-Part-6.pdf` (3 pp.)
- `SCH_CEA_S1P7A_2022` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P7A-Schedule-No-1-Part-7A.pdf` (4 pp.)
- `SCH_CEA_S1P8_2010` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P8-Schedule-No-1-Part-8.pdf` (2 pp.)
- `SCH_CEA_S2_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch2-Schedule-No-2.pdf` (60 pp.)

**Support mapping**
- `SCH_CEA_S1GEN_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1Gen-General-Notes-to-Schedules-to-Customs-and-Excise-Act.pdf` (515 pp.) — general Schedule 1 interpretation.
- `SCH_CEA_S1P7_2019` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P7-Schedule-No-1-Part-7.pdf` (1 pp.) — Part 7 notes for Part 7A.

**Batch note:** Closure scan for assignments in the source documents.

### A5 — Road Accident Fund levy

**LOCATE targets**
- `SCH_CEA_S1P5B_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1P5B-Schedule-No-1-Part-5B.pdf` (3 pp.)
- `EST_ROADACCIDENTFUND_2026` — `source_pdfs/sars_acts/ZAF_1996_road_accident_fund.pdf` (29 pp.)

**Support mapping**
- `SCH_CEA_S1GEN_2026` — `source_pdfs/customs_schedules/Legal-LPrim-CE-Sch1Gen-General-Notes-to-Schedules-to-Customs-and-Excise-Act.pdf` (515 pp.) — interpretation of Part 5B.

**Batch note:** Expected cross-document pipe: source in Part 5B; credit/use rules in the RAF Act. Keep separate document evidence and join later through census_ref.

### A6 — Unemployment Insurance contributions

**LOCATE targets**
- `CTA_UICONTRIBUTIONS_2024` — `source_pdfs/sars_acts/ZAF_2002_unemployment_insurance_contrinution.pdf` (11 pp.)
- `EST_UNEMPLOYMENTINSURANCE_2020` — `source_pdfs/sars_acts/ZAF_2001_unemployment_insurance.pdf` (42 pp.)

**Support mapping**
- None from the 50-PDF corpus. Use `ZAF_CENSUS_FINAL.json` where the note requires the source worklist.

**Batch note:** Both are targets: the Contributions Act provides the source/crediting rule; the UI Act provides the Fund and use restrictions.

### A7 — Skills Development levy and allocation architecture

**LOCATE targets**
- `CTA_SKILLSDEVLEVIES_2024` — `source_pdfs/sars_extracted/ZAF_1999_skills_development_levies_consolidated_2024.pdf`.
- `EST_SKILLSDEVELOPMENT_2015` — `source_pdfs/sars_acts/ZAF_1998_skills_development.pdf` (52 pp.).

**Support mapping**
- `source_markdown/sars_acts/ZAF_1999_skills_development_levies.md` — audit transcript only.
- `CTA_SKILLSDEVLEVIES_1999` — historical comparison only.

**Batch note:** LOCATE both targets independently. The levy Act states the collection and 20/80 statutory routing; the Skills Development Act supplies institutional purpose and expenditure restrictions. Keep clause evidence separate by document. Because sections 8–9 route **levies, interest and penalties** jointly, match each named source where the census contains it or preserve a joint-source allocation—do not force the entire clause onto the levy `census_ref`. Apply the cost-recovery rule to section 10 collection costs rather than automatically treating them as an earmark.

### A8 — Universal Service and Access Fund

**LOCATE targets**
- `EST_ELECTRONICCOMMS_2024` — `source_pdfs/sars_acts/ZAF_2005_electronic_communications.pdf` (95 pp.)

**Support mapping**
- None from the 50-PDF corpus. Use `ZAF_CENSUS_FINAL.json` where the note requires the source worklist.

**Batch note:** This file is both the allocation target and the unresolved source-grain case. Preserve the legal character as a review flag.

### A9 — International Oil Pollution Compensation Fund

**LOCATE targets**
- `CTA_IOPCFUNDCONTRIB_2025` — `source_pdfs/sars_acts/ZAF_2013_merchant_shipping_international_oil_pollution_compensation_fund_contributions.pdf` (3 pp.)

**Support mapping**
- `TAA_IOPCFUNDADM_2014` — `source_pdfs/sars_acts/ZAF_2013_merchant_shipping_international_oil_pollution_compensation_fund_adminsitration.pdf` (3 pp.) — administration/completeness support only.

**Batch note:** The Contributions Act may contain both source and destination clauses.

### A10 — Country-level public-finance default rules

**LOCATE targets**
- `CON_CONSTITUTION_2012` — `source_pdfs/sars_acts/ZAF_constituion.pdf` (182 pp.)

**Support mapping**
- None from the 50-PDF corpus. Use `ZAF_CENSUS_FINAL.json` where the note requires the source worklist.

**Batch note:** Extract country-level National Revenue Fund / division-of-revenue rules separately. Do not manufacture one general-budget allocation row per ordinary tax.

### A11 — Income Tax Act closure scan (large)

**LOCATE targets**
- `CTA_INCOMETAX_2026` — `source_pdfs/sars_acts/ZAF_1962_income_tax.pdf` (622 pp.)

**Support mapping**
- `GUI_TAXATIONINSA_2025` — `source_pdfs/sars_acts/ZAF_2025_Taxation_in_SA.pdf` (137 pp.) — completeness/cue-list support only.

**Batch note:** Run LOCATE alone because the target is 622 pages; EXTRACT only if source-specific assignment grammar is found.

### A12 — Other short charging Acts closure scan

**LOCATE targets**
- `CTA_TRANSFERDUTY_2025` — `source_pdfs/sars_acts/ZAF_1949_transfer_duty.pdf` (48 pp.)
- `CTA_DIAMONDEXPORTLEVY_2019` — `source_pdfs/sars_acts/ZAF_2007_diamond_export_levy.pdf` (8 pp.)
- `CTA_MPRROYALTY_2024` — `source_pdfs/sars_acts/ZAF_2008_mineral_and_petroleum_ressources_royalty.pdf` (19 pp.)
- `PTA_GLOBALMINIMUMTAX_2024` — `source_pdfs/sars_acts/ZAF_2024_global_minimum_tax.pdf` (10 pp.)

**Support mapping**
- `TAA_DIAMONDEXPORTLEVYADM_2017` — `source_pdfs/sars_acts/ZAF_2007_diamond_export_levy_administration.pdf` (11 pp.) — support for Diamond Export Levy.
- `TAA_MPRROYALTYADM_2008` — `source_pdfs/sars_acts/ZAF_2008_mineral_and_petroleum_ressources_royalty_administration.pdf` (11 pp.) — support for MPR royalty; stale, do not use for current substantive fields.
- `TAA_GLOBALMINIMUMTAXADM_2025` — `source_pdfs/sars_acts/ZAF_2024_global_minimum_tax_administration.pdf` (6 pp.) — support for Global Minimum Tax.

**Batch note:** LOCATE each target independently; EXTRACT only documents with assignment hits.

### A13 — Estate Duty, VAT and Securities Transfer Tax

**LOCATE targets**
- `CTA_ESTATEDUTY_2023` — `source_pdfs/sars_extracted/ZAF_1955_estate_duty_consolidated_2023.pdf`.
- `CTA_VAT_2026` — `source_pdfs/sars_extracted/ZAF_1991_value_added_tax_consolidated_2026.pdf`.
- `CTA_SECURITIESTRANSFERTAX_2026` — `source_pdfs/sars_extracted/ZAF_2007_securities_transfer_tax_consolidated_2026.pdf`.

**Support mapping**
- Their three Markdown transcripts are text-faithfulness/coverage audit sources only.
- `CTA_SECURITIESTRANSFERTAX_2027` is future-version comparison only.

**Batch note:** Run one independent LOCATE output per target. VAT section 7 and Securities Transfer Tax section 2 expressly say the tax is for the benefit of the National Revenue Fund, so expect general-budget allocation evidence (`is_purpose_restricted = 0`) under the extract-broad rule. Estate Duty remains a closure scan unless a source-specific assignment clause is located. Pending 2027 securities-transfer amendments are non-operative at the snapshot.

### A14 — Customs and Excise parent-Act allocation scan (very large)

**LOCATE target**
- `CTA_CUSTOMSEXCISE_2026` — `source_pdfs/sars_extracted/ZAF_1964_customs_and_excise_consolidated_2026.pdf`.

**Support mapping**
- current official Schedule 1/2 Parts and `SCH_CEA_S1GEN_2026`;
- `ZAF_CENSUS_FINAL.json` as the source worklist;
- `source_markdown/sars_acts/ZAF_1964_customs_and_excise.md` as the audit transcript.

**Batch note:** Run a full-document, fund-agnostic LOCATE over the current parent Act; it is no longer conditional or gap-only. Expected assignment grammar includes section 47's National Revenue Fund language, section 47B air passenger tax, section 52 customs-union fuel-levy routing, and other source-specific payment/disposal clauses. Section 47 covers several duty types jointly, so preserve it as a joint-source clause unless a narrower provision supports separate source links. Extract every hit and resolve duplication with A1–A5, SACU and RAF only during reconciliation—never by suppressing a located clause in advance.

## 7. Allocation reconciliation and census join

After all LOCATE hits have been extracted:

1. Union the clause-level EXTRACT outputs; preserve the document in which each clause appears.
2. Group clauses that concern the same revenue source, including cross-document source/allocation pairs and parent-Act/schedule restatements.
3. Match each source group to `ZAF_CENSUS_FINAL.json` using, in order: explicit charging reference; exact normalized source name; source name plus base/payer; manual review.
4. Propagate the matched `census_ref` to every allocation row in that source group.
5. Assign `instrument_id` as the reconciled source entity and `pair_id` as one source × destination × share level/pool × base scope.
6. Keep unmatched or genuinely joint multi-source clauses explicit; do not guess a singular source.
7. For VAT, Securities Transfer Tax and Customs/Excise clauses stating “for the benefit of the National Revenue Fund,” record the assignment but classify it as unrestricted general-budget routing, not an earmark.
8. Preserve joint-source clauses explicitly—especially Skills Development Levies sections 8–9 (levies, interest and penalties) and Customs and Excise section 47 (several duty types)—rather than manufacturing a singular `census_ref`.

**Cross-document examples**

- RAF levy: source in `SCH_CEA_S1P5B_2026`; allocation/use rules in `EST_ROADACCIDENTFUND_2026`; parent charging/payment language may also appear in `CTA_CUSTOMSEXCISE_2026`.
- UIF contribution: source/crediting in `CTA_UICONTRIBUTIONS_2024`; fund/use rules in `EST_UNEMPLOYMENTINSURANCE_2020`.
- Skills levy: source and 20/80 distribution in `CTA_SKILLSDEVLEVIES_2024`; purpose/use restrictions in `EST_SKILLSDEVELOPMENT_2015`.
- VAT and Securities Transfer Tax: source and National Revenue Fund assignment are in the same principal Act.
- SACU: the Agreement may assign customs/excise revenue collectively; preserve a joint-source relation if the text does not identify one singular source.
- Customs and Excise: parent-Act rows from C14/A14 and schedule rows from C1–C5/A1–A5 may describe the same source at different legal layers; reconcile rather than double-count.

**Final outputs**

- `ZAF_ALLOCATION_EVIDENCE.json` — clause-level source/allocation evidence.
- `ZAF_ALLOCATION_LINKS.json` — reconciled source–destination links.
- `ZAF_EARMARKS.json` — purpose-restricted `proceeds_share` subset.
- `ZAF_ALLOCATION_CENSUS_CROSSWALK.json` — source group to `census_ref` decisions.

## 8. Recovered consolidated-source status and denominator treatment

| Live source | Preferred target ID | Legal currency displayed in recovered source | Standard batches | Denominator/status treatment |
|---|---|---|---|---|
| Estate duty | `CTA_ESTATEDUTY_2023` | GG 47827, 5 Jan 2023 | C10; A13 | full latest-available consolidation; include after ordinary status check, with the currency date retained explicitly |
| VAT | `CTA_VAT_2026` | GG 54447 and 54448, 1 Apr 2026 | C11; A13 | current full text for the snapshot; no longer pending |
| Skills Development Levy | `CTA_SKILLSDEVLEVIES_2024` | GG 51828, 24 Dec 2024 | C12; A7 | full latest-available consolidation containing both source and distribution; no source-join gap remains |
| Securities transfer tax | `CTA_SECURITIESTRANSFERTAX_2026` | GG 54448, 1 Apr 2026 | C13; A13 | current 2026 text; visibly pending 2027 amendments excluded from the snapshot |
| Customs and Excise parent body | `CTA_CUSTOMSEXCISE_2026` | GG 54783, 5 Jun 2026 | C14; A14 | current full parent Act; official current schedules remain independent rate targets and duplicates are reconciled |

These five taxes must be removed from the “pending because no adequate consolidated text” category. The country census should now publish:

- `N_verified_current`: sources supported by a current full text, a latest-available full text that passes the status check, or an official current schedule;
- `N_extended_live`: `N_verified_current` plus only genuinely unresolved control-attested sources.

The remaining control-worklist source gaps are separate from these recovered Acts: `ZAF_CTRL_0057` (Stamp duties and fees) and `ZAF_CTRL_0085` (Mining leases and ownership).

## 9. Master assignment of the original 50-PDF corpus plus 5 recovered consolidated Acts

| Document ID | Census action | Allocation action | Main decision |
|---|---|---|---|
| `SCH_CEA_S1GEN_2026` | Support C1, C2, C3, C4 | Support A1, A3, A4, A5 | administration_support |
| `SCH_CEA_S1P1_2026` | Target C1 | LOCATE target A1 | census_enacting |
| `SCH_CEA_S1P2A_2026` | Target C2 | LOCATE target A3 | census_enacting |
| `SCH_CEA_S1P2B_2025` | Target C2 | LOCATE target A3 | census_enacting |
| `SCH_CEA_S1P3_2026` | Support C3, C4 | Support A3 | administration_support |
| `SCH_CEA_S1P3A_2024` | Target C3 | LOCATE target A3 | census_enacting |
| `SCH_CEA_S1P3B_2012` | Target C3 | LOCATE target A3 | census_enacting |
| `SCH_CEA_S1P3C_2024` | Target C3 | LOCATE target A3 | census_enacting |
| `SCH_CEA_S1P3D_2024` | Target C3 | LOCATE target A3 | census_enacting |
| `SCH_CEA_S1P3E_2022` | Target C3 | LOCATE target A3 | census_enacting |
| `SCH_CEA_S1P3F_2026` | Target C4 | LOCATE target A3 | census_enacting |
| `SCH_CEA_S1P5A_2026` | Target C4 | LOCATE target A4 | census_enacting |
| `SCH_CEA_S1P5B_2026` | Target C4 | LOCATE target A5 | census_enacting |
| `SCH_CEA_S1P6_2021` | Target C4 | LOCATE target A4 | census_enacting |
| `SCH_CEA_S1P7_2019` | Support C4 | Support A4 | administration_support |
| `SCH_CEA_S1P7A_2022` | Target C4 | LOCATE target A4 | census_enacting |
| `SCH_CEA_S1P8_2010` | Target C4 | LOCATE target A4 | census_enacting |
| `SCH_CEA_S2_2026` | Target C5 | LOCATE target A4 | census_enacting |
| `AGR_SACU_2002` | No CENSUS run | LOCATE target A2 | amendment check required |
| `CTA_TRANSFERDUTY_2025` | Target C7 | LOCATE target A12 | census_enacting |
| `CTA_ESTATEDUTY_2003` | Historical comparison/support only | Historical comparison/support only | Superseded as extraction target by `CTA_ESTATEDUTY_2023`; retain provenance, do not run |
| `CTA_ESTATEDUTY_2023` | Target C10 | LOCATE target A13 | recovered_consolidated_full_text; latest available currency 2023 |
| `CTA_INCOMETAX_2026` | Target C6 | LOCATE target A11 | census_enacting;status_validation |
| `CTA_CUSTOMSEXCISE_1968` | Historical comparison/support only | Historical comparison/support only | Superseded as extraction target by `CTA_CUSTOMSEXCISE_2026`; retain provenance, do not run |
| `CTA_CUSTOMSEXCISE_2026` | Target C14 | LOCATE target A14 | recovered_consolidated_full_text; parent Act processed independently from current schedules |
| `CTA_VAT_1991` | Historical comparison/support only | Historical comparison/support only | Superseded as extraction target by `CTA_VAT_2026`; retain provenance, do not run |
| `CTA_VAT_2026` | Target C11 | LOCATE target A13 | recovered_consolidated_full_text; census_enacting; general-budget assignment in s. 7 |
| `EST_ROADACCIDENTFUND_2026` | No CENSUS run | LOCATE target A5 | allocation_enacting |
| `EST_SARS_2002` | No CENSUS run | No LOCATE run | Collector-establishing/administrative support only; not a revenue source |
| `EST_SKILLSDEVELOPMENT_2015` | No CENSUS run | LOCATE target A7 with `CTA_SKILLSDEVLEVIES_2024` | allocation_enacting; use restrictions and institutional purpose |
| `CTA_SKILLSDEVLEVIES_1999` | Historical comparison/support only | Historical comparison/support only | Superseded as extraction target by `CTA_SKILLSDEVLEVIES_2024`; retain provenance, do not run |
| `CTA_SKILLSDEVLEVIES_2024` | Target C12 | LOCATE target A7 | recovered_consolidated_full_text; source and statutory distribution in same Act |
| `EST_UNEMPLOYMENTINSURANCE_2020` | No CENSUS run | LOCATE target A6 | amendment check required |
| `CTA_UICONTRIBUTIONS_2024` | Target C7 | LOCATE target A6 | census_enacting;allocation_enacting |
| `EST_ELECTRONICCOMMS_2024` | Target C9 | LOCATE target A8 | unresolved role |
| `CTA_DIAMONDEXPORTLEVY_2019` | Target C7 | LOCATE target A12 | amendment check required |
| `TAA_DIAMONDEXPORTLEVYADM_2017` | Support C7 | Support A12 | amendment check required |
| `CTA_SECURITIESTRANSFERTAX_2027` | Future-version comparison/support only | Future-version comparison/support only | Superseded as snapshot target by `CTA_SECURITIESTRANSFERTAX_2026`; do not treat 2027 provisions as current |
| `CTA_SECURITIESTRANSFERTAX_2026` | Target C13 | LOCATE target A13 | recovered_consolidated_full_text; pending 2027 amendments excluded from snapshot |
| `CTA_MPRROYALTY_2024` | Target C8 | LOCATE target A12 | census_enacting |
| `TAA_MPRROYALTYADM_2008` | Support C8 | Support A12 | current consolidation unavailable |
| `TAA_TAXADMIN_2011` | No standalone CENSUS run | No standalone LOCATE run | Administration support only when a target Act cross-refers to it |
| `OTH_EMPLOYMENTTAXINCENTIVE_2025` | Support C6 | No allocation run | status_validation;administration_support |
| `TAA_IOPCFUNDADM_2014` | Support C7 | Support A9 | amendment check required |
| `CTA_IOPCFUNDCONTRIB_2025` | Target C7 | LOCATE target A9 | census_enacting;allocation_enacting |
| `TAA_CUSTOMSCONTROL_2014` | No CENSUS run | No LOCATE run | Archive: not commenced at snapshot date |
| `CTA_CUSTOMSDUTY_2017` | No CENSUS run | No LOCATE run | Archive: not commenced at snapshot date |
| `CTA_CARBONTAX_2024` | Target C4 | LOCATE target A3 | amendment check required |
| `AMD_DISASTERTAXRELIEF_2022` | No CENSUS run | No allocation run | Archive: temporary relief measure, lapsed |
| `TAA_DISASTERTAXRELIEFADM_2021` | No CENSUS run | No allocation run | Archive: temporary relief measure, lapsed |
| `PTA_GLOBALMINIMUMTAX_2024` | Target C8 | LOCATE target A12 | census_enacting |
| `TAA_GLOBALMINIMUMTAXADM_2025` | Support C8 | Support A12 | administration_support |
| `GUI_TAXATIONINSA_2025` | Support C6 | Support A11 | document not legislation |
| `CON_CONSTITUTION_2012` | No CENSUS run | LOCATE target A10 | amendment check required |
| `OTH_SABCUNIVERSALSERVICEACCESS_UNDATED` | No CENSUS run | No allocation run | Exclude: document not legislation |

## 10. Batch-completion checklist

- [ ] P0 preserved the five Markdown transcripts, created five deterministic canonical PDFs, and added the five preferred manifest rows with SHA-256 values and page counts.
- [ ] C1–C8 produced 23 separate CENSUS files.
- [ ] C9 was adjudicated and documented.
- [ ] C10–C14 produced five separate standard CENSUS files from the recovered consolidations.
- [ ] C14 retained parent-Act evidence and deferred Act–schedule deduplication to country assembly.
- [ ] Country census was assembled with the five recovered taxes removed from the text-pending category.
- [ ] A1–A14 produced 34 separate LOCATE files, one per target.
- [ ] A7 processed both the current Skills Development Levies Act and the Skills Development Act.
- [ ] A13 processed Estate Duty, VAT and Securities Transfer Tax independently.
- [ ] A14 completed the full current Customs and Excise parent-Act scan.
- [ ] EXTRACT was run only for LOCATE hits.
- [ ] Every allocation source group was matched, left unmatched, or marked joint/ambiguous explicitly.
- [ ] General National Revenue Fund routing was recorded but excluded from the purpose-restricted earmark subset.
- [ ] Final `census_ref`, `instrument_id`, and `pair_id` audits passed.
- [ ] `ZAF_PENDING_SOURCE_CANDIDATES.json` contains only genuinely unresolved sources, not the five recovered Acts.
