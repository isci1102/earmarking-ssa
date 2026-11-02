## ============================================================================
## 04_design.R — A4 (how binding earmarks are) and A7 (do legal traditions shape the design?)
## A5 (reform candidates) is deferred to a later deep-dive project (decision of 2 Nov 2026) and is not built here.
## ANALYSIS_SPEC §0 and §2; units in DERIVED_TABLE_SPEC §3; figures by docs/PLOT_STYLE.md.
## Inputs: the analysis .rds (00_load.R), helpers.R, and 01_tableA1.csv (documents_read and law_year_median, and
## the check of the A7(b) measures) and 02_A2b_recipient_form.csv (the 5 forms coloured in A2b).
## Three instrument sets, each written to its own tables (ANALYSIS_SPEC §0), as in 02_composition.R:
##   headline: earmarked (E2 + E3), social contributions excluded       -> 04_*.csv, and the figures
##   sc:       earmarked, social contributions included (robustness)   -> 04_*_sc.csv, tables only
##   nopl:     headline without class placeholders                     -> 04_*_nopl.csv, tables only
## Weights: country-equal shares (within each country, then the mean over countries) are the main measure;
## pooled shares are written next to them as robustness.
## Levels: instrument-level indicators (commitment, fund-or-agency, benefit link) use the indicator legs of
## helpers.R, the same rule as Table A1. Allocation-level measures (vehicle, legal_rank, determinacy, recipient
## form) use top_level = 1 restricted allocations of the earmarked instruments of the set; a pool counts once.
## Outputs: 04_A4_instrument, 04_A4_allocation, 04_A7a_recipient_form, 04_A7b_profile, 04_A7b_group_summary,
## 04_A7c_regressions, 04_A7c_predicted (one file per set) in dir_tables; 3 figures (PDF + PNG) in dir_figures.
## ============================================================================

source(here::here("analysis", "paths.R"))
source(here::here("analysis", "helpers.R"))        # indicator legs, links, share checks, country-equal composition
source(here::here("analysis", "theme_earmark.R"))  # colours, theme, save_fig()

library(dplyr)
library(tidyr)
library(ggplot2)
library(sandwich)       # HC3 covariance of the A7(c) fractional logits
library(modelsummary)   # A7(c) regression table

earmarks <- readRDS(file_analysis_rds)

file_table_a1 <- file.path(dir_tables, "01_tableA1.csv")
file_a2b      <- file.path(dir_tables, "02_A2b_recipient_form.csv")
for (f in c(file_table_a1, file_a2b)) {
  if (!file.exists(f)) stop("Run 01_descriptives.R and 02_composition.R first: ", f, " not found")
}
table_a1_01 <- read.csv(file_table_a1)
a2b_02      <- read.csv(file_a2b)


## --- Vehicle classes (ANALYSIS_SPEC §2, vehicle definitions) ---
## Legal forms as written, not budget status: `fund` is any recipient the text calls a fund.
## Three classes (decision of 2 Nov 2026): territorial and external is one class, kept separate from the other two.
vehicle_fund_agency  <- c("fund", "agency", "social_security_institution", "non_government_body")
vehicle_on_budget    <- c("special_account", "ministry_or_vote", "program_or_purpose")
vehicle_territorial  <- c("subnational_government", "supranational_body", "foreign_government")
vehicle_levels <- c("fund_or_agency", "on_budget", "territorial_external")

## Benefit-linked classes: the base is tied to the use (Table A1, benefit_linked_share)
benefit_linked_classes <- c("corrective", "compensatory", "benefit", "sectoral")


## --- Labels for tables and figures ---
family_labels <- c(francophone_civil = "Francophone civil law", anglophone_common = "Anglophone common law",
                   lusophone_civil = "Lusophone civil law", hispanophone_civil = "Hispanophone civil law",
                   mixed = "Mixed")
design_labels <- c(uemoa_francophone = "UEMOA francophone", cemac_francophone = "CEMAC francophone",
                   francophone_noncfa = "Francophone, non-CFA", anglophone_common = "Anglophone common law",
                   lusophone_noncfa = "Lusophone, non-CFA", cfa_nonfrancophone = "CFA, non-francophone",
                   mixed = "Mixed")
form_labels <- c(agency = "Agency", fund = "Fund", program_or_purpose = "Programme or purpose",
                 special_account = "Special account", non_government_body = "Non-government body",
                 social_security_institution = "Social security institution",
                 subnational_government = "Subnational government", ministry_or_vote = "Ministry or vote",
                 supranational_body = "Supranational body", foreign_government = "Foreign government")
commitment_labels <- c(soft = "Soft", firm = "Firm", hard = "Hard")
measure_labels <- c(E3_share = "E3 (exclusive) share", hard_commitment_share = "Hard-commitment share",
                    benefit_linked_share = "Benefit-linked share", fund_agency_share = "Fund-or-agency share")

## A7 groups: the 5 main groups are compared; the two 2-country groups (cfa_nonfrancophone: GNB, GNQ; mixed:
## RWA, ETH) are shown as labelled countries, never as group bars (ANALYSIS_SPEC A7)
main_groups <- c("uemoa_francophone", "cemac_francophone", "francophone_noncfa", "anglophone_common",
                 "lusophone_noncfa")
single_countries <- c(GNB = "Guinea-Bissau (UEMOA, lusophone)", GNQ = "Equatorial Guinea (CEMAC, hispanophone)",
                      RWA = "Rwanda (mixed)", ETH = "Ethiopia (mixed)")


## --- Countries and groups ---
country_info <- earmarks %>% distinct(country, legal_family, design_group, resource_group)
if (nrow(country_info) != 43 || n_distinct(country_info$country) != 43) stop("Expected 43 countries with one group each")
countries_by_design <- country_info %>% count(design_group, .drop = FALSE)
if (sum(countries_by_design$n) != 43 || any(is.na(country_info$design_group))) {
  stop("Countries per design_group do not sum to 43")
}
outside_groups <- country_info %>% filter(!design_group %in% main_groups) %>% pull(country)
if (!setequal(outside_groups, names(single_countries))) {
  stop("The countries outside the 5 main groups are not GNB, GNQ, RWA, ETH: ", paste(outside_groups, collapse = ", "))
}
family_n <- country_info %>% count(legal_family)
design_n <- countries_by_design


## --- Composition overall and by legal_family (A4) ---
## units: one row per unit with its country and the category column (a factor, so that complete() fills zeros).
## Returns the country-equal and pooled shares for all countries and within each legal family, in long format,
## and checks that the shares sum to 1 within each group.
compose_by_family <- function(units, category, measure, unit_label, set_name) {
  by_country <- country_composition(units, category, paste(set_name, measure)) %>%
    left_join(country_info %>% select(country, legal_family), by = "country")
  out <- bind_rows(
    summarise_composition(by_country, category) %>%
      mutate(group = "all countries"),
    summarise_composition(by_country, category, group = "legal_family") %>%
      mutate(group = as.character(legal_family)) %>%
      select(-legal_family)
  ) %>%
    rename(category = all_of(category)) %>%
    mutate(category = as.character(category), measure = measure, unit = unit_label, set = set_name) %>%
    select(set, unit, measure, group, countries_in_mean, category, n, n_countries,
           share_country_equal, share_pooled)
  check_share(out$share_country_equal, paste(set_name, measure, "country-equal"))
  check_share(out$share_pooled, paste(set_name, measure, "pooled"))
  sums <- out %>% group_by(group) %>% summarise(ce = sum(share_country_equal), pooled = sum(share_pooled))
  if (any(abs(sums$ce - 1) > 1e-9 | abs(sums$pooled - 1) > 1e-9)) stop(set_name, " ", measure, ": shares do not sum to 1 within a group")
  out
}


## --- Instrument sets (ANALYSIS_SPEC §0) ---
sets <- list(headline = earmarks %>% filter(!social_contribution),
             sc       = earmarks,
             nopl     = earmarks %>% filter(!social_contribution, row_kind != "class_placeholder"))
set_suffix <- c(headline = "", sc = "_sc", nopl = "_nopl")
set_label  <- c(headline = "earmarked (E2+E3), social contributions excluded",
                sc       = "earmarked (E2+E3), social contributions included",
                nopl     = "earmarked (E2+E3), social contributions and class placeholders excluded")

unit_instrument <- "instrument (and class of charges), earmarked; commitment = maximum over its indicator legs"
unit_allocation <- "allocation (top level, restricted legs of earmarked instruments; a pool counted once)"

results <- list()

for (s in names(sets)) {
  rows <- sets[[s]]

  ## Instrument level: earmarked instruments of the set, one row per (country, instrument_id)
  instruments <- rows %>%
    filter(earmarked) %>%
    distinct(country, instrument_id, earmark_class)
  if (any(duplicated(instruments[, c("country", "instrument_id")]))) stop(s, ": earmark_class varies within an instrument")

  ## Instrument-level indicators over the indicator legs (helpers.R; the rule of Table A1).
  ## Commitment: the instrument maximum over its legs (none < soft < firm < hard; DERIVED_TABLE_SPEC §2.3).
  legs <- get_indicator_legs(rows)
  instrument_indicators <- legs %>%
    group_by(country, instrument_id) %>%
    summarise(commitment_max = max(commitment_strength),
              fund_agency = any(recipient_form %in% vehicle_fund_agency),
              .groups = "drop")
  if (nrow(instrument_indicators) != nrow(instruments)) stop(s, ": some earmarked instruments have no restricted leg")
  instruments <- instruments %>%
    left_join(instrument_indicators, by = c("country", "instrument_id"))
  ## Restricted legs are never "none", so the instrument maximum is soft, firm or hard
  if (any(instruments$commitment_max == "none")) stop(s, ": commitment 'none' on a restricted leg")
  instruments <- instruments %>%
    mutate(e_class = factor(as.character(earmark_class), levels = c("E3", "E2")),
           commitment = factor(as.character(commitment_max), levels = c("soft", "firm", "hard")))

  ## Links (instrument × cofog_division) for the benefit-linked share; null benefit_link (unallocated) excluded
  benefit_pairs <- get_link_pairs(legs) %>% filter(!is.na(benefit_link))

  ## Allocation level: top-level restricted allocations of the earmarked instruments, as in 02 (A1, A2b).
  ## The 27 instruments with no restricted top-level leg (headline) add no allocation here.
  allocations <- rows %>%
    filter(earmarked, top_level == 1, leg_class == "restricted") %>%
    distinct(country, allocation_id, recipient_form, legal_rank, determinacy)
  if (any(duplicated(allocations[, c("country", "allocation_id")]))) {
    stop(s, ": recipient_form, legal_rank or determinacy varies within an allocation")
  }
  allocations <- allocations %>%
    mutate(vehicle = case_when(recipient_form %in% vehicle_fund_agency ~ "fund_or_agency",
                               recipient_form %in% vehicle_on_budget   ~ "on_budget",
                               recipient_form %in% vehicle_territorial ~ "territorial_external"),
           vehicle = factor(vehicle, levels = vehicle_levels))
  if (any(is.na(allocations$vehicle))) {
    stop(s, ": restricted allocation outside the three vehicle classes: ",
         paste(unique(allocations$recipient_form[is.na(allocations$vehicle)]), collapse = ", "))
  }


  ## --- A4: how binding earmarks are ---
  ## Instrument level: E3 vs E2; commitment strength (instrument maximum).
  a4_instrument <- bind_rows(
    compose_by_family(instruments, "e_class", "e_class", unit_instrument, set_label[[s]]),
    compose_by_family(instruments, "commitment", "commitment_strength", unit_instrument, set_label[[s]])
  )
  if (sum(a4_instrument$n[a4_instrument$measure == "e_class" & a4_instrument$group == "all countries"]) != nrow(instruments)) {
    stop(s, ": A4 E-class counts differ from the earmarked instruments")
  }

  ## Allocation level: vehicle class; legal_rank; determinacy.
  ## legal_rank describes where the assignment clauses sit in the corpus (the rank of the text that carries
  ## each clause). It depends on which texts the corpus holds, so it is described, not read as a design choice.
  a4_allocation <- bind_rows(
    compose_by_family(allocations, "vehicle", "vehicle_class", unit_allocation, set_label[[s]]),
    compose_by_family(allocations, "legal_rank", "legal_rank", unit_allocation, set_label[[s]]),
    compose_by_family(allocations, "determinacy", "determinacy", unit_allocation, set_label[[s]])
  )
  for (m in unique(a4_allocation$measure)) {
    if (sum(a4_allocation$n[a4_allocation$measure == m & a4_allocation$group == "all countries"]) != nrow(allocations)) {
      stop(s, ": A4 ", m, " counts differ from the allocations")
    }
  }


  ## --- A7(a): recipient form by design_group (unit: allocation, top level, restricted) ---
  ## Country-equal within each group: the shares within each country, then the mean over the group's countries.
  ## The 4 countries outside the 5 main groups are also written one by one (their own shares).
  ## Forms with no allocation in the set are dropped.
  forms_present <- unique(as.character(allocations$recipient_form))
  a7a_by_country <- country_composition(allocations, "recipient_form", paste(s, "A7a")) %>%
    left_join(country_info %>% select(country, design_group), by = "country")
  a7a <- bind_rows(
    summarise_composition(a7a_by_country, "recipient_form", group = "design_group") %>%
      mutate(level = "design_group", group = as.character(design_group),
             note = ifelse(group %in% main_groups, "", "2-country group: shown as countries, not interpreted as a group")),
    a7a_by_country %>%
      filter(country %in% names(single_countries)) %>%
      transmute(level = "country", group = country, recipient_form, n_countries = as.integer(n > 0),
                countries_in_mean = 1L, share_country_equal = share, n, share_pooled = share,
                note = "country outside the 5 main groups")
  ) %>%
    filter(as.character(recipient_form) %in% forms_present) %>%
    rename(n_allocations = n) %>%
    mutate(recipient_form = as.character(recipient_form), unit = unit_allocation, set = set_label[[s]]) %>%
    select(set, unit, level, group, countries_in_mean, note, recipient_form, n_allocations, n_countries,
           share_country_equal, share_pooled)
  check_share(a7a$share_country_equal, paste(s, "A7a"))
  check_share(a7a$share_pooled, paste(s, "A7a pooled"))
  a7a_sums <- a7a %>% group_by(level, group) %>% summarise(total = sum(share_country_equal), .groups = "drop")
  if (any(abs(a7a_sums$total - 1) > 1e-9)) stop(s, ": A7a shares do not sum to 1 within a group or country")

  ## Overall ranking of the forms (country-equal over 43 countries), for the 5 forms coloured in the figure
  form_rank <- summarise_composition(a7a_by_country, "recipient_form") %>%
    filter(n > 0) %>%
    arrange(desc(share_country_equal)) %>%
    pull(recipient_form) %>%
    as.character()


  ## --- A7(b): design profile, one row per country (unit: country) ---
  ## The four shares of Table A1 (01_descriptives.R), recomputed on the set:
  ##   E3_share, hard_commitment_share, fund_agency_share: share of the country's earmarked instruments;
  ##   benefit_linked_share: share of its instrument × cofog_division links (null benefit_link excluded).
  ## documents_read and law_year_median (context column) are taken from Table A1: they do not depend on the set.
  profile <- instruments %>%
    group_by(country) %>%
    summarise(n_earmarked = n(),
              E3_share = mean(e_class == "E3"),
              hard_commitment_share = mean(commitment == "hard"),
              fund_agency_share = mean(fund_agency),
              .groups = "drop") %>%
    left_join(benefit_pairs %>%
                group_by(country) %>%
                summarise(n_benefit_pairs = n(),
                          benefit_linked_share = mean(benefit_link %in% benefit_linked_classes)),
              by = "country") %>%
    left_join(country_info, by = "country") %>%
    left_join(table_a1_01 %>% select(country, documents_read, law_year_median), by = "country") %>%
    mutate(set = set_label[[s]], unit = "country") %>%
    select(set, unit, country, legal_family, design_group, resource_group, documents_read, n_earmarked,
           n_benefit_pairs, E3_share, hard_commitment_share, benefit_linked_share, fund_agency_share,
           law_year_median) %>%
    arrange(design_group, country)

  if (nrow(profile) != 43 || any(is.na(profile))) stop(s, ": A7b profile should have 43 complete rows")
  for (v in names(measure_labels)) check_share(profile[[v]], paste(s, "A7b", v))

  ## The headline measures are those of Table A1, country by country
  if (s == "headline") {
    check_b <- profile %>%
      inner_join(table_a1_01 %>% select(country, n_earmarked_01 = n_earmarked, exclusive_share,
                                        hard_01 = hard_commitment_share, benefit_01 = benefit_linked_share,
                                        fund_01 = fund_agency_share),
                 by = "country")
    if (nrow(check_b) != 43) stop("A7b: countries differ from 01_tableA1.csv")
    if (any(check_b$n_earmarked != check_b$n_earmarked_01)) stop("A7b: n_earmarked differs from 01_tableA1.csv")
    if (any(abs(check_b$E3_share - check_b$exclusive_share) > 1e-9 |
            abs(check_b$hard_commitment_share - check_b$hard_01) > 1e-9 |
            abs(check_b$benefit_linked_share - check_b$benefit_01) > 1e-9 |
            abs(check_b$fund_agency_share - check_b$fund_01) > 1e-9)) {
      stop("A7b: a country measure differs from 01_tableA1.csv")
    }
  }

  ## Group summary of the four measures (unit: country): n, median, min and max per design_group
  a7b_groups <- profile %>%
    pivot_longer(all_of(names(measure_labels)), names_to = "measure", values_to = "value") %>%
    group_by(design_group, measure) %>%
    summarise(n_countries = n(), median = median(value), min = min(value), max = max(value), .groups = "drop") %>%
    mutate(note = ifelse(design_group %in% main_groups, "", "2-country group: not interpreted as a group"),
           measure = factor(measure, levels = names(measure_labels)),
           set = set_label[[s]], unit = "country (median, min, max of country shares)") %>%
    arrange(measure, design_group) %>%
    select(set, unit, measure, design_group, n_countries, median, min, max, note)


  ## --- A7(c): the pre-specified check (unit: country) ---
  ## For each measure, a fractional logit (Papke-Wooldridge: glm, quasibinomial, logit link) of the country share on
  ## design_group + resource_group + log(documents_read). Unweighted: one country = one observation, so the
  ## country, not the instrument, is the unit, as in the country-equal shares. HC3 standard errors (sandwich).
  ## Reference groups: francophone_noncfa, so that the design_group coefficients are the main contrasts
  ## (UEMOA and CEMAC vs non-CFA francophone; anglophone vs non-CFA francophone); non_resource_intensive, the
  ## largest resource group. The two 2-country groups keep their own dummies.
  ## Associations only: legal tradition, CFA membership and colonial history are confounded with every
  ## institutional variable (ANALYSIS_SPEC §3), and 43 countries with 10 parameters give imprecise contrasts.
  reg_data <- profile %>%
    mutate(design_group = relevel(factor(design_group), ref = "francophone_noncfa"),
           resource_group = relevel(factor(resource_group), ref = "non_resource_intensive"),
           log_documents = log(documents_read))

  models <- list()
  vcovs  <- list()
  predicted <- list()
  for (m in names(measure_labels)) {
    fit <- glm(as.formula(paste(m, "~ design_group + resource_group + log_documents")),
               family = quasibinomial(link = "logit"), data = reg_data)
    if (nobs(fit) != 43) stop(s, " A7c ", m, ": ", nobs(fit), " observations, not 43")
    ## HC3 divides each residual by (1 - leverage): undefined for a country with leverage 1
    if (max(hatvalues(fit)) > 0.99) stop(s, " A7c ", m, ": a country has leverage near 1, HC3 undefined")
    V <- vcovHC(fit, type = "HC3")
    models[[measure_labels[[m]]]] <- fit
    vcovs[[measure_labels[[m]]]]  <- V

    ## Predicted share of each main group at the sample means of the controls: the resource dummies at their
    ## sample shares, log documents at its mean, the design dummies set to the group.
    ## 95% interval by the delta method with the HC3 covariance: on the logit scale, where the prediction is
    ## linear in the coefficients, then transformed back, so the bounds stay in [0, 1]. se_share is the
    ## delta-method standard error of the share itself (dlogis(eta) * se of eta).
    b <- coef(fit)
    x_mean <- colMeans(model.matrix(fit))
    design_terms <- grep("^design_group", names(b), value = TRUE)
    for (g in main_groups) {
      x <- x_mean
      x[design_terms] <- 0
      if (g != "francophone_noncfa") x[paste0("design_group", g)] <- 1
      eta <- sum(x * b)
      se_eta <- sqrt(as.numeric(t(x) %*% V %*% x))
      predicted[[paste(m, g)]] <- data.frame(measure = m, design_group = g,
                                             n_countries = sum(profile$design_group == g),
                                             predicted_share = plogis(eta),
                                             se_share = dlogis(eta) * se_eta,
                                             ci_low = plogis(eta - 1.96 * se_eta),
                                             ci_high = plogis(eta + 1.96 * se_eta))
    }
  }
  a7c_predicted <- bind_rows(predicted) %>%
    mutate(set = set_label[[s]], unit = "country (fractional logit, HC3; controls at sample means)") %>%
    select(set, unit, measure, design_group, n_countries, predicted_share, se_share, ci_low, ci_high)
  for (v in c("predicted_share", "ci_low", "ci_high")) check_share(a7c_predicted[[v]], paste(s, "A7c", v))

  ## Regression table: coefficients (logit scale) with HC3 standard errors in brackets, and n. No stars.
  coef_names <- c("design_groupuemoa_francophone" = "UEMOA francophone",
                  "design_groupcemac_francophone" = "CEMAC francophone",
                  "design_groupanglophone_common" = "Anglophone common law",
                  "design_grouplusophone_noncfa"  = "Lusophone, non-CFA",
                  "design_groupcfa_nonfrancophone" = "CFA, non-francophone (GNB, GNQ; own dummy)",
                  "design_groupmixed" = "Mixed (RWA, ETH; own dummy)",
                  "resource_groupoil_exporter" = "Oil exporter",
                  "resource_groupother_resource_intensive" = "Other resource-intensive",
                  "log_documents" = "log(documents read)",
                  "(Intercept)" = "Intercept")
  if (!setequal(names(coef_names), names(coef(models[[1]])))) stop(s, ": A7c coefficient names changed")
  table_rows <- data.frame(term = c("Unit", "Weights", "Standard errors"),
                           matrix(c(rep("country", 4), rep("none (one country = one observation)", 4),
                                    rep("HC3", 4)), nrow = 3, byrow = TRUE))
  names(table_rows) <- c("term", names(models))
  a7c_table <- modelsummary(models, vcov = vcovs, statistic = "std.error", stars = FALSE, fmt = 3,
                            coef_map = coef_names, gof_map = "nobs", add_rows = table_rows,
                            output = "data.frame")
  a7c_notes <- c(
    "Fractional logit (glm, quasibinomial, logit link), country level; coefficients on the logit scale.",
    "Reference groups: Francophone, non-CFA (5 countries: BDI, COD, COM, GIN, MDG) and non-resource-intensive.",
    paste("The 2-country groups (GNB, GNQ; RWA, ETH) stay out of the group contrasts through their own dummies,",
          "but still inform the resource and documents coefficients through differences within each pair."),
    "The reference group has 5 countries, so the contrasts are imprecise.",
    "Associations only, not effects of legal tradition or CFA membership.")
  a7c_table <- bind_rows(a7c_table %>% mutate(across(everything(), as.character)),
                         data.frame(part = "note", term = a7c_notes))
  a7c_table[is.na(a7c_table)] <- ""
  a7c_table <- a7c_table %>% mutate(set = set_label[[s]]) %>% select(set, everything())
  n_obs <- sapply(models, nobs)
  if (any(n_obs != 43)) stop(s, ": a regression does not have 43 observations")


  ## --- Summary of the set ---
  cat("\n[", s, "]", set_label[[s]], "\n")
  cat("Earmarked instruments:", nrow(instruments), " | restricted top-level allocations:", nrow(allocations), "\n")
  a4_all <- bind_rows(a4_instrument, a4_allocation) %>% filter(group == "all countries")
  for (m in c("commitment_strength", "vehicle_class")) {
    x <- a4_all %>% filter(measure == m)
    cat("A4", m, "(country-equal):", paste(x$category, round(x$share_country_equal, 3), collapse = " | "), "\n")
  }
  x <- a4_all %>% filter(measure %in% c("legal_rank", "determinacy"), category %in% c("ordinary_law", "determinate"))
  cat("A4 ordinary_law share", round(x$share_country_equal[x$category == "ordinary_law"], 3),
      " | determinate share", round(x$share_country_equal[x$category == "determinate"], 3), "(country-equal)\n")
  x <- a7b_groups %>% filter(design_group %in% main_groups, measure == "hard_commitment_share")
  cat("A7b hard-commitment median by group:", paste(x$design_group, round(x$median, 3), collapse = " | "), "\n")
  cat("A7c regressions: n =", paste(n_obs, collapse = ", "), "\n")

  results[[s]] <- list(a4_instrument = a4_instrument, a4_allocation = a4_allocation, a7a = a7a, profile = profile,
                       a7b_groups = a7b_groups, a7c_table = a7c_table, a7c_predicted = a7c_predicted,
                       form_rank = form_rank, n_instruments = nrow(instruments), n_allocations = nrow(allocations))


  ## --- Write the tables of the set ---
  write.csv(a4_instrument, file.path(dir_tables, paste0("04_A4_instrument", set_suffix[[s]], ".csv")), row.names = FALSE)
  write.csv(a4_allocation, file.path(dir_tables, paste0("04_A4_allocation", set_suffix[[s]], ".csv")), row.names = FALSE)
  write.csv(a7a, file.path(dir_tables, paste0("04_A7a_recipient_form", set_suffix[[s]], ".csv")), row.names = FALSE)
  write.csv(profile, file.path(dir_tables, paste0("04_A7b_profile", set_suffix[[s]], ".csv")), row.names = FALSE)
  write.csv(a7b_groups, file.path(dir_tables, paste0("04_A7b_group_summary", set_suffix[[s]], ".csv")), row.names = FALSE)
  write.csv(a7c_table, file.path(dir_tables, paste0("04_A7c_regressions", set_suffix[[s]], ".csv")), row.names = FALSE)
  write.csv(a7c_predicted, file.path(dir_tables, paste0("04_A7c_predicted", set_suffix[[s]], ".csv")), row.names = FALSE)
}


## ============================================================================
## Figures: headline set only (social contributions excluded, placeholders included)
## ============================================================================
headline <- results$headline
caption_set <- "Earmarked instruments and classes of charges (E2 + E3), social contributions excluded."


## --- A4: commitment strength, overall and by legal family ---
## Ordinal stacking soft -> firm -> hard (pal_commitment), so bars are not reordered by size. Each bar is labelled
## with its number of countries. Labels are ink on the light "soft" segment, white on the darker ones.
group_order <- c("all countries", names(family_labels))
fig_a4_data <- headline$a4_instrument %>%
  filter(measure == "commitment_strength") %>%
  mutate(commitment = factor(category, levels = c("soft", "firm", "hard")),
         group_label = ifelse(group == "all countries", "All countries", family_labels[group]),
         group_label = paste0(group_label, " (", countries_in_mean, ")"),
         group_rank  = match(group, group_order))
fig_a4_data$group_label <- factor(fig_a4_data$group_label,
                                  levels = rev(unique(fig_a4_data$group_label[order(fig_a4_data$group_rank)])))

fig_a4 <- ggplot(fig_a4_data, aes(x = share_country_equal, y = group_label, fill = commitment)) +
  geom_col(width = 0.7, position = position_stack(reverse = TRUE)) +
  geom_text(aes(label = ifelse(share_country_equal >= 0.06, scales::percent(share_country_equal, accuracy = 1), ""),
                colour = commitment == "soft", group = commitment),   # group: stack the labels like the bars
            position = position_stack(vjust = 0.5, reverse = TRUE), size = 3.6) +
  scale_fill_manual(values = pal_commitment[c("soft", "firm", "hard")], labels = commitment_labels) +
  scale_colour_manual(values = c(`TRUE` = col_ink, `FALSE` = "white"), guide = "none") +
  scale_x_continuous(labels = scales::percent, expand = c(0, 0)) +
  labs(title = "How binding earmarks are: commitment strength",
       x = "Share of earmarked instruments (country-equal within each group)", y = NULL,
       caption = paste0("Unit: instrument (n = ", headline$n_instruments, "); commitment = the strongest of its",
                        " restricted legs. In brackets: number of countries.\nHard: determinate share, dedicated",
                        " vehicle, constitution, organic or ordinary law. Firm: determinate, but through a\nministry,",
                        " programme or finance law only. Soft: share not determinate, or set by regulation.\n",
                        caption_set)) +
  theme(plot.margin = margin(10, 24, 10, 10))
save_fig(fig_a4, "04_A4_commitment", width = 9, height = 4.5)


## --- A7(a): recipient form by design group, then the 4 countries outside the groups ---
## The 5 forms coloured in A2b (largest country-equal shares over 43 countries) plus Other, so the colours match
## 02_A2b_recipient_form. Groups in design order (top), then the 4 countries by name (bottom panel, no group bar
## for cfa_nonfrancophone or mixed).
top_forms <- headline$form_rank[1:5]
if (!identical(top_forms, a2b_02$recipient_form[1:5])) stop("A7a: the 5 largest forms differ from 02_A2b_recipient_form.csv")
other_forms <- setdiff(headline$form_rank, top_forms)
fig_a7a_data <- headline$a7a %>%
  filter((level == "design_group" & group %in% main_groups) | level == "country") %>%
  mutate(form = ifelse(recipient_form %in% top_forms, form_labels[recipient_form], "Other"),
         bar = ifelse(level == "design_group",
                      paste0(design_labels[group], " (", countries_in_mean, ")"),
                      single_countries[group]),
         panel = ifelse(level == "design_group", "groups", "countries")) %>%
  group_by(panel, group, bar, form) %>%
  summarise(share = sum(share_country_equal), .groups = "drop") %>%
  mutate(form = factor(form, levels = c(form_labels[top_forms], "Other")),
         panel = factor(panel, levels = c("groups", "countries")))
bar_order <- c(paste0(design_labels[main_groups], " (", design_n$n[match(main_groups, design_n$design_group)], ")"),
               single_countries)
fig_a7a_data$bar <- factor(fig_a7a_data$bar, levels = rev(bar_order))

fig_a7a <- ggplot(fig_a7a_data, aes(x = share, y = bar, fill = form)) +
  geom_col(width = 0.7, position = position_stack(reverse = TRUE)) +
  geom_text(aes(label = ifelse(share >= 0.06, scales::percent(share, accuracy = 1), "")),
            position = position_stack(vjust = 0.5, reverse = TRUE), colour = "white", size = 3.4) +
  facet_grid(panel ~ ., scales = "free_y", space = "free_y") +
  scale_fill_manual(values = c(setNames(pal_cat[1:5], form_labels[top_forms]), Other = col_grey)) +
  scale_x_continuous(labels = scales::percent, expand = c(0, 0)) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE)) +
  labs(title = "Recipient form of restricted allocations, by design group",
       x = "Share of allocations (country-equal within each group)", y = NULL,
       caption = paste0("Unit: allocation, top level, restricted legs of earmarked instruments (n = ",
                        headline$n_allocations, "; a pool counted once). In brackets: number of countries.\n",
                        "Top: shares within each country, averaged over the group. Bottom: the four countries",
                        " outside the five groups,\nwith their own shares. Legal forms as written, not budget status.\n",
                        "Other: ", paste(form_labels[other_forms], collapse = ", "), ".\n", caption_set)) +
  theme(strip.text = element_blank(),
        panel.spacing.y = unit(0.9, "cm"),
        legend.text = element_text(size = rel(0.85)),
        plot.margin = margin(10, 24, 10, 10))
save_fig(fig_a7a, "04_A7a_recipient_form", width = 10, height = 5.5)


## --- A7(b): design profile, small multiples ---
## One panel per share; rows = the 5 main groups (n in the label) and a last row for the 4 countries outside the
## groups (grey, labelled by ISO3). Country dots in pal_design, jittered vertically with a fixed seed so that ties
## stay visible; the group median is the ink tick.
row_labels <- c(setNames(paste0(design_labels[main_groups], " (n = ",
                                design_n$n[match(main_groups, design_n$design_group)], ")"), main_groups),
                outside = "Outside the groups (4)")
fig_a7b_data <- headline$profile %>%
  pivot_longer(all_of(names(measure_labels)), names_to = "measure", values_to = "value") %>%
  mutate(row = ifelse(design_group %in% main_groups, as.character(design_group), "outside"),
         row = factor(row_labels[row], levels = rev(row_labels)),
         measure = factor(measure_labels[measure], levels = measure_labels))
fig_a7b_medians <- fig_a7b_data %>%
  filter(design_group %in% main_groups) %>%
  group_by(measure, row) %>%
  summarise(median = median(value), .groups = "drop")

fig_a7b <- ggplot(fig_a7b_data, aes(x = value, y = row)) +
  geom_point(aes(colour = design_group), size = 2.2, alpha = 0.85,
             position = position_jitter(width = 0, height = 0.15, seed = 1)) +
  geom_point(data = fig_a7b_medians, aes(x = median), shape = 124, size = 7, colour = col_ink) +
  ggrepel::geom_text_repel(data = fig_a7b_data %>% filter(row == row_labels[["outside"]]),
                           aes(label = country), size = 3, colour = col_ink, seed = 1,
                           direction = "x", nudge_y = 0.35, segment.colour = col_grey, min.segment.length = 0) +
  facet_wrap(~ measure, ncol = 2) +
  scale_colour_manual(values = pal_design, guide = "none") +
  scale_x_continuous(labels = scales::percent, limits = c(0, 1), expand = expansion(mult = c(0.02, 0.04))) +
  labs(title = "Design profile of earmarks, by design group",
       x = "Country share", y = NULL,
       caption = paste0("Unit: country (one dot per country); tick: group median. E3, hard-commitment and",
                        " fund-or-agency shares: share of the\ncountry's earmarked instruments. Benefit-linked share:",
                        " share of its instrument x COFOG division links (unknown function\nexcluded). Grey:",
                        " GNB, GNQ (CFA, non-francophone) and RWA, ETH (mixed), not groups.\n", caption_set)) +
  theme(panel.spacing.x = unit(0.8, "cm"),
        panel.spacing.y = unit(0.5, "cm"),
        plot.margin = margin(10, 24, 10, 10))
save_fig(fig_a7b, "04_A7b_profile", width = 10, height = 7)


## --- Summary ---
cat("\nTables:", length(results) * 7, "files 04_*.csv in", dir_tables, "\n")
cat("Figures: 04_A4_commitment, 04_A7a_recipient_form, 04_A7b_profile (PDF + PNG) in", dir_figures, "\n")
