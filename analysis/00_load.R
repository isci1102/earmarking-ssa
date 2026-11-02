## ============================================================================
## 00_load.R — read the frozen stacked table, set factor orders, add top_level and the set flags,
## join the country groups, save the analysis .rds
## ANALYSIS_SPEC §0 and §6; variables in DERIVED_TABLE_SPEC §2–§3; enum levels from
## prompts/EARMARK_ALLOCATION_PROMPT.md (v1.5) and prompts/INSTRUMENT_PROMPT.md (v1.0).
## Unit: one row = one instrument_id × allocation_id. Ids are unique only within a country, so every
## key includes country: (country, instrument_id) and (country, allocation_id).
## No statistics beyond the checks below. The CSV inputs are only read, never modified.
## ============================================================================

source(here::here("analysis", "paths.R"))

library(dplyr)
library(readr)


## --- Read the stacked table with explicit column types ---
## Ids and codes are character: gfs_code ("1415"), cofog_division ("704" or a non-functional value such as
## "general_budget"), cofog_group ("7042") and base_isic_division ("03") are codes and keep leading zeros.
## 0/1 fields stay integer, as the specs test them (= 1); share_value and restricted_share_total are numeric.
col_spec <- cols(
  ## keys
  country = col_character(), instrument_id = col_character(), allocation_id = col_character(),
  allocation_group_id = col_character(),
  ## from the instrument table
  official_name = col_character(), row_kind = col_character(), instrument_type = col_character(),
  gfs_code = col_character(), base_category = col_character(), base_isic_division = col_character(),
  charging_provision_in_corpus = col_integer(),
  ## group size
  is_pool = col_integer(), n_instruments_in_group = col_integer(),
  ## from the allocation table
  destination_name = col_character(), recipient_form = col_character(), recipient_level = col_character(),
  cofog_division = col_character(), cofog_group = col_character(), cofog_basis = col_character(),
  is_purpose_restricted = col_integer(), allocation_nature = col_character(), assignment_type = col_character(),
  share_value = col_double(), share_unit = col_character(), share_basis = col_character(),
  share_level = col_integer(), share_pool = col_character(), covers_whole_proceeds = col_integer(),
  determinacy = col_character(), deferred_to = col_character(), legal_rank = col_character(),
  ## derived by the build script (DERIVED_TABLE_SPEC §2.1–§2.4)
  leg_class = col_character(), earmark_class = col_character(), earmark_class_determinate = col_integer(),
  restricted_share_total = col_double(), commitment_strength = col_character(),
  benefit_link = col_character(), benefit_link_basis = col_character(),
  ## provenance
  alloc_legal_reference = col_character(), instr_legal_reference = col_character(),
  alloc_document_year = col_integer(), instr_document_year = col_integer(),
  alloc_ai_confidence = col_character(), instr_ai_confidence = col_character()
)

earmarks <- read_csv(file_stacked, col_types = col_spec, na = c("", "NA"))

## Stop if the file has other columns than the spec, or if a value did not parse (it would become NA silently)
if (!identical(names(earmarks), names(col_spec$cols))) stop("Columns of the stacked CSV differ from col_spec")
if (nrow(problems(earmarks)) > 0) stop(nrow(problems(earmarks)), " parsing problems in the stacked CSV")


## --- Checks against the build report ---
## The build script skips a country whose identities fail (DERIVED_TABLE_SPEC §1), so every country must be
## "built", and the per-country counts in the frozen CSV must be the ones the build report recorded.
build_report <- read_csv(file_build_report, na = c("", "NA"),
                         col_types = cols(folder = col_character(), country = col_character(),
                                          status = col_character(), rows = col_integer(),
                                          instruments = col_integer(), allocations = col_integer(),
                                          message = col_character()))

if (any(build_report$status != "built")) stop("Build report has countries not built: ",
                                              paste(build_report$country[build_report$status != "built"], collapse = ", "))
if (n_distinct(earmarks$country) != 43) stop("Expected 43 countries, not ", n_distinct(earmarks$country))

## Counts per country: rows, distinct instruments, distinct allocations (ids are unique within a country)
check_by_country <- earmarks %>%
  group_by(country) %>%
  summarise(rows = n(),
            instruments = n_distinct(instrument_id),
            allocations = n_distinct(allocation_id)) %>%
  full_join(build_report %>% select(country, rows_report = rows, instruments_report = instruments,
                                    allocations_report = allocations),
            by = "country") %>%
  mutate(match = rows == rows_report & instruments == instruments_report & allocations == allocations_report)

if (any(is.na(check_by_country$match) | !check_by_country$match)) {
  stop("Counts differ from the build report for: ",
       paste(check_by_country$country[is.na(check_by_country$match) | !check_by_country$match], collapse = ", "))
}

## One row per (country, instrument_id, allocation_id)
n_dup <- sum(duplicated(earmarks[, c("country", "instrument_id", "allocation_id")]))
if (n_dup > 0) stop(n_dup, " duplicated (country, instrument_id, allocation_id) keys")


## --- Factor levels ---
## Orders follow the source definitions, so tables and figures list categories the same way everywhere.
levels_list <- list(
  ## E-class (DERIVED_TABLE_SPEC §2.2): exclusive, partial, assigned unrestricted; E4 and E0 (in neither set) last
  earmark_class = c("E3", "E2", "E1", "E4", "E0"),
  ## benefit link: the test order of DERIVED_TABLE_SPEC §2.4 (first match wins), then not_applicable
  benefit_link = c("corrective", "compensatory", "benefit", "sectoral", "general_revenue", "unlinked",
                   "not_applicable"),
  ## commitment (DERIVED_TABLE_SPEC §2.3): ordered, so that the instrument maximum can be taken with max()
  commitment_strength = c("none", "soft", "firm", "hard"),
  ## leg_class: rule order of DERIVED_TABLE_SPEC §2.1
  leg_class = c("general_budget", "refund_reserve", "cost_recovery", "staff_payment", "restricted",
                "unrestricted"),
  ## recipient_form: precedence order of allocation prompt §4.2 (first match decides)
  recipient_form = c("staff_personal_payment", "foreign_government", "supranational_body",
                     "subnational_government", "social_security_institution", "special_account", "fund",
                     "ministry_or_vote", "agency", "non_government_body", "program_or_purpose",
                     "general_budget"),
  ## allocation prompt §4.2, §4.3, §4.5, §4.6 (order as listed there)
  recipient_level = c("central", "subnational", "external", "non_government"),
  allocation_nature = c("proceeds_share", "cost_recovery", "refund_reserve"),
  assignment_type = c("earmark_functional", "hybrid_devolved_earmark", "equalization_transfer",
                      "derivation_transfer", "tax_sharing_general", "tax_sharing_specific",
                      "community_levy_external"),
  share_basis = c("stated", "whole_proceeds_implied", "residual", "schedule", "deferred", "cross_reference",
                  "statutory_maximum", "statutory_minimum", "unstated"),
  determinacy = c("determinate", "share_deferred", "share_bounded", "share_unstated", "destination_deferred"),
  deferred_to = c("regulation", "finance_law", "minister_or_executive", "agreement", "other"),
  legal_rank = c("constitution", "organic_law", "ordinary_law", "finance_law", "regulation", "other"),
  ## instrument prompt §4.1 / §5, §4.4 and §4.5 (broad bases first, then specific bases, as listed)
  row_kind = c("instrument", "class_placeholder"),
  instrument_type = c("income_profits_tax", "payroll_tax", "property_tax", "general_consumption_tax", "excise",
                      "specific_services_tax", "use_permission_tax", "other_goods_services_tax", "trade_tax",
                      "other_tax", "social_contribution", "resource_rent", "administrative_fee",
                      "sales_user_charge", "fine_penalty", "other_nontax", "mixed_class"),
  base_category = c("general_income", "general_consumption", "general_trade", "general_revenue_class",
                    "payroll_employment", "property_land", "financial_insurance", "harmful_consumption",
                    "fuel_energy", "motor_vehicles_road", "air_maritime_rail_transport", "telecom_ict_postal",
                    "media_advertising", "extractive_resources", "forestry_wildlife_fisheries",
                    "agricultural_commodities", "water", "pollution_waste_environment", "gambling_lotteries",
                    "tourism_hospitality", "construction_urban", "health_education_services",
                    "public_administrative_acts", "regulated_activities_professions", "persons",
                    "other_specific")
)

## Stop if a column has a value outside its levels (NA is checked separately below)
check_levels <- function(x, levels, name) {
  bad <- setdiff(unique(x[!is.na(x)]), levels)
  if (length(bad) > 0) stop(name, ": values outside the expected levels: ", paste(bad, collapse = ", "))
}

for (v in names(levels_list)) {
  check_levels(earmarks[[v]], levels_list[[v]], v)
  earmarks[[v]] <- factor(earmarks[[v]], levels = levels_list[[v]], ordered = (v == "commitment_strength"))
}

## NA only where the specs allow a null
nullable <- c("assignment_type", "deferred_to", "benefit_link")
for (v in setdiff(names(levels_list), nullable)) {
  if (any(is.na(earmarks[[v]]))) stop(v, ": ", sum(is.na(earmarks[[v]])), " missing values; the spec allows none")
}
## assignment_type: null only on general_budget legs (allocation prompt §5, field 16)
if (any(is.na(earmarks$assignment_type) & earmarks$recipient_form != "general_budget")) {
  stop("assignment_type missing on a leg that is not general_budget")
}
## deferred_to: filled exactly when the share or the destination is deferred (allocation prompt §4.6)
is_deferred <- earmarks$determinacy %in% c("share_deferred", "destination_deferred")
if (any(is.na(earmarks$deferred_to) == is_deferred)) stop("deferred_to does not match determinacy")
## benefit_link: null exactly on restricted legs with cofog_division = unallocated (DERIVED_TABLE_SPEC §2.4, step 2)
if (any(is.na(earmarks$benefit_link) != (earmarks$benefit_link_basis %in% "function_unallocated"))) {
  stop("benefit_link missing on rows other than benefit_link_basis = function_unallocated")
}

## The E-class is a property of the instrument (DERIVED_TABLE_SPEC §2.2), repeated on each of its rows
n_eclass <- earmarks %>%
  group_by(country, instrument_id) %>%
  summarise(n = n_distinct(earmark_class), .groups = "drop")
if (any(n_eclass$n > 1)) stop(sum(n_eclass$n > 1), " instruments with more than one earmark_class")


## --- Base groups: the A2 grouping (ANALYSIS_SPEC §2) ---
## base_category records what is taxed; the 26 categories are grouped into 12 rows for the A2a heatmap, the
## A2c Sankeys and A7. Factor order as listed in the spec. harmful_consumption keeps its own row although small,
## because it is the corrective case readers look for.
base_groups <- list(
  broad_bases                    = c("general_income", "general_consumption", "general_trade", "general_revenue_class"),
  extractive                     = c("extractive_resources"),
  fuel_energy                    = c("fuel_energy"),
  forestry_fisheries_agriculture = c("forestry_wildlife_fisheries", "agricultural_commodities"),
  environment_water              = c("pollution_waste_environment", "water"),
  telecom_media                  = c("telecom_ict_postal", "media_advertising"),
  transport                      = c("motor_vehicles_road", "air_maritime_rail_transport"),
  financial_insurance            = c("financial_insurance"),
  harmful_consumption            = c("harmful_consumption"),
  gambling_tourism               = c("gambling_lotteries", "tourism_hospitality"),
  payroll_property               = c("payroll_employment", "property_land", "construction_urban"),
  services_acts_other            = c("health_education_services", "regulated_activities_professions",
                                     "public_administrative_acts", "persons", "other_specific")
)

## Every base_category level in exactly one group
if (any(duplicated(unlist(base_groups)))) stop("base_groups: a base_category is in two groups")
check_levels(unlist(base_groups), levels_list$base_category, "base_groups")
missing_categories <- setdiff(levels_list$base_category, unlist(base_groups))
if (length(missing_categories) > 0) stop("base_groups: categories without a group: ", paste(missing_categories, collapse = ", "))

earmarks$base_group <- NA_character_
for (g in names(base_groups)) {
  earmarks$base_group[earmarks$base_category %in% base_groups[[g]]] <- g
}
earmarks$base_group <- factor(earmarks$base_group, levels = names(base_groups))
if (any(is.na(earmarks$base_group))) stop(sum(is.na(earmarks$base_group)), " rows without a base_group")


## --- Legal references: "a; b" cells into list-columns ---
## The governing (latest) text comes first, amended texts after "; " (allocation prompt §4.7, instrument
## prompt §4.6). Only these two columns are split; the original strings are kept. instr_legal_reference is
## null when the charging provision is not in the corpus; its list element is then NA.
earmarks <- earmarks %>%
  mutate(alloc_legal_reference_list = strsplit(alloc_legal_reference, "; ", fixed = TRUE),
         instr_legal_reference_list = strsplit(instr_legal_reference, "; ", fixed = TRUE))


## --- top_level (ANALYSIS_SPEC §0, share levels) ---
## 1 on the allocations at the shallowest share_level of their group: level 1, or the shallowest level present
## for the few groups with no level-1 row. Main statistics use top_level = 1 rows only: level 1 says where the
## gross proceeds go, and mixing levels counts the same money twice. Per country × group, because group ids
## repeat across countries.
earmarks <- earmarks %>%
  group_by(country, allocation_group_id) %>%
  mutate(top_level = as.integer(share_level == min(share_level))) %>%
  ungroup()

## Every instrument must keep at least one row in the main statistics
n_top <- earmarks %>%
  group_by(country, instrument_id) %>%
  summarise(n = sum(top_level), .groups = "drop")
if (any(n_top$n == 0)) stop(sum(n_top$n == 0), " instruments without a top_level = 1 row")


## --- Set flags (ANALYSIS_SPEC §0) ---
## earmarked = E2 + E3 (main set); assigned = E1 + E2 + E3 (secondary set). E4 and E0 are in neither.
## Social contributions are flagged, not dropped: the headline results exclude them and a robustness check
## includes them, so the later scripts combine the flags as needed.
earmarks <- earmarks %>%
  mutate(earmarked           = earmark_class %in% c("E2", "E3"),
         assigned            = earmark_class %in% c("E1", "E2", "E3"),
         social_contribution = instrument_type == "social_contribution")


## --- Country groups (ANALYSIS_SPEC §0, signed off 2 Nov 2026) ---
country_groups <- read_csv(file_country_groups, na = c("", "NA"),
                           col_types = cols(iso3 = col_character(), legal_family = col_character(),
                                            cfa_zone = col_character(), design_group = col_character(),
                                            rec = col_character(), rec_all = col_character(),
                                            resource_rich = col_integer(), resource_group = col_character(),
                                            notes = col_character()))
if (nrow(problems(country_groups)) > 0) stop("Parsing problems in country_groups.csv")

## One row per country, otherwise the join would duplicate rows
if (any(duplicated(country_groups$iso3))) stop("Duplicated iso3 in country_groups.csv")

## design_group is derived from legal_family × cfa_zone: it separates legal tradition from CFA harmonisation.
## Any combination outside the rule gives NA, which fails the check.
design_rule <- with(country_groups, case_when(
  legal_family == "francophone_civil" & cfa_zone == "UEMOA"             ~ "uemoa_francophone",
  legal_family == "francophone_civil" & cfa_zone == "CEMAC"             ~ "cemac_francophone",
  legal_family == "francophone_civil" & cfa_zone == "none"              ~ "francophone_noncfa",
  legal_family == "anglophone_common" & cfa_zone == "none"              ~ "anglophone_common",
  legal_family == "lusophone_civil"   & cfa_zone == "none"              ~ "lusophone_noncfa",
  legal_family != "francophone_civil" & cfa_zone %in% c("UEMOA", "CEMAC") ~ "cfa_nonfrancophone",
  legal_family == "mixed"             & cfa_zone == "none"              ~ "mixed"
))
bad_design <- is.na(design_rule) | design_rule != country_groups$design_group
if (any(bad_design)) stop("design_group does not follow the legal_family × cfa_zone rule for: ",
                          paste(country_groups$iso3[bad_design], collapse = ", "))

## Factor orders as listed in ANALYSIS_SPEC §0; rec in the order of the primary-community rule
group_levels <- list(
  legal_family   = c("francophone_civil", "anglophone_common", "lusophone_civil", "hispanophone_civil", "mixed"),
  cfa_zone       = c("UEMOA", "CEMAC", "none"),
  rec            = c("ECOWAS", "EAC", "SACU", "SADC", "ECCAS", "COMESA", "AES"),
  resource_group = c("oil_exporter", "other_resource_intensive", "non_resource_intensive"),
  design_group   = c("uemoa_francophone", "cemac_francophone", "francophone_noncfa", "anglophone_common",
                     "lusophone_noncfa", "cfa_nonfrancophone", "mixed")
)
for (v in names(group_levels)) {
  check_levels(country_groups[[v]], group_levels[[v]], v)
  if (any(is.na(country_groups[[v]]))) stop(v, ": missing values in country_groups.csv")
  country_groups[[v]] <- factor(country_groups[[v]], levels = group_levels[[v]])
}

## rec_all ("a; b", all memberships) as a list-column, original string kept.
## notes (the reason for each debatable call) stays in the CSV and is not joined.
country_groups <- country_groups %>%
  mutate(rec_all_list = strsplit(rec_all, "; ", fixed = TRUE)) %>%
  select(-notes)

## Join on country = iso3: every country of the data must find its row, and no row may be added
n_before <- nrow(earmarks)
unmatched <- setdiff(unique(earmarks$country), country_groups$iso3)
if (length(unmatched) > 0) stop("Countries without a country_groups row: ", paste(unmatched, collapse = ", "))
earmarks <- earmarks %>%
  left_join(country_groups, by = c("country" = "iso3"))
if (nrow(earmarks) != n_before) stop("Join with country_groups changed the number of rows")


## --- Summaries ---
## Instrument level: one row per (country, instrument_id). row_kind, instrument_type and earmark_class are
## instrument properties, so distinct() must return exactly one row per instrument.
instruments <- earmarks %>%
  distinct(country, instrument_id, row_kind, instrument_type, earmark_class, base_group,
           earmarked, assigned, social_contribution)
if (nrow(instruments) != sum(check_by_country$instruments)) {
  stop("row_kind, instrument_type, earmark_class or base_group varies within an instrument")
}
base_group_counts <- table(instruments$base_group)

n_rows        <- nrow(earmarks)
n_instruments <- nrow(instruments)
n_allocations <- nrow(distinct(earmarks, country, allocation_id))
eclass_counts <- table(instruments$earmark_class)
n_placeholder <- sum(instruments$row_kind == "class_placeholder")
n_social      <- sum(instruments$social_contribution)
n_earmarked   <- sum(instruments$earmarked)
n_earmarked_x <- sum(instruments$earmarked & !instruments$social_contribution)
n_assigned    <- sum(instruments$assigned)
n_assigned_x  <- sum(instruments$assigned & !instruments$social_contribution)
n_top_rows    <- sum(earmarks$top_level == 1)
n_groups_no_l1 <- earmarks %>%
  distinct(country, allocation_group_id, share_level) %>%
  group_by(country, allocation_group_id) %>%
  summarise(no_level1 = !any(share_level == 1), .groups = "drop") %>%
  pull(no_level1) %>% sum()
countries_by_design <- earmarks %>%
  distinct(country, design_group) %>%
  count(design_group, .drop = FALSE)

cat("Rows:", n_rows, " | instruments:", n_instruments, " | allocations:", n_allocations,
    " | countries:", n_distinct(earmarks$country), "\n")
cat("E-class (instruments):", paste(names(eclass_counts), eclass_counts, sep = " ", collapse = " | "), "\n")
cat("Base groups (instruments):", paste(names(base_group_counts), base_group_counts, sep = " ", collapse = " | "), "\n")
cat("Class placeholders (instruments):", n_placeholder, "\n")
cat("Social contributions (instruments):", n_social, "\n")
cat("Earmarked E2+E3 (instruments): with social contributions", n_earmarked, " | without", n_earmarked_x, "\n")
cat("Assigned E1+E2+E3 (instruments): with social contributions", n_assigned, " | without", n_assigned_x, "\n")
cat("top_level = 1 rows:", n_top_rows, "of", n_rows, " | groups with no level-1 row:", n_groups_no_l1, "\n")
cat("Countries per design_group:",
    paste(countries_by_design$design_group, countries_by_design$n, sep = " ", collapse = " | "), "\n")


## --- Write the check tables and save the analysis file ---
## The summary table repeats the cat() lines, with the unit of each count
load_summary <- bind_rows(
  data.frame(item = c("rows", "instruments", "allocations", "countries"),
             unit = c("row (instrument x allocation)", "instrument", "allocation", "country"),
             n = c(n_rows, n_instruments, n_allocations, n_distinct(earmarks$country))),
  data.frame(item = paste("earmark_class", names(eclass_counts)), unit = "instrument",
             n = as.integer(eclass_counts)),
  data.frame(item = c("class_placeholder", "social_contribution",
                      "earmarked (E2+E3), with social contributions", "earmarked (E2+E3), without social contributions",
                      "assigned (E1+E2+E3), with social contributions", "assigned (E1+E2+E3), without social contributions"),
             unit = "instrument",
             n = c(n_placeholder, n_social, n_earmarked, n_earmarked_x, n_assigned, n_assigned_x)),
  data.frame(item = c("top_level = 1", "groups with no level-1 row"),
             unit = c("row (instrument x allocation)", "allocation group"),
             n = c(n_top_rows, n_groups_no_l1)),
  data.frame(item = paste("design_group", countries_by_design$design_group), unit = "country",
             n = countries_by_design$n)
)

write.csv(check_by_country, file.path(dir_tables, "00_load_check_by_country.csv"), row.names = FALSE)
write.csv(load_summary, file.path(dir_tables, "00_load_summary.csv"), row.names = FALSE)

saveRDS(earmarks, file_analysis_rds)
cat("Saved:", file_analysis_rds, "\n")
