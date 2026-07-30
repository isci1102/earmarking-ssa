# Coverage Map — Nigeria corpus (1939–2025 standing law; earmark window ~2011–2026)

**Purpose.** Authoritative record of what source documents exist, their real format/quality, and which pre-processing gate each must pass before it enters extraction. This is the honest denominator for any coverage statistic and the guard against silent false nulls. Missing ≠ absent: the absence of a document for a year does **not** license the inference that no earmark existed or changed that year.

**Corpus-type note (read first).** Unlike the Côte d'Ivoire corpus — an annual-instrument series (one *annexe fiscale* / *loi de finances* per year) — the Nigerian corpus is **common-law standing law**: each Act is a single document in force until repealed, modified *in place* by an amendment chain (the Finance Acts) and terminated by the 2025 consolidation package (effective 2026). Consequently `document_year` here is an **enactment/citation year, not an observation year**, and the point-in-time state of any instrument is **reconstructed** (establishing Act + cumulative Finance-Act amendments through year *t*), never read from a single per-year document. Collection cardinality therefore differs by document class — recorded in §1 as `once` vs `per_year`.

---

## 1. Document inventory by document, class, and cardinality

Legend — Status: `OK` (clean embedded text layer, ready) · `OCR` (needs OCR before extraction) · `PARTIAL` (text present but truncated/low-density — recover from page images) · `PLAINTEXT` (delivered as UTF-8 text mislabeled `.pdf`; read directly) · `MISSING` (not held) · `DEFER` (held but out of first-pass scope). Cardinality: `once` (standing law, reconstruct-forward) · `per_year` (annual instrument).

| Document (file) | Class / Tier | Cite yr | Origin yr | Cardinality | Pages | Delivered format | Status |
|---|---|---|---|---|---|---|---|
| `NGA_2025_tax_act` (NTA) | Consolidation / T1 | 2025 | — | once | ~n/a (text) | **UTF-8 plaintext** mislabeled `.pdf` | **PLAINTEXT — OK** (S.59 Dev. Levy + 7-way schedule confirmed present) |
| `NGA_2025_tax_administration_act` (NTAA) | Consolidation / T1 | 2025 | — | once | 93 | ZIP(jpeg+txt) | **OK** (embedded text clean) |
| `NGA_2025_revenue_service_act` (NRS) | Consolidation / T1 | 2025 | — | once | 30 | ZIP(jpeg+txt) | **OK** |
| `NGA_2025_joint_revenue_board_act` (JRB) | Consolidation / T1 | 2025 | — | once | 32 | ZIP(jpeg+txt) | **OK** |
| `NGA_2011_tertiary_education_trustfund_act` (TETFund) | Establishing / T2 | 2011 | 1993 | once | 45 | ZIP(jpeg+txt) | **PARTIAL** (~560 char/pp; reads as *BILL* text — verify Act vs Bill & completeness vs page images) |
| `NGA_2007_national_information_technology_developmnt_agency_act` (NITDA) | Establishing / T2 | 2007 | 2007 | once | 19 | ZIP(jpeg+txt) | **OK** |
| `NGA_1992_national_agency_for_science_and_engineering_infrastructure_act` (NASENI) | Establishing / T2 | 1992 | 1992 | once | 30 | ZIP(jpeg+txt) | **OK** |
| `NGA_1992_national_housing_fund_act` (NHF) | Establishing / T2 | 1992 | 1992 | once | 6 | ZIP(jpeg+txt) | **OK** (short — QC completeness) |
| `NGA_2022_national_health_insurance_authority_act` (NHIA) | Establishing / T2 | 2022 | 1999 | once | 31 | ZIP(jpeg only) | **OCR** (txt layer empty) |
| `NGA_2019_police_trust_fund_act` (NPTF) | Establishing / T2 | 2019 | 2019 | once | 16 | **real `%PDF-1.4`** | **OCR** (scanned; no font/text layer — Dev-Levy predecessor) |
| `NGA_2007_companies_income_tax_act` (CITA) | Principal / T2.5 | 2007¹ | 1979 | once | 63 | ZIP(jpeg+txt) | **OK** (defines *assessable profits* base — see §4) |
| `NGA_1993_personal_income_tax_act` (PITA) | Principal / T2.5 | 1993 | 1993 | once | 93 | ZIP(jpeg+txt) | **OK** |
| `NGA_1959_petroleum_profits_tax_act` (PPTA) | Principal / T2.5 | 1959 | 1959 | once | 42 | ZIP(jpeg+txt) | **OK** (⚠ partly superseded by PIA 2021 — §4) |
| `NGA_2021_petroleum_industry_act` (PIA) | Principal / T2.5 | 2021 | 2021 | once | ~n/a (text) | **UTF-8 plaintext** mislabeled `.pdf` (Official Gazette No. 142) | **PLAINTEXT — OK** (dense petroleum earmarks: Host Communities Dev. Trust, Frontier Exploration Fund, Hydrocarbon Tax, environmental remediation fund) |
| `NGA_2025_value_added_tax_act` (VAT) | Principal / T2.5 | 2025² | 1993 | once | 39 | ZIP(jpeg+txt) | **OK** (contains VAT sharing formula → `tax_sharing`, §4) |
| `NGA_1967_capital_gains_tax_act` (CGT) | Principal / T2.5 | 1967 | 1967 | once | 23 | ZIP(jpeg+txt) | **OK** |
| `NGA_1939_stamp_duties_act` (SDA) | Principal / T2.5 | 1939 | 1939 | once | 64 | ZIP(jpeg+txt) | **OK** (dormant until FA2019 — treatment-relevant yr = 2019) |
| `NGA_2019_finance_act` | Amendment / T3 | 2019 | — | per_year | 31 | ZIP(jpeg only) | **OCR** (txt layer empty) |
| `NGA_2020_finance_act` | Amendment / T3 | 2020 | — | per_year | 46 | ZIP(jpeg only) | **OCR** (txt layer empty) |
| `NGA_2021_finance_act` | Amendment / T3 | 2021 | — | per_year | 31 | ZIP(jpeg+txt) | **OK** |
| `NGA_2023_finance_act` | Amendment / T3 | 2023 | — | per_year | 18 | ZIP(jpeg only) | **OCR** (txt layer empty; ⚠ irregular commencement — extract commencement clause, §4) |

¹ CITA file is the *CAP C21 LFN 2004 as amended (last reviewed Dec 2007)* consolidation; internal citation "CAP. 60 L.F.N. 1990 ACT CAP. C21 L.F.N. 2004". ² VAT file internal title is the plain "VALUE ADDED TAX ACT" (LFN 2004 as amended) — filename year `2025` reflects the held edition, **not** a new 2025 VAT statute; reconcile filename vs internal title at the year-verification gate.

**Now held (gaps closed since first diagnosis):** ✔ **PIA 2021** — closes the 2021 petroleum break (Gazette text, dense earmarks). ✔ **Police Trust Fund Act 2019** — completes the Development-Levy `predecessor_id` set (all four predecessors — TET, NITDA, NASENI, NPTF — now in corpus; NPTF pending OCR).

**Still not in corpus (log as `unobserved`, never as zeros):** Finance Act 2022 (status uncertain per external record; absent here) · Appropriation Acts / Budget Office fund tables (Tier 5 amounts layer) · Federation Account / RMAFC allocation instruments (Tier 4 boundary cases).

---

## 2. Known corpus hazards (all observed in *this* corpus — treat as corpus-wide, not one-off)

1. **Extension lies about format — corpus-wide, THREE variants.** Almost nothing is what `.pdf` claims. (a) **ZIP archives** (per-page `N.jpeg` + `N.txt` + manifest `.json`) renamed `.pdf` — 18/21 files — the app-uploaded-artifact decomposition adapter A6 warns of ("can decompose a searchable PDF into a zip-of-images"). (b) **UTF-8 plaintext** renamed `.pdf` — `NGA_2025_tax_act` (header `NIGERIA TAX ACT,`) and `NGA_2021_petroleum_industry_act` (header `Petroleum In…`, actually Official Gazette text) — the CIV "2025 annexe" hazard. (c) **Genuine `%PDF-1.4`** — exactly one file, `NGA_2019_police_trust_fund_act`, and it is a **scanned/raster PDF with no font or text layer** (the CIV 2017 corrupt-render hazard) → OCR. **Never trust the extension; branch on header bytes per §3.** Note the diagnostic tell: a plaintext file with binary/mojibake bytes, or a scanned PDF, will throw a UTF-8 read error — that error is a format signal, not a nuisance.
2. **Text layer lies about presence — OCR required for five files.** Four ZIPs (**FA2019, FA2020, FA2023, NHIA 2022**) carry page images but **empty** `.txt` files; the one genuine PDF (**NPTF 2019**) is scanned with no text layer. All five → OCR (English model). For the ZIPs the page images are already extracted (`N.jpeg`); for NPTF, rasterize the PDF pages first. Absence of text is a *delivery* artifact, not absence of content; treating these passages as null would be a silent false null.
3. **Text layer lies about completeness.** **TETFund** returns ~560 char/page (vs ~3,000 elsewhere) and reads as *"A BILL / Download E-copy"* — likely a truncated or bill-stage capture. Do **not** extract load-bearing rate/share values from it without verifying against its page images (and against the Gazette Act, not the Bill).
4. **Filename may lie about instrument identity.** `NGA_2025_value_added_tax_act` is (per its internal title) the standing VAT Act LFN 2004-as-amended, not a distinct 2025 VAT statute; the `2025` is an edition/hold year. Confirm at the year-verification gate before assigning `document_year`.

---

## 3. Pre-processing gate (must pass before a file enters extraction)

For every file, in order:
1. **Format diagnosis** — inspect header bytes, do **not** trust `.pdf`. Route: `PK\x03\x04` → ZIP, `unzip` and use embedded `N.txt` if non-empty else OCR the `N.jpeg`; ASCII/UTF-8 header (e.g. `NIGERIA TAX ACT`) → read directly as text; genuine `%PDF` → standard PDF path. (The container `.json` manifest gives page order — preserve it as the page-anchor index.)
2. **Year / identity verification** — confirm the document's internal title & citation (e.g. "CAP C21 LFN 2004") matches the intended instrument; resolve filename-vs-title mismatches (VAT `2025`; CITA `2007`) before setting `document_year`. Mismatch on *content* → `BAD-SUB`, exclude.
3. **Text-quality / completeness check** — sample mid-document; empty → `OCR`; abnormally low char/page or bill-stage markers → `PARTIAL`, recover from images. English-language diagnostics: ligatures/§/₦, "assessable profits", "paid into", section numbering intact.
4. **OCR (conditional)** — for empty-text ZIPs, rasterize is unnecessary (images already present): OCR the embedded `N.jpeg` with an **English** model (Tesseract `eng` / ABBYY), **preserve page boundaries** (retain `N` as `page_start`/`page_end` anchor so every clause keeps its page).
5. **Percentage/fund QC** — after OCR/recovery, for every passage the assignment-grammar sweep flags, verify allocation percentages and fund names **against the page image**, digit-for-digit (e.g. Dev-Levy split 50/15/10/8/8/5/4; TET rate 2→2.5→3; NITDA 1%). OCR errors in a share or a dropped fund name are load-bearing; this bounded check is mandatory.

---

## 4. Cross-year / cross-document comparability warnings (record; do not silently pool)

- **Structural break — the 2026 consolidation (mass event).** The NTA + NTAA + NRS + JRB (effective 1 Jan 2026) simultaneously **repeal** CITA/PITA/PPTA/VAT/CGT/SDA and **merge** four earmark levies (TET, NITDA, NASENI, Police Trust Fund) into the **4% Development Levy** (NTA §59), then re-split it seven ways (50% TETFund / 15% NELFUND / 10% Defence & Security / 8% NITDA / 8% NASENI / 5% Cybersecurity / 4% NBTI). This is one dated but **package-confounded** discontinuity: cleanly *timed*, not cleanly *identified* (everything moves at once). Flag per register **A4**; it is a merger under `decision_rules §2` (new `instrument_id`, `predecessor_id = [TET, NITDA, NASENI, PTF]`) with a **nested allocation key** (`share_level` 1 = levy→special account, 2 = seven beneficiary shares).
- **Second petroleum break — PIA 2021 (now held, Gazette text).** PPTA is *partly superseded by the Petroleum Industry Act 2021*, which restructures upstream taxation (**Hydrocarbon Tax**) and — load-bearing for the inventory — creates **new purpose-restricted destinations** the old PPTA lacked: the **Host Communities Development Trust**, the **Frontier Exploration Fund**, and an **environmental remediation fund** (grammar sweep already fires densely on all three). So the 2021 event is not merely a base change on the petroleum instrument but a **destination-set expansion** (`decision_rules §3`: new `pair_id`s entering the set). Petroleum thus carries **two** in-window discontinuities (2021 PIA, 2026 NTA); both are now attested in-corpus. Verify percentages/shares (e.g. HCDT contribution rate, Frontier Exploration Fund quota) digit-for-digit against the Gazette per §3.5.
- **Base-definition dependency (cross-document).** The profits-based earmark levies (TET, NITDA, NASENI) are surtaxes on the **"assessable profits"** base *defined in CITA*. `tax_base_detail` on those source rows is a **dangling reference** until CITA is extracted; reconciliation joins them on the base term. Read CITA before/with Tier 2 to avoid unresolved base refs (a sequencing choice — flag either way; reconciliation resolves it regardless of order).
- **Point-in-time reconstruction, not per-year snapshots.** Standing Acts are collected `once`; the TET rate path (2%→2.5% by **FA2021**→3% by **FA2023**) lives in the Finance-Act chain, applied as `predecessor_relation = amends` (same `instrument_id`, `decision_rules §9`). The yearly state is *derived* by replaying amendments through year *t*. Do **not** treat any single Act as the year-*t* value.
- **Finance-Act commencement ≠ enactment.** FA2023 has irregular/late commencement (external record; the TET 3% is "effective September 2023"). Treatment dates are **effective dates** — extract each Finance Act's **commencement clause** and store the effective date separately from the enactment year, else the rate series smears across the year boundary.
- **VAT sharing formula.** The VAT Act embeds a federal/state/local **revenue-sharing** split — a `tax_sharing_general` boundary case (register **A10**), recorded and flagged, filtered out of the earmark subset at analysis, **never** silently dropped at extraction.
- **De-jure vs de-facto.** Every figure here is legal assignment (register **A1**). No realized revenue/spending is in this corpus; the Appropriation/Budget amounts layer (Tier 5) and execution data are separate and absent.

---

## 5. First-pass corpus decision

**In scope (first pass):**
- **T1 consolidation** — NTA (plaintext, ready), NTAA/NRS/JRB (embedded text OK). Extract first (current law; densest single earmark event; terminal node of every lineage chain).
- **T2 establishing Acts** — NITDA, NASENI, NHF (text OK); **NHIA and NPTF after OCR**; **TETFund after image-verification** (bill/partial hazard). All four Development-Levy predecessors now in corpus.
- **T2.5 principal Acts** — CITA, PITA, VAT, CGT, SDA, PPTA (text OK); **PIA 2021 (text OK, Gazette)** — petroleum lineage now complete across both breaks. Swept exhaustively with the English assignment-grammar lexicon (A2) for (i) base/rate definitions the levies depend on, (ii) any embedded earmark/sharing clause. PIA in particular yields several purpose-restricted petroleum destinations; most CITA/PITA/VAT/CGT/SDA rows are `is_purpose_restricted = 0` (general budget) recorded for the sum-check per **A10**.
- **T3 amendment chain** — FA2021 (text OK); **FA2019, FA2020, FA2023 after OCR**. Extract commencement clauses (effective dates).

**Deferred / not yet held (pull surgically; log as `unobserved`):**
- **Finance Act 2022** — existence uncertain; verify against Gazette before recording present *or* absent.
- **Tier 4** — Federation Account / RMAFC allocation instruments (constitutional revenue-sharing / derivation; `tax_sharing` boundary, extract-broad when pulled).
- **Tier 5 (separate amounts table, not evidence rows)** — Appropriation Acts + Budget Office fund tables (incl. the 2024/2025 Appropriation re-enactments); the Development-Levy budgeted envelopes are the CST-analogue.

**Schema-stress flags to resolve *before* bulk extraction (per core C9/C10 — additive extension, log CIV vs NGA provenance):**
- `document_type` needs NGA-additive values: `establishing_act`, `principal_tax_act`, `finance_act`, `consolidated_tax_act` (NTA), `appropriation_act`.
- `tax_instrument` needs a bucket for a profits-based earmarked surtax (candidate `profits_surcharge` / `education_levy`) rather than forcing TET/NITDA/NASENI into `other`.
