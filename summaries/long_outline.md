# Proposed Paper 1 Outline and Research Protocol

## Working title

**Mapping Statutory Revenue Earmarking in Africa: Prevalence, Design, and Revenue-to-Function Links**

## 1. Paper objective and contribution

Paper 1 will be a **current-law database and stylized-facts paper** documenting the statutory revenue-earmarking environment across Africa. Its principal contribution will be the construction of a denominator-based, source-linked, and auditable legal database that identifies:

* the universe of revenue instruments observed in each country’s legal corpus;
* whether and how their proceeds are statutorily assigned;
* the revenue sources used for earmarking;
* the functions and institutional recipients financed;
* the legal architecture of the assignments;
* and the relationship between national earmarking architectures and selected fiscal and institutional conditions.

The database is built from two linked tables: a revenue-instrument census, which provides the denominator, and a statutory-allocation layer, which records instrument-to-recipient channels. The two are linked through `census_ref`, allowing prevalence to be measured without counting a multi-recipient instrument several times. The database records **de jure statutory assignment**, not collections, transfers, appropriations, execution, additionality, compliance, or outcomes. 

The paper will preserve the project taxonomy:

* **E0:** no statutory assignment observed in the selected corpus;
* **E1:** assigned but unrestricted;
* **E2:** partial earmark;
* **E3:** exclusive earmark;
* **E4:** cost recovery only.

Earmarked instruments are **E2 + E3**. Unrestricted territorial sharing and cost recovery will remain analytically separate from purpose-restricted earmarking. 

This reframes the initial internship objective into a contribution that the available data can support rigorously. The original proposal combined a literature review, a regional inventory, and an evaluation of the performance of earmarked systems. Paper 1 will deliver the first two components comprehensively and establish the measurement foundation needed for later implementation and causal work.  The database and paper are intended to become the fixed foundation of the broader research program rather than an indefinitely expanding inventory. 

# 2. Paper 1 protocol

## 2.1 Central research questions

Paper 1 will answer three principal questions:

1. **How prevalent are statutory revenue assignments and  earmarks across African countries?**
2. **Which types of revenue instruments finance which functions, institutions, and levels of government?**
3. **How are earmarks structured in law particularly in terms of partial versus exclusive dedication, recipient architecture, allocation breadth, and legal determinacy?**

A fourth, secondary question will examine:

4. **How are country-level earmarking architectures descriptively associated with budget institutions, fiscal decentralization, revenue structure, fiscal rules, governance, and tax related attitudes?**

## 2.2 Geographic and temporal scope

The target geographic universe will be:

* all feasible SSA sovereign countries, excluding Somalia and Eritrea;
* North African countries where authoritative legal sources permit adequate coverage, excluding Sudan;
* France, Portugal, and the United Kingdom as methodological comparators.

Under the adopted scope, the target is approximately **51 African countries plus three European benchmarks**. The UN M49 classification will be used to distinguish SSA from North Africa. ([UNSD][1])

The legal snapshot will be centered on **2025-2026**, using the most recent authoritative or consolidated source available for each country. Each country will have a recorded legal reference date and information on consolidation, amendments, subordinate texts, and sectoral law coverage.

## 2.3 Analytical samples

Geographic inclusion will be separated from analytical eligibility:

| Status                           | Definition                                                                                     | Use                                           |
| -------------------------------- | ---------------------------------------------------------------------------------------------- | --------------------------------------------- |
| **A - prevalence-comparable**    | Census and allocation law documents are sufficiently complete and aligned                            | All prevalence, design, and external analyses |
| **B - architecture-comparable**  | Assignments are well documented, but the full revenue-instrument denominator remains uncertain | Source, destination, and design analyses only |
| **C - attempted but incomplete** | Important legal sources or current-status information remain unresolved                        | Coverage map and country documentation only   |

SSA will be the principal analytical sample. North Africa will be reported as a separate extension. The European countries will appear in separate comparator profiles and will never enter African pooled averages.

## 2.4 Units and denominators

| Question                            | Unit                                                 |
| ----------------------------------- | ---------------------------------------------------- |
| Prevalence and E0-E4 status         | Census instrument                                    |
| Partial versus exclusive design     | Earmarked instrument                                 |
| Recipient and routing architecture  | Canonical allocation channel                         |
| Destination functions               | Deduplicated instrument × COFOG division             |
| Source-to-destination relationships | Country × instrument × source class × COFOG division |
| Institutional associations          | Country                                              |

For country $c$:

$$
D_c=\text{eligible current census instruments}
$$

$$
S_c=\text{instruments classified E2 or E3}
$$

$$
\text{Strict prevalence}_c=\frac{S_c}{D_c}
$$

The paper will report:

* pooled instrument-level prevalence, $\sum S_c/\sum D_c$;
* the equal-country mean of $S_c/D_c$;
* the median country prevalence;
* the full country distribution.

This prevents countries with larger legal instrument inventories from defining the entire regional result.

## 2.5 Statistical principles


* Country-level external analyses will use labelled scatterplots, Spearman correlations, Pearson correlations as sensitivity checks, and leave-one-country-out diagnostics.
* PEFA grades will be treated as ordinal rather than cardinal.
* All external analyses will be presented as associations, not effects.
* Main-text selection will be based on conceptual relevance, data coverage, and measurement quality-not statistical significance.
* Detailed source subclasses, four-digit COFOG results, alternative definitions, and secondary external analyses will be retained in the appendix.


# 3. Proposed paper outline

## 1. Introduction

### Purpose

Motivate the project through the financing and DRM challenges faced by African countries and the policy debate over whether visible revenue assignments can support tax acceptance, priority financing, or institutional credibility.

### Content

* Policy motivation and relevance for DRM and PFM.
* Absence of comparable destination-based legal data.
* Distinction between measuring statutory architecture and evaluating its effects.
* Presentation of the database and central research questions.
* Summary of the paper’s conceptual, measurement, and substantive contributions.

### Main contribution statement

Existing fiscal datasets classify government revenue primarily by source. This paper adds the missing statutory destination dimension and provides a systematic account of how current African laws connect revenue instruments to functions, institutions, and levels of government.


## 2. Literature review and conceptual framework

The literature review will follow the transmission-chain structure already developed rather than a binary list of advantages and disadvantages. 

### Proposed structure

The theroretical literature + empiracl evidence will be presented as follow: 

1. **The legal object and the legitimacy of de jure measurement**
2. **Political authorization, tax acceptance, and coalition formation**
3. **Revenue realization, compliance, and policy durability**
4. **Transfer, execution, additionality, and fungibility**
5. **Expenditure quality and fund governance**
6. **Evidence from SSA vs rest of the world**
7. **Evidence gap and contribution of Paper 1**

The central synthesis will be that earmarking can affect several distinct stages, but a gain at one stage does not imply a gain at the others:

$$
\text{legal design}
\rightarrow
\text{awareness and credibility}
\rightarrow
\text{authorization}
\rightarrow
\text{collection}
\rightarrow
\text{transfer}
\rightarrow
\text{additional spending}
\rightarrow
\text{spending quality}
\rightarrow
\text{outcomes}
$$

### Literature-to-empirics bridge

| Literature mechanism          | Observable in Paper 1                                                                | Paper 1 analysis                                                                            | Not observed in Paper 1                                       |
| ----------------------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| Benefit principle             | Taxed base and destination function                                                  | ISIC-COFOG source-to-destination links; benefit/corrective/capacity/unlinked classification | Individual valuation and willingness to pay                   |
| Political commitment          | Partial/exclusive design, legal source, share basis, routing                         | Legal-design analysis                                                                       | Actual credibility, enactment counterfactual                  |
| Visible dedication            | Named destination, recipient form, statutory restriction                             | Prevalence and recipient architecture                                                       | Public awareness and salience                                 |
| Budget fragmentation          | Routing through funds and agencies; national institutional context                   | Dedicated-vehicle incidence crossed with PEFA and OBS                                       | Actual off-budget status unless separately collected          |
| Fiscal decentralization       | E1 territorial assignment, derivation, equalization, restricted territorial channels | Territorial assignments crossed with WOFI indicators                                        | Effective subnational autonomy                                |
| Budget additionality          | Potentially relevant legal design only                                               | Identification of candidate cases for later work                                            | Actual transfer, execution, offsets, and marginal expenditure |
| Tax acceptance and compliance | No direct legal measure                                                              | Afrobarometer correlations as contextual secondary analysis                                 | Individual response to a specific earmark                     |
| Durability                    | Explicit change references encountered during extraction                             | Descriptive metadata and future sampling frame                                              | Systematic adoption, survival, or repeal history              |
| Demand-enforceability tension | Country earmarking architecture and institutional environment                        | OBS, PEFA, WGI, and fiscal-rule associations                                                | Causal direction between institutions and earmarking          |

---

## 3. Definitions and measurement framework

### Purpose

Establish precisely what is being counted and prevent the conflation of earmarking, cost recovery, and fiscal decentralization.

### Content

* Census versus allocation layer.
* Instrument versus allocation channel.
* E0-E4 classification.
* Strict earmarking as E2 + E3.
* Treatment of unrestricted territorial sharing and cost recovery.
* Instrument-level and channel-level counting rules.
* Current-law and de jure scope.
* Count-based rather than revenue-weighted prevalence.

Two or three legal examples will illustrate partial, exclusive, and unrestricted assignments. The full taxonomy and coding rules will remain in the appendix and replication package.



## 4. Country coverage and database construction

### Purpose

Explain how comparable data are constructed from different legal-source architectures.

### Content

* Final geographic universe and legal reference dates.
* Country document manifests and source hierarchies.
* Francophone consolidated-code workflow.
* Anglophone multi-Act and cross-document workflow.
* Lusophone workflow.
* North African bilingual or Arabic-source adaptations.
* LLM-assisted LOCATE-EXTRACT-RECONCILE pipeline.
* Census and allocation matching through `census_ref`.
* COFOG and source-class enrichment.
* Country coverage grades.


## 5. Validation and measurement quality

### Purpose

Demonstrate both auditability and empirical accuracy.

### Content

* Legal excerpts and page-level provenance.
* Manifest and coverage closure.
* Positive-record precision.
* Blind recall review of complete documents or sampled legal sections.
* Review of negative or no-assignment passages.
* Instrument-identity and allocation-channel agreement.
* Purpose-restriction and cost-recovery agreement.
* `census_ref` accuracy.
* COFOG division accuracy.
* Validation performance across legal languages and corpus architectures.
* Country-level coverage indicators.



## 6. Current statutory earmarking in Africa

This will be the central empirical section.

### 6.1 Prevalence and assignment architecture

The analysis will report:

* country-level E0 E4 distributions;
* strict earmarking prevalence;
* pooled, equal country, and median prevalence;
* cross country heterogeneity;
* SSA results;
* North African extension;
* sensitivity to country coverage and legal-source vintage.

### 6.2 Which revenue sources are earmarked?

Two distinct measures will be reported:

$$
\text{Source composition}_{s}
=
\frac{\text{strict instruments in source class }s}
{\text{all strict instruments}}
$$

$$
\text{Within-source propensity}_{s}
=
\frac{\text{strict instruments in source class }s}
{\text{eligible census instruments in source class }s}
$$

The first identifies the main sources used for earmarking. The second establishes whether a source class is disproportionately likely to be earmarked, conditional on the number of instruments of that type in the legal system.

The main text will use broad source classes; the complete 14-class and 30-subclass results will be available in supplementary tables.

### 6.3 What functions and institutions receive earmarked proceeds?

For each COFOG division, the analysis will report:

* the number and share of distinct instrument-function relationships;
* the number of countries in which the function appears;
* pooled and equal-country destination shares;
* recipient tier: national, territorial, or supranational;
* recipient form: fund, agency, ministry, programme, stated function, or other recipient.

The main destination unit will be the deduplicated instrument × COFOG division relationship. Channel-level results will be used specifically for institutional routing.

### 6.4 Source-to-destination architecture

The central source-to-destination table will use:

$$
\text{country}
\times
\text{instrument}
\times
\text{source class}
\times
\text{COFOG division}
$$

The analysis will document:

* recurrent source-to-function relationships;
* conditional destination distributions within each source class;
* conditional source distributions within each destination;
* the number of countries using each source-destination combination;
* continent-wide patterns versus country-specific arrangements.

The principal visualization will be a source-class × destination-function matrix in which the cell information combines instrument frequency and geographic spread.

### 6.5 How are earmarks legally designed?

The principal design dimensions will be:

* partial versus exclusive earmarking;
* single versus multiple statutory recipients;
* single versus multiple functions;
* national, territorial, and supranational recipient tiers;
* fund, agency, ministry, programme, and stated-function recipients;
* stated, scheduled, whole-proceeds-implied, and deferred allocations;
* direct versus nested routing.

### 6.6 Secondary internal analyses

These analyses will be completed but will enter the main text only when they provide a clear additional fact:

1. **Payer beneficiary linkage:** benefit-linked, corrective-linked, capacity-linked, and unlinked relationships.
2. **Legal rank and determinacy:** location of assignments in constitutions, principal laws, finance laws, or subordinate instruments.
3. **Dedication ratios:** only for instruments whose complete percentage allocation key is computable.
4. **Country architecture profiles:** descriptive heatmaps using a limited set of interpretable dimensions; no automated clustering as a principal result.
5. **Detailed source subclasses and four-digit COFOG groups.**
6. **Equalization, derivation, supranational assignments, and nested-pool structures.**



## 7. Institutional and fiscal context

This section will examine a pre-specified set of country-level associations. The central outcomes will be:

$$
\text{Strict prevalence}
=
\frac{E2+E3}{D}
$$

$$
\text{Exclusive share}
=
\frac{E3}{E2+E3}
$$

$$
\text{Dedicated-vehicle incidence}
=
\frac{\text{strict instruments routed to a fund or agency}}
{\text{strict instruments}}
$$

$$
\text{Legal-determinacy share}
=
\frac{\text{strict instruments without a deferred or unknown restricted allocation}}
{\text{strict instruments}}
$$

$$
\text{Territorial-assignment prevalence}
=
\frac{\text{instruments with an unrestricted territorial, derivation, or equalization channel}}
{D}
$$

For each external relationship, the paper will report:

* a labelled country scatterplot or grouped distribution;
* the number of matched countries;
* Spearman correlation as the principal summary;
* Pearson correlation as a sensitivity measure where appropriate;
* leave-one-country-out estimates;
* SSA and North African results separately;
* no causal interpretation.


## 8. Comparators, robustness, and limitations

### Comparator strategy

France, Portugal, and the United Kingdom will be used to assess whether the taxonomy and production methodology travel across:

* consolidated Francophone legislation;
* Lusophone legislation;
* fragmented common-law legislation.

They will be displayed in separate profiles or comparator panels rather than included in African averages.

### Principal robustness checks

Main-text checks:

* Grade-A countries only;
* pooled versus equal-country weighting;
* SSA versus the African extension;
* leave-one-country-out prevalence;
* inclusion and exclusion of penalties;
* separate treatment of unrestricted territorial assignments.

Appendix checks:

* `referenced_not_enacted_here`;
* equalization and supranational channels;
* low-confidence or inferred COFOG classifications;
* unmatched or complex `census_ref`;
* legal-vintage restrictions;
* instrument-level versus channel-level results;
* alternative narrow tax-only denominator;
* detailed comparisons across legal-source architectures.

### Limits

The paper will measure the current statutory architecture. It will not estimate effects on:

* tax acceptance or compliance;
* net DRM;
* actual transfers;
* budget execution;
* expenditure additionality;
* service delivery;
* policy durability.

These are separate measurement layers and will motivate subsequent papers rather than be inferred from the legal cross-section.


## 9. Conclusion and research agenda

The conclusion will summarize the contribution of the legal database and explain how it creates:

* a sampling frame for a legal-event history of creation, amendment, and repeal;
* a list of instruments and funds for de jure-de facto implementation analysis;
* a basis for targeted country studies of collections, transfers, execution, and additionality;
* empirically realistic source-destination treatments for future acceptability or compliance experiments.



# 4. External-data analysis plan

## 4.1 Main external analyses

| Hypothesis                                                    | Earmarking indicators                                                                              | External dataset and variables                                                                                                                                                                                                      | Exact analysis                                                                                                                                                                                                                |
| ------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Budget transparency and the demand-enforceability tension** | Strict prevalence; exclusive share; legal-determinacy share; dedicated-vehicle incidence           | **Open Budget Survey 2025:** transparency score, oversight score, and legislative/audit components where separately available                                                                                                       | Strict prevalence × transparency; exclusive and determinate design × transparency; dedicated-vehicle incidence × oversight                                                                                                    |
| **PFM comprehensiveness, cash management, and audit**         | Strict prevalence; dedicated-vehicle incidence; legal-determinacy share                            | **PEFA 2016 framework:** PI-6.1 expenditure outside reports, PI-6.2 revenue outside reports, PI-6.3 financial reports of extrabudgetary units, PI-21.1 cash-balance consolidation, PI-30 external audit, PI-31 legislative scrutiny | Dedicated vehicles × PI-6.3 and PI-21.1; strict prevalence × PI-6.1/6.2; determinacy and dedicated vehicles × PI-30/31                                                                                                        |
| **Fiscal decentralization**                                   | Territorial-assignment prevalence; derivation/equalization incidence; restricted territorial share | **OECD-UCLG WOFI:** subnational revenue and expenditure shares, grants as a share of subnational revenue, subnational tax-revenue share                                                                                             | Territorial assignment × subnational revenue/expenditure shares; derivation/equalization × transfer dependence; restricted territorial earmarks shown separately                                                              |
| **Revenue-system structure**                                  | Category-specific source shares and within-source earmarking propensities                          | **IMF WoRLD 2026:** social contributions, taxes on goods and services, trade taxes, natural-resource revenue, grants, and total revenue composition                                                                                 | Social-contribution revenue × social-contribution earmark propensity; indirect-tax share × consumption/excise propensity; trade-tax share × import-levy propensity; natural-resource revenue × resource-assignment propensity |
| **Resource and non-tax revenue architecture**                 | Resource-tax/royalty assignments; derivation and territorial sharing                               | **Revenue Statistics in Africa 2025:** rents, royalties, property income, non-tax revenue, social contributions, and detailed tax composition                                                                                       | Resource dependence × resource earmarking and territorial assignment; used as a robustness and coverage extension to WoRLD                                                                                                    |

OBS 2025 separately measures transparency, participation, and oversight; its SSA release covers 33 countries, its MENA release covers eight, and the assessment reflects practices through the end of 2024. ([International Budget Partnership][2])

PEFA PI-6 covers central-government operations outside financial reports, PI-21 covers predictability of in-year resource allocation, and PI-30 and PI-31 cover external audit and legislative scrutiny. Only national assessments using the 2016 framework will be combined, with assessment year reported explicitly. ([Pefa][3])

WOFI currently provides comparable subnational-finance and institutional data for 135 countries. The fourth edition is scheduled for December 2026; the newest edition available at the data-freeze date will be used. ([OECD][4])

The IMF’s 2026 WoRLD update tracks nine main tax and non-tax revenue components and extends through 2024. The proposed merge will use 2022-2024 averages where available. ([IMF][5]) Revenue Statistics in Africa 2025 covers tax and non-tax revenues through 2023 for 38 African countries and provides additional detail on rents, royalties, and other non-tax revenues. ([OECD][6])

## 4.2 Secondary external analyses

| Question                                                                                                      | Earmarking indicators                                                               | Dataset and variables                                                                                                                                                                  | Proposed use                                                                                                            |
| ------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **Are earmarks and fiscal rules complementary or competing legal constraints?**                               | Strict prevalence; exclusive share; legal rank; legal-determinacy share             | **IMF Fiscal Rules Dataset:** any rule, budget-balance/debt/expenditure/revenue rules, legal basis, escape clauses, independent monitoring                                             | Compare country distributions with and without rules; appendix unless coverage and interpretation are especially strong |
| **Is legal-source completeness institutionally selective?**                                                   | Coverage grade; corpus-coverage index; inferred-function share; unmatched-link rate | **World Governance Indicators:** government effectiveness and rule of law                                                                                                              | Measurement-selection diagnostic before interpreting governance-earmarking relationships                                |
| **How does earmarking architecture relate to broad governance conditions?**                                   | Strict prevalence; dedicated-vehicle incidence; legal determinacy                   | **WGI:** government effectiveness, control of corruption, rule of law                                                                                                                  | Secondary correlations conditional on the coverage diagnostic                                                           |
| **Are visible or benefit-linked architectures associated with tax legitimacy and information?**               | Strict prevalence; benefit-linked share; dedicated-vehicle incidence                | **Afrobarometer:** tax legitimacy, access to information on revenue use, perceived corruption among tax officials, trust or perceived use of taxes for public welfare where harmonized | Country-level contextual correlations; appendix because awareness of specific earmarks is not observed                  |
| **Does grant dependence or broader fiscal pressure correspond to greater use of protected revenue channels?** | Strict prevalence; exclusive share; health/education destination shares             | **WoRLD:** grants as a share of revenue and total revenue composition                                                                                                                  | Secondary contextual analysis; no causal interpretation                                                                 |

The IMF Fiscal Rules Dataset covers national and supranational rules in 123 economies from 1985 through 2024 and records rule type, legal basis, correction mechanisms, and monitoring institutions. ([IMF][7])

The 2025 WGI revision provides annual indicators for six governance dimensions across more than 200 economies through 2024. Its first use in this project will be to test whether country coverage quality is systematically related to government effectiveness or rule of law. ([Banque mondiale][8])

Afrobarometer provides country datasets and codebooks through Round 10 for a growing set of African countries. The merge will use the latest common round with sufficiently harmonized tax questions rather than mixing country rounds without documentation. ([Afrobarometer][9]) Its survey materials include recurring measures of tax legitimacy and difficulty obtaining information on how tax revenues are used. ([Afrobarometer][10])

# 5. Country extraction and production sequence

## Phase 1 - Complete Francophone SSA

Complete the remaining countries that can use the established consolidated-code or French-language workflow.

Deliverables for each country:

* legal-source manifest;
* census;
* allocation evidence;
* reconciliation;
* `census_ref`;
* COFOG classification;
* final allocation table;
* routine QA report.

At the end of this phase, conduct a Francophone-block consistency review covering source scope, legal vintage, join rates, and classification completeness.

## Phase 2 - Consolidate the Anglophone methodology

Use Ghana, Nigeria, and South Africa to formalize a reproducible Anglophone method before adding further Anglophone countries.

The methodology note will cover:

* mapping of all tax, customs, social-contribution, resource, sectoral-levy, and fund-administering institutions;
* principal, levy-specific, fund, Finance, amendment, and subordinate Acts;
* official consolidation versus amendment reconstruction;
* use of budgets and revenue lists as discovery tools;
* identification of levies outside the central revenue-authority corpus;
* cross-document matching of charging and destination provisions;
* current-law reconciliation;
* denominator-completion and stopping rules.

The three pilot countries will then be reviewed retrospectively against the consolidated protocol.

## Phase 3 - Screen and roll out the remaining Anglophone SSA countries

Build a feasibility matrix recording for each country:

* administrative and legal-source architecture;
* principal Acts and amendments;
* sectoral and fund legislation;
* official portals;
* document quality;
* latest legal year;
* expected source gaps;
* proposed corpus boundary.

Countries will then be extracted in manageable batches, with routine QA completed before each batch is closed.

## Phase 4 - Develop and apply the Lusophone methodology

Develop a Portuguese-language legal-search grammar, source hierarchy, consolidation protocol, and terminology dictionary. Pilot the method on two contrasting Lusophone systems before applying it to the remaining Lusophone SSA countries.

## Phase 5 - Complete remaining mixed-system SSA cases

Multilingual or mixed-source systems will be assigned to the closest validated workflow, with country-specific retrieval adaptations but no change to the common analytical schema.

## Phase 6 - North Africa

Develop an Arabic/French/English source adapter for Algeria, Egypt, Libya, Morocco, and Tunisia where authoritative sources permit adequate coverage.

## Phase 7 - European benchmarks

Extract France, Portugal, and the United Kingdom last. These cases will test methodological portability rather than define the African results.


# 6. Cross-country data engineering

Before final analysis, the country extraction outputs will be transformed into a reproducible analytical database containing:

1. **Country document manifest:** one row per legal source.
2. **Census master:** one row per country × current revenue instrument.
3. **Allocation master:** one row per canonical non-restatement `pair_id`.
4. **Census-allocation bridge:** long-form representation of `census_ref`.
5. **Instrument analytical table:** one row per instrument with E0-E4 and derived design indicators.
6. **Instrument-destination table:** one row per instrument × COFOG division.
7. **Country summary table:** prevalence, source, destination, design, and coverage indicators.
8. **Source-to-destination cube:** country × source class × COFOG division.
9. **External-context table:** external indicators, years, definitions, and missingness reasons.
10. **Analysis-sample registry:** eligibility of each country for every empirical block.

The data-engineering pipeline will automatically verify:

* uniqueness of country-instrument and `pair_id` keys;
* exclusion of restatements;
* validity of all `census_ref` links;
* exactly one E0-E4 status per eligible instrument;
* separation of E1 territorial assignment from E2 partial earmarking;
* separation of cost recovery from proceeds assignments;
* correct handling of nested pools;
* reconciliation of country totals across all final tables.


# 7. Validation and robustness protocol

## Routine QA during extraction

Each country will continue to undergo:

* manifest-to-output reconciliation;
* page and coverage checks;
* duplicate and restatement checks;
* low-confidence review;
* `pair_id` and `census_ref` checks;
* review of purpose-restriction and cost-recovery boundary cases.

## Publication-grade validation after data engineering

The final validation exercise will include:

* a stratified random sample of positive census and allocation records;
* complete human review of selected legal documents or sections;
* blind review of negative or no-assignment regions;
* instrument-level merge/split agreement;
* allocation-channel agreement;
* purpose-restriction and cost-recovery accuracy;
* `census_ref` exact-set accuracy;
* recipient and COFOG division accuracy;
* separate performance by language and legal-source architecture;
* an explicit error taxonomy and correction log.

The validated and corrected analytical data will then be frozen before the final empirical results are produced.


# 8. Priority list and next steps

Literature writing and legal extraction can proceed in parallel. The proposed order of work is:

| Priority | Task                                                                   | Concrete deliverable                                                                                                        | Completion condition                                                                                                     |
| -------: | ---------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
|    **1** | Write the literature review from the existing outline                  | Full mechanism-based draft, concise paper version, literature-to-empirics table, verified bibliography                      | Every outline section is in prose and approximate references are identified for source verification                      |
|    **2** | Complete remaining Francophone SSA extractions                         | Full country outputs under the established workflow                                                                         | Every targeted country has census, allocations, joins, COFOG, manifest, and QA outputs or a documented source limitation |
|    **3** | Close the Francophone production block                                 | Cross-country Francophone consistency report                                                                                | All schemas align and unexplained differences in scope, joins, or unknown classifications are reviewed                   |
|    **4** | Consolidate the Anglophone legal-source methodology                    | Stand-alone methodology, source hierarchy, amendment decision tree, sectoral-levy checklist, and stopping rule              | One common protocol can be applied to Ghana, Nigeria, and South Africa                                                   |
|    **5** | Reassess GHA, NGA, and ZAF under the consolidated method               | Three source-gap and consistency reports, with corrected outputs where needed                                               | Each pilot satisfies the common protocol or has an explicit unresolved limitation                                        |
|    **6** | Build the Anglophone-country feasibility matrix                        | Country-by-country source and legal-architecture inventory                                                                  | Every remaining Anglophone-source SSA country has a proposed corpus and risk assessment                                  |
|    **7** | Roll out the Anglophone SSA extraction                                 | Completed country outputs in successive batches                                                                             | Every feasible country has been attempted and assigned a preliminary coverage status                                     |
|    **8** | Develop and roll out the Lusophone workflow                            | Lusophone methodology, terminology dictionary, pilot review, and country outputs                                            | The workflow has been tested on contrasting systems and applied to all target Lusophone countries                        |
|    **9** | Complete remaining mixed-system SSA cases                              | Country-specific adapters and harmonized outputs                                                                            | All target SSA countries have been attempted                                                                             |
|   **10** | Build and roll out the North African workflow                          | Arabic/French/English source protocol and country outputs                                                                   | Each feasible North African target has complete outputs or a documented source barrier                                   |
|   **11** | Extract the three European benchmarks                                  | FRA, PRT, and GBR databases and methodology-comparison note                                                                 | All three can be processed without altering the substantive taxonomy                                                     |
|   **12** | Close the all-country corpus documentation                             | Final document manifest, legal reference dates, and A/B/C eligibility registry                                              | Every country has a transparent coverage status and source boundary                                                      |
|   **13** | Build the final cross-country analytical database                      | Census master, allocation master, bridge, instrument table, country summary, source-destination cube, and analysis registry | All outputs are generated automatically and all row-count identities reconcile                                           |
|   **14** | Conduct publication-grade validation and freeze the data               | Precision/recall report, agreement tables, correction log, and versioned analytical release                                 | Core classifications and links meet the pre-declared validation criteria                                                 |
|   **15** | Produce the internal and external analyses and complete the manuscript | Stylized-facts outputs, external-data merge, robustness appendix, and full paper draft                                      | Every empirical claim is tied to a defined unit, denominator, sample, and reproducible output                            |

Once the feasible African universe has been attempted, every country has a transparent coverage status, the cross-country analytical data have passed validation, and the substantive results are stable under the principal coverage and denominator checks, the current-law database will be frozen.

Subsequent work will then move to a legal-event history of adoption and durability, de jure-de facto implementation, and focused studies of transfers, additionality, compliance, and tax acceptability.

[1]: https://unstats.un.org/unsd/methodology/m49/overview/ "UNSD - Methodology"
[2]: https://internationalbudget.org/open-budget-survey/ "Open Budget Survey - International Budget Partnership"
[3]: https://www.pefa.org/node/4760?utm_source=chatgpt.com "3. measuring performance indicators and dimensions"
[4]: https://www.oecd.org/en/topics/subnational-finance-and-investment.html "Subnational finance and investment | OECD"
[5]: https://www.imf.org/en/topics/fiscal-policies/world-revenue-longitudinal-database "World Revenue Longitudinal Database"
[6]: https://www.oecd.org/en/publications/revenue-statistics-in-africa-2025_8d3bf3af-en.html "Revenue Statistics in Africa 2025 | OECD"
[7]: https://www.imf.org/en/topics/fiscal-policies/fiscal-rules-dataset "IMF Fiscal Rules Dataset"
[8]: https://www.worldbank.org/en/publication/worldwide-governance-indicators "Home | Worldwide Governance Indicators"
[9]: https://www.afrobarometer.org/surveys-and-methods/survey-resources/ "Survey resources and data - Afrobarometer"
[10]: https://www.afrobarometer.org/publication/ad886-most-ugandans-struggle-to-access-information-on-taxes-they-owe-and-how-revenues-are-used/?utm_source=chatgpt.com "AD886: Most Ugandans struggle to access information on ..."
