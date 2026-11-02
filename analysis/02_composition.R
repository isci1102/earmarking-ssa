## ============================================================================
## 02_composition.R — A1 (how much earmarking, and where), A2a (base group × COFOG division), A2a′ (zoom on
## 704 Economic affairs: base group × COFOG group), A2b (recipient forms), A2d (GFS instrument types) and A3
## (benefit links)
## ANALYSIS_SPEC §0 and §2; units in DERIVED_TABLE_SPEC §3; figures by docs/PLOT_STYLE.md.
## Inputs: the analysis .rds (00_load.R, with base_group), helpers.R, and 00_load_summary.csv and 01_tableA1.csv
## (for the checks).
## Three instrument sets, each written to its own tables (ANALYSIS_SPEC §0):
##   headline: earmarked (E2 + E3), social contributions excluded       -> 02_*.csv, and the figures
##   sc:       earmarked, social contributions included (robustness)   -> 02_*_sc.csv, tables only
##   nopl:     headline without class placeholders                     -> 02_*_nopl.csv, tables only
##             ("with and without placeholders" is part of the main results, §0)
## Weights: country-equal shares (within each country, then the mean over countries) are the main measure;
## pooled shares are written next to them as robustness.
## Levels: links and benefit links use the indicator legs of helpers.R (top-level restricted legs, or the
## shallowest restricted level for instruments with none at the top), the same rule as Table A1.
## Allocation-level counts and composition (A1 allocations, A2b) use top_level = 1 restricted allocations.
## Outputs: 02_A1_by_country, 02_A2a_links, 02_A2a_zoom704, 02_A2b_recipient_form, 02_A2d_instrument_type,
## 02_A3_benefit_link (one file per set) and 02_A1_by_country_columns.csv in dir_tables; 5 figures (PDF + PNG)
## in dir_figures.
## ============================================================================

source(here::here("analysis", "paths.R"))
source(here::here("analysis", "helpers.R"))        # indicator legs and instrument × division links
source(here::here("analysis", "theme_earmark.R"))  # colours, theme, save_fig()

library(dplyr)
library(tidyr)
library(ggplot2)

earmarks <- readRDS(file_analysis_rds)
if (!"base_group" %in% names(earmarks)) stop("Re-run 00_load.R: the .rds has no base_group")

file_load_summary <- file.path(dir_tables, "00_load_summary.csv")
file_table_a1     <- file.path(dir_tables, "01_tableA1.csv")
for (f in c(file_load_summary, file_table_a1)) {
  if (!file.exists(f)) stop("Run 00_load.R and 01_descriptives.R first: ", f, " not found")
}
load_summary <- read.csv(file_load_summary)
table_a1_01  <- read.csv(file_table_a1)

## Stop if a share is missing or outside [0, 1]
check_share <- function(x, name) {
  if (any(is.na(x) | x < 0 | x > 1)) stop(name, ": share missing or outside [0, 1]")
}


## --- Country-equal composition ---
## units: one row per unit (instrument, link or allocation), with its country and category columns.
## Returns one row per country × category, with zeros for the categories a country does not have (the category
## columns are factors, so complete() uses every level): n, and share = n / the country's number of units.
## The country-equal share of a category is the mean of share over countries, zeros included. Only countries
## with at least one unit enter the mean: a share is undefined for the others.
country_composition <- function(units, categories, name) {
  by_country <- units %>%
    count(country, across(all_of(categories))) %>%
    complete(country, !!!syms(categories), fill = list(n = 0L)) %>%
    group_by(country) %>%
    mutate(share = n / sum(n)) %>%
    ungroup()
  sums <- by_country %>% group_by(country) %>% summarise(total = sum(share))
  if (any(abs(sums$total - 1) > 1e-9)) stop(name, ": country shares do not sum to 1")
  by_country
}

## By category (and by group, e.g. legal_family): number of countries with at least one unit, number of
## countries in the mean, country-equal share, pooled count and pooled share (n / all units of the group).
summarise_composition <- function(by_country, categories, group = character(0)) {
  by_country %>%
    group_by(across(all_of(c(group, categories)))) %>%
    summarise(n_countries = sum(n > 0),
              countries_in_mean = n(),
              share_country_equal = mean(share),
              n = sum(n),
              .groups = "drop") %>%
    group_by(across(all_of(group))) %>%
    mutate(share_pooled = n / sum(n)) %>%
    ungroup()
}


## --- Labels for tables and figures ---
## COFOG divisions on restricted legs: 701–710, then unallocated (function unknown) last
division_levels <- c(as.character(701:710), "unallocated")
division_labels <- c("701" = "701\nGeneral\npublic\nservices", "702" = "702\nDefence",
                     "703" = "703\nPublic\norder,\nsafety", "704" = "704\nEconomic\naffairs",
                     "705" = "705\nEnviron-\nment", "706" = "706\nHousing,\ncommunity",
                     "707" = "707\nHealth", "708" = "708\nRecreation,\nculture,\nreligion",
                     "709" = "709\nEducation", "710" = "710\nSocial\nprotection",
                     "unallocated" = "Unallo-\ncated")
## COFOG groups of 704 Economic affairs (A2a′); not_coded = a 704 leg with no cofog_group, last
group_704_levels <- c(as.character(7041:7049), "not_coded")
group_704_labels <- c("7041" = "7041\nGeneral\neconomic,\nlabour", "7042" = "7042\nAgriculture,\nforestry,\nfishing",
                      "7043" = "7043\nFuel and\nenergy", "7044" = "7044\nMining,\nmanufact.,\nconstruction",
                      "7045" = "7045\nTransport", "7046" = "7046\nCommuni-\ncation",
                      "7047" = "7047\nOther\nindustries", "7048" = "7048\nR&D", "7049" = "7049\nn.e.c.",
                      "not_coded" = "Group\nnot coded")
base_group_labels <- c(broad_bases = "Broad bases", extractive = "Extractive", fuel_energy = "Fuel and energy",
                       forestry_fisheries_agriculture = "Forestry, fisheries, agriculture",
                       environment_water = "Environment and water", telecom_media = "Telecom and media",
                       transport = "Transport", financial_insurance = "Financial and insurance",
                       harmful_consumption = "Harmful consumption", gambling_tourism = "Gambling and tourism",
                       payroll_property = "Payroll and property", services_acts_other = "Services, acts, other")
family_labels <- c(francophone_civil = "Francophone civil law", anglophone_common = "Anglophone common law",
                   lusophone_civil = "Lusophone civil law", hispanophone_civil = "Hispanophone civil law",
                   mixed = "Mixed")
form_labels <- c(agency = "Agency", fund = "Fund", program_or_purpose = "Programme or purpose",
                 special_account = "Special account", non_government_body = "Non-government body",
                 social_security_institution = "Social security institution",
                 subnational_government = "Subnational government", ministry_or_vote = "Ministry or vote",
                 supranational_body = "Supranational body", foreign_government = "Foreign government")
benefit_labels <- c(corrective = "Corrective", compensatory = "Compensatory", benefit = "Benefit",
                    sectoral = "Sectoral", general_revenue = "General revenue", unlinked = "Unlinked")

## benefit_link classes of restricted legs: the test order of DERIVED_TABLE_SPEC §2.4 (not_applicable only
## occurs on legs that are not restricted)
benefit_levels <- setdiff(levels(earmarks$benefit_link), "not_applicable")

country_info <- earmarks %>% distinct(country, legal_family)


## --- Instrument sets (ANALYSIS_SPEC §0) ---
## Rows of the instruments in each set; earmarked (E2 + E3) is applied below, so the assigned set of A1 is
## read from the same rows.
sets <- list(headline = earmarks %>% filter(!social_contribution),
             sc       = earmarks,
             nopl     = earmarks %>% filter(!social_contribution, row_kind != "class_placeholder"))
set_suffix <- c(headline = "", sc = "_sc", nopl = "_nopl")
set_label  <- c(headline = "earmarked (E2+E3), social contributions excluded",
                sc       = "earmarked (E2+E3), social contributions included",
                nopl     = "earmarked (E2+E3), social contributions and class placeholders excluded")

results <- list()

for (s in names(sets)) {
  rows <- sets[[s]]

  ## Instrument level: one row per (country, instrument_id); these are instrument properties (00_load.R)
  instruments <- rows %>%
    distinct(country, instrument_id, legal_family, earmark_class, earmarked, assigned, instrument_type, base_group)
  if (nrow(instruments) != nrow(distinct(rows, country, instrument_id))) {
    stop(s, ": instrument attributes vary within an instrument")
  }

  ## Allocation level: top-level restricted allocations of the earmarked instruments of the set, one row per
  ## (country, allocation_id). A pool shared by several instruments counts once; a pool shared with an
  ## instrument outside the set (e.g. a social contribution) stays in when one of its instruments is in the set.
  allocations <- rows %>%
    filter(earmarked, top_level == 1, leg_class == "restricted") %>%
    distinct(country, allocation_id, recipient_form)
  if (any(duplicated(allocations[, c("country", "allocation_id")]))) stop(s, ": recipient_form varies within an allocation")

  ## Links: instrument × cofog_division over the indicator legs (helpers.R), with the instrument's base group.
  ## The legs are kept for the 704 zoom (A2a′), which reads their cofog_group.
  legs <- get_indicator_legs(rows)
  links <- get_link_pairs(legs) %>%
    left_join(instruments %>% select(country, instrument_id, base_group, legal_family),
              by = c("country", "instrument_id"))
  bad_division <- setdiff(unique(links$cofog_division), division_levels)
  if (length(bad_division) > 0) stop(s, ": cofog_division on restricted legs outside 701–710 / unallocated: ",
                                     paste(bad_division, collapse = ", "))
  links$cofog_division <- factor(links$cofog_division, levels = division_levels)
  if (nrow(distinct(links, country, instrument_id)) != sum(instruments$earmarked)) {
    stop(s, ": some earmarked instruments have no restricted leg")
  }
  ## A link has a null benefit_link exactly when its function is unknown (DERIVED_TABLE_SPEC §2.4, step 2)
  if (any(is.na(links$benefit_link) != (links$cofog_division == "unallocated"))) {
    stop(s, ": null benefit_link on a link other than cofog_division = unallocated")
  }


  ## --- A1: how much earmarking, and where (unit: instrument; allocations as context) ---
  ## n_earmarked = E2 + E3 of the set; E3 share = E3 / n_earmarked. Secondary: the assigned set (E1 + E2 + E3)
  ## and its E1, E2 and E3 shares. Raw counts depend on corpus completeness: context only (ANALYSIS_SPEC §0).
  a1 <- instruments %>%
    group_by(country, legal_family) %>%
    summarise(n_earmarked = sum(earmarked),
              n_E3 = sum(earmark_class == "E3"),
              E3_share = n_E3 / n_earmarked,
              n_assigned = sum(assigned),
              E1_share_of_assigned = sum(earmark_class == "E1") / n_assigned,
              E2_share_of_assigned = sum(earmark_class == "E2") / n_assigned,
              E3_share_of_assigned = n_E3 / n_assigned,
              .groups = "drop") %>%
    left_join(allocations %>% count(country, name = "n_alloc_top_restricted"), by = "country") %>%
    mutate(n_alloc_top_restricted = coalesce(n_alloc_top_restricted, 0L)) %>%
    select(country, legal_family, n_earmarked, n_E3, E3_share, n_alloc_top_restricted,
           n_assigned, E1_share_of_assigned, E2_share_of_assigned, E3_share_of_assigned) %>%
    arrange(country)

  if (nrow(a1) != 43) stop(s, ": A1 should have 43 countries, not ", nrow(a1))
  for (v in c("E3_share", "E1_share_of_assigned", "E2_share_of_assigned", "E3_share_of_assigned")) {
    check_share(a1[[v]], paste(s, "A1", v))
  }
  if (any(abs(a1$E1_share_of_assigned + a1$E2_share_of_assigned + a1$E3_share_of_assigned - 1) > 1e-9)) {
    stop(s, ": E1, E2 and E3 shares of the assigned set do not sum to 1")
  }
  if (sum(a1$n_alloc_top_restricted) != nrow(allocations)) stop(s, ": A1 allocations differ from the allocation table")

  ## Checks against the earlier outputs: the headline set is the n_earmarked of Table A1, country by country;
  ## the sc total is the "with social contributions" count of 00_load_summary.csv
  if (s == "headline") {
    check_a1 <- a1 %>%
      select(country, n_earmarked, E3_share) %>%
      full_join(table_a1_01 %>% select(country, n_earmarked_01 = n_earmarked, exclusive_share), by = "country")
    if (any(is.na(check_a1$n_earmarked) | check_a1$n_earmarked != check_a1$n_earmarked_01)) {
      stop("A1: n_earmarked differs from 01_tableA1.csv")
    }
    if (any(abs(check_a1$E3_share - check_a1$exclusive_share) > 1e-9)) stop("A1: E3_share differs from exclusive_share of 01_tableA1.csv")
  }
  if (s == "sc") {
    n_sc <- load_summary$n[load_summary$item == "earmarked (E2+E3), with social contributions"]
    if (sum(a1$n_earmarked) != n_sc) stop("A1 sc: earmarked instruments differ from 00_load_summary.csv")
  }


  ## --- A2a: base group × COFOG division (unit: instrument × cofog_division link) ---
  ## Cell = number of links (pooled), label = number of countries with at least one link in the cell.
  ## Country-equal cell shares: each country's links over the 12 × 11 grid, then the mean over countries.
  a2a_by_country <- country_composition(links, c("base_group", "cofog_division"), paste(s, "A2a"))
  a2a <- summarise_composition(a2a_by_country, c("base_group", "cofog_division")) %>%
    rename(n_links = n) %>%
    mutate(unit = "instrument x cofog_division link (indicator legs)", set = set_label[[s]]) %>%
    select(set, unit, base_group, cofog_division, n_links, n_countries, countries_in_mean,
           share_country_equal, share_pooled)
  if (sum(a2a$n_links) != nrow(links)) stop(s, ": A2a heatmap total differs from the number of links")
  check_share(a2a$share_country_equal, paste(s, "A2a"))


  ## --- A2a′: zoom on 704 Economic affairs (unit: instrument × cofog_group) ---
  ## 704 holds over half of the links (ANALYSIS_SPEC §2), so its groups 7041–7049 get their own heatmap. Same
  ## legs as A2a, restricted to cofog_division = 704. A cell counts distinct (instrument, cofog_group) pairs, so
  ## an instrument linked to two 704 groups counts in both. A 704 leg with no cofog_group goes to not_coded,
  ## a column kept only when such legs exist.
  zoom <- legs %>%
    filter(cofog_division == "704") %>%
    mutate(cofog_group = coalesce(cofog_group, "not_coded")) %>%
    distinct(country, instrument_id, cofog_group) %>%
    left_join(instruments %>% select(country, instrument_id, base_group), by = c("country", "instrument_id"))
  bad_group <- setdiff(unique(zoom$cofog_group), group_704_levels)
  if (length(bad_group) > 0) stop(s, ": cofog_group of 704 legs outside 7041–7049: ", paste(bad_group, collapse = ", "))
  zoom_levels <- if (any(zoom$cofog_group == "not_coded")) group_704_levels else setdiff(group_704_levels, "not_coded")
  zoom$cofog_group <- factor(zoom$cofog_group, levels = zoom_levels)

  zoom_by_country <- country_composition(zoom, c("base_group", "cofog_group"), paste(s, "A2a zoom 704"))
  zoom704 <- summarise_composition(zoom_by_country, c("base_group", "cofog_group")) %>%
    rename(n_pairs = n) %>%
    mutate(unit = "instrument x cofog_group within 704 (indicator legs; an instrument in two 704 groups counts in both)",
           set = set_label[[s]]) %>%
    select(set, unit, base_group, cofog_group, n_pairs, n_countries, countries_in_mean,
           share_country_equal, share_pooled)
  if (sum(zoom704$n_pairs) != nrow(zoom)) stop(s, ": A2a zoom total differs from the number of 704 pairs")
  check_share(zoom704$share_country_equal, paste(s, "A2a zoom 704"))

  ## Each base group's distinct instruments in the zoom = its 704 cell in A2a (a 704 link is one instrument)
  check_zoom <- zoom %>%
    distinct(country, instrument_id, base_group) %>%
    count(base_group, name = "n_zoom", .drop = FALSE) %>%
    full_join(a2a %>% filter(cofog_division == "704") %>% select(base_group, n_links), by = "base_group") %>%
    mutate(n_zoom = coalesce(n_zoom, 0L), n_links = coalesce(n_links, 0L))
  if (any(check_zoom$n_zoom != check_zoom$n_links)) stop(s, ": instruments of the 704 zoom differ from the 704 cells of A2a")


  ## --- A2b: recipient form (unit: allocation, top level, restricted) ---
  ## Legal forms as written, not budget status (ANALYSIS_SPEC §2, vehicle definitions). Forms with no
  ## allocation in the set are dropped from the table.
  a2b_by_country <- country_composition(allocations, "recipient_form", paste(s, "A2b"))
  a2b <- summarise_composition(a2b_by_country, "recipient_form") %>%
    filter(n > 0) %>%
    rename(n_allocations = n) %>%
    mutate(unit = "allocation (top level, restricted legs of earmarked instruments)", set = set_label[[s]]) %>%
    select(set, unit, recipient_form, n_allocations, n_countries, countries_in_mean,
           share_country_equal, share_pooled) %>%
    arrange(desc(share_country_equal))
  if (sum(a2b$n_allocations) != nrow(allocations)) stop(s, ": A2b counts differ from the allocations")
  check_share(a2b$share_country_equal, paste(s, "A2b"))


  ## --- A2d: GFS instrument type (unit: instrument) ---
  ## What kind of charges the counts are made of (instrument_type records the economic nature of the charge).
  a2d_by_country <- country_composition(instruments %>% filter(earmarked), "instrument_type", paste(s, "A2d"))
  a2d <- summarise_composition(a2d_by_country, "instrument_type") %>%
    filter(n > 0) %>%
    rename(n_instruments = n) %>%
    mutate(unit = "instrument (and class of charges)", set = set_label[[s]]) %>%
    select(set, unit, instrument_type, n_instruments, n_countries, countries_in_mean,
           share_country_equal, share_pooled) %>%
    arrange(desc(share_country_equal))
  if (sum(a2d$n_instruments) != sum(a1$n_earmarked)) stop(s, ": A2d counts do not sum to n_earmarked")
  check_share(a2d$share_country_equal, paste(s, "A2d"))


  ## --- A3: benefit link (unit: instrument × cofog_division link) ---
  ## Links with a null benefit_link (cofog_division = unallocated) are excluded and counted in n_null_excluded.
  ## Country-equal within each group: the mean over all countries, then over the countries of each legal family.
  linked <- links %>%
    filter(!is.na(benefit_link)) %>%
    mutate(benefit_link = factor(benefit_link, levels = benefit_levels))
  a3_by_country <- country_composition(linked, "benefit_link", paste(s, "A3")) %>%
    left_join(country_info, by = "country")

  ## The non-null links per country are the n_benefit_pairs of Table A1, so that total links = Table A1 pairs
  ## + null links
  if (s == "headline") {
    check_a3 <- linked %>%
      count(country, name = "n_linked") %>%
      full_join(table_a1_01 %>% select(country, n_benefit_pairs), by = "country")
    if (any(is.na(check_a3$n_linked) | check_a3$n_linked != check_a3$n_benefit_pairs)) {
      stop("A3: non-null links per country differ from n_benefit_pairs of 01_tableA1.csv")
    }
    if (nrow(links) != sum(table_a1_01$n_benefit_pairs) + sum(is.na(links$benefit_link))) {
      stop("A3: total links differ from n_benefit_pairs plus the null links")
    }
  }

  null_links <- links %>% filter(is.na(benefit_link))
  a3 <- bind_rows(
    summarise_composition(a3_by_country, "benefit_link") %>%
      mutate(group = "all countries", n_null_excluded = nrow(null_links)),
    summarise_composition(a3_by_country, "benefit_link", group = "legal_family") %>%
      left_join(null_links %>% count(legal_family, name = "n_null_excluded"), by = "legal_family") %>%
      mutate(group = as.character(legal_family), n_null_excluded = coalesce(n_null_excluded, 0L))
  ) %>%
    rename(n_links = n) %>%
    mutate(unit = "instrument x cofog_division link (indicator legs; null benefit_link excluded)",
           set = set_label[[s]]) %>%
    select(set, unit, group, countries_in_mean, n_null_excluded, benefit_link, n_links, n_countries,
           share_country_equal, share_pooled)
  check_share(a3$share_country_equal, paste(s, "A3"))
  a3_sums <- a3 %>% group_by(group) %>% summarise(total = sum(share_country_equal))
  if (any(abs(a3_sums$total - 1) > 1e-9)) stop(s, ": A3 shares do not sum to 1 within a group")


  ## --- Summary of the set ---
  cat("\n[", s, "]", set_label[[s]], "\n")
  cat("Earmarked instruments:", sum(a1$n_earmarked), " | E3:", sum(a1$n_E3),
      " | assigned:", sum(a1$n_assigned), " | restricted top-level allocations:", nrow(allocations), "\n")
  cat("Links (instrument x division):", nrow(links), " | null benefit_link (unallocated):", nrow(null_links),
      " | with several benefit_link values:", sum(links$n_links > 1), "\n")
  cat("Country medians over 43: n_earmarked", median(a1$n_earmarked), " | E3 share", round(median(a1$E3_share), 3),
      " | restricted allocations", median(a1$n_alloc_top_restricted), "\n")
  largest_cell <- a2a %>% slice_max(n_links, n = 1, with_ties = FALSE)
  cat("Largest A2a cell:", as.character(largest_cell$base_group), "x", as.character(largest_cell$cofog_division),
      "=", largest_cell$n_links, "links",
      " | links to 704 (country-equal share):",
      round(sum(a2a$share_country_equal[a2a$cofog_division == "704"]), 3), "\n")
  zoom_instruments <- zoom %>% count(country, instrument_id)
  largest_zoom <- zoom704 %>% slice_max(n_pairs, n = 1, with_ties = FALSE)
  cat("704 zoom: instrument x group pairs", nrow(zoom), " | instruments", nrow(zoom_instruments),
      " | in two or more 704 groups", sum(zoom_instruments$n > 1), " | countries", n_distinct(zoom$country),
      " | largest cell:", as.character(largest_zoom$base_group), "x", as.character(largest_zoom$cofog_group),
      "=", largest_zoom$n_pairs, "\n")
  cat("Recipient forms, country-equal:",
      paste(a2b$recipient_form[1:3], round(a2b$share_country_equal[1:3], 3), collapse = " | "), "\n")
  a3_all <- a3 %>% filter(group == "all countries")
  cat("Benefit link, country-equal (all countries):",
      paste(a3_all$benefit_link, round(a3_all$share_country_equal, 3), collapse = " | "), "\n")

  results[[s]] <- list(a1 = a1, a2a = a2a, zoom704 = zoom704, a2b = a2b, a2d = a2d, a3 = a3, n_links = nrow(links),
                       n_null = nrow(null_links), n_allocations = nrow(allocations),
                       n_zoom_pairs = nrow(zoom), n_zoom_instruments = nrow(zoom_instruments))


  ## --- Write the tables of the set ---
  write.csv(a1,  file.path(dir_tables, paste0("02_A1_by_country", set_suffix[[s]], ".csv")), row.names = FALSE)
  write.csv(a2a, file.path(dir_tables, paste0("02_A2a_links", set_suffix[[s]], ".csv")), row.names = FALSE)
  write.csv(zoom704, file.path(dir_tables, paste0("02_A2a_zoom704", set_suffix[[s]], ".csv")), row.names = FALSE)
  write.csv(a2b, file.path(dir_tables, paste0("02_A2b_recipient_form", set_suffix[[s]], ".csv")), row.names = FALSE)
  write.csv(a2d, file.path(dir_tables, paste0("02_A2d_instrument_type", set_suffix[[s]], ".csv")), row.names = FALSE)
  write.csv(a3,  file.path(dir_tables, paste0("02_A3_benefit_link", set_suffix[[s]], ".csv")), row.names = FALSE)
}

## Unit and definition of each A1 column (the same in the three sets)
a1_columns <- data.frame(
  column = names(results$headline$a1),
  unit = c("country", "country", "instrument", "instrument", "share of earmarked instruments",
           "allocation (top level)", "instrument", "share of assigned instruments",
           "share of assigned instruments", "share of assigned instruments"),
  definition = c("ISO3", "country_groups.csv",
                 "earmarked instruments and classes of charges (E2 + E3) of the set",
                 "E3 instruments of the set",
                 "n_E3 / n_earmarked",
                 "distinct top-level restricted allocations of the earmarked instruments of the set; a pool counts once",
                 "assigned instruments (E1 + E2 + E3) of the set",
                 "E1 / n_assigned", "E2 / n_assigned", "E3 / n_assigned")
)
if (nrow(a1_columns) != ncol(results$headline$a1)) stop("a1_columns does not describe every A1 column")
write.csv(a1_columns, file.path(dir_tables, "02_A1_by_country_columns.csv"), row.names = FALSE)


## ============================================================================
## Figures: headline set only (social contributions excluded, placeholders included)
## ============================================================================
headline <- results$headline
caption_set <- "Earmarked instruments and classes of charges (E2 + E3), social contributions excluded."


## --- A1: dot plot of countries ---
## Two panels on one country axis: earmarked instruments, and their restricted top-level allocations.
## Countries ordered by n_earmarked (ties by ISO3), largest at the top.
country_order <- headline$a1 %>% arrange(n_earmarked, desc(country)) %>% pull(country)
fig_a1_data <- headline$a1 %>%
  select(country, legal_family, n_earmarked, n_alloc_top_restricted) %>%
  pivot_longer(c(n_earmarked, n_alloc_top_restricted), names_to = "measure", values_to = "n") %>%
  mutate(measure = factor(measure, levels = c("n_earmarked", "n_alloc_top_restricted"),
                          labels = c("Earmarked instruments", "Restricted allocations")),
         country = factor(country, levels = country_order))

fig_a1 <- ggplot(fig_a1_data, aes(x = n, y = country, colour = legal_family)) +
  geom_point(size = 2.4) +
  facet_wrap(~ measure, scales = "free_x") +
  scale_colour_manual(values = pal_family, labels = family_labels) +
  scale_x_continuous(limits = c(0, NA), expand = expansion(mult = c(0.02, 0.06))) +
  guides(colour = guide_legend(nrow = 2, byrow = TRUE)) +
  labs(title = "Earmarked instruments and their allocations, by country",
       x = "Number", y = NULL,
       caption = paste0("Unit: instrument (left); allocation, top level, restricted legs, a pool counted once (right).\n",
                        caption_set, "\nRaw counts depend on corpus completeness.")) +
  theme(axis.text.y = element_text(size = 9),
        panel.spacing.x = unit(1.2, "cm"))
save_fig(fig_a1, "02_A1_countries", width = 7, height = 9)


## --- A2a: heatmap of base group × COFOG division ---
## Fill = number of links on a square-root scale (704 holds most links); label = number of countries.
## Empty cells stay white. Labels are white on the darker cells, which the ink would not show.
fig_a2a_data <- headline$a2a %>%
  mutate(fill  = ifelse(n_links > 0, n_links, NA),
         label = ifelse(n_links > 0, n_countries, ""),
         dark  = n_links > max(n_links) / 4)

fig_a2a <- ggplot(fig_a2a_data, aes(x = cofog_division, y = base_group)) +
  geom_tile(aes(fill = fill), colour = "white", linewidth = 0.6) +
  geom_text(aes(label = label, colour = dark), size = 3.6) +
  scale_fill_gradient(low = seq_low, high = seq_high, trans = "sqrt", na.value = "white",
                      name = "Number of links") +
  scale_colour_manual(values = c(`FALSE` = col_ink, `TRUE` = "white"), guide = "none") +
  scale_x_discrete(labels = division_labels, position = "top") +
  scale_y_discrete(limits = rev(levels(fig_a2a_data$base_group)), labels = base_group_labels) +
  labs(title = "What earmarked revenue taxes, and what it finances",
       x = NULL, y = NULL,
       caption = paste0("Unit: instrument x COFOG division link (restricted legs; n = ", headline$n_links,
                        " links). Fill: number of links, not revenue.\nLabel: number of countries with at least",
                        " one link in the cell (of 43).\n", caption_set)) +
  theme(panel.grid.major = element_blank(),
        axis.text.x = element_text(size = 9, lineheight = 0.9),
        legend.title = element_text(colour = col_grey_dark, size = rel(0.85)),
        legend.key.width = unit(1.6, "cm"))
save_fig(fig_a2a, "02_A2a_heatmap", width = 10, height = 6.5)


## --- A2a′: heatmap of base group × COFOG group within 704 ---
## Same style as A2a: fill = number of pairs on a square-root scale, label = number of countries, empty cells
## white, white labels on the darker cells. The fill range is the zoom's own (A2a's maximum would wash it out).
## Groups with no pair in any base group (e.g. 7049) are dropped from the figure only; the table keeps them.
empty_groups <- headline$zoom704 %>%
  group_by(cofog_group) %>%
  summarise(n = sum(n_pairs)) %>%
  filter(n == 0) %>%
  pull(cofog_group) %>%
  as.character()
fig_zoom_data <- headline$zoom704 %>%
  filter(!cofog_group %in% empty_groups) %>%
  mutate(cofog_group = droplevels(cofog_group)) %>%
  mutate(fill  = ifelse(n_pairs > 0, n_pairs, NA),
         label = ifelse(n_pairs > 0, n_countries, ""),
         dark  = n_pairs > max(n_pairs) / 4)

fig_zoom <- ggplot(fig_zoom_data, aes(x = cofog_group, y = base_group)) +
  geom_tile(aes(fill = fill), colour = "white", linewidth = 0.6) +
  geom_text(aes(label = label, colour = dark), size = 3.6) +
  scale_fill_gradient(low = seq_low, high = seq_high, trans = "sqrt", na.value = "white",
                      name = "Number of instrument-group pairs") +
  scale_colour_manual(values = c(`FALSE` = col_ink, `TRUE` = "white"), guide = "none") +
  scale_x_discrete(labels = group_704_labels, position = "top") +
  scale_y_discrete(limits = rev(levels(fig_zoom_data$base_group)), labels = base_group_labels) +
  labs(title = "Inside 704 Economic affairs: which sectors earmarked revenue finances",
       x = NULL, y = NULL,
       caption = paste0("Unit: instrument x COFOG group within 704 Economic affairs (restricted legs; n = ",
                        headline$n_zoom_pairs, " pairs from ", headline$n_zoom_instruments, " instruments).\n",
                        "An instrument linked to two 704 groups counts in both. Fill: number of pairs, not revenue.\n",
                        "Label: number of countries with at least one pair in the cell (of 43).",
                        if (length(empty_groups) > 0) paste0(" Groups with no pair not shown: ",
                                                             paste(empty_groups, collapse = ", "), "."),
                        "\n", caption_set)) +
  theme(panel.grid.major = element_blank(),
        axis.text.x = element_text(size = 9, lineheight = 0.9),
        legend.title = element_text(colour = col_grey_dark, size = rel(0.85)),
        legend.key.width = unit(1.6, "cm"))
save_fig(fig_zoom, "02_A2a_zoom704", width = 10, height = 6.5)


## --- A2b: recipient form, one horizontal stacked bar ---
## The 5 largest forms by country-equal share, the rest folded into Other (grey, PLOT_STYLE rule 1).
top_forms <- as.character(headline$a2b$recipient_form[1:5])
other_forms <- setdiff(as.character(headline$a2b$recipient_form), top_forms)
fig_a2b_data <- headline$a2b %>%
  mutate(form = ifelse(recipient_form %in% top_forms, form_labels[as.character(recipient_form)], "Other")) %>%
  group_by(form) %>%
  summarise(share = sum(share_country_equal), .groups = "drop") %>%
  mutate(form = factor(form, levels = c(form_labels[top_forms], "Other")))

fig_a2b <- ggplot(fig_a2b_data, aes(x = share, y = "43 countries", fill = form)) +
  geom_col(width = 0.6, position = position_stack(reverse = TRUE)) +
  geom_text(aes(label = ifelse(share >= 0.05, scales::percent(share, accuracy = 1), "")),
            position = position_stack(vjust = 0.5, reverse = TRUE), colour = "white", size = 4) +
  scale_fill_manual(values = c(setNames(pal_cat[1:5], form_labels[top_forms]), Other = col_grey)) +
  scale_x_continuous(labels = scales::percent, expand = c(0, 0)) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE)) +
  labs(title = "Recipient form of restricted allocations",
       x = "Share of allocations (country-equal)", y = NULL,
       caption = paste0("Unit: allocation, top level, restricted legs of earmarked instruments (n = ",
                        headline$n_allocations, "; a pool counted once).\nShares within each country, averaged over",
                        " countries. Legal forms as written, not budget status.\nOther: ",
                        paste(form_labels[other_forms], collapse = ", "), ".\n", caption_set)) +
  theme(plot.margin = margin(10, 24, 10, 10))
save_fig(fig_a2b, "02_A2b_recipient_form", width = 8, height = 3.6)


## --- A3: benefit link, overall and by legal family ---
## Fixed stacking order of pal_benefit (PLOT_STYLE: green and orange collapse for colour-blind readers, grey
## sits between them), so bars are not reordered by size. Each bar is labelled with its number of countries.
group_order <- c("all countries", names(family_labels))
fig_a3_data <- headline$a3 %>%
  mutate(group_label = ifelse(group == "all countries", "All countries", family_labels[group]),
         group_label = paste0(group_label, " (", countries_in_mean, ")"),
         group_rank  = match(group, group_order))
fig_a3_data$group_label <- factor(fig_a3_data$group_label,
                                  levels = rev(unique(fig_a3_data$group_label[order(fig_a3_data$group_rank)])))

fig_a3 <- ggplot(fig_a3_data, aes(x = share_country_equal, y = group_label, fill = benefit_link)) +
  geom_col(width = 0.7, position = position_stack(reverse = TRUE)) +
  geom_text(aes(label = ifelse(share_country_equal >= 0.06, scales::percent(share_country_equal, accuracy = 1), "")),
            position = position_stack(vjust = 0.5, reverse = TRUE), colour = "white", size = 3.6) +
  scale_fill_manual(values = pal_benefit[benefit_levels], labels = benefit_labels) +
  scale_x_continuous(labels = scales::percent, expand = c(0, 0)) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE)) +
  labs(title = "Economic link between the taxed base and the use",
       x = "Share of links (country-equal within each group)", y = NULL,
       caption = paste0("Unit: instrument x COFOG division link (restricted legs; n = ",
                        headline$n_links - headline$n_null, "). ", headline$n_null,
                        " links with an unknown function\n(cofog_division = unallocated) excluded.",
                        " In brackets: number of countries.\n", caption_set)) +
  theme(legend.text = element_text(size = rel(0.8)),
        plot.margin = margin(10, 24, 10, 10))
save_fig(fig_a3, "02_A3_benefit_link", width = 9, height = 4.5)


## --- Summary ---
cat("\nTables:", length(results) * 6 + 1, "files 02_*.csv in", dir_tables, "\n")
cat("Figures: 02_A1_countries, 02_A2a_heatmap, 02_A2a_zoom704, 02_A2b_recipient_form, 02_A3_benefit_link",
    "(PDF + PNG) in",
    dir_figures, "\n")
