# Reconciliation Rules

Governs the pass that assigns `instrument_id` and `pair_id` over a country's complete evidence set (CORE C6; fills decision_rules §10).

**In:** one `{COUNTRY}_{DOC}_EXTRACT_whole.json`, ids null.
**Out:** one JSON, two keys: `evidence_table` (v0.5 schema + `instrument_id`, `pair_id`, `pair_row_role`, `base_scope`, `intra_document_conflict`) and `reconciliation_summary`.

The rules are identical for every country. Country-specific hand-coding is a defect: it makes cross-country counts measure the coding, not the law.

---

## Scope

The unit is the **revenue instrument**, not the tax. CORE C1(a) admits a levy of any kind: taxes, redevances, prélèvements, parafiscal contributions, fees, fines, royalties. Nothing is excluded for being a non-tax revenue.

Report composition by `tax_instrument` so the non-tax share is visible rather than assumed.

---

## R1 — Grain

- **quote-part** — name denotes a *share* (`quote-part`, `quotité`, `reliquat`, `part de`, `segment`, `— sub-scope`). Takes the parent levy's `instrument_id` when the parent is in the document; position carried by `share_level` / `share_pool`. No parent present → stands alone (parent is out of corpus).
- **pool / container** — name enumerates or pools several levies. Kept as a row, **not counted as an instrument** (would double-count its members). Its members are then not separately enumerated — state as a coverage limit.
- **instrument** — everything else. Countable.

## R2 — Instrument identity

The source levy: normalised name + `tax_base_detail` + payer, qualifiers stripped. Name alone is a weak signal.

- A re-split of a share in another article is the **same instrument** at a deeper `share_level`.
- **Branch** = distinct instrument only if distinct base **and** distinct destination.
- Same policy area, failing the base match → do not auto-merge; flag (decision_rules §5 hard regime).

## R3 — Pair identity

`instrument × normalised recipient × share_level × share_pool × base_scope`.

- Normalise recipient strings (case, accents, "au profit de", parentheticals).
- A special account naming its beneficiary is the **route**, not a second recipient (CORE C5).
- **`share_pool` is part of the key.** Same recipient under a different parent pool is a different channel. Omitting it manufactures false conflicts.
- **`base_scope` is part of the key.** When R1 absorbed a segment, branch, or territorial or payer-class variant into a parent instrument, carry the stripped qualifier as the channel's `base_scope` (empty on parent rows). A segment's key is a *different key over a different slice of the base*, not a restatement of the parent's.

The two are the same idea at different depths: `share_pool` separates channels that divide different pools of money; `base_scope` separates channels that divide the proceeds of different slices of the base. Omitting either collapses distinct channels and turns their differing shares into a phantom conflict — the same failure R9's sub-scope guard prevents downstream.

*Illustration — CIV: the contribution des patentes and its « patente transport » segment are one instrument (R1) but four channels, not two — each scope has its own collectivités and FER shares.*

## R4 — Governing row when a channel is stated twice

**Every row is retained.** Duplicate statements of one channel are evidence, not noise: they are how the document's internal consistency is observed. They share one `pair_id`; one is marked **governing** and supplies the channel's attributes.

First criterion that separates them decides; record which.

| | |
|---|---|
| a | stated share beats null |
| b | full key beats `partial_key = 1` |
| c | `stated` > `whole_proceeds_implied` > `deferred_arrete` |
| d | code body beats annexe |
| e | earliest `evidence_id` — tie-break only |

Falling to (e) means no substantive criterion separated them: the choice is arbitrary, the governing row is **provisional**, and it is recorded as such.

**`pair_row_role`** — second and last added column. `governing` on the row supplying the attributes, `restatement` on the others, empty on source rows and on single-row channels.

Read a channel's share, basis and type from its **governing** row only. Reading them off restatements will double-count and, where the rows disagree, silently pick at random.

## R5 — Duplicate source rows

One per instrument: body before annexe, then most complete, then earliest id. Differing rates trigger the R9 flag.

## R6 — Repeal

Where the document asserts replacement (`predecessor_relation = replaces` or `change_type = replacement`) **and** names a predecessor present in the corpus, that instrument is closed and removed with its allocations. A regulatory annexe reproducing a superseded levy does not revive it.

Predecessor named but not in the corpus → lineage signal only; remove nothing.

## R7 — Source-only instruments are retained

They contribute zero channels automatically (C1 needs a levy *and* an assignment; an allocation row carries both, a source row never does). Do not delete:

- it may be the evidence justifying a repeal elsewhere;
- its destination may be **unobserved, not absent** (deferred to an arrêté or a text outside the corpus). A7: gaps are unobserved, never zeros.

Before reading "no channel" as "no destination", check the allocations are not sitting on a joint-key or parent entity.

## R8 — Joint keys

One clause, one key, two separately instituted levies → duplicate the allocation rows to **both**, suffix `evidence_id` `_A` / `_B`, record origin in `notes`.

Those shares are of the **joint product**: they appear on two instruments and must not be summed across them.

## R9 — Conflict flag

`intra_document_conflict`, set at instrument level:

| value | |
|---|---|
| `none` | stated once, or consistently |
| `competing_share` | same recipient, same level and pool, different share values |
| `competing_rate` | rate or schedule stated more than one way |
| `stated_inconsistency` | extraction recorded one in `source_internal_inconsistency` |

Combine with `+`.

**Classify by what the inconsistency is about.** Where a `stated_inconsistency` concerns a rate or schedule, also set `competing_rate`; where it concerns a share, also set `competing_share`. `stated_inconsistency` alone is for inconsistencies that are neither (headings against enacting text, cross-references to a missing article, drafting slips).

Collapsing everything into `stated_inconsistency` makes the column useless across countries: it records only that the extraction noticed something, not what kind of defect it is. *Illustration — CIV: the taxe d'apprentissage (décret 0,5 % against CGI), the taxe additionnelle formation continue (décret 1,5 % against CGI 1,2 %) and the contribution nationale (CGI 1,2 % against ord. 62-90's 1,50 %/2 %) are all `stated_inconsistency + competing_rate`, not `stated_inconsistency` alone.*

**Sub-scope guard.** A share or rate difference between rows whose `official_name` denoted **different sub-scopes before R1 absorption** — a segment, branch, or territorial or payer-class variant folded into the parent — is **not** a conflict. Those rows describe different slices of the base, not rival statements of one key.

Compare only rows that were describing the same scope. Without this guard, every country with segmented rates produces phantom `competing_share` flags. *Illustration — CIV: the État receives 15 % of the contribution des patentes and 40 % of the patente transport segment; these are different sub-scopes, not a contradiction.*

**Why this is a variable, not a defect.** A levy stated two ways in one code has a weaker benefit link and more room for discretion at execution. Retaining the duplicate rows (R4) is what makes the flag auditable: the evidence for it sits in the table, not only in the summary.

---

## Conventions

**Consolidation.** Code body beats annexed amending instrument on the same article. Settles destination and rate conflicts together, no external verification. Reversible if a code proves un-consolidated.

**Renvoi precedence.** A clause deferring to another (*"conformément aux dispositions du…"*) while stating a contradictory figure → the **cited text governs**. It points at the text it contradicts; that is a drafting instruction.

**Norm hierarchy.** A décret in a *Partie Réglementaire* annexe does not override the code body.

**General rule vs territorial special regime.** Mutually exclusive, never summed. Each key sums to 100 % within its own regime. Treat the regime as a filter.

**Downstream carve-out.** An equalization levy on the *local product* does not replace the key that put the money there; it bites on what the authority received. Carries `partial_key = 1`.

---

## Counting

**Earmarked = any destination other than `beneficiary_type = general_budget`.** That is the only non-earmarked category.

**Unit = the allocation channel** (`instrument × recipient × share_level × share_pool`), never the evidence row.

Because duplicate rows are retained (R4), count `DISTINCT pair_id` — or filter `pair_row_role != "restatement"`. Counting allocation rows overstates the channel count by the number of restatements.

**Headline, then breakdown by `beneficiary_type × share_level`.** Levels are not additive: a level-2 share is a fraction of its parent, so the level split shows how deep the assignment chain runs. Never sum `share_value` across levels, or across the two instruments of a joint key.

**Report separately inside the total** — each is contested and will be asked about:

- `cost_recovery_component` — decision_rules §11 rules these out on benefit-principle grounds; included here, shown as a line so the narrower reading is recoverable.
- `collectivite_territoriale` with `is_purpose_restricted = 0` — a tier's general budget is a general budget. A10: fiscal decentralisation carries distinct confounders and must not be pooled with functional earmarks in regression.
- `equalization_transfer` — dictionary 22 leaves the boundary open pending manager ratification.

**Filter line on every published count:** *Unit: allocation channel (instrument × recipient × share_level × share_pool). Earmarked = every channel whose `beneficiary_type` is not `general_budget`; cost-recovery splits and unrestricted sub-national transfers are included and reported separately. Source: de jure legal text only; no execution data.*

---

## Output checks

The run is not finished until these hold. State them in the reply.

- `counts.instruments_by_conflict_flag` sums to the total instrument count.
- `instruments_flagged` lists **exactly** the instruments whose rows carry a non-`none` `intra_document_conflict`; its length equals the non-`none` total in `counts`.
- Every row of one instrument carries the same `intra_document_conflict` value.
- allocation rows − allocation channels = number of `pair_row_role = restatement` rows.
- `pair_row_role` is `governing` on exactly one row of every multi-row channel, and empty on source rows and single-row channels.
- Every allocation row has a `pair_id`; no source row has one.
- Rows removed are only R5 duplicate sources and R6 repeals. Nothing else leaves the table.

## Never

- Make a scope or earmark judgment. `is_purpose_restricted`, `assignment_type`, `allocation_nature`, `beneficiary_type` pass through **exactly as extracted**.
- Alter the evidence table. Reconciliation is derived (A9); every removal is reversible from the extract.
- Delete a row to resolve a contradiction. Where two rows disagree and no rule separates them, the kept row is **provisional** and marked.
- Resolve a hard entity-resolution case by string similarity.
