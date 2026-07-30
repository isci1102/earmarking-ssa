# CENSUS CORE Methodology (FROZEN — document-agnostic, country-agnostic)

> **What this is.** The invariant core of the *source-instrument census*: the operative test, grain, id-free discipline, and audit requirements for enumerating **every** revenue instrument present in a corpus document. It is applied to every document unchanged; only the *retrieval adapter* varies.
>
> **What the census is.** A per-document enumeration of the revenue instruments a document institutes or provides for. It is **not** a tax history, **not** a panel, and **not** a claim about a country's tax system. Each run answers one question about one primary source: *which revenue instruments does this document contain, and on what textual evidence?*
>
> **Layering.** Every census run = this CENSUS CORE + the CENSUS TABLE DICTIONARY + one RETRIEVAL ADAPTER instantiated with the document's structural parameters. These three are the complete input; nothing else is consulted (N7). Never duplicate this core into a per-document prompt — duplication drifts and breaks reproducibility. Refine the core in ONE place; all runs inherit it.

---

## N1. Operative test (binding)

A census row is warranted when **all** of the following hold.

**(a) Instrument.** The text institutes or provides for a source levy/tax/charge/contribution of any kind, whether its proceeds accrue to the general budget or to a specific recipient. The character of the instrument, and the identity or existence of any recipient, are recorded — never a condition of admission.

**(b) Distinctness.** The instrument is identifiable as distinct by its own base and/or rate. One row per distinct instrument.

**(c) Provenance.** The instrument is present as an instrument in this document's enacting text. Text that is motivational, explanatory, or definitional is not enacting text and does not warrant a row. An instrument named only by cross-reference to another instrument is recorded with `evidence_status = referenced_not_enacted_here`.

**Vocabulary is not in this core.** The forms a revenue instrument may take are jurisdiction-specific (civil-law *redevance*, *prélèvement*, parafiscal charge; common-law duty, cess, charge). That vocabulary lives in the retrieval adapter's lexicon and is swapped per language (N9). The test above is stated in terms of what an instrument *is*, not what it is *called*, which is what lets it hold unchanged across drafting traditions.

## N2. Scope — extract-broad, filter-later

Record **every** instrument satisfying N1, without regard to its type. Narrow and broad readings of the population (strictly fiscal instruments only / fiscal plus parafiscal / all compulsory charges) are obtained by filtering the recorded field `instrument_nature`, never by excluding rows at extraction.

**Consequence (binding).** Extraction is run once, at the broadest boundary. Any narrower population is a filter over the same table. An extraction-time exclusion is irreversible and destroys this property; a tag is free to reinterpret.

## N3. Instruments that price a service — recorded and tagged, never excluded

An instrument that prices a service the payer is consuming (administrative cost-recovery, processing or service fees) **is extracted** and tagged in `instrument_nature`. It is not excluded at extraction.

Rationale: whether such instruments belong in a given analytical population is a defensible judgment in either direction. Recording them tagged means that judgment can be made, revisited, and its effect measured downstream. Excluding them at extraction forecloses it and hides the sensitivity.

**Soft boundary (log case-by-case with excerpt).** General administrative cost-recovery not tied to a specific transaction sits between a service price and a charge proper. Record it, tag it, and enter it in the boundary-call log (N8) so the call is auditable rather than assumed uniform.

## N4. Unit of analysis — the INSTRUMENT, not the container

Legal drafting bundles several unrelated instruments under one article/section — one provision may create two or more distinct charges. Decompose each container to its distinct instruments; classify per instrument, never per container. (Language-agnostic: applies to French articles, Anglophone sections, budget-law line items alike.)

**Grain is fixed and may not be varied per document or per run.** A census counted at container grain in one document and instrument grain in another is not one census. Any change to the grain is a change to what the census measures and must be applied corpus-wide.

## N5. Grain & row types

One row = one (clause × one distinct source instrument) at N4 decomposition. A container provision bundling three instruments produces three rows, each independently anchored to its own verbatim excerpt.

**All census rows are source rows.** `row_type = source` on every row, retained as a constant rather than dropped, for schema compatibility. The census records no destinations, shares, or assignment relations — the schema contains no fields for them (dictionary §6).

## N6. Id-free extraction

No synthetic ids at extraction. `instrument_id` blank. Identity is carried by the NATURAL KEYS (`document_id`, `legal_article`, `official_name` verbatim, `verbatim_excerpt`, page anchors) — mandatory on every row. `human_validation_status = unchecked` at extraction.

**No cross-document reconciliation is performed.** The census makes no claim that an instrument appearing in one document is the same instrument appearing in another. Each document's census stands alone. This is deliberate: it is what keeps the census a set of statements about primary sources rather than an assertion about a country's tax history, and it removes the entity-resolution burden entirely.

Lineage signals are captured only where the text states them (`predecessor_ref`, `predecessor_relation`) — recorded textual facts, never judgments. `change_type` is provisional and document-local.

## N7. Independence discipline (binding)

The census sweep is run **independently**. During census extraction:

- No other extraction output, evidence table, or prior result set is consulted.
- No known-instrument list, checklist, or register is used as an input. Retrieval anchors on the grammar by which a text institutes a charge, plus the document's own section structure.
- Every row is justified by the document in front of the extractor and by nothing else.

Rationale: an external list can only confirm instruments already known and will systematically miss the rest, biasing the census toward the already-catalogued and voiding any claim of completeness. Independence is also what makes the census usable as a check on other enumerations of the same corpus — a sweep that consulted them could not check them.

**Corollary.** The census schema contains no field for any property an instrument may have *outside* this document. Where such a property is needed downstream, it is appended after extraction closes, never populated during it.

## N8. Mandatory audits (the reproducibility guarantee)

Completeness is VERIFIED, not promised. Every census run must produce:

- **Coverage certificate** — the document's own divisions enumerated CONTIGUOUSLY from first to last (front matter → body → annexes), each certified swept, each with its count of instruments found, **including certified zeros**. A numbering gap between certified ranges is itself a reportable finding. This is what converts "the whole document was read" from a promise into an auditable claim.
- **Boundary-call log** — every judgment call at the inclusion margin, logged with its verbatim excerpt and the call made. Marginal judgment calls, not missed pages, dominate the uncertainty in any census count: each one adds or removes a row directly. Log every `instrument_nature` call that is not self-evident, every N4 decomposition of a container, every N1(c) referenced-not-enacted disposition, and every instrument recorded with no rate concept.
- **Recall audit** — every instrument-grammar hit from the sweep either captured as a row or dismissed with a one-line reason. No hit unaccounted.
- **Schema-stress note** — only genuinely NEW gaps. A real one means STOP and revise the schema before continuing the corpus (keeps the corpus homogeneous).
- **Confidence reasons** — per non-high-confidence row, typed as document problem vs schema problem.

## N9. Cross-jurisdiction invariance & extension points

The core is country-agnostic.

- **Invariant:** N1–N8 hold unchanged. The operative test, grain, id-free architecture, independence discipline, and audits are universal.
- **Extension points (additive, never rewrite):** (a) `instrument_nature` may gain values for structures not present in the pilot corpus — **OPEN ITEM, see N10**; (b) `evidence_status` may gain values; (c) the retrieval grammar — the vocabulary by which a text institutes a charge — is NOT in this core: it lives in the adapter and is swapped per language. The adapter itself is reused unchanged, since it keys on document *structure*, not on what is being extracted; only its lexicon is repointed to instrument-institution grammar.

Record any enum extension in the assumptions register with the country/document that forced it.

## N10. Open items (to be closed before freeze)

1. **`instrument_nature` value set — OPEN.** The enum must be the smallest set that (i) covers the natures actually present in the corpus and (ii) draws its lines where downstream population boundaries need to be filterable. It cannot be fixed a priori: it is an empirical question about what the documents contain. To be closed by inspection of the pilot corpus, then recorded here and in the assumptions register. **Until closed, census extraction records `instrument_nature` as the verbatim term the document itself uses, plus a provisional tag.** No row is lost and the enum can be imposed retrospectively without re-extraction.

2. **`evidence_status = referenced_not_enacted_here` — proposed extension, pending ratification.** The existing register vocabulary is `{attested, interpolated, unobserved}`. The proposal is a distinct fourth value rather than folding into `unobserved`, on the grounds that the two are analytically different: `unobserved` means the attesting document is missing from the corpus (a coverage gap); `referenced_not_enacted_here` means the document is present and correctly read, and the instrument is genuinely enacted elsewhere (a correct reading). Conflating them would let a document-availability problem hide inside an ordinary cross-reference. To be ratified against the corpus.
