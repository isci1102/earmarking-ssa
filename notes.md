
Once the report is rendered and checked, the first pass on the database is finished. Here’s what remains, in the order I’d do it.

### Close the first pass (short)

1. **Review the report.** I check it against the tables, then you send it to Julien and Luc.
2. **Commit and sync.**
   * **Commit to git:** the R scripts, `docs\`, `prompts\`, the build script, the concordance files (v1, v2, overrides), `country_groups.csv` and the skill.
   * **Copy back to the Project:** the docs that changed today (PROJECT_STATE, ANALYSIS_SPEC, DERIVED_TABLE_SPEC, PLOT_STYLE, and the new GLOSSARY).
3. **`run_all.R`:** a small script that re-runs `00`–`05` and the report in order, as the spec requires.

### Second pass: external data (section B)

4. **Download** WoRLD 2026, the GRD and the PEFA PI-6 scores into `supporting-data`.
5. **`10_external_prepare.R`:** one row per country, with the source and years of each variable.
6. **`11_exposure.R`:** B1, revenue exposed to earmarking and the largest statutory earmarks as % of GDP.
7. **`12_associations.R`:** B3 (resource revenue vs compensatory design) can run directly. **B2 (PEFA) has to wait for open issue (d):** it needs the on/off-budget status of fund rows, which we decided to build first.
8. **`first_results_external.qmd`:** the second report.

### Open issues to close along the way

* **(d) Budget status of fund rows:** needed before B2.
* **(e) Missing social contributions:** check whether they are corpus gaps (COM, GIN, MDG, NER).
* **A6:** whether to keep the payments to local collectors and chiefs in the subnational counts.
* **The four main-text Sankeys:** a provisional choice, to confirm once you’ve looked at all 43 pages.
* **A7(c):** main text or appendix.

### Examples (whenever convenient)

9. **`06_examples.R`:** draw the examples by rule, with the review log; you check them later or during validation.

### Validation (§4.1): must come before any institutional result is written up

10. **Write the protocol,** then:
    * **recall** on 2–3 hand-coded countries;
    * **precision and κ** on about 150 rows, stratified by AI confidence (60% of allocations are below “high”);
    * **stability** on 2 re-runs. This one costs compute, since it means re-extracting with the LLM. Given your budget, limit it to a few countries, or raise cost-sharing with Julien first;
    * **a corpus-completeness index,** correlated with WGI government effectiveness.

### Second stage and release

11. **Survey of IMF country teams:** missing funds, errors and amounts. These feed the validation and the B4 magnitudes.
12. **Robustness checks** (§4.4).
13. **Release:** CSVs, a codebook (the glossary is a good start), versioned prompts, scripts, corpus lists with URLs and hashes, and a Zenodo DOI.

### Deferred to later projects

* **A5:** reform candidates, a deep dive including the sovereign funds.
* **The supranational layer:** regional community levies.
