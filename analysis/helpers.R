## ============================================================================
## helpers.R — rules shared by several scripts, so that every script reads the same legs and links
## Source it after paths.R:  source(here::here("analysis", "helpers.R"))
## Used by 01_descriptives.R (Table A1) and 02_composition.R (A1–A3).
## ============================================================================

library(dplyr)


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
