## ============================================================================
## 05_territorial.R — A6 (territorial and regional channels): subnational sharing and decentralisation, and one
## count of allocations to regional bodies
## ANALYSIS_SPEC §0 and §2 (A6 row); units in DERIVED_TABLE_SPEC §3; figures by docs/PLOT_STYLE.md.
## Inputs: the analysis .rds (00_load.R, with base_group).
## Set: the assigned instruments (E1 + E2 + E3), not the earmarked set: E1 is mostly unrestricted sharing with
## subnational tiers, which is what A6 describes. Three instrument sets, each written to its own tables:
##   headline: assigned, social contributions excluded        -> 05_*.csv, and the figure
##   sc:       assigned, social contributions included        -> 05_*_sc.csv, tables only
##   nopl:     headline without class placeholders            -> 05_*_nopl.csv, tables only
## Unit: allocation with recipient_level = subnational, a pool counted once (distinct country × allocation_id).
## Levels: all share levels. A6 is where the sub-keys sit (ANALYSIS_SPEC §0), so a level-2 sub-key counts as an
## allocation of its own; top_level tells them apart (allocations below the top level: top_level = 0).
## Counts only: no money, and no shares added across levels. No weights.
## Outputs: 05_A6_subnational_by_country, 05_A6_incidence, 05_A6_regional_count (one file per set) in
## dir_tables; 1 figure (PDF + PNG) in dir_figures.
## ============================================================================

source(here::here("analysis", "paths.R"))
source(here::here("analysis", "theme_earmark.R"))  # colours, theme, save_fig()

library(dplyr)
library(tidyr)
library(ggplot2)

earmarks <- readRDS(file_analysis_rds)
if (!"base_group" %in% names(earmarks)) stop("Re-run 00_load.R: the .rds has no base_group")


## --- Classes and labels ---
## Type of sharing (assignment_type), in the order of the A6 row. community_levy_external is a level of the
## column but never occurs on a subnational allocation; it is checked below, not shown.
type_levels <- c("tax_sharing_general", "tax_sharing_specific", "equalization_transfer", "derivation_transfer",
                 "hybrid_devolved_earmark", "earmark_functional")
type_labels <- c(tax_sharing_general = "General tax sharing", tax_sharing_specific = "Specific tax sharing",
                 equalization_transfer = "Equalisation transfer", derivation_transfer = "Derivation transfer",
                 hybrid_devolved_earmark = "Devolved earmark",
                 earmark_functional = "Functional earmark of a tier's body")

## Restricted vs unrestricted, by leg_class (DERIVED_TABLE_SPEC §2.1), in three classes (decision of 2 Nov 2026):
## administrative retentions (cost recovery, staff payments, refund reserves) are never earmarks, so they are
## kept apart from the restricted legs even though their is_purpose_restricted = 1.
restriction_levels <- c("restricted", "retention", "unrestricted")
retention_classes  <- c("cost_recovery", "staff_payment", "refund_reserve")

caveat_regional <- "recorded only where a national text restates the levy; community acts were not collected"


## --- Countries ---
countries <- earmarks %>% distinct(country) %>% arrange(country)
if (nrow(countries) != 43) stop("Expected 43 countries, found ", nrow(countries))


## --- Instrument sets (ANALYSIS_SPEC §0) ---
## The assigned filter (E1 + E2 + E3) is applied below, so the three sets are those of 02 and 04.
sets <- list(headline = earmarks %>% filter(!social_contribution),
             sc       = earmarks,
             nopl     = earmarks %>% filter(!social_contribution, row_kind != "class_placeholder"))
set_suffix <- c(headline = "", sc = "_sc", nopl = "_nopl")
set_label  <- c(headline = "assigned (E1+E2+E3), social contributions excluded",
                sc       = "assigned (E1+E2+E3), social contributions included",
                nopl     = "assigned (E1+E2+E3), social contributions and class placeholders excluded")

unit_country    <- "country; counts of subnational allocations (all share levels, a pool counted once) and of the instruments they share"
unit_allocation <- "allocation with recipient_level = subnational, all share levels, a pool counted once"

## Expected headline counts (read-only check of 2 Nov 2026)
expected_headline <- c(allocations = 763, instruments = 744, countries = 38, restricted = 101, retention = 28,
                       unrestricted = 634, below_top = 68)

results <- list()

for (s in names(sets)) {
  rows <- sets[[s]] %>%
    filter(assigned, recipient_level == "subnational")

  ## Allocation level: one row per (country, allocation_id). A pool shared by several instruments counts once.
  allocations <- rows %>%
    distinct(country, allocation_id, leg_class, assignment_type, top_level, recipient_form)
  if (any(duplicated(allocations[, c("country", "allocation_id")]))) {
    stop(s, ": leg_class, assignment_type, top_level or recipient_form varies within an allocation")
  }
  if (any(allocations$leg_class == "general_budget")) stop(s, ": general_budget leg with recipient_level = subnational")
  other_types <- setdiff(unique(as.character(allocations$assignment_type)), type_levels)
  if (length(other_types) > 0) stop(s, ": assignment_type outside the 6 A6 types: ", paste(other_types, collapse = ", "))
  allocations <- allocations %>%
    mutate(restriction = case_when(leg_class == "restricted"         ~ "restricted",
                                   leg_class %in% retention_classes  ~ "retention",
                                   leg_class == "unrestricted"       ~ "unrestricted"),
           restriction = factor(restriction, levels = restriction_levels),
           assignment_type = factor(as.character(assignment_type), levels = type_levels))
  if (any(is.na(allocations$restriction))) stop(s, ": a subnational allocation has no restriction class")

  ## Instrument level: the instruments with at least one subnational allocation, with their base group
  instruments <- rows %>%
    distinct(country, instrument_id, base_group)
  if (any(duplicated(instruments[, c("country", "instrument_id")]))) stop(s, ": base_group varies within an instrument")


  ## --- By country (unit: country), all 43, zeros where none ---
  ## Base groups: the 3 with the most shared instruments, "group (n)"; ties by the spec order of base_group.
  top_groups <- instruments %>%
    count(country, base_group) %>%
    arrange(country, desc(n), base_group) %>%
    group_by(country) %>%
    slice_head(n = 3) %>%
    summarise(top_base_groups = paste0(base_group, " (", n, ")", collapse = "; "), .groups = "drop")

  type_counts <- allocations %>%
    count(country, assignment_type, .drop = FALSE) %>%
    pivot_wider(names_from = assignment_type, values_from = n, names_prefix = "n_")

  by_country <- countries %>%
    left_join(instruments %>% count(country, name = "n_instruments"), by = "country") %>%
    left_join(allocations %>%
                group_by(country) %>%
                summarise(n_allocations = n(),
                          n_restricted   = sum(restriction == "restricted"),
                          n_retention    = sum(restriction == "retention"),
                          n_unrestricted = sum(restriction == "unrestricted"),
                          n_below_top    = sum(top_level == 0),
                          .groups = "drop"),
              by = "country") %>%
    left_join(type_counts, by = "country") %>%
    left_join(top_groups, by = "country") %>%
    mutate(across(starts_with("n_"), ~ coalesce(as.integer(.x), 0L)),
           top_base_groups = coalesce(top_base_groups, ""),
           set = set_label[[s]], unit = unit_country) %>%
    select(set, unit, country, n_instruments, n_allocations, n_restricted, n_retention, n_unrestricted,
           all_of(paste0("n_", type_levels)), n_below_top, top_base_groups)

  ## Checks: 43 rows; each country's type and restriction counts sum to its allocations; totals = the tables above
  if (nrow(by_country) != 43) stop(s, ": the by-country table should have 43 rows")
  if (any(rowSums(by_country[, paste0("n_", type_levels)]) != by_country$n_allocations)) {
    stop(s, ": type counts do not sum to the allocations in a country")
  }
  if (any(by_country$n_restricted + by_country$n_retention + by_country$n_unrestricted != by_country$n_allocations)) {
    stop(s, ": restriction counts do not sum to the allocations in a country")
  }
  if (sum(by_country$n_allocations) != nrow(allocations) || sum(by_country$n_instruments) != nrow(instruments)) {
    stop(s, ": by-country totals differ from the allocation or instrument tables")
  }

  ## The headline totals are those of the read-only check
  if (s == "headline") {
    totals <- c(allocations  = sum(by_country$n_allocations),
                instruments  = sum(by_country$n_instruments),
                countries    = sum(by_country$n_allocations > 0),
                restricted   = sum(by_country$n_restricted),
                retention    = sum(by_country$n_retention),
                unrestricted = sum(by_country$n_unrestricted),
                below_top    = sum(by_country$n_below_top))
    if (any(totals != expected_headline[names(totals)])) {
      stop("A6 headline totals differ from the expected counts: ",
           paste(names(totals), totals, "vs", expected_headline, collapse = "; "))
    }
    ## Restricted + retention = the 129 allocations with is_purpose_restricted = 1
    if (totals[["restricted"]] + totals[["retention"]] != 129) stop("A6: restricted + retention is not 129")
  }


  ## --- Incidence by type of sharing (unit: allocation; country = at least one allocation of the type) ---
  incidence <- allocations %>%
    group_by(assignment_type, .drop = FALSE) %>%
    summarise(n_countries = n_distinct(country), n_allocations = n(), .groups = "drop") %>%
    mutate(assignment_type = as.character(assignment_type), set = set_label[[s]], unit = unit_allocation) %>%
    select(set, unit, assignment_type, n_countries, n_allocations)
  if (sum(incidence$n_allocations) != nrow(allocations)) stop(s, ": type counts do not sum to the allocations")
  for (t in type_levels) {
    if (incidence$n_countries[incidence$assignment_type == t] != sum(by_country[[paste0("n_", t)]] > 0)) {
      stop(s, ": incidence of ", t, " differs from the by-country table")
    }
  }


  ## --- Regional bodies: one count (unit: allocation) ---
  ## All allocations of the assigned set to a supranational_body, all share levels, a pool counted once.
  regional <- sets[[s]] %>%
    filter(assigned, recipient_form == "supranational_body") %>%
    distinct(country, allocation_id)
  regional_count <- data.frame(set = set_label[[s]],
                               unit = "allocation with recipient_form = supranational_body, all share levels, a pool counted once",
                               n_allocations = nrow(regional),
                               n_countries = n_distinct(regional$country),
                               note = caveat_regional)


  ## --- Summary of the set ---
  ## Payments to collectors and local chiefs (recipient_form = staff_personal_payment) are named: they are
  ## retentions recorded at the subnational level, not sharing with a tier.
  staff_payments <- allocations %>%
    filter(recipient_form == "staff_personal_payment") %>%
    count(country, sort = TRUE)
  cat("\n[", s, "]", set_label[[s]], "\n")
  cat("Subnational allocations:", nrow(allocations), " | instruments shared:", nrow(instruments),
      " | countries with any:", sum(by_country$n_allocations > 0), "of 43\n")
  cat("Restricted", sum(by_country$n_restricted), " | administrative retentions", sum(by_country$n_retention),
      " | unrestricted", sum(by_country$n_unrestricted), " | below the top level", sum(by_country$n_below_top), "\n")
  cat("Of the retentions, payments to tax collectors and local chiefs (staff_personal_payment):",
      sum(staff_payments$n), "(", paste(staff_payments$country, staff_payments$n, collapse = ", "), ")\n")
  cat("By type (allocations / countries):",
      paste(incidence$assignment_type, incidence$n_allocations, "/", incidence$n_countries, collapse = " | "), "\n")
  cat("Countries with none:", paste(by_country$country[by_country$n_allocations == 0], collapse = ", "), "\n")
  cat("Regional bodies: allocations", regional_count$n_allocations, " | countries", regional_count$n_countries, "\n")

  results[[s]] <- list(by_country = by_country, incidence = incidence, regional_count = regional_count,
                       n_allocations = nrow(allocations))


  ## --- Write the tables of the set ---
  write.csv(by_country, file.path(dir_tables, paste0("05_A6_subnational_by_country", set_suffix[[s]], ".csv")), row.names = FALSE)
  write.csv(incidence, file.path(dir_tables, paste0("05_A6_incidence", set_suffix[[s]], ".csv")), row.names = FALSE)
  write.csv(regional_count, file.path(dir_tables, paste0("05_A6_regional_count", set_suffix[[s]], ".csv")), row.names = FALSE)
}


## ============================================================================
## Figure: headline set only
## ============================================================================
headline <- results$headline

## --- A6: subnational allocations by type of sharing, by country ---
## Countries with at least one subnational allocation, ordered by total (ties by ISO3), largest at the top.
## The 6 types fit the 6 pal_cat colours, so nothing is folded into Other; types are stacked and coloured from
## the largest to the smallest headline count.
type_order <- headline$incidence %>% filter(n_allocations > 0) %>% arrange(desc(n_allocations)) %>% pull(assignment_type)
if (length(type_order) > length(pal_cat)) stop("A6 figure: more types than colours; fold the smallest into Other")
fig_a6_by_country <- headline$by_country %>% filter(n_allocations > 0)
country_order <- fig_a6_by_country %>% arrange(n_allocations, desc(country)) %>% pull(country)
fig_a6_data <- fig_a6_by_country %>%
  select(country, all_of(paste0("n_", type_order))) %>%
  pivot_longer(-country, names_to = "assignment_type", names_prefix = "n_", values_to = "n") %>%
  filter(n > 0) %>%
  mutate(assignment_type = factor(assignment_type, levels = type_order),
         country = factor(country, levels = country_order))

fig_a6 <- ggplot(fig_a6_data, aes(x = n, y = country, fill = assignment_type)) +
  geom_col(width = 0.75, position = position_stack(reverse = TRUE)) +
  scale_fill_manual(values = setNames(pal_cat[seq_along(type_order)], type_order), labels = type_labels) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.04))) +
  guides(fill = guide_legend(nrow = 3, byrow = TRUE)) +
  labs(title = "Subnational allocations, by type of sharing",
       x = "Number of allocations", y = NULL,
       caption = paste0("Unit: allocation to or through a subnational tier (recipient_level = subnational),\n",
                        "all share levels, a pool counted once (n = ", headline$n_allocations, " in ",
                        nrow(fig_a6_by_country), " countries; ", 43 - nrow(fig_a6_by_country), " countries have none).\n",
                        "Assigned instruments and classes of charges (E1 + E2 + E3), social contributions excluded.\n",
                        "Counts, not revenue: a sub-key (a share of a share) counts as an allocation of its own.\n",
                        "Raw counts depend on corpus completeness.")) +
  theme(axis.text.y = element_text(size = 9),
        legend.text = element_text(size = rel(0.85)))
save_fig(fig_a6, "05_A6_subnational", width = 8, height = 9)


## --- Summary ---
cat("\nTables:", length(results) * 3, "files 05_*.csv in", dir_tables, "\n")
cat("Figure: 05_A6_subnational (PDF + PNG) in", dir_figures, "\n")
