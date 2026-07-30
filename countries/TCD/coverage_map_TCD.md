# Coverage Map — Chad (TCD) corpus

**Purpose.** Authoritative record of what source documents exist, their real format/quality, and which pre-processing gate each must pass before it enters extraction. This is the honest denominator for any coverage statistic and the guard against silent false nulls. Missing != absent: the absence of a document for a year does not license the inference that no earmark existed or changed that year.

**Status.** First entry. Corpus holds one document (`TCD_2024_CGI`). Chad is CEMAC, not UEMOA; CORE C1-C10 applies unchanged, language is French so the A2 lexicon carries over from CIV.

---

## 1. Document inventory

Legend — Status: `OK` (clean text layer, ready) · `OCR` (needs OCR/re-render) · `MISSING` (confirmed absent) · `BAD-SUB` (wrong-year/wrong-content file served; excluded) · `DEFER` (available, out of first-pass scope).

| Year | Document | document_id | Status |
|------|----------|-------------|--------|
| 2024 | Code Général des Impôts | `TCD_2024_CGI` | OK — gate passed (353 pp, double-column, see §3) |

No other document is held. Cells are added as documents are acquired; a year absent from this table means acquisition has not been attempted, not that no document exists.

**No annexe fiscale column.** Chad's annual fiscal instrument, per CGI2024's own citations, is the LFI (`LFI 2017`, `LFI 2020`, `LFI 2024`), not a separate annexe fiscale as in CIV. `document_type = loi_finances_initiale` covers it; no enum extension needed.

### 1.1 Acquisition list (from CGI2024's in-line citation tags)

CGI2024 tags amended articles with their amending instrument (`Art. 217 (art 52 LFI 2020)`). Sweeping the tags gives a document-attested acquisition list. Counts are citation frequency, not earmark frequency.

| Instrument | Citations | Priority |
|---|---|---|
| LFI 2024 | 56 | high |
| LFI 2023 | 29 | high |
| LFI 2020 | 23 (+5 as `LF 2020`) | high |
| LFI 2018 | 23 | medium |
| LFI 2017 | 22 | medium |
| LFI 2019 | 16 (+1 `LF 2019`) | medium |
| LFI 2021 | 11 | medium |
| LFI 2022 | 6 | medium |
| LFI 2016 | 1 (+3 `LF 2016`) | low |
| LF 2017 / LF 2018 / LF 2023 | 3 / 2 / 3 | low — naming variant, verify whether same instrument |
| LFR 2020 | 1 | high — see §4 |

---

## 2. Known corpus hazards

CIV's three hazards are recurring; carry them forward as the default suspicion for every new Chad file. CGI2024 status: format lie — not present (`%PDF-1.7`); year lie — not present (internal header `CODE GÉNÉRAL DES IMPÔTS 2024`); text-layer lie — not present (clean UTF-8, accents intact).

Two hazards new to this corpus:

1. **Column layout lies about itself under naive extraction.** CGI2024 is double-column on a narrow page (419.6 x 595.4 pt). An x0 histogram reads as continuous and would wrongly certify single-column. Only the A1 canary on actual text exposes the splice:
   > `LIVRE III – RECOUVREMENT DE conditions prévues aux articles 125 à 128, 147 et 179 sont immédiatement exigibles pour la`

   Generalizes: the canary is the certifying check, a coordinate histogram is at best a hint. Resolved by crop (§3).

2. **Duplicate annexe numbering.** Two blocks titled `ANNEXE III` (p257 amortisation rates; p305 procédure comptable). Do not deduplicate — if either yields a row, record in `source_internal_inconsistency` and disambiguate `legal_article` by page anchor.

---

## 3. Pre-processing gate (A6) — `TCD_2024_CGI`

| Step | Result | Evidence |
|---|---|---|
| Format diagnosis | PASS | Header `%PDF-1.7`. |
| Year verification | PASS | Internal header `CODE GÉNÉRAL DES IMPÔTS 2024` = filename year. |
| Text-quality check | PASS | 1,218,826 chars; coherent French; accents intact at mid-document sample (p161, p251). |
| OCR | Not required | Native clean text layer. |
| Column-aware extraction | RESOLVED | Gutter x ≈ 208 (left column ends 195-198, right begins 220; stable across 46 sampled body pages). Crop `(0,0,208,h)` then `(208,0,w,h)`. Canary re-test on p161 returns contiguous clauses. Reader: `read_tcd.py`. |
| Percentage/fund QC | PENDING | Mandatory, see below. |

**Provenance caveat.** Metadata reports `Producer: iLovePDF`, `ModDate: 2026-07-14` — the file passed through a third-party web tool and is not a certified-canonical original. No diagnostic suggests content damage. Non-blocking; re-obtain from DGI Tchad / Ministère des Finances where feasible.

**Image-QC requirement (mandatory, bounded).** Because the file passed through a re-processing tool of unknown fidelity and column-aware cropping reconstructs reading order, every load-bearing figure (allocation shares, fund names, rates) reaching an evidence row must be verified against the rendered page image, digit-for-digit, before that row is marked `validated`. A handful of passages per livre, not a full re-read.

---

## 4. Cross-year comparability warnings

- **Single-year snapshot.** A CGI is a stock (the law as of 2024), not a flow (the year's changes). Supports a 2024 cross-sectional inventory only; no time-series or event-study design until the LFI series arrives.

- **Consolidated-code dating problem.** CGI2024 states what the law is in 2024, not when each earmark was established. Its `(art N LFI YYYY)` tags date the most recent amendment, not establishment; untagged articles carry no date. Inferring establishment year from an amendment tag violates C8. `year_established` is unobservable from this document for most instruments — it comes from the LFI series or stays null with `evidence_status = unobserved` (register A7).

- **Repeal-in-place and left truncation.** 49 `Abrogé` markers, including assignment-bearing chapters retained as headings over a repealed article (`CHAPITRE IX: TAXE AU PROFIT DU FONDS NATIONAL DE DEVELOPPEMENT DU SPORT — Art. 216 – Abrogé (art 25 LFI 2017)`). Extract the stub with `change_type = repeal` and `predecessor_ref` from the tag; a naive count would either include the dead heading (over-count) or skip the stub (lose the repeal event). Earmarks repealed and deleted outright leave no trace at all, so CGI2024 is blind to pre-2024 deaths. Absence in CGI2024 is not evidence a levy never existed.

- **No amount_budgeted source.** A CGI contains no appropriations; there is no CST/special-account table in this document (CIV's came from the LFI). Chad supports no revenue-magnitude or fungibility test until the LFI series is held (register A1, A5).

- **Register A6 (rectificatives excluded) — qualified for Chad.** A6 requires per-country verification. Chad's premise partially fails: CGI2024 cites `LFR 2020` at `Art. 241 (Art 6 LFR 2020)` — a rectificative that amended the code, which CIV's never did. Inspection: the cited article governs VAT deduction exclusions, a base rule, not earmark creation/repeal/re-keying. The exclusion survives for the first pass but rests on a one-case inspection, not a structural argument. Conditional; revisit on acquisition of any LFR.

- **Document-availability bias (register A7).** One of ~13 candidate document-years held. Gaps are unobserved, never zeros.

---

## 5. First-pass corpus decision

**In scope.** `TCD_2024_CGI`, whole document, via LOCATE (whole-document) then EXTRACT (per-livre).

**Structural parameter vector (A0):** `TCD_2024_CGI = {fr, double, long, sparse, mixed, livre+article}`

| Parameter | Value | Basis |
|---|---|---|
| `language` | fr | Native French; A2 French lexicon unchanged from CIV. |
| `column_layout` | double | Gutter x≈208; canary failed naive, passed after crop (§2, §3). |
| `length_class` | long (353 pp) | Above the ~80 pp threshold; A3 requires sectioning by the document's own divisions. |
| `earmark_density` | sparse | Assignment grammar thin and uniform across all divisions (0.47-0.76 cue-hits/page; no concentrated livre); A4 LOCATE-then-EXTRACT. |
| `content_form` | mixed | Body prose clauses; annexes contain real tables (5 detected p258) alongside prose; A5 applies both to their regions. |
| `numbering` | livre+article | Contiguous Art. 1-1133 across Livres I-V; annexes re-number from Art. 1. Coverage unit = article, grouped by livre. |

### 5.1 Division enumeration — C9 coverage checklist and EXTRACT batch plan

Divisions enumerated contiguously (front matter, body, annexes). This is the denominator for the LOCATE sweep-coverage certificate; every division must be certified swept, including those certifying zero hits.

| # | Division | Pages | Articles | Cue hits | Hits/pp | Batch |
|---|---|---|---|---|---|---|
| 0 | SOMMAIRE | 1-8 | — | — | — | Not extracted. Certify `0 (enacting)`: its assignment grammar is a table-of-contents echo of body headings; navigation is not assignment (C1). |
| 1 | LIVRE I : IMPÔTS D'ÉTAT | 9-143 | 1-758 | 79 | 0.59 | 1 — largest; sub-batch by TITRE/CHAPITRE if a single call is intractable. |
| 2 | LIVRE II : IMPÔTS PERÇUS AU PROFIT DES COLLECTIVITÉS LOCALES ET DE DIVERS ORGANISMES | 144-160 | 759-839 | 13 | 0.76 | 2 — highest expected yield; its title is an assignment clause. Expect heavy `is_purpose_restricted = 0` / `tax_sharing_general` (register A10) alongside genuine earmarks. |
| 3 | LIVRE III : RECOUVREMENT DE L'IMPÔT | 161-182 | 840-982 | 12 | 0.55 | 3 — procedural; expect §11/§11.1 cost-recovery calls rather than earmarks. |
| 4 | LIVRE IV : OBLIGATIONS | 183-199 | 983-1037 | 13 | 0.76 | 4 — declaratory; low earmark expectation, sweep regardless. |
| 5 | LIVRE V : SANCTIONS ET PÉNALITÉS | 200-252 | 1038-1133 | 25 | 0.47 | 5 — fines-as-source question (open CIV item under C1) lives here. Extract-broad; do not pre-resolve. |
| 6 | ANNEXES I-VI (incl. duplicate ANNEXE III) | 253-353 | re-numbered 1-90 | 70 | 0.69 | 6 — mixed prose+table (A5). Annexe IV "Dispositions non codifiées" (259-280) is the priority sub-region: taxe civique, centimes additionnels, pourcentage sur le produit des — assignment-bearing, and being non-codified may hold earmarks absent from the body. |

Totals: 6 enacting divisions; Art. 1-1133 (body) + Art. 1-90 (annexes); 345 body pages; 175 (51%) carrying at least one assignment cue.

**Deferred.**
- LFI series 2016-2024 (§1.1) — not held. Binding constraint on the Chad extension: no time variation, no `amount_budgeted`, no reliable `year_established` without it. Acquisition is the next action, ahead of further extraction.
- LFR series — excluded on the CIV precedent but qualified for Chad (§4). Reversible on acquisition.
- Past-year CGIs — only 2024 held. Pull surgically to date a specific standing earmark, never wholesale.

---

## 6. C10 extension points — watch list

Chad is the first non-UEMOA (CEMAC) country in the corpus. Core invariant; enum extensions additive-only; record any that fire in the assumptions register.

- `document_type` — `cgi` and `loi_finances_initiale` both cover Chad. 
- `assignment_type` — CEMAC appears 37 times in CGI2024, but the probe found no prélèvement communautaire or TCI instrument; references look like regional-scope context (residence, treaty, harmonisation), not a levy. Verify during LOCATE. If a CEMAC community levy exists, `community_levy_external` should cover it — confirm rather than assume.
- `rate_basis = deferred_arrete` — Chad is civil-law Francophone; arrêté is the literal instrument, no generalization strain.
- `beneficiary_type = collectivite_territoriale` — Livre II's title indicates heavy use. No extension expected.
