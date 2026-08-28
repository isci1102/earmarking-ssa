# AGENTS.md

## Project

Statistical analysis of revenue instruments and statutory earmarking in Sub-Saharan Africa for an International Monetary Fund research project. The datasets were built from primary legal texts and describe the **de jure** system; they do not measure actual collections, transfers, disbursements, or expenditure execution.

The full methodology and variable definitions are in the project methodology, annexes, and data dictionaries. Read the relevant files before writing code and re-check them whenever a variable's meaning or table grain matters. Those documents take precedence over this file.

## Data

Country folders are expected to contain two types of Excel tables:

- `COUNTRY_DOCIDYEAR_CENSUS.xlsx` — revenue instruments in the selected legal corpus; the potential universe or denominator. This is in countries/COUNTRY_ISO/outputs/extract/
- `COUNTRY_DOCIDYEAR_EARMARK_ALLOCATIONS.xlsx` — canonical statutory allocation channels; the allocation layer or potential numerator source. This is in countries/COUNTRY_ISO/outputs/allocations/

Country files are expected to follow a common schema. Validate this before stacking and report missing, additional, duplicated, or incompatible columns; do not silently coerce files into conformity.

Text fields may be French or English and may contain accents. Preserve text exactly as stored.

## Work plan

### Step 1 — Pooled datasets

Stack all country files into one pooled dataset per table, retaining only the columns specified for the task.

Before analysis, run and report checks for:

- files discovered, loaded, skipped, or failed;
- expected and unexpected columns;
- key uniqueness and duplicate rows;
- unexpected category values;
- document-year ranges;
- missing values by column; and
- row and relevant-key counts by country.

Then produce the requested basic counts and descriptive statistics.

### Step 2 — Statistical analysis

Organize each analytical step in its own `.Rmd` notebook unless instructed otherwise. Analytical definitions are task-specific and will be provided during the analysis.

## Standing rules

- **Never assume one row equals one tax or one analytical observation.** The counting unit may be a key such as `instrument_id`, `census_ref`, or `pair_id`. I will specify the grain and variables for each computation. If the grain is not stated or the documentation is ambiguous, ask rather than guess.

- **Do not hard-code analytical choices.** Do not fix filters, category groupings, denominator definitions, counting units, missing-value treatment, or inclusion rules unless they are specified for the current task.

- **Do not invent data.** Never impute, fabricate, or silently fill source values. Preserve null values as information.

- **Preserve source variables.** Derived variables may be created only when requested or necessary for a stated computation. Give them new names, document their construction, and keep the original fields unchanged.

- **Never silently drop observations.** For each filter, report the condition applied and the row count and relevant-key count before and after filtering.

- Do not modify the source Excel files.

## Code style

- Use R in `.Rmd` notebooks.
- Use one analytical result per section. Where applicable, use separate chunks for:
  1. preparation and computation;
  2. printing the resulting table; and
  3. constructing and displaying the plot.
- Prefer simple, readable `dplyr` code with `%>%`, clear object names, and transparent intermediate objects.
- Avoid large loops, deeply nested helper functions, and premature abstraction.
- Comment analytical choices and non-obvious transformations, not basic syntax.
- Save figures in `figures/` with descriptive filenames.


## Graphics

- Use dark, muted, publication-style colors.
- For single-series plots, use a dark blue as the default main color.
- For maps, use dark blue for focal/covered countries and a light blue-grey for background countries.
- For multi-category plots, use distinct but muted colors that are easy to distinguish.
- Avoid bright, flashy, or pastel palettes.
- Titles and subtitles should emphasize the substantive economic meaning, not internal coding or processing terminology.
- Avoid variable names or technical labels such as `level-1`, `share_level`, or dataset names in chart titles.