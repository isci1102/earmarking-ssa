# GLOSSARY — how to read the first results (2 Nov 2026)

*Plain definitions of the terms used in the tables, figures and reports. The formal rules are in `DERIVED_TABLE_SPEC.md` (variables) and `ANALYSIS_SPEC.md` (analysis); this file only explains them.*

## Units
- **Instrument**: one charge (tax, levy, fee, fine…) whose proceeds the law assigns somewhere. A *class placeholder* stands for a class of charges the law names without listing them ("customs revenue").
- **Allocation**: one assignment of an instrument's proceeds to one destination (a fund, an agency, a commune…). One instrument can have several allocations.
- **Link**: one instrument × one COFOG division it finances (restricted assignments only). Heatmaps, Sankeys and benefit links count links.
- **Top level**: the first split of an instrument's gross proceeds in its assignment clause. Sub-keys (a share of a share) are used only as detail.

## Where the proceeds go: the E-class (one per instrument)
| class | meaning | example |
|---|---|---|
| E3 exclusive | all proceeds go to restricted destinations (apart from small collection-cost shares) | "the tax is assigned to the Forest Fund" |
| E2 partial | part restricted, the rest to the general budget | "20% to the Tobacco Control Fund, 80% to the Treasury" |
| E1 | assigned, but to an unrestricted budget | "50% to the communes' general budget" |
| E4 | collection-cost retentions only | "5% to the tax office for its costs" |
| E0 | refund reserve only | a VAT refund account |

- **Earmarked set** = E2 + E3 (main results). **Assigned set** = E1 + E2 + E3 (secondary, e.g. sharing with local governments).
- **Social contributions** (pension, health-insurance contributions) are left out of the headline results and included in a robustness check.

## How binding: commitment strength (one per assignment)
| label | rule | example |
|---|---|---|
| hard | fixed share, a dedicated body or account (fund, agency, special account, local government…), in a law voted by parliament | "10% of the levy is paid to the Road Fund" in an Act |
| firm | fixed share, but routed through a ministry or programme, or written only in an annual finance law | "10% to the Ministry of Health" |
| soft | share left to a later decree, unstated or only bounded; or the assignment itself is in a decree or order | "a share fixed by décret goes to the Fund" |

An instrument's commitment is its strongest assignment.

## Is there an economic rationale: the benefit link (one per link)
| class | the destination… | example |
|---|---|---|
| corrective | mitigates the harm the base causes | tobacco excise → health |
| compensatory | compensates the territory bearing the activity | mining royalty → host communities |
| benefit | serves the payers themselves | fuel levy → roads |
| sectoral | serves the taxed sector as a whole | telecom levy → telecom regulator |
| general revenue | broad base, no specific link | profit tax share → research agency |
| unlinked | specific base, unrelated destination | alcohol excise → sport |

## Vehicles and groups
- **Fund-or-agency share**: share of a country's earmarked instruments paying into a fund, agency, social-security body or non-government body (not a ministry, programme or Treasury special account). A legal form as written, **not** budget status: "fund" is anything the law calls a fund.
- **Base groups**: 12 groups of what is taxed (ANALYSIS_SPEC §2).
- **Design groups** (A7): UEMOA francophone, CEMAC francophone, francophone outside the CFA zone, anglophone, lusophone outside the CFA zone; GNB, GNQ (CFA but not francophone) and RWA, ETH (mixed) are shown individually.

## Sharing with local governments (A6)
Each allocation to or through a subnational tier (region, district, commune…) has one type of sharing (`assignment_type`, defined in the allocation prompt §4.3):

| type | meaning | example |
|---|---|---|
| General tax sharing | a share of a national tax paid into a tier's general budget, free to use | "50% of the business licence tax goes to the commune's budget" |
| Specific tax sharing | a share paid to a tier, but its use is restricted by the law | "10% of the fuel levy goes to the districts for road maintenance" |
| Devolved earmark | a restricted assignment routed to or through a tier (often to the tier's own fund or programme) | "5% of the forest tax goes to the commune's reforestation fund" |
| Equalisation transfer | revenue pooled and redistributed across all tiers by a formula, not by where it was raised | "20% of mining revenue goes to a support and equalisation fund for local governments" |
| Derivation transfer | revenue shared with the territory where it arises | "a share of the mining royalty goes to the producing commune" |
| Functional earmark of a tier's body | a restricted assignment to a body that belongs to a tier (e.g. a regional agency), coded by its function | "the levy finances the regional water board" |

Specific tax sharing and devolved earmarks are close; both are restricted. In the A6 tables, allocations are also split by economic role: **restricted**, **administrative retention** (collection costs, payments to local collectors or chiefs; never an earmark) and **unrestricted**.

**Reading the counts:** they show the *type* of decentralisation, not its degree. Where local governments receive fixed shares of specific taxes written into the tax code, these appear as allocations; where they are funded by grants set each year (annual revenue-division Acts were excluded from the corpus), they do not.

## Averages
- **Country-equal share** (default): compute the share in each country, then average across countries; each country counts once.
- **Pooled share** (robustness): pool all instruments of all countries; large countries weigh more.

## A7 in one paragraph
*Question*: do earmark designs differ by legal tradition, and does CFA membership matter beyond tradition? *Unit*: country (43). *Outcomes*: four shares of the country's earmarked instruments — exclusive (E3), hard, fund-or-agency, benefit-linked. *Regressors*: design-group dummies, reference = francophone outside the CFA zone; UEMOA and CEMAC vs that reference = harmonisation contrast; anglophone vs that reference = legal-tradition contrast. *Controls*: resource group, log documents read. *Model*: fractional logit (Papke–Wooldridge), one equation per outcome, HC3 errors; coefficients are log-odds differences, converted into predicted shares at the means of the controls. *Reading*: conditional differences in means, not effects. A7(a) and (b) are the same comparison without controls.

## External data (section B)
- **Tax revenue (% of GDP)**: from the IMF World Revenue Longitudinal Database (WoRLD), mean of 2022–2024 for each country.
- **PEFA PI-6** (2016 framework): how much central-government revenue and spending sits outside the financial reports. PI-6.2 scores revenue outside financial reports; PI-6.3 scores the financial reports of extrabudgetary units. Grades run from A (best) to D; we code A = 4, B = 3, C = 2, D = 1. D* means D for lack of information; NR means not rated (missing). We use each country's latest assessment and report its year.
- **Spearman ρ**: a rank correlation between −1 and 1. It uses only the ordering of countries, so it suits ordinal grades and is not driven by one extreme value. With about 30 to 43 countries, a ρ below about 0.3 in absolute value is hard to tell from zero.
- **Leave-one-out range**: ρ recomputed 43 times (or 31), each time without one country; a wide range means a few countries drive the result.
- **Reading**: associations, not effects. Causality can run both ways, and legal tradition, resource wealth and corpus completeness move with every institutional variable.
