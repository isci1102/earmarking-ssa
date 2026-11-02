# EARMARK ALLOCATION EXTRACTION — PROMPT (v1.5)

**Input.** `COUNTRY_FOLDER = C:/Users/alexa/Documents/earmarking-ssa/countries/GNQ/` . The country is the ISO3 code in the folder name (or, failing that, the country the documents legislate for).

**Corpus.** The legal documents are **every file in `{COUNTRY_FOLDER}/source_pdfs/`, subfolders included, and nothing else.** Other files in the country folder (corpus lists, briefs, logs, manifests, old outputs) are not legal documents and are never read as such.

**Output.** One file: `{COUNTRY_FOLDER}/outputs/allocations/{ISO3}_EARMARK_ALLOCATIONS.json` (format in §6).

This prompt is self-contained. It is the only rulebook. Do not read older governing documents, manifests or hits files.

---

## 1. What the table is

One row = **one allocation**: the assignment, by an enacting legal clause, of the proceeds of **one instrument or one pool of instruments** to **one destination**.

- `allocation_group_id` identifies the instrument-or-pool **under one allocation key**. All destinations that share the proceeds of that instrument-or-pool under that key carry the same group id.
- `allocation_id` identifies one instrument-or-pool → destination link. It is unique.
- The table records **current law** for the country, consolidated across every document in `source_pdfs/`.
- The instrument table is built later from this table. Here, record the instrument or pool **as the text names it**; do not expand pools into their members.

## 2. Operative test (binding)

Record an allocation only when BOTH hold:

- **(a) Source.** A compulsory charge imposed or authorised by national legislation, whoever collects it: tax, duty, levy, contribution, fee, royalty, parafiscal charge, fine, *redevance*, *prélèvement*; pt *imposto, taxa, contribuição, emolumento, direito, multa*; es *impuesto, tasa, contribución, canon, arancel, derecho, multa*.
  Not sources: non-compulsory revenue (sales proceeds such as lottery ticket sales, enterprise profits, dividends, interest), grants and loans, charges under subnational own-source laws.
- **(b) Assignment.** A clause in **enacting text** assigning its proceeds, in whole or in part, to a destination: a body, a fund, an account, a tier of government, a programme or a stated purpose.

Not assignment:

- the mere existence of a fund, or a list of a fund's resources that names no charge;
- preambles, *exposé des motifs*, memoranda, explanatory notes, headings, definitions;
- a payment-mechanics clause with no destination ("payable to the Commissioner", "recouvré par la DGI", "cobrado pela AGT", "recaudado por la Hacienda");
- an **expenditure floor** that is not tied to revenue ("at least 15% of the budget shall be allocated to health"). By contrast, a share of *revenue* ("X% of total tax revenue shall be paid into fund Y") is an assignment of a pool and is recorded.

Never infer an unnamed destination. The unit is the instrument, not the article: split an article that creates several instruments.

### 2.1 Scope rule — central general budget only

**Drop** an allocation group whose only destination is the **central government's general budget** (budget général de l'État, Orçamento Geral do Estado, Conta Única do Tesouro, Presupuesto General del Estado, Tesoro Público, Treasury, Consolidated Fund, National Revenue Fund, Treasury single account, any treasury account at the central bank, with no stated purpose). Such a group is not recorded at all.

**Keep** a `general_budget` row when it is one leg of a group that also has at least one other destination (e.g. the 90% in a 90/10 key). It is needed to read the key.

Everything else is recorded and classified, including unrestricted shares to subnational tiers, collection-cost retentions, staff payments and refund accounts. Whether a row counts as an earmark is decided at analysis, from the fields.

## 3. Procedure

The run may take **several sessions**. Every session is started the same way, with this prompt and the same `COUNTRY_FOLDER`. Progress is kept on disk, never in a session's memory:

- `outputs/_cache/`: the extracted text of every file;
- `outputs/_work/{ISO3}_alloc_work.json`: the run's state. It has three keys:
  - `files`: one entry per file, `{file, pages, year, status: pending | done | failed, reason}`;
  - `candidates`: every allocation row found so far;
  - `sessions`: one line per session (files done, rows added).

**Page budget: 1,200 pages of reading per session.** Most countries finish in one session; very large corpora take two or three. Candidate rows are saved after each file, so earlier files leaving the session's context does no harm. The budget only bounds how long one session runs. A single file longer than the budget is read alone in its own session.

### Every session

1. **Start or resume.**
   - If the working file does not exist, this is the first session: do Step 2.
   - Otherwise, load it. **Add any new file:** every file in `source_pdfs/` that is not yet in `files` is gated and cached as in Step 2 and added as `pending`. Then go to Step 3.
2. **First session only: inventory, gate and cache every file.**
   - List every file in `{COUNTRY_FOLDER}/source_pdfs/`, subfolders included.
   - Gate each file:
     - it opens;
     - its text is clean (no mojibake; accents, ligatures, curly quotes and § intact);
     - a mid-document sample reads as coherent text;
     - check the layout: if it is double-column, read one assignment passage and confirm it is a contiguous clause. If it is interleaved, use column-aware extraction or the page images. **Never take a share from interleaved text.**
   - A file that fails and cannot be repaired (OCR included) is `failed`, with the reason.
   - Extract and cache the text of **every** file now. This is mechanical, not reading: it lets any later session search the whole corpus.
   - Create the working file with all files `pending`, their page counts and years.
3. **Read the next files, up to the budget.**
   - Take `pending` files in this order: the latest finance law and its annex first, then codes and compilations, then the other texts; then by size, largest first. Stop adding files when the next one would take the session past 1,200 pages (except a file read alone, see above).
   - For each file:
     - Read it **in full**. A long document (more than ~80 pages) is read section by section along its own divisions (books, titles, parts, chapters, schedules); never as one block.
     - Use the §3.1 vocabulary to locate assignments, but read the surrounding text: the destination, the key and the charge are often in neighbouring paragraphs.
     - When a clause needs something defined in **another** file (the full name of "the levy", a defined term, the charging provision), **search the cache** for it. Do not read the other file in full.
     - Extract every allocation as a candidate row (§4, §5), with this file in `document_sources`. No ids yet.
     - **Save after each file:** append its rows to `candidates`, set it `done`, and write the working file atomically (temporary file, then replace). A file is never `done` before its rows are saved, so an interrupted session simply redoes that file.
4. **End of session.**
   - If `pending` files remain: add a `sessions` line, then stop and tell the user, in one line: *"Batch {n} done: {k} files ({p} pages) left. Start a new session with the same prompt and folder."*
   - If no `pending` file remains: go on to the final steps **in this same session**. This also applies when the output already exists and new files were added: the final steps run again on all `candidates` and replace the output.

### Final steps (in the session that finds no pending file)

5. **Consolidate across documents** (§4.10), working from `candidates` only.
6. **Assign ids** (§5, fields 1–2).
7. **Recall self-check (internal, not output).** Search the whole cache for the §3.1 vocabulary. Every hit must be either covered by a row, or clearly not an allocation (procedure, definition, motivation, central-budget-only). For a miss, read that passage and add the row.
8. **Run the checks (§7)** with Python. If a check fails, re-read the source and correct the row. Never patch a value without reading the source.
9. **Write the output** atomically: write to a temporary file, then replace.
10. **Report in chat (≤ 10 lines):**
    - sessions used;
    - files read and failed;
    - groups and allocations, with counts by `recipient_form` and by `is_purpose_restricted`;
    - the number of rows with `ai_confidence ≠ high`;
    - every `SCHEMA:` note.

### 3.1 Assignment vocabulary (search aid, not a checklist)

- **fr:** affecté / affectation, au profit de, réparti / répartition, quote-part, quotité, produit de la taxe / du droit / de la redevance, est financé par le produit de, reversé, rétrocédé / rétrocession, alimente, ristourne, compte spécial, compte d'affectation spéciale, versé au compte, fonds commun.
- **en:** earmarked, dedicated, allocated / appropriated to, paid into / over to, credited to, for the credit of, direct charge, shall accrue to, transferred to, retained by, used exclusively for, distributed as follows, levied for the purpose of, the moneys of the Fund shall consist of, X per cent … to.
- **pt:** consignado / consignação, receita consignada, é consignado ao, afeto / afecto / afetação / afectação, é afeto a, destinado a, reverte para / a favor de, constitui receita do / da, constituem receitas do Fundo, o produto do imposto / da taxa, a receita da taxa, repartido / repartição, distribuído da seguinte forma, na proporção de, X% para, a favor de, em benefício de, é entregue / transferido / depositado (na conta), conta especial, fundo autónomo, cabe ao, pertence ao, receitas próprias, participação emolumentar. *Spellings before and after the 1990 orthographic agreement both occur (afectação / afetação).*
- **es:** afectado / afectación, destinado a, se destinará a, el producto del impuesto / de la tasa, constituye ingreso / recurso de, constituyen recursos del Fondo, a favor de, en beneficio de, se distribuirá / se repartirá como sigue, distribución / reparto, X por ciento para, se ingresará en la cuenta, cuenta especial, fondo especial, revertirá a, corresponderá a, se transferirá a, participación de los municipios / ayuntamientos, recursos propios.

**Destination-agnostic.** The destination is the output of the search, never its input. Never work from a list of known funds.

**Language.** Read the texts in their original language. Every verbatim field (`instrument_name`, `destination_name`, `share_detail`, `share_pool`, `verbatim_excerpt`, `pool_members`) stays in that language; `notes` and `legal_change_note` are in English.

## 4. Classification rules

### 4.1 Instrument or pool (fields 4–6)

**`instrument_name`.** The instrument's name as the corpus gives it, with every distinguishing qualifier (good taxed, origin, payer class). When the clause names it only generically ("the levy", "such fees"), use the most specific name the corpus gives, in this order:

1. the clause itself;
2. the Act's definitions;
3. the heading of the charging provision;
4. the generic term plus the Act's short title, e.g. `levy (Road Accident Fund Act 56 of 1996)`.

Never name a charge after its destination unless the text does.

**`is_pool = 1`** when the clause assigns the combined proceeds of several instruments:

- listed instruments ("the customs duties and the statistical fee");
- a class ("droits de douane", "recettes fiscales", "the levies imposed under this Act").

`instrument_name` then holds the pool as written. `pool_members` lists the members' names as written when the text (or a list it cites in the corpus) enumerates them; otherwise it is null. Do not expand a pool into separate groups.

**Interest, penalties and surcharges** assigned together with their parent charge are folded into the parent: no separate rows, and the fold is stated in `notes`. They get rows of their own only when assigned differently. **Additional points or centimes on another tax** with their own key are a separate instrument.

**Group boundaries.**

- One instrument-or-pool under one key = one group.
- The same instrument assigned on its own (10% to fund A) and also as a member of a pool (the "customs revenue" pool, 1% to ECOWAS) gives two groups.
- **Revenue-sharing matrices** (taxes × beneficiaries): each tax column with its own key is one group, with one row per non-empty cell. A key applied to several taxes at once is one pool group.

### 4.2 Destination and recipient (fields 7–9)

**`destination_name`.** The recipient as written. Use the defined term ("Road Accident Fund", not "the Fund"). For a programme or purpose, write the purpose as written.

**Routing.** An account is a route, not a destination.

- "Paid into the Treasury / National Revenue Fund for the credit of Fund X" → destination = Fund X. Note the route in `notes`.
- A **book-credit** earmark whose cash stays in the treasury is coded to the named fund, with the route noted.
- A treasury or central-bank account with no stated purpose is `general_budget`.

**`recipient_form`.** Apply the rules in order; the first match decides. Only the text's wording counts; never infer the ultimate use.

| #  | value                           | when                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| -- | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1  | `staff_personal_payment`      | The text pays **persons**: agents, officers, staff, office-holders paid personally; bonuses, *primes*, *ristournes*, *fonds commun des agents*, pt *participação emolumentar, emolumentos pessoais, prémios*, es *gratificaciones, participación del personal*, even when paid through a body's accounts. Paid to an office for its costs → not this; use the office's form. Wording silent → the closer reading, `ai_confidence = medium`. |
| 2  | `foreign_government`          | The government of another state (e.g. a customs-union partner).                                                                                                                                                                                                                                                                                                                                                                                                     |
| 3  | `supranational_body`          | A regional or international organisation (ECOWAS, UEMOA, CEMAC, AU, …).                                                                                                                                                                                                                                                                                                                                                                                            |
| 4  | `subnational_government`      | A tier of government or its own budget as such (region, department, commune, district, county; pt *província, município, autarquia local*; es *provincia, municipio, ayuntamiento*). A tier's **fund** or **body** is not this: use rows 5–11 with `recipient_level = subnational`.                                                                                                                                                            |
| 5  | `social_security_institution` | A social-insurance or social-security body: pensions, health insurance, employment injury, family benefits (CNPS, CNAM, NSSF, …), whatever it is called.                                                                                                                                                                                                                                                                                                           |
| 6  | `special_account`             | A *compte d'affectation spéciale*, *compte spécial du Trésor*, pt *conta especial do Tesouro*, es *cuenta especial del Tesoro*, or special/trust account the text places inside the State budget or treasury, including one that is titled "Fonds …".                                                                                                                                                                                                   |
| 7  | `fund`                        | Named as a fund (*fonds*, *fundo*, *fondo*), whatever its legal personality. Legal personality goes in `notes`.                                                                                                                                                                                                                                                                                                                                             |
| 8  | `ministry_or_vote`            | A ministry, a minister's department, or a ministerial budget line or vote.                                                                                                                                                                                                                                                                                                                                                                                          |
| 9  | `agency`                      | Any other public body: *établissement public*, pt *instituto público, autoridade reguladora, empresa pública*, es *organismo autónomo, ente / entidad pública*, authority, office, agency, directorate-general, revenue authority, regulator, board, council, commission, public corporation, state-owned enterprise, chamber of commerce.                                                                                                               |
| 10 | `non_government_body`         | A private or mutual body, a professional order, an association, or a private insurer.                                                                                                                                                                                                                                                                                                                                                                               |
| 11 | `program_or_purpose`          | A purpose or activity is named but no body ("financing of fraud-control actions in telecommunications").                                                                                                                                                                                                                                                                                                                                                            |
| 12 | `general_budget`              | The central general budget, only as one leg of a kept group (§2.1).                                                                                                                                                                                                                                                                                                                                                                                                |

**`recipient_level`.**

- `central`
- `subnational`
- `external`: forms 2–3
- `non_government`: form 10

For forms 1, 5–9 and 11, the level is that of the government the recipient belongs to. Default to `central` when the text is silent.

### 4.3 Restriction, nature and assignment type (fields 14–16)

**`is_purpose_restricted`** — restriction of use, not recipient identity.

- `1`: use restricted to a function, programme, fund, account, or a body's mandate. Any receipt by a fund, agency, special account, social-security institution, or a staff payment scheme is 1.
- `0`: unrestricted receipt into a general-purpose budget (the general budget leg; a tier's general budget).
- The same tax going to a commune's general budget is 0; going to the commune's road fund is 1.

**`allocation_nature`** — why the share is paid.

- `proceeds_share`: the proceeds are directed to a party or purpose outside the service the payer is buying.
- `cost_recovery`: the share prices the service the payer is receiving, or covers the cost of assessing and collecting **this** charge (*frais d'assiette et de recouvrement*, pt *encargos / custos de liquidação e cobrança*, es *premio de cobranza, gastos de recaudación*, administering-office costs). Collector-share sub-rule:
  - a share that funds administering this specific charge is `cost_recovery`;
  - a share that funds the collector's substantive mandate is `proceeds_share`;
  - regulatory levies funding the payer's own supervisor are `proceeds_share`.
- `refund_reserve`: the share is set aside to refund the charge itself to taxpayers (e.g. a VAT refund or escrow account, *compte de séquestre TVA*). This nets the tax; it is not an earmark.

**`assignment_type`** — null only on `general_budget` rows.

- `earmark_functional`: restricted to a function, fund, body's mandate or programme.
- `hybrid_devolved_earmark`: restricted, and routed to or through a subnational tier.
- `equalization_transfer`: pooled and redistributed across territorial units by formula.
- `derivation_transfer`: shared with the territory where the revenue arises.
- `tax_sharing_general`: unrestricted sharing with a tier's general budget (pairs with `is_purpose_restricted = 0`).
- `tax_sharing_specific`: sharing with a tier whose use remains restricted.
- `community_levy_external`: to a supranational body or foreign government.

### 4.4 Destination function — COFOG (fields 10–13)

COFOG as in GFSM 2014 (Table A8.6), from the list in §8.

**Code the function from the destination and the assignment clause only. Never from the source.** The taxed base is not the financed function: a fund fed by mining royalties that finances local development plans is not `7044`. Coding the base into the destination makes any later benefit-link variable true by construction.

Rules:

- **Code the function financed, not the recipient's form.** A body is coded by what it does. A regulator is coded inside its sector (transport regulator `7045`, telecom regulator `7046`, media regulator `7083`).
- **R&D sits inside its function** (geological research `7048`). `7014` is only for basic research with no sector.
- **Tax and customs administration** is `7011`, including staff payments at those bodies.
- **Social security.** Pensions `7102`; sickness or disability cash benefits `7101`; family `7104`; unemployment `7105`; employment injury `7101`. Health insurance financing care is health (`707`): code the group if determinable, else division only.
- A pooled national fund redistributed to tiers by formula **for spending across sectors** is `7018`. A devolved transfer with a specific purpose takes that purpose (a commune road fund is `7045`).
- A cost-recovery share takes the function of the service it prices (registry → `7013`, courts → `7033`, tax collection → `7011`).

**`cofog_division`.** A three-digit division (`701` … `710`), or one of five non-functional values:

| value                        | when                                                                                                                                                                                                                                                                               |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `general_budget`           | `recipient_form = general_budget`                                                                                                                                                                                                                                                |
| `subnational_unrestricted` | a tier's general budget, no purpose stated                                                                                                                                                                                                                                         |
| `external_unrestricted`    | an unrestricted share paid into the general budget of a foreign government or a regional / supranational body (e.g. partner states' shares of a customs-union revenue pool). A restricted share to such a body (e.g. the budget of a regional secretariat) keeps a functional code |
| `refund_reserve`           | `allocation_nature = refund_reserve`                                                                                                                                                                                                                                             |
| `unallocated`              | a destination is named but neither the text nor the body's name fixes even its division                                                                                                                                                                                            |

**`cofog_group`.** The four-digit group when the text or the body's name fixes it; otherwise null. Use an *n.e.c.* group only when the text states an activity that genuinely falls outside the named groups. Never use it as a fallback.

**`cofog_basis`** (null for non-functional values):

- `stated`: the clause names the purpose.
- `named_body`: only a body is named, but its name or mandate fixes the function for any competent reader.
- `inferred`: the code rests on a judgment that could reasonably go another way. If you are weighing two codes, it is `inferred`.

**`cofog_secondary`.** When the text names functions in different divisions or groups, `cofog_division` / `cofog_group` take the function stated **first**, and the others go here as a list of codes in the order stated. Compound wording inside one function is one code ("lutte contre le tabagisme, l'alcoolisme et la toxicomanie" → `7074`, no secondary). Null otherwise.

### 4.5 Shares (fields 17–22)

Never a bare percentage, and never text in a numeric field. Record amounts as written, with no conversion.

| situation                                                                                                                                          | `share_value`                                                                                       | `share_basis`            |
| -------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | -------------------------- |
| explicit number                                                                                                                                    | the number                                                                                            | `stated`                 |
| "paid in full to X", no number                                                                                                                     | null                                                                                                  | `whole_proceeds_implied` |
| "the balance / the remainder / le solde / o remanescente / o restante / el resto / el remanente"                                                   | 100 minus the other shares at the same level and pool, when all of them are stated numbers; else null | `residual`               |
| banded or scheduled shares                                                                                                                         | null (full schedule in `share_detail`)                                                              | `schedule`               |
| value fixed by a future act (arrêté, décret, regulation, finance law, minister; pt portaria, despacho, decreto; es orden, decreto, resolución) | null                                                                                                  | `deferred`               |
| value fixed by reference to another existing text                                                                                                  | null (do not import the number)                                                                       | `cross_reference`        |
| upper bound ("not exceeding", "up to")                                                                                                             | null (bound verbatim in `share_detail`)                                                             | `statutory_maximum`      |
| floor ("at least 40 per cent")                                                                                                                     | the number                                                                                            | `statutory_minimum`      |
| destinations listed with no key and no deferral                                                                                                    | null                                                                                                  | `unstated`               |

- **`share_unit`**: `pct`, `per_unit_amount` (per litre, per tonne …) or `fixed_amount`. Null when `share_value` is null and the text gives no unit.
- **`share_detail`**: the verbatim schedule or bound; otherwise null.
- **Nested keys.** `share_level = 1` is a share of the gross proceeds of the instrument or pool. `2` is a share of a named sub-pool, `3` deeper. `share_pool` holds the **verbatim name** of the parent pool at level ≥ 2, and is null at level 1. Never create level-1 rows for a sub-pool whose size the text does not state.

**`covers_whole_proceeds`** — a property of the **group**, repeated identically on every row of the group. Does the clause assign the **whole** proceeds of the instrument or pool to the group's destinations (all of them together, including any general-budget leg)? It is binary and never null.

- **`1`** when any of these holds:

  - the clause assigns the charge or its proceeds **with no limiting word**: "le produit de la taxe est affecté au Fonds X et à l'Agence Y", "la taxe est affectée au Fonds X", "le produit est réparti entre …", "the proceeds shall be paid into …", "all moneys collected under this Act shall be credited to …", "o produto da taxa é consignado ao Fundo X", "constitui receita do Fundo X", "el producto de la tasa se destinará al Fondo X", "constituye recurso del Fondo X";
  - a leg has `share_basis ∈ {residual, whole_proceeds_implied}`;
  - the stated level-1 pct shares sum to 100.

  This holds **even when the split between the destinations is deferred or unstated**: whether the whole proceeds are assigned does not depend on how they are divided.
- **`0`** when any of these holds:

  - the clause contains a **partitive or limiting word**: *quote-part, une partie, une fraction, une part, a portion, a share of, part of, up to, not exceeding, at least*; pt *uma parte, uma quota-parte, uma parcela, uma percentagem de, até, no máximo, pelo menos*; es *una parte, una fracción, una cuota, un porcentaje de, hasta, como máximo, al menos*;
  - the stated level-1 pct shares sum below 100 with no residual leg.

  **`0` is the default** for any wording that does not plainly assign everything: exclusivity must be shown by the text.
- If you hesitate, choose the value the wording best supports, set `ai_confidence = medium`, and give the reason in `notes`.

### 4.6 Determinacy and legal rank (fields 23–25)

**`determinacy`** — one value per row, always filled:

| value                    | when                                                                                                                                                                                                                 |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `determinate`          | destination named, and `share_basis ∈ {stated, whole_proceeds_implied, residual, schedule, cross_reference}`                                                                                                      |
| `share_deferred`       | destination named, `share_basis = deferred`                                                                                                                                                                        |
| `share_bounded`        | destination named, `share_basis ∈ {statutory_maximum, statutory_minimum}`                                                                                                                                         |
| `share_unstated`       | destination named, `share_basis = unstated`                                                                                                                                                                        |
| `destination_deferred` | the text assigns proceeds but leaves the recipient(s) to a later act ("aux fonds dont la liste est fixée par décret"). `destination_name` holds the wording as written, `recipient_form = program_or_purpose`. |

**`deferred_to`** — filled when `determinacy ∈ {share_deferred, destination_deferred}`, else null. Values: `regulation` (décret, arrêté, regulation, statutory instrument; pt decreto, decreto regulamentar, decreto presidencial, portaria, despacho; es decreto, orden ministerial, resolución), `finance_law`, `minister_or_executive` (a minister, the government, or a council of ministers without a named act form), `agreement` (convention, contract), `other`.

**`legal_rank`** — the rank of the text containing the **assignment** clause:

- `constitution`;
- `organic_law`;
- `ordinary_law`: codes, principal and establishing acts, ordinances with force of law (pt Lei, Decreto-Lei, Decreto Legislativo, Decreto Legislativo Presidencial; es Ley, Decreto-Ley);
- `finance_law`: annual finance laws and their *annexes fiscales*, finance acts, appropriation acts (pt Lei do Orçamento Geral do Estado; es Ley de Presupuestos Generales del Estado);
- `regulation`: décret, arrêté, regulations, statutory instruments (pt Decreto, Decreto Regulamentar, Decreto Presidencial, Portaria, Despacho; es Decreto, Orden, Resolución);
- `other`.

### 4.7 Evidence (fields 26–30)

- **`legal_reference`**: the assignment clause, as `{short title or text} {unit}`, e.g. `CGI 2023 art. 1084`, `Act 56 of 1996 s 5(1)`, `LF 2025 art. 12`, `Lei 7/20 art. 15.º n.º 2`, `Ley 2/2019 art. 8`. If a later text amends the clause, cite the governing (latest) text first and the others after `;`.
- **`source_reference`**: the charging provision of the instrument, in the same format, when the corpus identifies it (in the same clause or a provision it cites). Otherwise null. The instrument prompt uses it.
- **`verbatim_excerpt`**: the exact text of the assignment clause, never summarised. It must contain the assignment language and the share. For a long matrix, the excerpt is the row or column concerned, with its heading.
- **`document_sources`**: a list of the file names (no paths) from which any value in this row was taken.
- **`document_year`**: the year of the most recent document in `document_sources`. This is the document's year (title, version or enactment), never the year the earmark was created.

### 4.8 Legal change and difficulty note (field 31)

**`legal_change_note`** (≤ 2 sentences, or null). Use it for:

- an explicit amendment, replacement or repeal touching this allocation (e.g. "share raised from 5% to 10% by LF 2025 art. 8, replacing CGI art. 1084");
- conflicting statements between documents;
- a drafting inconsistency in the source;
- a stale cross-reference;
- any difficulty in reading the legal system (missing consolidation, unclear which text is in force).

State the fact, not your reasoning.

### 4.9 Confidence and notes (fields 32–33)

- **`ai_confidence`**: `high`, `medium` or `low`.
- **`notes`**: ≤ 2 sentences. **Mandatory when `ai_confidence ≠ high`**, saying whether the problem lies in the document or in the schema. Also use it for routes, legal personality of a fund, collector-share or cost-recovery calls, and folds of interest and penalties.
- **Schema gap.** When a clause shows a pattern the fields cannot represent: code the closest values, set `ai_confidence = medium`, and start `notes` with `SCHEMA:`. Never invent a field or an enum value.

### 4.10 Consolidation across documents (current law)

- **One allocation, one row.** The same instrument-or-pool → destination link stated in several documents (a code and a finance law that restates or amends it; a fund Act and the tax Act it cites) is **one row**. All contributing files go in `document_sources`.
- **Latest text in force governs.** Each value comes from the most recent enacting text in `source_pdfs/` that states it, unless a later text there amends or repeals it. Order by document date. Within a year, an amending text beats the text it amends. Superseded values are described in `legal_change_note`, never kept as rows.
- **Repealed** allocations, or allocations of a repealed instrument, are not recorded.
- **Two halves.** When the charge is imposed in one document and its proceeds assigned in another, the row is built from the **assignment** clause. `source_reference` cites the charging provision, and both files are listed.
- **Attestation.** Every value must be stated in a document listed in `document_sources`. Never fill a field from general knowledge or the web.
- **One destination, one coding.** Candidates come from different sessions, so the same recipient may have been coded differently. After merging, harmonise: rows naming the same destination (same body, fund or account, after matching defined terms and abbreviations) carry the **same** `destination_name`, `recipient_form` and `recipient_level`, and the same `cofog_division` and `cofog_group` **unless the clauses state different purposes** for that recipient (then each row keeps the function its clause states, and `notes` says so). Choose the coding best supported by the clauses, and note the harmonisation in `notes` where a value changed.
- **One instrument, one name.** Rows for the same charge carry the same `instrument_name` (the most specific name the corpus gives, §4.1), whichever session found them. Use `source_reference` and the cache to match them.

## 5. Column dictionary

Fill every field, in this order. Use JSON `null` for empty values, never `""`.

| #  | field                     | type            | null? | rule                                                                                                                                                |
| -- | ------------------------- | --------------- | ----- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1  | `allocation_id`         | string          | no    | `{ISO3}_G{nnn}_A{nn}` — the group id plus a destination number within the group                                                                  |
| 2  | `allocation_group_id`   | string          | no    | `{ISO3}_G{nnn}`, numbered in order of the first `legal_reference` in the corpus                                                                 |
| 3  | `country`               | ISO3            | no    |                                                                                                                                                     |
| 4  | `instrument_name`       | string          | no    | §4.1. Never a bare generic word (`tax`, `levy`, `fee`, `taxe`, `redevance`, `droit`, `imposto`, `taxa`, `impuesto`, `tasa` …) |
| 5  | `is_pool`               | 0/1             | no    | §4.1                                                                                                                                               |
| 6  | `pool_members`          | list of strings | yes   | §4.1. Only when `is_pool = 1` and the members are enumerated                                                                                     |
| 7  | `destination_name`      | string          | no    | §4.2                                                                                                                                               |
| 8  | `recipient_form`        | enum            | no    | §4.2                                                                                                                                               |
| 9  | `recipient_level`       | enum            | no    | `central`, `subnational`, `external`, `non_government`                                                                                      |
| 10 | `cofog_division`        | string          | no    | §4.4                                                                                                                                               |
| 11 | `cofog_group`           | string          | yes   | §4.4; must belong to the division                                                                                                                  |
| 12 | `cofog_basis`           | enum            | yes   | `stated`, `named_body`, `inferred`; null only for non-functional divisions                                                                    |
| 13 | `cofog_secondary`       | list of strings | yes   | §4.4                                                                                                                                               |
| 14 | `is_purpose_restricted` | 0/1             | no    | §4.3                                                                                                                                               |
| 15 | `allocation_nature`     | enum            | no    | `proceeds_share`, `cost_recovery`, `refund_reserve`                                                                                           |
| 16 | `assignment_type`       | enum            | yes   | §4.3; null only when `recipient_form = general_budget`                                                                                           |
| 17 | `share_value`           | number          | yes   | §4.5                                                                                                                                               |
| 18 | `share_unit`            | enum            | yes   | `pct`, `per_unit_amount`, `fixed_amount`                                                                                                      |
| 19 | `share_basis`           | enum            | no    | §4.5                                                                                                                                               |
| 20 | `share_detail`          | string          | yes   | §4.5                                                                                                                                               |
| 21 | `share_level`           | integer         | no    | §4.5                                                                                                                                               |
| 22 | `share_pool`            | string          | yes   | §4.5                                                                                                                                               |
| 23 | `covers_whole_proceeds` | 0/1             | no    | §4.5; identical on every row of a group                                                                                                            |
| 24 | `determinacy`           | enum            | no    | §4.6                                                                                                                                               |
| 25 | `deferred_to`           | enum            | yes   | §4.6                                                                                                                                               |
| 26 | `legal_rank`            | enum            | no    | §4.6                                                                                                                                               |
| 27 | `legal_reference`       | string          | no    | §4.7                                                                                                                                               |
| 28 | `source_reference`      | string          | yes   | §4.7                                                                                                                                               |
| 29 | `verbatim_excerpt`      | string          | no    | §4.7                                                                                                                                               |
| 30 | `document_sources`      | list of strings | no    | §4.7                                                                                                                                               |
| 31 | `document_year`         | integer         | no    | §4.7                                                                                                                                               |
| 32 | `legal_change_note`     | string          | yes   | §4.8                                                                                                                                               |
| 33 | `ai_confidence`         | enum            | no    | §4.9                                                                                                                                               |
| 34 | `notes`                 | string          | yes   | §4.9                                                                                                                                               |

## 6. Output format

One JSON object:

```json
{
  "country": "XXX",
  "prompt_version": "allocation_v1.5",
  "documents": [
    {"file": "CGI_2024.pdf", "year": 2024, "status": "read", "reason": null},
    {"file": "LF_2025.pdf", "year": 2025, "status": "failed", "reason": "scanned, OCR illegible pp. 40-62"}
  ],
  "rows": [
    {
      "allocation_id": "XXX_G004_A01",
      "allocation_group_id": "XXX_G004",
      "country": "XXX",
      "instrument_name": "taxe spécifique sur les tabacs",
      "is_pool": 0,
      "pool_members": null,
      "destination_name": "Fonds national de lutte contre le tabagisme",
      "recipient_form": "fund",
      "recipient_level": "central",
      "cofog_division": "707",
      "cofog_group": "7074",
      "cofog_basis": "named_body",
      "cofog_secondary": null,
      "is_purpose_restricted": 1,
      "allocation_nature": "proceeds_share",
      "assignment_type": "earmark_functional",
      "share_value": 20,
      "share_unit": "pct",
      "share_basis": "stated",
      "share_detail": null,
      "share_level": 1,
      "share_pool": null,
      "covers_whole_proceeds": 1,
      "determinacy": "determinate",
      "deferred_to": null,
      "legal_rank": "finance_law",
      "legal_reference": "LF 2025 art. 9; CGI 2024 art. 412",
      "source_reference": "CGI 2024 art. 410",
      "verbatim_excerpt": "Le produit de la taxe spécifique sur les tabacs est réparti comme suit : 20 % au profit du Fonds national de lutte contre le tabagisme ; 80 % au budget général de l'État.",
      "document_sources": ["CGI_2024.pdf", "LF_2025.pdf"],
      "document_year": 2025,
      "legal_change_note": "Share raised from 10% to 20% by LF 2025 art. 9.",
      "ai_confidence": "high",
      "notes": null
    }
  ]
}
```

*(Illustrative values only. In this example, group `XXX_G004` also has an `A02` row for the 80% general-budget leg, with `recipient_form = general_budget` and `cofog_division = general_budget`.)*

`documents` holds one entry per file in `source_pdfs/`: `year` is the document's year (title, version or enactment; null if none can be read), `status ∈ {read, failed}`. It records coverage only.

## 7. Final checks (Python, read-only — any failure is fixed by re-reading the source)

1. Every `allocation_id` is unique and matches `{ISO3}_G\d{3}_A\d{2}`. Its prefix equals `allocation_group_id`.
2. Every row has all 34 fields in order. The non-null fields of §5 are non-null.
3. Every enum value is listed in this prompt. Every COFOG code is in §8, and `cofog_group` belongs to `cofog_division`.
4. **Scope.** No group consists only of `general_budget` rows.
5. **Consistency.**
   - `recipient_form = general_budget` ⇔ `cofog_division = general_budget`; on those rows `is_purpose_restricted = 0` and `assignment_type` is null.
   - `allocation_nature = refund_reserve` ⇔ `cofog_division = refund_reserve`.
   - `cofog_division = subnational_unrestricted` ⇒ `is_purpose_restricted = 0`.
   - `cofog_division = external_unrestricted` ⇒ `is_purpose_restricted = 0` and `recipient_level = external`; and every `recipient_level = external` row with `is_purpose_restricted = 0` has `cofog_division = external_unrestricted`.
   - `assignment_type` is non-null on every other row.
   - `cofog_basis` is null ⇔ `cofog_division` is non-functional.
6. **Shares.**
   - `share_value` non-null ⇒ `share_basis ∈ {stated, residual, statutory_minimum}`.
   - `share_basis ∈ {schedule, statutory_maximum}` ⇒ `share_detail` non-null.
   - Within a (group, `share_level`, `share_pool`), the stated `pct` shares sum to ≤ 100 (tolerance 0.5).
   - `share_level ≥ 2` ⇔ `share_pool` non-null.
7. **Determinacy** agrees with `share_basis` (§4.6 table). `deferred_to` is non-null ⇔ `determinacy ∈ {share_deferred, destination_deferred}`.
8. **Pools.** `pool_members` non-null ⇒ `is_pool = 1`. Every row in a group shares the same `instrument_name`, `is_pool` and `covers_whole_proceeds`.
   8a. **Coverage of the key.** In every group:
   - a level-1 leg with `share_basis ∈ {residual, whole_proceeds_implied}` ⇒ `covers_whole_proceeds = 1`;
   - level-1 legs all with `share_unit = pct` and a non-null `share_value` that sum to ≥ 99.5 ⇒ `covers_whole_proceeds = 1`;
   - the same legs summing below 99.5, with no residual or whole-proceeds leg ⇒ `covers_whole_proceeds = 0`.
9. `notes` is non-null on every row with `ai_confidence ≠ high`.
10. `instrument_name` is not a bare generic word.
11. Every file in `document_sources` appears in `documents` with `status = read`. `document_year` equals the latest year among them.
12. No two rows share (`instrument_name`, `destination_name`, `share_level`, `share_pool`). A duplicate means a consolidation failure.
13. **Consistent coding:** rows with the same `destination_name` have the same `recipient_form` and `recipient_level`; where their `cofog_division` or `cofog_group` differ, each such row's `notes` explains the different stated purpose.
14. **Run complete:** every file in the working file is `done` or `failed`, and every `failed` file appears in `documents` with its reason.

## 8. COFOG reference (GFSM 2014, Table A8.6)

| division                                       | groups                                                                                                                                                                                                                                                                                                                                             |
| ---------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **701** General public services          | `7011` executive and legislative organs, financial and fiscal affairs, external affairs · `7012` foreign economic aid · `7013` general services · `7014` basic research · `7015` R&D · `7016` n.e.c. · `7017` public debt transactions · `7018` transfers of a general character between levels of government               |
| **702** Defense                          | `7021` military defense · `7022` civil defense · `7023` foreign military aid · `7024` R&D · `7025` n.e.c.                                                                                                                                                                                                                            |
| **703** Public order and safety          | `7031` police · `7032` fire protection · `7033` law courts · `7034` prisons · `7035` R&D · `7036` n.e.c.                                                                                                                                                                                                                          |
| **704** Economic affairs                 | `7041` general economic, commercial and labor affairs · `7042` agriculture, forestry, fishing and hunting · `7043` fuel and energy · `7044` mining, manufacturing and construction · `7045` transport · `7046` communication · `7047` other industries (incl. tourism, distributive trades) · `7048` R&D · `7049` n.e.c. |
| **705** Environmental protection         | `7051` waste management · `7052` waste water management · `7053` pollution abatement · `7054` protection of biodiversity and landscape · `7055` R&D · `7056` n.e.c.                                                                                                                                                               |
| **706** Housing and community amenities  | `7061` housing development · `7062` community development · `7063` water supply · `7064` street lighting · `7065` R&D · `7066` n.e.c.                                                                                                                                                                                             |
| **707** Health                           | `7071` medical products, appliances and equipment · `7072` outpatient services · `7073` hospital services · `7074` public health services · `7075` R&D · `7076` n.e.c.                                                                                                                                                            |
| **708** Recreation, culture and religion | `7081` recreational and sporting services · `7082` cultural services · `7083` broadcasting and publishing (a national broadcaster is here, not `7046`) · `7084` religious and other community services · `7085` R&D · `7086` n.e.c.                                                                                             |
| **709** Education                        | `7091` pre-primary and primary · `7092` secondary · `7093` post-secondary non-tertiary · `7094` tertiary · `7095` not definable by level · `7096` subsidiary services · `7097` R&D · `7098` n.e.c.                                                                                                                          |
| **710** Social protection                | `7101` sickness and disability · `7102` old age · `7103` survivors · `7104` family and children · `7105` unemployment · `7106` housing · `7107` social exclusion n.e.c. · `7108` R&D · `7109` n.e.c.                                                                                                                     |

## 9. Hard rules

- Write only `outputs/allocations/{ISO3}_EARMARK_ALLOCATIONS.json`, `outputs/_cache/` and `outputs/_work/`. Never modify the source documents.
- Enacting text only. Verbatim and anchored. Never summarise an excerpt.
- Never infer a destination, a share or a function the text does not state. Use null plus the flag.
- Destination function from the destination side only; never from the source.
- Never use a list of expected funds or taxes.
- Uncertainty goes in `notes`; it is never resolved silently.
