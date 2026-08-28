# Codex Prompt: Descriptive Figures

Read `AGENTS.md` and the methodology before coding.

Create and execute:

```text
analysis/Code/04_descriptive_figures.Rmd
```

Use:

```text
data/derived/SSA_CENSUS.csv
data/derived/SSA_EARMARK_ALLOCATIONS.csv
data/derived/SSA_EARMARK_ALLOCATIONS_EXPANDED.csv
analysis/tables/01_country_corpus_coverage.csv
analysis/tables/02_country_summary.csv
data/COFOG_GFSM2014_mapping.csv
```

Save figures in `analysis/figures/` and the exact data displayed in each figure as a separate CSV in `analysis/tables/`, using matching filenames. Follow the graphics rules in `AGENTS.md`.

Before plotting, validate required columns and confirm that expanded `census_instrument_id` values match Census `instrument_id` within country. Stop and report major linkage problems.

## 1. Sample coverage

Create a country-level dataset containing:

```text
country
country_name
document_years
latest_document_year
corpus_type
D_census_instruments
A_allocation_source_groups
allocation_incidence_E_D
```

Use the latest Census document year as `latest_document_year`; retain all years in `document_years`.

Create:

1. **Africa inventory map:** distinguish countries in the inventory from other African countries.
2. **Horizontal coverage timeline:** country on the y-axis, latest legal-source year on the x-axis, and `A_allocation_source_groups` as the point label.

## 2. Earmark incidence

Create a horizontal bar chart with:

```text
y = country
x = allocation_incidence_E_D
```

Sort countries by incidence and display the x-axis as percentages. Keep countries with missing incidence in the CSV but exclude them from the plot.

## 3. Sector bearing the charge

Join `SSA_EARMARK_ALLOCATIONS_EXPANDED` to `SSA_CENSUS` using:

```text
country
census_instrument_id = instrument_id
```

Use distinct valid linked Census instruments:

```text
country + census_instrument_id + base_sector
```

Create:

1. **Pooled composition:** number of distinct linked Census instruments by `base_sector`.
2. **Equal-country composition:** within each country, compute the share of linked Census instruments in each `base_sector`; complete absent sectors with zero, then take the unweighted country mean.

Use horizontal bar charts.

## 4. Source-to-destination flows

Construct a long destination table from `SSA_EARMARK_ALLOCATIONS` by combining:

- `destination_function`; and
- `destination_function_detail`, split on `";"`.

Trim values and retain one row per:

```text
country + pair_id + destination_function
```

Attach the four-digit COFOG code and label, plus the division code and division name, using the mapping file. Preserve `general_budget` and `local_budget`; exclude `unallocated` from Sankey plots.

Join this table to the expanded Census links and count distinct atomic flows:

```text
country + pair_id + census_instrument_id + destination_function
```

Create two Sankey plots:

1. `base_sector → four-digit destination function`;
2. `base_sector → destination division`.

Flow width must represent the number of distinct atomic allocation links.

## 5. Destination composition

Create every plot at both:

```text
four-digit destination-function level
division level
```

Use distinct:

```text
country + pair_id + destination category
```

as one function link.

Create:

1. **Pooled composition:** horizontal bars showing the number of function links by destination.
2. **Equal-country composition:** compute destination shares within each country, complete absent categories with zero, and average equally across countries.
3. **Country composition:** 100% stacked horizontal bars showing each country’s distribution of function links.
4. **Top-two concentration:** for each country, sum the shares of its two largest destination categories and create a lollipop chart. Save the names and individual shares of the first and second categories in the CSV. Exclude `unallocated` from this measure.

For the equal-country and country-composition plots, the denominator is the total number of distinct pair–function links in that country. Therefore, shares sum to 100% within country.

## Output naming

Use descriptive matching names, for example:

```text
04_africa_inventory_map.png
04_africa_inventory_map.csv

04_earmark_incidence.png
04_earmark_incidence.csv

04_destination_pooled_cofog4.png
04_destination_pooled_cofog4.csv
```

Do not create additional statistics or plots. Finish with a concise report of files created, countries included, missing values, unmapped function codes, and linkage problems.