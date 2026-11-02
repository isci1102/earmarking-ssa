# Earmarking SSA: first results meeting

Nov 2, 2026 · @Alexandra Amani

The database is complete for 43 countries and the first two reports are ready. The aim of this hour is to share the main patterns and agree on validation, the survey and the next analyses. All results are preliminary until validation.

## Agenda

We walk through the two HTML reports on screen, following their table of contents.

| Time | Report and section | What to say |
| --- | --- | --- |
| 10 min | Database: status box, Table 1 | What the database is: 43 countries, clause-level and auditable, preliminary until validation |
| 25 min | Database: A2a heatmap and 704 zoom, two Sankeys (Niger, Cabo Verde), A3, A4, A6, A7(a) and (b) | The five messages below |
| 10 min | External: B1, B2, "what this can and cannot say" | A first look, explicitly exploratory |
| 15 min | (no report) | The decisions below |

## Database results

The database holds 4,165 instruments, of which 2,545 are earmarked (E2 or E3, social contributions excluded), coded from 1,509 legal documents.

1. **Earmarks mostly finance the sector that pays them.** Economic affairs (COFOG 704) receives 56% of instrument-function links. Within it, transport levies finance transport, telecom levies communication, and forestry and agricultural levies their own sector.
2. **Most links have an economic rationale.** Sectoral links are 46%, benefit 20%, corrective 8% and compensatory 3%. About one link in seven (15%) is unlinked, for example tobacco and alcohol excises financing sport.
3. **Agencies and funds are the main recipients.** They take about seven in ten restricted allocations. These are legal forms as written, not budget status.
4. **Sharing with local governments is mostly general tax sharing and derivation.** There are 735 allocations in 38 countries. The counts show the type of decentralisation (tax shares written into tax codes), not its degree.
5. **Design differs by legal tradition.** Anglophone countries have more exclusive and more hard earmarks. Francophone earmarks are more often left to, or made by, decree.

Caveats to state once: 60% of allocations are coded below high AI confidence, and counts depend on corpus completeness, so countries are compared by shares.

## External results

Two patterns appear in the full sample, and neither survives a closer look. All figures are Spearman rank correlations across countries, read as associations.

| Question | Full sample | Within legal tradition | Reading |
| --- | --- | --- | --- |
| Tax revenue (WoRLD, % of GDP, 2022 to 2024) vs exclusive (E3) share | 0.40 (43 countries); 0.37 without oil exporters | Anglophone 0.63 (18); francophone 0.19 (17) | Driven by southern Africa: without the 5 SACU members, 0.18 (38); among the other 13 anglophone countries 0.32, and −0.08 without Mauritius and Seychelles too (checked after seeing the figure) |
| Budget comprehensiveness (PEFA PI-6) vs hard-commitment share | 0.44 on PI-6 (31); 0.39 on PI-6.2 (28) | Anglophone 0.14 and 0.22 (14 and 13); francophone unreadable | Mostly legal tradition: anglophone countries have harder earmarks and better grades |

- The other shares show little with tax revenue, and the raw number of earmarked instruments shows nothing (0.03). With about 40 correlations in the table, one or two look strong by chance, so no single one is singled out.
- The fund-or-agency share shows nothing with PEFA, as expected from an interim legal-form proxy. Two thirds of PI-6.2 grades are D, and 12 of 13 francophone countries are D on the overall PI-6.
- Trade taxes go the other way with the exclusive share (−0.18, and −0.32 without the SACU members). How WoRLD records SACU pool receipts was not verified.

## Decisions needed

- [ ] **Validation and its cost.** Recall on 2 or 3 hand-coded countries, precision and kappa on about 150 rows (stratified by AI confidence), stability on re-runs, and a corpus-completeness index. Re-runs need new LLM extraction: agree how compute is shared.
- [ ] **Survey of IMF country teams.** Who sends each country table, to which desks, and when. It checks missing funds, errors and amounts.
- [ ] **Budget status of funds.** Code whether each fund is on or off budget (finance-law special-account tables, legal personality, hand check). It is needed for the real PEFA test. Can Luc help?
- [ ] **Scope choices made so far.** Reform candidates (A5) deferred; regional community levies reduced to one count; WGI used only in the validation; revenue exposure dropped, with magnitudes moved to the survey stage. Do they agree?
- [ ] **Positioning and release.** How to frame the paper against the IMF database built from EIU reports (Das, Furceri, Patel and Peralta-Alva, 2026), and the plan for a public release with a DOI.
