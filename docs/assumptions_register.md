# Assumptions Register — load-bearing choices and what they constrain

**Purpose.** Building the database "question-agnostic" is correct but is **not** assumption-free. Each construction choice below quietly privileges some research questions over others. This register keeps those choices explicit so that when the research question is selected *against* the data, it is not unconsciously the question the construction already favoured (the selection-on-the-analyst analogue of endogeneity). Each entry: the assumption, why it is load-bearing, and which questions it constrains or enables.

---

### A1. Scope is *de jure* (legal assignment), not *de facto* (execution)
- **Choice.** The inventory records legally-assigned earmarks from statutes and budget laws. It does not record realized disbursement.
- **Load-bearing because.** It supplies the **left-hand side of identification** (treatment: earmark existence, design, reform, and its *timing*) but **not the outcome**. Revenue-mobilization and fungibility questions require outcomes (realized revenue, sector spending) from separate execution sources (TOFE, BOOST, budget-execution reports).
- **Constrains.** Any causal claim about revenue or spending effects needs a later, separate execution-data layer. Do not mistake the legal inventory for a revenue-effects dataset. Fungibility (the central "con") is only testable against execution + total-sector-allocation data.

### A2. Entity grain: instrument-parent, pair-child
- **Choice.** `instrument_id` (source) with `pair_id` (instrument × destination) beneath it.
- **Load-bearing because.** Instrument-level continuity serves the revenue-mobilization framing (does the tax raise money); pair-level share series serve the allocation/political-economy framing (do shares respond to outcomes; do reforms to shares affect compliance/acceptability). Both are preserved; neither is foreclosed.
- **Enables/constrains.** Unit of observation in the estimating equation is deliberately **left open**. Instrument-level → treatment often earmark creation/existence (staggered adoption), with selection-into-earmarking endogeneity (which sectors/countries earmark is a function of fiscal capacity and governance). Pair-level → treatment is the share change; cleaner exogeneity claim is a reallocation set by *arrêté* for reasons unrelated to a specific sector's outcomes — but must defend against reverse causality (shares cut *because* a fund underperformed).

### A3. `pair_id` tracks destination *set*, not allocation *value*
- **Choice.** Share is a time-varying attribute; `pair_id` changes only on destination add/drop.
- **Load-bearing because.** Preserves within-channel continuity across allocation-key reforms — the variation a share-change event study depends on. Baking share into the key would convert a reform into unit-death+birth and destroy within-unit identification.

### A4. Structural-break rule anchored to legal text, not economic judgment
- **Choice.** New `instrument_id` only when the text asserts abolition/replacement; base redefinitions keep the id with a flag.
- **Load-bearing because.** Determines where a revenue series has a *mechanical* discontinuity (base redefinition, `structural_break = 1`) vs. a genuine unit change. Recording breaks at extraction is cheap; reconstructing them later is not. Omitting them would leave a within-instrument revenue design blind to confounds it cannot later recover without re-reading every document.

### A5. `amount_budgeted` is appropriation, not execution; sourced from CST tables
- **Choice.** Yearly earmarked-account figures are budgeted amounts from the loi-de-finances CST table, held in a **separate budget-amounts table** (not the clause-anchored evidence table).
- **Load-bearing because.** It is the only bridge from the legal inventory to a *fiscal magnitude* — the candidate outcome for revenue-mobilization tests and one half of the fungibility test. But budget≠execution; the de-facto gap is non-random (correlates with fiscal stress/governance). Using it as an outcome without flagging this overclaims.
- **Constrains.** Time-series use must respect the **CST granularity break** (~6 aggregate accounts pre-2022 → 34–40 itemised 2025–2026): account-level amounts are not comparable across the break.

### A6. Rectificatives excluded from de-jure structure
- **Choice.** First pass excludes lois de finances rectificatives.
- **Load-bearing because.** Inspection (2021) shows they revise *amounts*, not earmark *structure* — corroborated by CGI amendment chains citing ordinary annexes, never rectificatives. Including them would add execution-flavoured noise to a de-jure inventory.
- **Reversible.** If a later rectificative is found to create/repeal/re-key an account, reinstate for that year.

### A7. Coverage is uneven and non-random (document-availability bias)
- **Choice.** Extraction proceeds on the documents that exist (annexes only 2012, 2017, 2023–2026; CGI 2026 only).
- **Load-bearing because.** Availability correlates with the same institutional-quality factors that may drive outcomes — a within-country (and, at SSA scale, cross-country) confounder. Gaps are treated as **unobserved**, never as zeros; `evidence_status ∈ {attested, interpolated, unobserved}` carries this into the panel.

### A8. Retrieval is fund-agnostic (anchored on assignment grammar)
- **Choice.** Candidate detection keys on the grammar of assignment, never on a known-fund allow-list.
- **Load-bearing because.** A fund allow-list can only confirm known earmarks and would systematically miss new ones — biasing the inventory toward what was already known and corrupting any claim of completeness. Preserving discovery is what lets the inventory be described as a genuine mapping rather than a checklist.

### A9. Hand-built layer is evidence-only; instrument and panel are derived
- **Choice.** Only clause-anchored evidence rows are hand-authored; the instrument entity and the panel are generated from them.
- **Load-bearing because.** Guarantees every hand-built row carries a verbatim quote and page (the evidence rule holds with zero exceptions), and that derived layers can never silently drift from their sources (they are always a function of the evidence). Deriving the instrument entity doubles as a completeness test: an instrument that cannot be reconstructed from its evidence reveals an evidence gap.

---

### A10. Scope: recorded population is broader than "earmarks" (extract-broad, filter-later)
- **Choice.** The evidence table records **every** revenue instrument assigned to a *specific named recipient* (fund, organism, ministry, tier, programme), not only purpose-restricted earmarks. The earmark-vs-tax-sharing distinction is a recorded field (`is_purpose_restricted`/`assignment_type`) applied as an analysis-time filter.
- **Load-bearing because.** It widens the paper's object from "earmarked taxes" to "revenue instruments with a specific legal destination, of which earmarks are a subset." This preserves the full population (enabling earmark-vs-tax-sharing/decentralization contrasts) and makes inclusion a reversible, auditable choice rather than a silent extraction judgment.
- **Constrains.** (i) Every aggregate statistic ("X% of revenue earmarked") is meaningless without stating its `assignment_type` filter. (ii) Fiscal-decentralization cases carry distinct confounders (political structure, ethnic geography, colonial administrative legacy) and must not be pooled with earmarks in a single regression without accounting for the treatment difference. (iii) The paper owes an explicit definitional sentence separating earmarking from tax-sharing/decentralization, and must anticipate the referee question "why is impôt foncier → Communes in an earmarking dataset?" (answer: recorded, flagged `tax_sharing_general`, filtered out of earmark analysis).

### A11. Cost-recovery / user-charge components are not earmarks (S1 — DECIDED)
- **Choice.** A statutory split of a payment that prices the *service the payer is consuming* (administrative cost-recovery, processing-officer remuneration) is classified `allocation_nature = cost_recovery_component`, recorded but excluded from the earmark subset and from the allocation-share panel. Proceeds directed to a party external to the service (fund, sector, programme) are `proceeds_share` (earmark candidate).
- **Load-bearing because.** Without the distinction, service-fee cost-splits inflate the earmark count, mix rate-decomposition percentages with proceeds-share percentages, and — most seriously — a re-priced service fee would register as a spurious allocation-share change, injecting systematic measurement error into the treatment variable (earmark-share reforms) that underpins the identification strategy.
- **Basis.** Benefit-principle boundary between a user charge and an earmarked tax (Bird; Buchanan; Charging-for-Government literature). Researcher's decision; managers informed.
- **Soft boundary flagged.** General administrative cost-recovery not tied to the specific taxed transaction is logged case-by-case, resolved toward `cost_recovery_component`.

---

## Open items — pending manager ratification (weekly meeting)

1. **`assignment_type` boundary (A10).** Which categories count as earmark-adjacent vs. excluded: does *specific* tax-sharing (a shared tax whose sub-national share is legally tied to a named restricted use) belong in the earmark subset, or only pure functional earmarks? The data records all; the analytical boundary is unratified.
2. **`program`-destination precedent (decision rules §8).** Functional-purpose destinations (a named activity, not a proper-noun body) provisionally count as genuine assignments — confirm.
3. **Scope-expansion framing (A10).** Ratify that the paper's object is "specific-destination revenue instruments, earmarks as a subset," with the definitional distinction stated up front.
4. **Reconciliation protocol (decision rules §10).** Deferred artifact — design after extraction; the excerpt-justified decision-log requirement is fixed now.

---


**Standing caution.** SSA-specific conjectures (acceptability channel, fungibility channel, institutional-quality conditioning, sign-ambiguity) are **educated guesses** until SSA data/literature support them — present as such, not as hypotheses with priors or as findings.
