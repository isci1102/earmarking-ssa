## ============================================================================
## 01_descriptives.R — D1 (Table 1, the database at a glance) and D2 (Appendix Table A1, one row per country)
## ANALYSIS_SPEC §0 and §1; vehicle definitions in ANALYSIS_SPEC §2; benefit-link test order in
## DERIVED_TABLE_SPEC §2.4.
## Inputs: the analysis .rds (00_load.R), 00_load_summary.csv (for the checks), and the "documents" list of each
## countries/{ISO3}/outputs/allocations/{ISO3}_EARMARK_ALLOCATIONS.json (read only).
## Outputs: ssa_earmarks_documents_prelim_2026-11.rds (one row per country × document); 01_table1.csv,
## 01_tableA1.csv and 01_tableA1_columns.csv (unit and definition of each A1 column) in dir_tables.
## Both tables use top_level = 1 rows (ANALYSIS_SPEC §0). Two exceptions, stated where they are coded: the Table 1
## line on allocations below the top level, and the restricted legs read by the instrument-level indicators of A1.
## ============================================================================

source(here::here("analysis", "paths.R"))

library(dplyr)
library(jsonlite)

earmarks <- readRDS(file_analysis_rds)

file_load_summary <- file.path(dir_tables, "00_load_summary.csv")
if (!file.exists(file_load_summary)) stop("Run 00_load.R first: ", file_load_summary, " not found")
load_summary <- read.csv(file_load_summary)

## One count of 00_load_summary.csv, by its item name
summary_n <- function(item_name) {
  n <- load_summary$n[load_summary$item == item_name]
  if (length(n) != 1) stop("00_load_summary.csv: no single row for ", item_name)
  n
}

## Stop if a share is missing or outside [0, 1]
check_share <- function(x, name) {
  if (any(is.na(x) | x < 0 | x > 1)) stop(name, ": share missing or outside [0, 1]")
}


## --- Documents (one row per country × document) ---
## The allocation JSON lists every file of the corpus given to the extraction, with status "read" or "failed"
## (wrong document, web-page asset). Documents read = status "read", whether or not the file produced a row.
alloc_files <- Sys.glob(file.path(dir_countries, "*", "outputs", "allocations", "*_EARMARK_ALLOCATIONS.json"))

documents <- data.frame()
for (f in alloc_files) {
  folder <- basename(dirname(dirname(dirname(f))))
  alloc_json <- fromJSON(f, simplifyDataFrame = TRUE)
  if (!identical(alloc_json$country, folder)) stop(f, ": country ", alloc_json$country, " differs from its folder")
  docs <- alloc_json$documents
  if (is.null(docs) || length(docs) == 0) next   # caught by the check below if the country is in the .rds
  if (!all(c("file", "year", "status", "reason") %in% names(docs))) stop(f, ": documents list without file, year, status or reason")
  documents <- bind_rows(documents,
                         data.frame(country = folder, file = docs$file, year = as.integer(docs$year),
                                    status = docs$status, reason = as.character(docs$reason)))
}

no_documents <- setdiff(unique(earmarks$country), documents$country)
if (length(no_documents) > 0) stop("Countries of the .rds without a documents list: ", paste(no_documents, collapse = ", "))
if (any(!documents$status %in% c("read", "failed"))) stop("Document status other than read / failed")
if (any(duplicated(documents[, c("country", "file")]))) stop("Duplicated (country, file) in the documents lists")

saveRDS(documents, file_documents_rds)

documents_read <- documents %>%
  filter(country %in% earmarks$country) %>%
  group_by(country) %>%
  summarise(documents_read = sum(status == "read"),
            documents_failed = sum(status == "failed"))


## --- Top-level rows, and the instrument and allocation tables ---
## ANALYSIS_SPEC §0: level 1 (or the shallowest level of a group) says where the gross proceeds go; deeper levels
## subdivide a share and would count the same allocation chain twice.
top <- earmarks %>% filter(top_level == 1)

## Instrument level: one row per (country, instrument_id). Every instrument has a top-level row (00_load.R), so
## the top-level instrument table holds every instrument.
instruments <- top %>%
  distinct(country, instrument_id, row_kind, earmark_class, earmarked, social_contribution, instr_ai_confidence)
if (nrow(instruments) != nrow(distinct(earmarks, country, instrument_id))) {
  stop("Instrument attributes vary within an instrument, or an instrument has no top-level row")
}

## Allocation level: one row per (country, allocation_id). An allocation is either top-level or not (share_level
## is an allocation field), so allocations split cleanly into top-level and sub-level ones.
allocations_top <- top %>%
  distinct(country, allocation_id, allocation_group_id, leg_class, cofog_division,
           alloc_ai_confidence, alloc_document_year)
if (nrow(allocations_top) != nrow(distinct(top, country, allocation_id))) stop("Allocation attributes vary within an allocation")

allocations_sub <- earmarks %>%
  filter(top_level == 0) %>%
  distinct(country, allocation_id)
if (nrow(semi_join(allocations_sub, allocations_top, by = c("country", "allocation_id"))) > 0) {
  stop("Some allocations have both top-level and sub-level rows")
}


## --- Per-country counts (top level) ---
## Unique destinations: distinct (country, destination_name), exact strings, so spelling variants of one
## destination count twice. Names repeat across countries ("Treasury"), hence the country in the key.
by_country <- top %>%
  group_by(country) %>%
  summarise(instruments  = n_distinct(instrument_id),
            groups       = n_distinct(allocation_group_id),
            allocations  = n_distinct(allocation_id),
            destinations = n_distinct(destination_name))


## --- Table 1 (D1) ---
## One line per statistic. value = total count, or pooled share. The country_* columns describe the distribution
## of the per-country counts over the 43 countries (unit: country); they are filled only for those counts.
table1_line <- function(item, unit, value, per_country = NULL) {
  data.frame(item = item, unit = unit, value = value,
             country_mean   = if (is.null(per_country)) NA else mean(per_country),
             country_median = if (is.null(per_country)) NA else median(per_country),
             country_min    = if (is.null(per_country)) NA else min(per_country),
             country_max    = if (is.null(per_country)) NA else max(per_country))
}

## Instruments by E-class and row_kind. Table 1 describes the database, so social contributions are included
## here and reported on their own line.
eclass_rowkind <- instruments %>% count(earmark_class, row_kind, .drop = FALSE)
eclass_counts  <- instruments %>% count(earmark_class, .drop = FALSE)
rowkind_counts <- instruments %>% count(row_kind, .drop = FALSE)

## Restricted allocations at the top level: the denominator of the unallocated share
restricted_top <- allocations_top %>% filter(leg_class == "restricted")

table1 <- bind_rows(
  table1_line("countries", "country", n_distinct(top$country)),
  table1_line("documents read", "document (status read in the allocation JSON)",
              sum(documents_read$documents_read), documents_read$documents_read),
  table1_line("instruments", "instrument (and class of charges)", nrow(instruments), by_country$instruments),
  table1_line("allocation groups", "allocation group", sum(by_country$groups), by_country$groups),
  table1_line("allocations (top level)", "allocation", nrow(allocations_top), by_country$allocations),
  table1_line("unique destinations (top level)", "country x destination_name (exact string)",
              sum(by_country$destinations), by_country$destinations),
  table1_line("allocations below the top level", "allocation", nrow(allocations_sub)),
  table1_line(paste("earmark_class", eclass_counts$earmark_class), "instrument", eclass_counts$n),
  table1_line(paste("row_kind", rowkind_counts$row_kind), "instrument", rowkind_counts$n),
  table1_line(paste("earmark_class", eclass_rowkind$earmark_class, "x row_kind", eclass_rowkind$row_kind),
              "instrument", eclass_rowkind$n),
  table1_line("social contributions", "instrument", sum(instruments$social_contribution)),
  table1_line("share with alloc_ai_confidence not high", "share of allocations (top level), pooled",
              mean(allocations_top$alloc_ai_confidence != "high")),
  table1_line("share with instr_ai_confidence not high", "share of instruments, pooled",
              mean(instruments$instr_ai_confidence != "high")),
  table1_line("restricted allocations (top level)", "allocation", nrow(restricted_top)),
  table1_line("share of restricted allocations with cofog_division = unallocated",
              "share of restricted allocations (top level), pooled",
              mean(restricted_top$cofog_division == "unallocated"))
)

## Checks against 00_load_summary.csv. It has no group count, so groups are checked against the full .rds:
## the top-level filter must keep every group.
if (nrow(instruments) != summary_n("instruments")) stop("Instruments differ from 00_load_summary.csv")
if (sum(by_country$groups) != nrow(distinct(earmarks, country, allocation_group_id))) stop("Groups lost at the top level")
for (k in levels(earmarks$earmark_class)) {
  if (eclass_counts$n[eclass_counts$earmark_class == k] != summary_n(paste("earmark_class", k))) {
    stop("earmark_class ", k, " differs from 00_load_summary.csv")
  }
}
if (sum(eclass_rowkind$n) != nrow(instruments)) stop("E-class x row_kind cells do not sum to the instruments")
if (rowkind_counts$n[rowkind_counts$row_kind == "class_placeholder"] != summary_n("class_placeholder")) {
  stop("Class placeholders differ from 00_load_summary.csv")
}
if (sum(instruments$social_contribution) != summary_n("social_contribution")) stop("Social contributions differ from 00_load_summary.csv")
if (nrow(allocations_top) + nrow(allocations_sub) != summary_n("allocations")) {
  stop("Top-level plus sub-level allocations differ from the allocations of 00_load_summary.csv")
}
check_share(table1$value[grepl("^share", table1$item)], "Table 1")


## --- Table A1 (D2): counts per country ---
## Instrument counts include social contributions, so the E-class counts sum to the instrument count; social
## contributions get their own column. The class-placeholder share is over all instruments of the country.
## n_earmarked = E2 + E3 without social contributions: the denominator of every A1 share (ANALYSIS_SPEC §0).
a1_counts <- instruments %>%
  group_by(country) %>%
  summarise(E3 = sum(earmark_class == "E3"),
            E2 = sum(earmark_class == "E2"),
            E1 = sum(earmark_class == "E1"),
            E4 = sum(earmark_class == "E4"),
            E0 = sum(earmark_class == "E0"),
            social_contributions = sum(social_contribution),
            placeholder_share = mean(row_kind == "class_placeholder"),
            n_earmarked = sum(earmarked & !social_contribution),
            ## exclusive share = E3 / earmarked, both without social contributions
            exclusive_share = sum(earmark_class == "E3" & !social_contribution) / n_earmarked)

## Legal snapshot year (ANALYSIS_SPEC §0), from the rows, not from the documents lists.
## law_year_max: latest of alloc_document_year and instr_document_year over the country's top-level rows.
## law_year_median: median alloc_document_year over the country's distinct top-level allocations.
law_year_max <- top %>%
  group_by(country) %>%
  summarise(law_year_max = max(alloc_document_year, instr_document_year))
law_year_median <- allocations_top %>%
  group_by(country) %>%
  summarise(law_year_median = median(alloc_document_year))


## --- Table A1: instrument-level indicators of earmarked instruments ---
## Restricted legs read by the indicators (decision of 2 Nov 2026): for each earmarked instrument (no social
## contributions), its restricted legs at the shallowest level where it has a restricted leg.
## - An instrument with a top-level restricted leg keeps its top-level restricted legs, so nothing changes for it.
##   The rule is written on top_level, not on share_level: an instrument can also sit in a group with no
##   level-1 row, whose top level is level 2, and a minimum over share_level would drop those top-level legs.
## - The few E2 instruments whose restricted legs all sit below the top level (the E-class reads every level)
##   keep their restricted legs at the shallowest share_level; otherwise they would stay in n_earmarked and
##   count as "no" on every indicator. Their number is reported in n_earmarked_no_top_restricted.
indicator_legs <- earmarks %>%
  filter(earmarked, !social_contribution, leg_class == "restricted") %>%
  group_by(country, instrument_id) %>%
  mutate(no_top_restricted = !any(top_level == 1)) %>%
  filter(if (first(no_top_restricted)) share_level == min(share_level) else top_level == 1) %>%
  ungroup()

## Instruments with a top-level restricted leg where a minimum over share_level would have given other legs
n_top_level_2 <- earmarks %>%
  filter(earmarked, !social_contribution, leg_class == "restricted") %>%
  group_by(country, instrument_id) %>%
  summarise(differs = any(top_level == 1) & any(top_level == 1 & share_level > min(share_level)), .groups = "drop") %>%
  pull(differs) %>% sum()

## Fund-or-agency vehicles (ANALYSIS_SPEC §2): legal forms as written, not budget status.
## Commitment: the instrument maximum over the selected restricted legs (none < soft < firm < hard).
vehicle_fund_agency <- c("fund", "agency", "social_security_institution", "non_government_body")
instrument_indicators <- indicator_legs %>%
  group_by(country, instrument_id) %>%
  summarise(no_top_restricted = first(no_top_restricted),
            fund_agency = any(recipient_form %in% vehicle_fund_agency),
            commitment_max = max(commitment_strength),
            .groups = "drop")
if (nrow(instrument_indicators) != sum(a1_counts$n_earmarked)) stop("Some earmarked instruments have no restricted leg")

a1_instrument_shares <- instrument_indicators %>%
  group_by(country) %>%
  summarise(n_earmarked_no_top_restricted = sum(no_top_restricted),
            fund_agency_share = mean(fund_agency),
            hard_commitment_share = mean(commitment_max == "hard"))

## Benefit link (DERIVED_TABLE_SPEC §3): unit = instrument × cofog_division over the selected restricted legs.
## Null benefit_link (cofog_division = unallocated: the function, and so the link, is unknown) is excluded.
## A pair with several values takes the first in the test order of DERIVED_TABLE_SPEC §2.4, which is the
## factor order set in 00_load.R.
benefit_pairs <- indicator_legs %>%
  filter(!is.na(benefit_link)) %>%
  group_by(country, instrument_id, cofog_division) %>%
  summarise(n_links = n_distinct(benefit_link),
            benefit_link = levels(benefit_link)[min(as.integer(benefit_link))],
            .groups = "drop")
n_pairs_null <- indicator_legs %>%
  group_by(country, instrument_id, cofog_division) %>%
  summarise(all_null = all(is.na(benefit_link)), .groups = "drop") %>%
  pull(all_null) %>% sum()

a1_benefit <- benefit_pairs %>%
  group_by(country) %>%
  summarise(n_benefit_pairs = n(),
            benefit_linked_share = mean(benefit_link %in% c("corrective", "compensatory", "benefit", "sectoral")))


## --- Table A1: assemble ---
country_info <- top %>% distinct(country, legal_family, cfa_zone, design_group)

table_a1 <- country_info %>%
  left_join(documents_read %>% select(country, documents_read), by = "country") %>%
  left_join(law_year_max, by = "country") %>%
  left_join(law_year_median, by = "country") %>%
  left_join(by_country %>% select(country, instruments, allocations), by = "country") %>%
  left_join(a1_counts, by = "country") %>%
  left_join(a1_instrument_shares, by = "country") %>%
  left_join(a1_benefit, by = "country") %>%
  select(country, legal_family, cfa_zone, design_group, documents_read, law_year_max, law_year_median,
         instruments, allocations, E3, E2, E1, E4, E0, social_contributions, placeholder_share,
         n_earmarked, n_earmarked_no_top_restricted, exclusive_share, fund_agency_share,
         n_benefit_pairs, benefit_linked_share, hard_commitment_share) %>%
  arrange(country)

## Unit and definition of each A1 column, written next to the table
a1_columns <- data.frame(
  column = names(table_a1),
  unit = c("country", "country", "country", "country", "document", "year", "year",
           "instrument", "allocation (top level)", rep("instrument", 6), "share of instruments",
           "instrument", "instrument", "share of earmarked instruments", "share of earmarked instruments",
           "instrument x cofog_division", "share of instrument x cofog_division pairs", "share of earmarked instruments"),
  definition = c("ISO3", "country_groups.csv", "country_groups.csv", "country_groups.csv (legal_family x cfa_zone)",
                 "documents with status read in the allocation JSON",
                 "latest alloc_document_year or instr_document_year over top-level rows",
                 "median alloc_document_year over distinct top-level allocations",
                 "all instruments, social contributions included", "distinct top-level allocations",
                 "E3, social contributions included", "E2, social contributions included",
                 "E1, social contributions included", "E4, social contributions included",
                 "E0, social contributions included", "instrument_type = social_contribution",
                 "class placeholders / instruments",
                 "earmarked (E2 + E3) without social contributions: denominator of the A1 shares",
                 "earmarked instruments whose restricted legs all sit below the top level",
                 "E3 / n_earmarked, both without social contributions",
                 "at least one restricted leg to fund, agency, social_security_institution or non_government_body",
                 "pairs of earmarked instruments' restricted legs with non-null benefit_link",
                 "pairs in corrective, compensatory, benefit or sectoral (first value in the test order)",
                 "maximum commitment_strength over restricted legs = hard")
)
if (nrow(a1_columns) != ncol(table_a1)) stop("a1_columns does not describe every A1 column")

## Checks
if (nrow(table_a1) != 43) stop("Table A1 should have 43 rows, not ", nrow(table_a1))
if (any(is.na(table_a1$documents_read) | is.na(table_a1$n_benefit_pairs))) stop("Table A1: country without documents or benefit pairs")
if (any(table_a1$E3 + table_a1$E2 + table_a1$E1 + table_a1$E4 + table_a1$E0 != table_a1$instruments)) {
  stop("Table A1: E-class counts do not sum to the instrument count")
}
for (v in c("placeholder_share", "exclusive_share", "fund_agency_share", "benefit_linked_share", "hard_commitment_share")) {
  check_share(table_a1[[v]], paste("Table A1", v))
}


## --- Summary ---
cat("Countries:", n_distinct(top$country), " | documents read:", sum(documents_read$documents_read),
    "(failed:", sum(documents_read$documents_failed), ")\n")
cat("Instruments:", nrow(instruments), " | groups:", sum(by_country$groups),
    " | allocations: top level", nrow(allocations_top), "+ below", nrow(allocations_sub),
    " | unique destinations (top level):", sum(by_country$destinations), "\n")
cat("E-class (instruments):", paste(eclass_counts$earmark_class, eclass_counts$n, sep = " ", collapse = " | "),
    " | class placeholders:", sum(instruments$row_kind == "class_placeholder"),
    " | social contributions:", sum(instruments$social_contribution), "\n")
cat("Not high confidence: allocations (top level)", round(mean(allocations_top$alloc_ai_confidence != "high"), 3),
    " | instruments", round(mean(instruments$instr_ai_confidence != "high"), 3), "\n")
cat("Restricted allocations (top level):", nrow(restricted_top), " | with cofog_division = unallocated:",
    sum(restricted_top$cofog_division == "unallocated"), "\n")
cat("Earmarked without social contributions (instruments):", sum(table_a1$n_earmarked),
    " | restricted legs only below the top level:", sum(table_a1$n_earmarked_no_top_restricted),
    " | with top-level legs at level 2 (groups with no level-1 row):", n_top_level_2, "\n")
cat("Benefit pairs (instrument x cofog_division):", nrow(benefit_pairs), " | with several links:",
    sum(benefit_pairs$n_links > 1), " | excluded, null benefit_link:", n_pairs_null, "\n")
cat("Country shares, median over 43 countries: exclusive", round(median(table_a1$exclusive_share), 3),
    " | fund-or-agency", round(median(table_a1$fund_agency_share), 3),
    " | benefit-linked", round(median(table_a1$benefit_linked_share), 3),
    " | hard commitment", round(median(table_a1$hard_commitment_share), 3), "\n")


## --- Write the tables ---
write.csv(table1, file.path(dir_tables, "01_table1.csv"), row.names = FALSE)
write.csv(table_a1, file.path(dir_tables, "01_tableA1.csv"), row.names = FALSE)
write.csv(a1_columns, file.path(dir_tables, "01_tableA1_columns.csv"), row.names = FALSE)
cat("Saved:", file_documents_rds, "\n")
