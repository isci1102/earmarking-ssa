# CORPUS DISCOVERY — PROMPT (v1.4)

**Input.**

- `COUNTRY = <name> (<ISO3>)`
- `COUNTRY_FOLDER = C:\Users\alexa\Documents\earmarking-ssa\countries\<ISO3>\`

**Output.** Two files in `COUNTRY_FOLDER`:

- `{ISO3}_corpus.csv`: the document list, read by `download_corpus.py` (format in §5);
- `{ISO3}_corpus_brief.md`: a one-page brief (format in §6).

Do not download the documents yourself.

---

## 1. Goal

Find the documents in which the country's **current national law**:

- **(a)** imposes the charges whose proceeds are assigned; and
- **(b)** assigns those proceeds to destinations (funds, agencies, special accounts, tiers of government, programmes, regional bodies).

The documents feed the earmark allocation and instrument extraction prompts. Rates and tariff schedules are not needed.

Find them by a **fixed procedure, identical for every country**. The procedure, not your judgment of completeness, defines when the search ends.

## 2. Rules

### 2.1 Which version of a text

**A text the user can download comes first.** The user does not use rates, and assignment clauses change rarely, so a free, downloadable older text beats a current text behind a login.

**"Downloadable" means downloadable by the user's script.** Government, parliament, gazette, revenue-authority and regulator sites serve files to the script. **SAFLII and lawlibrary.org.za / Laws.Africa block it** (HTTP 403), so their texts must be saved by hand. Therefore:

- whenever a government or regulator site has a copy of the Act, **even an older or as-enacted one**, list that copy;
- use SAFLII or lawlibrary only for an Act that no government or regulator site holds.

For each Act or code, take the first of these that exists:

1. **A free, downloadable consolidated version**: a text that incorporates amendments up to a stated date ("as amended", "as at", "à jour", "édition 2026", "actualizado", "atualizado / actualizado", "texto consolidado", "versión consolidada"). It counts as consolidated whoever publishes it, as long as it is free; `official` (§5) records the host separately.
2. **A free, downloadable original or older consolidated text, plus the annual amendment laws enacted after its date**, and only these:
   - **civil law:** every loi de finances / Lei do Orçamento / Ley de Presupuestos Generales del Estado enacted after the edition of the code you list (in practice, usually only the latest one);
   - **common law:** the **main annual revenue-amendment Acts** enacted after the text's date, within the last 5 calendar years (current year included). These are the annual Finance Act, or its national equivalent (South Africa: Rates and Monetary Amounts Act and Taxation Laws Amendment Act). Tax-administration and procedure amendment Acts are excluded;
   - **any amending Act whose title names a specific levy or fund** already in the list (e.g. "Road Accident Fund Amendment Act").
3. **A landing page**, only when no free downloadable version of the text exists at all.

**Rule 2 applies text by text.** An annual amendment law (within the 5-year window) is listed when **at least one** listed core text is dated before it. It is not listed when **every** listed core text it amends already incorporates it.

Example: the Income Tax Act is consolidated to 2026, but the Customs and Excise Act is only available as at 1968. The annual amendment Acts of the last 5 years are then listed, because they are not in the Customs text.

Never collect other amendments. Never list tariff or rate schedules.

### 2.2 Sources

- **Prefer official hosts:** government, parliament, official gazette, revenue authority, statutory regulators.
- **Otherwise use, in this order:**
  1. Laws.Africa and the LII sites (SAFLII, GhaLII, ULII, Kenya Law, ZambiaLII, MalawiLII, ZimLII, LesLII, NamibLII, SierraLII, LiberLII, SeyLII …). SAFLII and lawlibrary.org.za come last among these (§2.1); the other LII sites are untested, so record which ones download and which fail in the brief;
  2. Droit-Afrique, Legis-PALOP (Lusophone), FAOLEX, NATLEX, ECOLEX;
  3. any other site holding the **full legal text** (e.g. a private mirror of an official edition), with `official = 0` and the original publisher in `note`.
- **Never list subscription or commercial readers** (Acts Online / acts.co.za readers, LexisNexis, Juta, sars.mylexisnexis …), or any page that needs a login or payment. They may serve as discovery sources (§2.3), to learn an Act's number and latest amendment.
- **Always put the country name in queries**, and use site-restricted searches to the country's domains where possible. Generic queries drift to other countries ("Code général des impôts" returns Morocco and France).

### 2.3 Discovery sources

These help you learn *which* documents exist, but are **never listed** in the corpus:

- PEFA reports;
- IMF and World Bank reports;
- budget speeches, statements and estimates of expenditure (lists of public entities and their revenue sources);
- Auditor-General reports on statutory funds;
- Big-4 tax guides, unofficial legal databases, news.

Name the useful ones in the brief.

### 2.4 Checking links

- **Open every URL before listing it.** Confirm the title and year, and that it is legal text, not a summary or a table of contents.
- **A cut-off fetch is fine.** Long PDFs come back truncated; the opening pages are enough. A scanned PDF that returns no text is listed if the listing page confirms its title (say "scanned" in `note`).
- Open only enough to confirm. **Do not read whole documents.**
- **Never construct or guess a URL.** Use links that appear on a page you opened.
- **`url_type`:**
  - `direct_file`: the URL returns the file (PDF, DOC, DOCX), including links that look like web pages but serve a file.
  - `html_full_text`: the web page itself contains the full text of the law (typical of Laws.Africa / LII pages for consolidated Acts). It is saved as HTML and read by the extraction.
  - `landing_page`: neither of the above (a JavaScript reader, a login wall, a page linking to a file you could not open). The user downloads it by hand. Use it only when no `direct_file` or `html_full_text` exists.
- **Blocked to you.** The free full-text law sites often block automated fetch tools (robots.txt, HTTP 403). When such a page is blocked and a search result shows its title and version (Act name, number, "as at" date), list it with `checked = listing_only` and:
  - on **SAFLII or lawlibrary.org.za / Laws.Africa**: `url_type = landing_page`, because the user's script is blocked too and the user will save it by hand. Do this only when no government or regulator copy exists (§2.1);
  - on **other free law sites** (other LII sites, Droit-Afrique, Legis-PALOP, FAOLEX): keep its `direct_file` or `html_full_text` type; the user's downloader will try it.
- Any other blocked site → try another host for the same text. If none exists, list the blocked URL as `landing_page`.
- **Never move an identified Act to the gaps because its page is blocked.** If any URL for it is known, it is listed (as `landing_page` if need be, with the reason in `note`). The gaps list is only for Acts with **no** usable URL at all.

### 2.5 Scope

- **Exclude:** draft bills; explanatory memoranda on their own; commentaries and tax guides; subnational own-source laws; repealed texts.
- **Enacted texts with explanatory notes are included.** An enacted finance law or annexe fiscale that carries its law number is listed even if each article is preceded by an exposé des motifs. Say so in `note`.
- **Regional community levies** (UEMOA, ECOWAS, CEMAC, SACU …): list the **national** text that imposes or applies them. If none is found, name the regional act in the brief's gaps; do not list it.
- **Annual spending laws are excluded:** appropriation Acts, and annual division-of-revenue Acts that split revenue in amounts for one year. These are spending decisions, not assignments of a charge's proceeds.
- **Permanent revenue-sharing laws are included** when they fix a **share of revenue** in law: e.g. a common fund receiving a stated percentage of revenue, or a constitutional or organic allocation formula.
- Francophone, Lusophone and Hispanophone finance and budget laws stay in the checklist (Step 2), because they carry the special-accounts tables and consigned or earmarked revenue.

### 2.6 Budget

- About **60 web searches** in total: standard search throughout, plus at most **5 extended searches** in Step 5.
- **At most 60 documents.** If more qualify, keep those most likely to contain assignment clauses and name the rest in the gaps.

## 3. Procedure

### Step 1 — Country profile (≤ 3 searches)

Establish:

- the legal family: civil law Francophone / Lusophone / Hispanophone, common law, mixed;
- who collects revenue: revenue authority, separate customs, sector regulators, social-security bodies;
- the year of the latest finance law (or its equivalent) and the latest budget law;
- whether consolidated texts exist, and where.

### Step 2 — Core tax corpus (≤ 15 searches)

Search the best repository for the legal family first:

| family      | look first                                                   | then                                        |
| ----------- | ------------------------------------------------------------ | ------------------------------------------- |
| Francophone | DGI and Ministry of Finance / budget sites; official journal | Droit-Afrique; mirrors of the DGI edition   |
| Lusophone   | tax authority site; Diário / Boletim da República          | Legis-PALOP                                 |
| Hispanophone | Ministerio de Hacienda / Hacienda y Presupuestos site; Boletín Oficial del Estado | FAOLEX; CEMAC texts applied nationally |
| Common law  | revenue authority "legislation / laws we administer" page    | Laws.Africa / the country's LII; parliament |

Fixed checklist:

- **Francophone:**
  - **The DGI's full compilation of tax texts**, latest edition: the CGI **together with** the "autres textes fiscaux / textes fiscaux non codifiés / taxes parafiscales / fiscalité des collectivités / droits domaniaux" that the DGI publishes with it. These non-codified parts often hold most of the assignment clauses. If they are published separately, list each part.
  - The latest loi de finances. Its annexe fiscale, if published separately. The table of comptes d'affectation spéciale, whether it is an annex or an article of the loi de finances.
  - The customs code.
- **Lusophone:**
  - the code of each major tax (IRPS/IRS, IRPC/IRC, IVA, Imposto de Consumo / Especial de Consumo, Código Aduaneiro), or the Código Geral Tributário if it contains them;
  - the latest Lei do Orçamento (Geral) do Estado, including its consigned-revenue tables if published separately.
- **Hispanophone:**
  - the general tax law or tax code (Ley General Tributaria, Código Tributario, Ley de Reforma Fiscal, or equivalent) and the laws of each major tax not in it;
  - the customs code (for CEMAC members, the national text applying the CEMAC customs code);
  - the latest Ley de Presupuestos Generales del Estado.
- **Common law:**
  - the principal Acts for income tax, VAT, excise / customs (consolidated where possible);
  - the annual revenue-amendment Acts under §2.1 rule 2;
  - any consolidated revenue or levies Act.

### Step 3 — Lists of funds (≤ 5 searches)

Fetch the lists that name funds or bodies financed by levies or tax shares:

1. **Budget:** the comptes d'affectation spéciale table (Francophone), the statutory funds / public entities lists in the budget or estimates of expenditure (common law), the consigned-revenue tables of the Orçamento (Lusophone), or the earmarked-revenue (*ingresos afectados*) tables of the Presupuestos (Hispanophone).
2. **The latest PEFA report:** indicator PI-6 (2016 framework) or PI-7 (2011 framework), on extrabudgetary units and funds.

For each fund or body these lists show as financed by a levy or tax share, add its founding Act, or the levy Act if separate, to the Step 4 sector it belongs to.

### Step 4 — Sector sweep (all 17 sectors, every country; ≤ 30 searches)

For each sector:

- run **one** search, in the country's legal language (add English for non-English countries if useful). Useful words: pt *fundo, taxa, contribuição, receita consignada, consignação*; es *fondo, tasa, canon, afectación, recursos del fondo*;
- list **every** founding or levy Act the results reveal for that sector, not just the first;
- run a **second** search only if the first found nothing.

You may cover two sectors in one query when they share an Act. A sector with nothing after its searches is recorded `none found`.

Sectoral codes (Code minier, Code pétrolier, Code forestier, Code des communications électroniques, Code de l'environnement, Código Mineiro, Lei das Actividades Petrolíferas, Ley de Hidrocarburos, Ley de Minas …) belong here: in civil-law countries they often contain the assignment key.

| #  | sector                                                    | look for                                                                                                                                                                                 |
| -- | --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1  | roads and fuel                                            | road fund / road maintenance fund, fuel levy, road-accident fund                                                                                                                         |
| 2  | skills, training and payroll                              | skills / training levy, apprenticeship fund, housing fund                                                                                                                                |
| 3  | social security, health insurance and occupational injury | social-security and health-insurance funds and levies, occupational injury and disease funds                                                                                             |
| 4  | education                                                 | education trust fund, tertiary education fund                                                                                                                                            |
| 5  | telecom, ICT and postal                                   | universal service / access fund, telecom levy, postal code                                                                                                                               |
| 6  | broadcasting, media and culture                           | TV licence, audiovisual levy, public broadcaster, cinema / media / copyright funds                                                                                                       |
| 7  | energy and electricity                                    | rural electrification fund, energy levy, energy regulator levies                                                                                                                         |
| 8  | mining and petroleum                                      | royalties shared with local communities, local mining development funds, mine health and safety levies, petroleum funds                                                                  |
| 9  | forestry, wildlife and fisheries                          | forest fund, wildlife and fisheries levies                                                                                                                                               |
| 10 | agriculture and commodities                               | levies on each regulated commodity chain (cocoa, coffee, cotton, cashew, rubber, palm oil …), commodity boards, agricultural funds                                                      |
| 11 | environment and water                                     | environment fund, pollution / plastic levies, water code and water levies                                                                                                                |
| 12 | tourism                                                   | tourism levy, tourism development fund                                                                                                                                                   |
| 13 | aviation, ports and maritime                              | airport development fee, civil aviation levies, port and maritime levies, oil-pollution compensation                                                                                     |
| 14 | financial sector and insurance                            | regulator levies, deposit insurance, insurance levies, motor guarantee funds                                                                                                             |
| 15 | gaming and lotteries                                      | gaming levy, lottery proceeds, sport fund                                                                                                                                                |
| 16 | subnational sharing and regional community levies         | common funds for local governments, local-government finance law, permanent revenue-sharing laws (fixed shares of revenue), national texts applying UEMOA / ECOWAS / CEMAC / SACU levies |
| 17 | professional and occupational regulation                  | levies or fees funding professional councils and regulators (legal practice, health professions, engineering, accountancy …)                                                            |

### Step 5 — Close gaps, check, write the files

1. For the most important items still missing (a core-checklist item, a fund named in Step 3), run at most **5 extended searches** in total. Whatever is still missing goes to the gaps list.
2. Make sure every row's link was opened (§2.4). Prefer a `direct_file` or `html_full_text` over a `landing_page`.
3. Write the two files (§5, §6), then run the checks (§7).

## 4. What counts as one document

- **One row per file or page to download.** A code published in several volumes or parts is several rows. An official compilation (*recueil*) is one row.
- If the same text is available from two sites, list it **once**, from the best source (§2.2), and give the other URL in `note`.
- A finance law and its annexe fiscale are one row if published as one file, two rows if published separately.

## 5. `{ISO3}_corpus.csv`

UTF-8, comma-separated, header row, one row per document, columns in this order:

| column        | content                                                                                                                                                                                                                                                                                                                            |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `file_name` | `{ISO3}_{Short_Title}_{year}.{ext}`, with `ext` `html` for `html_full_text` rows. ASCII letters, digits and underscores only; unique. `year` is the same as the `year` column. Examples: `CIV_CGI_Autres_textes_fiscaux_2026.pdf`, `CIV_Loi_de_finances_2026.pdf`, `ZAF_Skills_Development_Levies_Act_2024.html` |
| `title`     | full title in the original language                                                                                                                                                                                                                                                                                                |
| `doc_type`  | `tax_code`, `principal_tax_act`, `finance_law`, `annexe_fiscale`, `budget_law`, `sectoral_code`, `establishing_act`, `levy_act`, `amending_act`, `regulation`, `compilation`, `other`                                                                                                                      |
| `role`      | `source` (imposes charges), `destination` (founds or finances a recipient), or `both`                                                                                                                                                                                                                                        |
| `sector`    | `general`, or a sector number from Step 4 (`1`–`17`)                                                                                                                                                                                                                                                                        |
| `year`      | finance and budget laws: the **budget year** (the LF for 2026 → 2026). Consolidated texts and compilations: the edition or "as at" year. Other texts: the enactment year                                                                                                                                                    |
| `vintage`   | `consolidated` (incorporates amendments to a stated date) or `as_enacted` (the text as passed, including finance laws and amending Acts)                                                                                                                                                                                       |
| `url`       | the link that was opened                                                                                                                                                                                                                                                                                                           |
| `url_type`  | `direct_file`, `html_full_text` or `landing_page` (§2.4)                                                                                                                                                                                                                                                                    |
| `official`  | `1` if the host is a government, parliament, gazette, revenue authority or statutory regulator, else `0`                                                                                                                                                                                                                       |
| `host`      | domain name                                                                                                                                                                                                                                                                                                                        |
| `checked`   | `opened` (the link was opened and matched), or `listing_only` (a free full-text law site blocked to you; title and version confirmed from a search result, §2.4)                                                                                                                                                              |
| `note`      | ≤ 1 sentence, or empty (other URL, original publisher, "scanned", "consolidated to 2025-03-01, later amendments not applied" …)                                                                                                                                                                                                  |

**Finance-law equivalents for `doc_type`:**

- `finance_law`: the annual law that changes taxes (loi de finances, Finance Act, Rates and Monetary Amounts Act …).
- `amending_act`: the annual tax-laws amendment Act.
- `budget_law`: Lei do Orçamento, Ley de Presupuestos Generales del Estado, and permanent revenue-sharing laws (appropriation and annual division-of-revenue Acts are excluded, §2.5).

**`role`:** most levy and fund Acts both impose and assign, so they are `both`. Use `establishing_act` when the Act's main object is the body or fund, and `levy_act` when it is the charge.

## 6. `{ISO3}_corpus_brief.md`

At most one page:

1. **Legal system** (≤ 10 lines): legal family; consolidated or fragmented corpus; who collects revenue; the latest finance and budget laws; where assignment clauses typically sit in this country (compilation annexes, finance-law articles, sectoral codes, fund Acts …).
2. **Currency of the core corpus** (one line per core text): `consolidated to {date}`, `base text + amendment laws to {year}`, or `as enacted only`.
3. **Sector sweep:** a 17-row table with sector, documents found (file names) or `none found`.
4. **Gaps:** documents identified but not obtained (title, why missing, where it might be). Plus `landing_page` rows the user must download by hand.
5. **Discovery sources used** (one line each).
6. **Counts:** documents listed; by `url_type`; by `checked`; by `official`; searches used.

## 7. Final checks (before writing)

1. At most 60 rows. `file_name` is unique, matches the pattern, ends in `.html` exactly for `html_full_text` rows, and its year equals `year`.
2. Every row has `checked ∈ {opened, listing_only}` and a non-empty `url`. `listing_only` appears only on the free full-text law sites named in §2.4.
3. Every enum column holds a listed value.
4. **No subscription or commercial reader** among the hosts (§2.2).
5. **Amendment laws text by text (§2.1):** every listed annual amendment law post-dates at least one listed core text; none is missing that post-dates a listed core text within the 5-year window.
   5a. **Script-friendly hosts first:** no SAFLII or lawlibrary row for an Act that a government or regulator site also holds. Every SAFLII or lawlibrary row is a `landing_page`.
   5b. **No blocked Act in the gaps:** every Act named in the gaps has no known URL.
6. **No appropriation or annual division-of-revenue Act** (§2.5).
7. **`landing_page` is the exception:** each `landing_page` row has a `note` saying why no free downloadable version exists.
8. All 17 sectors appear in the brief, each with documents or `none found`.
9. Every core-checklist item for the legal family (Step 2) is listed or named in the gaps.
