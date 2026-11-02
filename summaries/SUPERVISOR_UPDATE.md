# Earmarked taxes in SSA — progress update and decisions needed

*28 September 2026. Companion file: `AFR_PROGRESS_TRACKER.xlsx` (country-by-country status).*

## 1. Where we are

- **Scope widened** from 19 countries to **49**: 44 SSA countries (all sovereign SSA countries except Somalia and Eritrea) plus 5 North African countries as a comparison group (DZA, EGY, LBY, MAR, TUN). Mauritania and Djibouti are excluded as MCD countries; Sudan is excluded.
- **Original 19 countries:** earmark and census extractions done on the earlier corpus. They will be re-run only where the new corpus definition adds documents.
- **South Africa:** first full run of the new pipeline, completed.
  - 44 documents read in full; 140 evidence rows (51 source rows, 89 allocation rows).
  - All automated consistency checks pass.
- **Ghana:** corpus mapped (52 documents: tax Acts, 20+ levy and fund Acts, the earmark cap law Act 947, PFM Act, revenue-management laws).
- **Design classes:** 2 verified from the corpus map (ZAF, GHA), 9 desk-checked (East Africa), 38 still working hypotheses.

## 2. The new pipeline, one country at a time

| Step | What it does | Why |
|---|---|---|
| **Stage 0: corpus map** | Web search for the latest official texts; outputs a manifest (one row per document, with source quality and known gaps) | Makes the corpus explicit and comparable across countries before any extraction |
| **Download** | Saves each text; checks each file against its title | Catches wrong editions and scanned files early |
| **Keyword pre-scan** | Script flags every passage with assignment wording (`find_hits.py`) | Independent recall check; costs nothing |
| **Extraction** | One run per country, document by document, reading every document in full | Scales to large corpora (ZAF: about 2,700 pages) and resumes if interrupted |
| **Reconciliation** | Links rows into instruments and pairs source with destination | Done by me, after extraction |

The extraction is quote-anchored: each row carries the verbatim clause and its page. An earmark is recorded only when an enacting text names the recipient of a charge's proceeds.

## 3. Rules adopted, and why

### 3.1 What goes into a country's corpus

The corpus is defined by **content blocks**, not by document names, because what a "Code général des impôts" contains varies from country to country (e.g. the CIV volume includes parafiscal taxes and the mining and petroleum codes; the Congo volume includes levies for local governments and "divers organismes").

| Block | Content | Rule |
|---|---|---|
| A | State taxes (income, VAT, excise, stamp, registration) | In |
| B | Customs law and levies in customs schedules | In |
| C | Parafiscal, levy and fund laws (charges for a named agency or fund) | In; this is where most earmarks are |
| D | Local-government shares set by national law | In |
| E | Natural-resource fiscal regimes and revenue-management laws | In |
| F | Budget-law allocations, PFM rules on earmarking, cap laws | In |
| G | Social security contributions | Not searched for; extracted and flagged if printed in a corpus document |
| H | Administrative fees priced to a service | Not searched for; same rule |
| I | Procedure: penalty shares, collector shares, collection-cost retentions | In |

**Why G and H are out:** social contributions are earmarked by construction and classified separately from taxes in GFS; fee texts are a long tail of low-value documents. Searching for them in some countries and not others would bias counts. Flagged rows remain available for a robustness check.

**Regional and community levies** (UEMOA, CEMAC, ECOWAS, EAC, AU levy) are not collected separately; they are recorded when they appear in a national text.

### 3.2 Latest snapshot, not history

- For each text, the latest consolidated or official edition, with the date it is current to.
- Amending laws are not added to rebuild a text, **except** when the amendment replaces a charging or allocation provision that no consolidation incorporates (e.g. Ghana's Act 1132 of 2025, which replaces the schedule of funds under the cap law). Otherwise the snapshot would record allocations that are no longer in force.
- Texts known to be in force but not found are recorded as gaps in the manifest.
- Each document carries its source quality: official (gazette, parliament), administration (revenue authority, ministry, legal information institute) or private.

### 3.3 Design classes, derived after the corpus map

| | One main volume carries the main taxes | Taxes in separate laws |
|---|---|---|
| **Civil-law drafting** | D1 | D2 |
| **Common-law drafting** | D4 | D3 |

The class describes where the legal texts sit, which determines how the corpus is collected. It is assigned **after** the corpus map, never in advance. Legal origin is kept as a separate variable for the analysis.

### 3.4 Feasibility, applied mechanically

A country is **high** feasibility if current official or administration texts are found for blocks A, B and C; **medium** if one of them is incomplete, private-source or more than about five years old; **low** if one is missing. The rule is fixed in advance so that exclusions are not chosen case by case: data availability correlates with state capacity, which also drives revenue mobilisation.

### 3.5 Main extraction rules added since the CIV pilot

- **Who receives vs why:** the recipient type records who the text names (fund, agency, ministry, public employees, local governments…); a separate field records whether the share is a collection-cost retention or a proceeds share.
- **A recipient named as a fund is a fund,** even if it is a legal entity with its own board.
- **Shares:** residual shares ("the balance") and floors ("at least 40 per cent") are now coded with their values.
- **Source and destination in different Acts** (typical in common-law countries): each half is recorded where it appears, and rows are linked by an explicit pointer.
- **Instrument names** are never left generic ("a levy"); the name is taken from the same text.
- **New structural patterns** are logged and flagged, never forced into new categories, so that all countries share one vocabulary.

## 4. Why re-run the original countries

The earlier Francophone corpora were built mostly around the general tax code, while the new corpora include levy, fund and resource laws. Without a common corpus definition, earmark counts would rise mechanically where corpora are broader, and that difference would be correlated with legal origin. Re-running where Stage 0 adds documents keeps cross-country comparisons valid.

A first test is planned on Côte d'Ivoire: compare the revenue allocations in the 2026 initial finance law with the existing CGI extraction. If the CGI already carries almost all of them, civil-law corpora can stay CGI-centred; if not, the latest finance law is added for every D1 country.

## 5. Questions for you

1. **North Africa:** is a comparison group the right role? Does it change the paper's title or framing?
2. **Language verification:** Portuguese (5 countries), Spanish (GNQ) and Arabic texts (EGY, LBY) are hard for me to verify. Should these be handled differently (colleague review, reduced depth, or later phase)?
3. **Scope:** do you agree with excluding social contributions and administrative fees (flagged when found)?
4. **Classification of flows:** should regulatory levies that fund the payer's own supervisor, and collector shares (e.g. CIV's FNAOJ, fonds communs), be treated as a separate class from earmarks in the analysis?
5. **Feasibility:** are you comfortable excluding low-feasibility countries by the mechanical rule (South Sudan is the likely first case), reported with reasons?
6. **Ghana case study:** confirm the de jure vs de facto comparison, using the budget and expenditure data available for Ghana's earmarked funds.
7. **Priorities:** given the internship timeline, should the order be the original 19 first, then new English-language countries, then civil-law and North Africa?
