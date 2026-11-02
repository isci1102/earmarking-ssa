## ============================================================================
## helpers.R — rules shared by several scripts, so that every script reads the same legs and links
## Source it after paths.R:  source(here::here("analysis", "helpers.R"))
## Used by 01_descriptives.R (Table A1), 02_composition.R (A1–A3), 03_sankey.R (A2c), 04_design.R (A4, A7),
## 11_tax_revenue.R (B1) and 12_pefa.R (B2).
## ============================================================================

library(dplyr)
library(tidyr)


## --- Restricted legs read by the instrument-level indicators (ANALYSIS_SPEC §0, share levels) ---
## Decision of 2 Nov 2026: for each earmarked instrument, its restricted legs at the shallowest level where it
## has a restricted leg.
## - An instrument with a top-level restricted leg keeps its top-level restricted legs, so nothing changes for it.
##   The rule is written on top_level, not on share_level: an instrument can also sit in a group with no
##   level-1 row, whose top level is level 2, and a minimum over share_level would drop those top-level legs.
## - The few E2 instruments whose restricted legs all sit below the top level (the E-class reads every level)
##   keep their restricted legs at the shallowest share_level; otherwise they would stay in the earmarked set and
##   count as "no" on every indicator. They carry no_top_restricted = TRUE.
## rows: the analysis rows of the instrument set wanted (the caller drops social contributions or placeholders
## first; the rule is per instrument, so that filter does not change the legs of the other instruments).
get_indicator_legs <- function(rows) {
  rows %>%
    filter(earmarked, leg_class == "restricted") %>%
    group_by(country, instrument_id) %>%
    mutate(no_top_restricted = !any(top_level == 1)) %>%
    filter(if (first(no_top_restricted)) share_level == min(share_level) else top_level == 1) %>%
    ungroup()
}


## --- Instrument × cofog_division links (DERIVED_TABLE_SPEC §3) ---
## One row per (country, instrument_id, cofog_division) over the legs from get_indicator_legs(): a division
## counts once per instrument, so a tax split between two health bodies is one link.
## benefit_link of the link: a pair with several values takes the first in the test order of DERIVED_TABLE_SPEC
## §2.4, which is the factor order set in 00_load.R. NA when every leg of the pair has a null benefit_link
## (cofog_division = unallocated: the function, and so the link, is unknown); the caller excludes or counts them.
## n_links: number of distinct non-null benefit_link values on the pair.
get_link_pairs <- function(legs) {
  legs %>%
    group_by(country, instrument_id, cofog_division) %>%
    summarise(n_links = n_distinct(benefit_link[!is.na(benefit_link)]),
              benefit_link = if (all(is.na(benefit_link))) NA_character_
                             else levels(benefit_link)[min(as.integer(benefit_link), na.rm = TRUE)],
              .groups = "drop")
}


## --- Share checks and country-equal composition (02_composition.R, 04_design.R) ---
## Stop if a share is missing or outside [0, 1]
check_share <- function(x, name) {
  if (any(is.na(x) | x < 0 | x > 1)) stop(name, ": share missing or outside [0, 1]")
}

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


## --- Design shares of Table A1, one row per country (11_tax_revenue.R, 12_pefa.R) ---
## The four shares of Table A1 (01_descriptives.R) on the set given in rows (the caller drops social
## contributions for the headline set). 01 and 04 compute the same shares inline; 11 and 12 check the result
## against 01_tableA1.csv.
##   exclusive_share, hard_commitment_share, fund_agency_share: share of the country's earmarked instruments;
##   benefit_linked_share: share of its instrument × cofog_division links, null benefit_link (unallocated) excluded.
## Commitment: the instrument maximum over its indicator legs. Fund-or-agency vehicles are legal forms as
## written, not budget status (ANALYSIS_SPEC §2).
get_design_shares <- function(rows) {
  vehicle_fund_agency    <- c("fund", "agency", "social_security_institution", "non_government_body")
  benefit_linked_classes <- c("corrective", "compensatory", "benefit", "sectoral")

  instruments <- rows %>%
    filter(earmarked) %>%
    distinct(country, instrument_id, earmark_class)
  if (any(duplicated(instruments[, c("country", "instrument_id")]))) stop("earmark_class varies within an instrument")

  legs <- get_indicator_legs(rows)
  indicators <- legs %>%
    group_by(country, instrument_id) %>%
    summarise(fund_agency = any(recipient_form %in% vehicle_fund_agency),
              commitment_max = max(commitment_strength),
              .groups = "drop")
  if (nrow(indicators) != nrow(instruments) ||
      nrow(anti_join(instruments, indicators, by = c("country", "instrument_id"))) > 0) {
    stop("Some earmarked instruments have no restricted leg")
  }

  benefit_pairs <- get_link_pairs(legs) %>% filter(!is.na(benefit_link))

  instruments %>%
    left_join(indicators, by = c("country", "instrument_id")) %>%
    group_by(country) %>%
    summarise(n_earmarked = n(),
              exclusive_share = mean(earmark_class == "E3"),
              hard_commitment_share = mean(commitment_max == "hard"),
              fund_agency_share = mean(fund_agency),
              .groups = "drop") %>%
    left_join(benefit_pairs %>%
                group_by(country) %>%
                summarise(n_benefit_pairs = n(),
                          benefit_linked_share = mean(benefit_link %in% benefit_linked_classes)),
              by = "country")
}


## --- Spearman rho with its leave-one-out range (ANALYSIS_SPEC §3, common reporting; 11, 12) ---
## x, y: one value per country (NA allowed); country: ISO3, sorted. Unit: country, unweighted, complete cases only.
## rho = cor(method = "spearman"), which gives tied values their average rank (ordinal PEFA grades have many ties).
## Leave-one-out: rho recomputed n times, each time without one country; min, max, and the country whose removal
## gives each (the first in ISO3 order on a tie). A removal that leaves one variable constant (e.g. the only
## country graded above D) has no rho: it is left out of the min and max and counted in loo_undefined.
## Stop if rho is missing or if any rho is outside [-1, 1].
spearman_loo <- function(x, y, country, name) {
  keep <- !is.na(x) & !is.na(y)
  x <- x[keep]
  y <- y[keep]
  country <- country[keep]
  n <- length(x)
  rho <- cor(x, y, method = "spearman")
  loo <- rep(NA_real_, n)
  for (i in 1:n) {
    if (length(unique(x[-i])) > 1 && length(unique(y[-i])) > 1) loo[i] <- cor(x[-i], y[-i], method = "spearman")
  }
  if (is.na(rho) || all(is.na(loo)) || any(abs(c(rho, loo)) > 1 + 1e-12, na.rm = TRUE)) {
    stop(name, ": rho missing or outside [-1, 1]")
  }
  data.frame(n = n, rho = rho, loo_min = min(loo, na.rm = TRUE), loo_max = max(loo, na.rm = TRUE),
             loo_min_drop = country[which.min(loo)], loo_max_drop = country[which.max(loo)],
             loo_undefined = sum(is.na(loo)))
}
