# CENSUS_REF — join the earmark layer to the census

Give every earmark instrument the `evidence_id` of the census row for the same instrument.

**Inputs:** `{country}_{document_id}_CENSUS.json` (`census_rows`) · `{country}_{document_id}_RECONCILED.json` (`evidence_table`)
**Output:** `{country}_{document_id}_CENSUS_REF.json` — RECONCILED with `census_ref` added to every row.

## Rules

1. Match once per `instrument_id`, on RECONCILED. RECONCILED holds `source` and `allocation` rows; both types carry `instrument_id`. Resolve the instrument once and write the same `census_ref` to every row sharing that `instrument_id` — differing values within an `instrument_id` is a hard failure. ALLOCATIONS inherits by `instrument_id`; never match it separately.
2. Match the same **instrument**, not the same place in the document. The census records an instrument where it is enacted; the earmark layer records it where its assignment clause sits, often far away. Article and page agreement corroborates; its absence proves nothing.
3. Normalise names before comparing (accents, apostrophes, case, punctuation, whitespace) and read past length differences — the census name usually carries more qualifiers.
4. Never decide on name alone. Each side names an instrument as its own clause phrases it, so one is often a truncation, expansion, or different designation of the other.
5. Source rows carry the base and rate fields — they hold the identity evidence. Allocation rows carry the assignment. Match on the source row where the instrument has one; where it has only allocation rows the instrument is enacted elsewhere in the document, not absent, and still matches.
6. Nothing is filtered out of the census. Every row is a valid target, penalties included — earmarked fines exist. Note only that a tax and the penalty for not paying it are two instruments sharing nearly all their words: read the base text before deciding which one a candidate is.
7. `census_ref` is an **array**. Several census rows can be right: the census sometimes decomposes an instrument the earmark layer carries whole, splitting it by base component or taxed good. List all of them — picking one leaves the rest unreferenced in the numerator while the denominator still counts them.
8. One census row can serve several earmark instruments. The census merges on its own grain and folds advances, minimums and withholdings into the parent; the earmark layer splits wherever an assignment attaches. Both point at the same row; the ratio counts it once.
9. When evidence conflicts or ties, flag it and list the candidates with the reason. Do not force a pick — a forced pick is unrecoverable, a flagged pair takes a minute to settle.
10. Never invent a census row. Never edit either input file. An unmatched instrument means the census missed it or the two sides name it differently; both need a person.

## Evidence to use

| field | use |
|---|---|
| `tax_base_detail`, `verbatim_excerpt` | both sides, always populated — strongest discriminator when names disagree or several candidates sit in one article |
| `instrument_label_verbatim` (census) | label as literally written; often matches an earmark name that `official_name` does not |
| `additional_mentions` (census) | the instrument's other loci — catches an earmark recorded away from the enacting article |
| `enabling_reference` | both sides; a shared founding law corroborates, rarely singles one out |
| `tax_instrument`, `rate_*` | agreement confirms; disagreement does not refute alone (schedule vs scalar, one `base_scope` segment vs the whole) |
| `instrument_nature`, `base_sector` (census) | sanity-check a candidate held on other grounds |
| `legal_article`, `page_start` | corroboration only, never decisive |

## Output

**File** — `{country}_{document_id}_CENSUS_REF.json`: RECONCILED unchanged, with `census_ref` added to every row. Same structure, same row count, same order, no other field touched. Nothing else in the file.

**Inline in the reply** — nothing more than:
- the number of instruments matched
- `unmatched`, as a list of `{instrument_id, official_name, legal_article, page_start, reason}`
