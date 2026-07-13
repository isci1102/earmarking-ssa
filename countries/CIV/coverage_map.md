# Coverage Map — Côte d'Ivoire corpus (2012–2026)

**Purpose.** Authoritative record of what source documents exist, their real format/quality, and which pre-processing gate each must pass before it enters extraction. This is the honest denominator for any coverage statistic and the guard against silent false nulls. Missing ≠ absent: the absence of a document for a year does **not** license the inference that no earmark existed or changed that year.

---

## 1. Document inventory by year and type

Legend — Status: `OK` (clean text layer, ready) · `OCR` (needs OCR/re-render before extraction) · `MISSING` (not available) · `BAD-SUB` (a wrong-year or wrong-content file was served; excluded) · `DEFER` (available but out of first-pass scope).

| Year | Loi de finances initiale | Annexe fiscale | Loi de finances rectificative | CGI |
|------|--------------------------|----------------|-------------------------------|-----|
| 2012 | OK (verify) | present — **OCR** (verify text layer) | — | — |
| 2013 | OK (verify) | MISSING | — | — |
| 2014 | OK (verify) | MISSING | DEFER (rectificative) | — |
| 2015 | OK (verify) | MISSING | — | — |
| 2016 | **BAD-SUB** (site served 2017 file) | **BAD-SUB** | — | — |
| 2017 | OK (verify) | present — **OCR** (font layer corrupt: extracts as mojibake; page images fine) | DEFER (rectificative) | — |
| 2018 | OK (verify) | MISSING | — | — |
| 2019 | OK (verify) | MISSING | — | — |
| 2020 | OK (verify) | MISSING | DEFER (rectificative) | — |
| 2021 | OK — but Ghostscript-produced, **verify/OCR** | MISSING | DEFER (rectificative) — inspected: amount-revision only, no structural earmark change | — |
| 2022 | OK (verify) | MISSING | — | — |
| 2023 | OK (verify) | **OK** | DEFER (rectificative) | — |
| 2024 | OK (verify) | **OK** | — | — |
| 2025 | OK (558 pp, ABBYY, text OK) | **OK** (genuine ABBYY PDF v1.5, 150 pp, clean text; internal title "ANNÉE 2025" — filename corrected by researcher; earlier "mislabeled text" note superseded) | — | — |
| 2026 | OK (583 pp, ABBYY, text OK) | **OK** | — | **OK — use PDF version** (273 pp, only 2026 edition held; two-column layout → read per-column to avoid clause interleaving, cf. gold GOLD_07 canary passage) |

> Fill/confirm the "verify" cells as each file is diagnosed. The table records the *known* state as of hand-off; every `OK (verify)` must be confirmed by the format-diagnosis gate (§3) before extraction, never assumed.

---

## 2. Known corpus hazards (all three have been observed — treat as recurring, not one-off)

1. **Extension lies about format.** The "2025 annexe `.pdf`" was plain UTF-8 text renamed to `.pdf` (no PDF header). Diagnose actual bytes, not the extension.
2. **Filename lies about year.** 2016 has no genuine document; the DGBF site served the 2017 file in the 2016 slot. Verify each document's *internal* stated year against its filename; drop wrong-year substitutes.
3. **Text layer lies about readability.** The 2017 annexe is a real PDF whose embedded font has no Unicode cmap → `pdftotext` returns mojibake though the page renders fine to the eye. This is a re-render/OCR problem, not a scan problem. Rasterize pages → OCR with **French** language model → recover clean text.

---

## 3. Pre-processing gate (must pass before a file enters extraction)

For every file, in order:
1. **Format diagnosis** — inspect header bytes; confirm it is the format claimed. Route: real-PDF → step 2; plain-text-mislabeled → read directly; ZIP/Office archive → extract; scanned/no-text → OCR.
2. **Year verification** — confirm the document's internal title year matches its filename year. Mismatch → `BAD-SUB`, exclude.
3. **Text-quality check** — extract a sample; if it returns non-French/mojibake or empty, mark `OCR`.
4. **OCR (conditional)** — rasterize to images, OCR with a French model (Tesseract `fra` or ABBYY), **preserve page boundaries** (retain `\f`/page anchors so every clause keeps `page_start`/`page_end`).
5. **Percentage/fund QC** — after OCR, for every passage the assignment-grammar sweep flags, verify allocation percentages and fund names **against the page image**, digit-for-digit. OCR errors in a share ("50%"→"60%") or a dropped fund name are load-bearing data errors; this bounded check (a handful of passages per file) is mandatory, not optional.

---

## 4. Cross-year comparability warnings (record; do not silently pool)

- **CST granularity break.** The loi-de-finances Comptes d'Affectation Spéciale table changed classification granularity over time: ~6 aggregate accounts (2021 and earlier) → 34–40 itemised accounts (2025–2026). Account-level counts and `amount_budgeted` series are **not comparable across this break** without adjustment. Flag the break year in any time-series use.
- **De-jure vs de-facto.** `amount_budgeted` (from the CST table) is an appropriation, not an execution figure. The de-jure inventory cannot, on its own, measure realized revenue or spending. De-facto testing requires separate execution sources (TOFE, BOOST, budget-execution reports).
- **Document-availability bias.** Uneven coverage across years (annexes present only for 2012, 2017, 2023–2026) is itself non-random and correlates with the same institutional-quality factors that may drive outcomes. Coverage is an evidence property, not an earmark property; treat gaps as unobserved, never as zeros.

---

## 5. First-pass corpus decision

**In scope (first pass):** annexes fiscales (2023–2026 clean; 2012, 2017 after OCR) · lois de finances initiales (CST tables; OCR pre-2022 as needed) · CGI 2026.
**Deferred:** lois de finances rectificatives — inspected (2021 initiale vs rectificative): identical CST account set, amount revisions only, **no** creation/repeal/re-keying of earmarks. Rectificatives modify appropriations, not earmark structure; excluded from the de-jure inventory, retained as an optional source for execution analysis. Reversible if a later rectificative is found to re-key an account.
**Deferred (targeted):** past-year CGIs — only the 2026 edition is held; older editions to be pulled *surgically* to date a specific standing earmark's establishment year, not ingested wholesale.
