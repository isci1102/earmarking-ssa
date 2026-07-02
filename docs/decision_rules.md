# Decision Rules — Entity Resolution & Structural Breaks

**Governing principle (applies throughout).** *Identity in the key; magnitude and parameters in attributes; contestable identity-changes as flags.* Never bake a reversible judgment into a primary key (keys are expensive to change; flags are free to reinterpret). Every identity call must be **anchored to what the legal text asserts about continuity or replacement** — not to economic judgment about how "different" a change feels.

---

## 1. Keys

- **`instrument_id`** — one per tax instrument (the source). Stable across rate and base-*parameter* changes. Parent key.
- **`pair_id`** — one per `(instrument, destination)` **identity**. Child key. Defined by the destination's *identity*, **never** by the allocation value. A share moving 5%→3% does **not** change `pair_id`.
- Repetition: one `instrument_id` recurs across its multiple `pair_id`s (one instrument → many destinations). This one-to-many repetition is what makes the instrument→pair relationship queryable.

---

## 2. Source-side change rules (does `instrument_id` survive?)

The deciding question is always: **did the source — the tax instrument itself — change identity, or did only something around it change?**

| Event | `instrument_id` | Flag / fields | `change_from_previous` |
|-------|-----------------|---------------|------------------------|
| **Rate change** (e.g. 2%→6%) | same | none | — (rate is a time-varying attribute) |
| **Base-parameter change** (composition, exemptions, thresholds) — *text signals continuity* | **same** | `structural_break = 1` | `"base redefinition: [detail]"` |
| **Merger** (two levies → one) | **new** | `structural_break = 1`, `predecessor_id = [X, Y]` | `"merger"` |
| **Split** (one levy → several) | **new** (one per resulting levy) | `structural_break = 1`, `predecessor_id = [X]` | `"split"` |
| **Source replaced / instrument abolished-and-recreated** (incl. destination-restructuring that *swaps out* the feeding tax) — *text signals replacement* | **new** | `structural_break = 1`, `predecessor_id = [X]` | `"replacement"` |
| **Repeal + later re-creation** | **new** | `predecessor_id = [X]`, `year_repealed`/`year_established` set | `"repeal+recreation"` |

### The base-redefinition vs. source-replacement distinction (the one that looks similar)
Both touch "what feeds the fund," but:
- **Base redefinition** = *same tax, different base.* Destinations untouched; tax still recognizably the same (same name, taxpayers, collection). Source **persists**. → same `instrument_id` + flag. *Same pipe, wider mouth.*
- **Source replacement** = the tax is *abolished and replaced* by a new instrument (often as part of overhauling a fund's financing). Destinations may persist, but the feeding tax is new (different base, article, name). Source **replaced**. → new `instrument_id` + `predecessor_id`. *New pipe, same tank.*

**Operative test:** new `instrument_id` **only** when the source document explicitly abolishes/replaces the instrument or creates a newly-named one; otherwise same `instrument_id` + base-redefinition flag. The extractor reads whether the text asserts replacement — it does not speculate about whether a change is "deep enough."

---

## 3. Destination-side change rule (does `pair_id` survive?)

Orthogonal to §2. `pair_id` tracks the destination **set**, not the share value.

| Event | `pair_id` | `instrument_id` |
|-------|-----------|-----------------|
| **Share value changes** (existing destination) | **same** | same |
| **Destination added** (new beneficiary enters the set) | **new pair born** | same |
| **Destination dropped** | pair closed (`year_repealed` on that pair) | same |

Worked example — telecom reform (AF2026), one reform containing *both* event types:
- Youth-fund channel: same `pair_id`, `share_value` 5→3 (magnitude change within an existing pair — preserves the within-unit variation needed for identification).
- ANSSI channel: **new** `pair_id` (new destination entering the set).
Keeping the youth-fund `pair_id` stable is what preserves the reform as a within-`pair_id` treatment; regenerating it would mechanically destroy the treatment.

---

## 4. Lineage model

`predecessor_id` + `change_from_previous` together fully describe any lineage:
- merger: multiple predecessors → one (`change = "merger"`)
- split: one predecessor → multiple (`change = "split"`)
- replacement / repeal+recreation: one → one, old abolished (`change = "replacement"` / `"repeal+recreation"`)
Follow `predecessor_id` chains + read `change_from_previous` at each hop to reconstruct an instrument's full genealogy.

---

## 5. Entity resolution during reconciliation (id-free → ids)

Extraction is id-free; ids are assigned in a single reconciliation pass over the **complete** country evidence set (all mentions visible before any identity call — superior to premature live assignment).

- **Easy regime (resolve mechanically):** same/similar `official_name` + matching base + matching destination across documents → same instrument. String similarity + attribute match suffices. Rows sharing `document_id` + `legal_article` + `official_name` + `verbatim_excerpt` are grouped as one instrument's multiple allocations (handles the "split across rows" case: e.g. the 5-destination telecom clause → one instrument, five pairs).
- **Hard regime (flag for human adjudication — do NOT auto-resolve):** same policy area, different name/base/destination structure across years (e.g. AF2024 CIAPOL levy→Fonds National de l'Environnement 30/50/20 vs AF2025 chemical-pollution tax→ministry 40/40/20). String matching cannot and must not decide this. Present both verbatim excerpts side by side; the human applies the §2 operative test (does the text assert replacement or continuity?).

**Decision rule for the hard regime, restated:** same source instrument + same destination = same earmark regardless of naming variation; change in the *set* of destinations = pair change; change in the *tax base/instrument* judged by whether the text asserts replacement = new instrument (replacement) or same instrument + flag (redefinition).

---

## 6. Rate & share representation (no-invention safeguard)

Both are `value` + `type`, never a bare percentage:
- `rate_value` + `rate_type ∈ {ad_valorem_pct, per_unit_fcfa, fixed_fcfa}`
- `share_value` + `share_type ∈ {pct, per_unit_fcfa, fixed_fcfa}`; `share_value` is **null** when a clause names a destination but not a share (e.g. quote-part deferred to an arrêté).
Coercing a fixed-amount tax/share into a percentage column would fabricate or lose information — prohibited.

---

## 7. [v0.2] `assignment_type` criterion (scope gate)

The dividing line between an **earmark** and **tax-sharing/devolution** is **purpose-restriction of use**, NOT the identity of the recipient. An earmark restricts the *use* of proceeds to a specific purpose; general tax-sharing transfers *unrestricted* revenue to a tier of government.

- `is_purpose_restricted = 1` → in scope. A State tax → a purpose-restricted fund/organism/programme (incl. a collectivité's *earmarked* fonds d'investissement) qualifies, regardless of whether the recipient is national or sub-national. Sub-classify in `assignment_type` (`earmark_functional`, `hybrid_devolved_earmark`, `equalization_transfer`, `community_levy_external`, `tax_sharing_specific`).
- `is_purpose_restricted = 0` → out of scope but recorded. A tax → a tier's *general/unrestricted* budget (Communes, Régions, État) is ordinary fiscal decentralization, indistinguishable from general devolution → `assignment_type = tax_sharing_general`. Kept for completeness and manager review, excluded from earmark analysis.

**OPEN ITEM — manager ratification.** Whether to retain in-scope *specific* tax-sharing (e.g. a shared tax whose sub-national share is legally tied to a named restricted use) as a distinct earmark-adjacent category, vs. excluding all tax-sharing, is to be decided at the weekly meeting. The scope expansion (from "earmarks" to "revenue instruments with a specific legal destination") must be recorded in the assumptions register once ratified.

## 8. [v0.2] `program` destination precedent (ratified)

A **functional-purpose destination** — a named activity or purpose rather than a proper-noun body (e.g. AF2025 Art 24: "au financement des actions de contrôle du trafic et de lutte contre la fraude en matière de télécommunications") — counts as a **genuine assignment**, `beneficiary_type = program`, not a deferral or a null. Consistent with the definition's inclusion of "programme" as a valid destination. This resolves the recurring boundary between functional-purpose and named-body destinations in favour of inclusion; it is not to be re-litigated per document. The distinct case where the *enacting* text names no destination at all (only the exposé does) remains null/medium (no-invention).

---

## 9. [v0.2] Lineage capture at extraction vs. reconciliation (the deferral rule)

**Extraction captures lineage SIGNALS the text states; reconciliation makes lineage JUDGMENTS across the corpus.** Identity, lineage, and structural breaks are relations *between* documents — not observable within any single clause — so they cannot be honestly asserted at per-document extraction. The split:

- **At extraction (document-local facts only):** populate `predecessor_ref` **only** when the clause itself names a prior instrument/article, and `predecessor_relation ∈ {amends, replaces, merges, splits, none}` for what the text says the relationship is. Set `change_type` and `structural_break` **provisionally** as hints; mark `human_validation_status = unchecked`. No cross-document identity call is made — `instrument_id`/`pair_id` stay blank. This loses no document-local evidence (citations are captured while the text is already open) while making no unsupported cross-document claim.
- **At reconciliation (full-corpus inference):** resolve `predecessor_ref` strings to actual `predecessor_id`s; confirm/reject each provisional `structural_break` against the assembled instrument time-series; assign `instrument_id`/`pair_id` from the natural keys; adjudicate hard entity-resolution cases (e.g. AF2024 CIAPOL/FNE vs AF2025 chemical-pollution) with all excerpts visible — flagged, never auto-merged.

**`amends` ≠ `replaces`.** Both put a prior-article reference in the text, but they are opposite for `instrument_id` survival (§2): `amends` = continuity (same id, attribute/base change); `replaces`/`merges`/`splits` = discontinuity (new id + predecessor link). Recording `predecessor_relation` at extraction fixes this distinction as a stated signal so reconciliation does not re-derive it.

## 10. Reconciliation protocol — DEFERRED ARTIFACT (design after extraction)

The operational reconciliation procedure (how each provisional/lineage field is finalized, how entity resolution is executed and adjudicated, how the panel is derived) is **deliberately not specified yet** — it should be drafted against the *real* lineage signals and provisional breaks the corpus produces, not in the abstract (avoids over-engineering for cases that don't occur). To be specified once annexes + CGI are extracted.

**Non-negotiable now (fixed as principle, details deferred):** reconciliation must produce an **excerpt-justified decision log** — every `instrument_id`/`pair_id` assignment, every confirmed/rejected structural break, and every entity-resolution adjudication recorded with the verbatim excerpts that justified it. Rationale: reconciliation errors propagate directly into treatment timing (a mis-dated break = a mis-timed treatment in any event study; a wrong merge collapses two treated units). The relational layer must therefore be as auditable and reproducible as the evidence layer — the decision log is the reconciliation-stage analogue of the gold standard.
