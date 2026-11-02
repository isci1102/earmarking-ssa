## ============================================================================
## 12_pefa.R — B2: earmarking and budget comprehensiveness (ANALYSIS_SPEC §3, B2 and common reporting)
## Question: do countries whose earmarks run through funds and agencies score lower on the reporting of
## revenue and units outside the budget?
## Inputs: the analysis .rds (00_load.R), the external indicators .rds (10_external_prepare.R), helpers.R
## (design shares, Spearman with leave-one-out), 01_tableA1.csv (check of the shares) and
## 10_external_sources.csv (check of the PEFA n).
## Outputs: 12_B2_pefa.csv (every PEFA score × share × version, incl. within legal family), 12_B2_pefa_countries.csv
## (one row per country with a PEFA) in dir_tables; figure 12_B2_pefa.
## Unit: country with a 2016-framework PEFA, unweighted; the latest assessment, with its year.
## Earmarking measures: the fund-or-agency share, an INTERIM measure (legal form as written, not budget status)
## until budget_status is built (PROJECT_STATE, issue (d)); the hard-commitment share as a second measure.
## PEFA PI-6 as ordinal grades: A = 4, B = 3, C = 2, D = 1; D* (insufficient information) coded D and flagged;
## NR (not rated) missing. The "+" of the overall PI-6 (M2 aggregation) is dropped: B+ = 3, C+ = 2, D+ = 1
## (decision of 2 Nov 2026). Read as associations: causality can run both ways.
## ============================================================================

source(here::here("analysis", "paths.R"))
source(here::here("analysis", "helpers.R"))         # get_design_shares(), spearman_loo()
source(here::here("analysis", "theme_earmark.R"))

library(dplyr)
library(tidyr)

earmarks <- readRDS(file_analysis_rds)
external <- readRDS(file_external_rds)

file_table_a1 <- file.path(dir_tables, "01_tableA1.csv")
file_sources  <- file.path(dir_tables, "10_external_sources.csv")
for (f in c(file_table_a1, file_sources)) {
  if (!file.exists(f)) stop("Run 01_descriptives.R and 10_external_prepare.R first: ", f, " not found")
}
table_a1_01 <- read.csv(file_table_a1)
sources     <- read.csv(file_sources)

share_labels <- c(fund_agency_share = "Fund-or-agency share (interim: legal form)",
                  hard_commitment_share = "Hard-commitment share")

## PEFA scores: prefix in the external .rds, label, and the n of ANALYSIS_SPEC §3 (B2)
pefa_scores <- data.frame(
  score = c("pi6", "pi6_2", "pi6_3"),
  score_label = c("PI-6 Central government operations outside financial reports (overall)",
                  "PI-6.2 Revenue outside financial reports",
                  "PI-6.3 Financial reports of extrabudgetary units"),
  n_expected = c(31, 28, 29)
)


## --- Design shares of the headline set, checked against Table A1 ---
shares <- get_design_shares(earmarks %>% filter(!social_contribution))

check_a1 <- shares %>%
  inner_join(table_a1_01 %>% select(country, n_earmarked_01 = n_earmarked, exclusive_01 = exclusive_share,
                                    hard_01 = hard_commitment_share, fund_01 = fund_agency_share,
                                    benefit_01 = benefit_linked_share),
             by = "country")
if (nrow(shares) != 43 || nrow(check_a1) != 43) stop("Design shares: countries differ from 01_tableA1.csv")
if (any(check_a1$n_earmarked != check_a1$n_earmarked_01)) stop("Design shares: n_earmarked differs from 01_tableA1.csv")
if (any(abs(check_a1$exclusive_share - check_a1$exclusive_01) > 1e-9 |
        abs(check_a1$hard_commitment_share - check_a1$hard_01) > 1e-9 |
        abs(check_a1$fund_agency_share - check_a1$fund_01) > 1e-9 |
        abs(check_a1$benefit_linked_share - check_a1$benefit_01) > 1e-9)) {
  stop("Design shares: a country share differs from 01_tableA1.csv")
}


## --- Country data: the countries with a 2016-framework PEFA ---
country_info <- earmarks %>% distinct(country, legal_family, design_group, resource_group)

pefa_cols <- c("pefa_year", paste0(rep(pefa_scores$score, each = 3), c("_letter", "_ord", "_dstar")))
b2_data <- external %>%
  select(country = iso3, all_of(pefa_cols)) %>%
  filter(!is.na(pefa_year)) %>%
  left_join(country_info, by = "country") %>%
  left_join(shares %>% select(country, n_earmarked, all_of(names(share_labels))), by = "country") %>%
  arrange(country)

if (nrow(b2_data) != 31) stop("B2: expected 31 countries with a PEFA, not ", nrow(b2_data))
if (any(is.na(b2_data$resource_group) | is.na(b2_data$fund_agency_share))) stop("B2: a PEFA country is not in the database")

## The n of each score is the one of 10_external_sources.csv (31, 28, 29)
for (i in 1:nrow(pefa_scores)) {
  s <- pefa_scores$score[i]
  n_data    <- sum(!is.na(b2_data[[paste0(s, "_ord")]]))
  n_sources <- sources$n_countries[sources$variable == paste0(s, "_ord")]
  if (length(n_sources) != 1 || n_data != n_sources || n_data != pefa_scores$n_expected[i]) {
    stop("B2: ", s, " has ", n_data, " graded countries; 10_external_sources.csv or the spec says otherwise")
  }
}

## Flags reported with the results: D* per score, and the "+" grades of the overall PI-6
n_plus <- sum(grepl("+", b2_data$pi6_letter, fixed = TRUE))


## --- Spearman rho, n and leave-one-out range: every PEFA score × share × version ---
## Versions (ANALYSIS_SPEC §0, external data window):
##   latest:    the latest 2016-framework assessment of each country (main);
##   from_2018: the same, restricted to assessments from 2018 or later.
versions <- data.frame(
  version = c("latest", "from_2018"),
  version_label = c("Latest 2016-framework assessment", "Latest assessment, from 2018 or later"),
  min_year = c(-Inf, 2018)
)

## One row of the table: rho of one share with one score on a set of countries, the years of the graded
## assessments, and how many grades are D (D* included) or above D. With most grades at D, rho mostly compares
## the D countries with the few others, so n_above_D says how many countries carry the correlation.
b2_row <- function(rows_v, p, s, version) {
  grade  <- rows_v[[paste0(p, "_ord")]]
  graded <- !is.na(grade)
  data.frame(version = version, score = p, share = s,
             spearman_loo(rows_v[[s]], grade, rows_v$country, paste(version, p, s)),
             year_min = min(rows_v$pefa_year[graded]),
             year_max = max(rows_v$pefa_year[graded]),
             n_grade_D = sum(grade %in% 1),
             n_above_D = sum(grade %in% 2:4),
             n_dstar = sum(rows_v[[paste0(p, "_dstar")]][graded] %in% 1))
}

b2 <- data.frame()
for (i in 1:nrow(versions)) {
  rows_v <- b2_data %>% filter(pefa_year >= versions$min_year[i])
  for (p in pefa_scores$score) {
    for (s in names(share_labels)) {
      b2 <- bind_rows(b2, b2_row(rows_v, p, s, versions$version[i]))
    }
  }
}

## Within legal tradition (decision of 2 Nov 2026): the whole grid (3 scores × 2 shares, latest assessment),
## computed separately among the anglophone_common and francophone_civil countries with a PEFA grade. All 12
## correlations are reported; none is selected. The samples are small, and among francophone countries almost every
## grade is D: a rho resting on 2 or fewer countries graded above D is reported but cannot be read.
families <- c("anglophone_common", "francophone_civil")
for (fam in families) {
  rows_f <- b2_data %>% filter(as.character(legal_family) == fam)
  for (p in pefa_scores$score) {
    for (s in names(share_labels)) {
      b2 <- bind_rows(b2, b2_row(rows_f, p, s, "within_family") %>% mutate(legal_family = fam))
    }
  }
}

versions_extra <- data.frame(version = "within_family",
                             version_label = "Within legal family (anglophone_common or francophone_civil), latest assessment")

b2 <- b2 %>%
  left_join(bind_rows(versions %>% select(version, version_label), versions_extra), by = "version") %>%
  left_join(pefa_scores %>% select(score, score_label), by = "score") %>%
  mutate(share_label = share_labels[share],
         unit = "country",
         note = ifelse(score == "pi6",
                       paste0("'+' dropped (B+ = 3, C+ = 2, D+ = 1): ", n_plus, " of 31 latest overall grades carry a '+'"),
                       "D* coded D"),
         note = ifelse(n_above_D <= 2,
                       paste0(note, "; rests on ", n_above_D, ifelse(n_above_D == 1, " country", " countries"), " graded above D: cannot be read"), note)) %>%
  select(version, version_label, legal_family, score, score_label, share, share_label, unit, n, rho, loo_min, loo_max,
         loo_min_drop, loo_max_drop, loo_undefined, year_min, year_max, n_grade_D, n_above_D, n_dstar, note)

## Checks: 3 scores × 2 shares × 2 versions, plus the same grid in 2 families; the n of the main version and of
## each family (the number of graded countries of the family in the PEFA data); every rho in [-1, 1]
if (sum(b2$version %in% versions$version) != 3 * 2 * 2) stop("B2: expected 12 rows in the two main versions")
if (sum(b2$version == "within_family") != 3 * 2 * 2) stop("B2: expected 12 within-family rows")
for (fam in families) {
  for (p in pefa_scores$score) {
    n_fam <- sum(as.character(b2_data$legal_family) == fam & !is.na(b2_data[[paste0(p, "_ord")]]))
    if (any(b2$n[b2$version == "within_family" & b2$legal_family %in% fam & b2$score == p] != n_fam)) {
      stop("B2: n of ", p, " within ", fam, " differs from the graded countries of the family")
    }
  }
}
if (any(b2$n_grade_D + b2$n_above_D != b2$n)) stop("B2: grades D and above D do not sum to n")
for (i in 1:nrow(pefa_scores)) {
  if (any(b2$n[b2$version == "latest" & b2$score == pefa_scores$score[i]] != pefa_scores$n_expected[i])) {
    stop("B2: n of ", pefa_scores$score[i], " differs from ", pefa_scores$n_expected[i])
  }
}
if (any(b2$n[b2$version == "from_2018"] > b2$n[b2$version == "latest"])) stop("B2: the 2018 version has more countries")
if (any(b2$year_min[b2$version == "from_2018"] < 2018)) stop("B2: an assessment before 2018 in the 2018 version")
if (any(is.na(b2$rho) | abs(b2$rho) > 1 | b2$loo_min < -1 | b2$loo_max > 1)) stop("B2: a rho outside [-1, 1]")


## --- Country table: grades as published (D* kept), year, the two shares ---
## Letter with its star: the external .rds stores the letter without "*" and a D* flag
grade_shown <- function(letter, dstar) ifelse(is.na(letter), "NR", ifelse(dstar %in% 1, paste0(letter, "*"), letter))
b2_countries <- b2_data %>%
  transmute(country, unit = "country", legal_family, design_group, resource_group, pefa_year,
            pi6 = grade_shown(pi6_letter, pi6_dstar),
            pi6_2 = grade_shown(pi6_2_letter, pi6_2_dstar),
            pi6_3 = grade_shown(pi6_3_letter, pi6_3_dstar),
            pi6_ord, pi6_2_ord, pi6_3_ord,
            n_earmarked, fund_agency_share, hard_commitment_share)
## "NR" here means no grade: not rated or not applicable in the PEFA file (both are missing in the analysis)
if (sum(b2_countries$pi6_2 != "NR") != 28 || sum(b2_countries$pi6_3 != "NR") != 29) stop("B2: country table grades")


## --- Figure: fund-or-agency share by grade, PI-6.2 and PI-6.3 ---
## Labelled points (ISO3), coloured by resource_group (first 3 slots of pal_cat; PLOT_STYLE rule 1). D* hollow.
## Vertical jitter drawn once with a fixed seed and stored in the data, so that labels follow their points.
resource_labels <- c(oil_exporter = "Oil exporters", other_resource_intensive = "Other resource-intensive",
                     non_resource_intensive = "Non-resource-intensive")
pal_resource <- setNames(pal_cat[1:3], names(resource_labels))
panel_labels <- c(pi6_2 = "PI-6.2 Revenue outside financial reports",
                  pi6_3 = "PI-6.3 Financial reports of extrabudgetary units")

fig_data <- bind_rows(
  b2_data %>% transmute(country, resource_group, fund_agency_share, score = "pi6_2", grade = pi6_2_ord, dstar = pi6_2_dstar),
  b2_data %>% transmute(country, resource_group, fund_agency_share, score = "pi6_3", grade = pi6_3_ord, dstar = pi6_3_dstar)
) %>%
  filter(!is.na(grade)) %>%
  mutate(grade_type = ifelse(dstar %in% 1, "D* (insufficient information, scored D)", "Graded"),
         panel = factor(panel_labels[score], levels = panel_labels))
## x axis starts at the tenth below the lowest share, so the D row has room for its labels
x_floor <- floor(10 * min(fig_data$fund_agency_share)) / 10
set.seed(1)
fig_data$grade_jitter <- fig_data$grade + runif(nrow(fig_data), -0.15, 0.15)

fig_rho <- b2 %>%
  filter(version == "latest", score %in% names(panel_labels), share == "fund_agency_share") %>%
  mutate(panel = factor(panel_labels[score], levels = panel_labels),
         label = paste0("ρ = ", formatC(ifelse(abs(rho) < 0.005, 0, rho), format = "f", digits = 2), ", n = ", n))

fig_b2 <- ggplot(fig_data, aes(x = fund_agency_share, y = grade_jitter)) +
  geom_point(aes(colour = resource_group, shape = grade_type), size = 2.4, stroke = 0.9, fill = "white") +
  ggrepel::geom_text_repel(aes(label = country), size = 2.6, colour = col_ink, seed = 1, max.overlaps = Inf,
                           box.padding = 0.15, point.padding = 0.1, segment.colour = col_grey,
                           segment.size = 0.3, min.segment.length = 0.2) +
  geom_text(data = fig_rho, aes(x = -Inf, y = Inf, label = label), hjust = -0.05, vjust = 1.4,
            size = 3.6, colour = col_ink) +
  facet_wrap(~ panel, ncol = 2) +
  scale_colour_manual(values = pal_resource, labels = resource_labels) +
  scale_shape_manual(values = c("Graded" = 16, "D* (insufficient information, scored D)" = 21)) +
  scale_x_continuous(labels = scales::percent, limits = c(x_floor, 1), expand = expansion(mult = c(0.02, 0.04))) +
  scale_y_continuous(breaks = 1:4, labels = c("D", "C", "B", "A"), limits = c(0.75, 4.45)) +
  guides(colour = guide_legend(order = 1, nrow = 1), shape = guide_legend(order = 2, nrow = 1)) +
  labs(title = "Fund-or-agency share and PEFA grades on reporting outside the budget",
       x = "Fund-or-agency share of earmarked instruments (interim: legal form, not budget status)",
       y = "PEFA grade",
       caption = paste0("Unit: country with a 2016-framework PEFA; latest assessment (", min(b2_data$pefa_year),
                        "-", max(b2_data$pefa_year), "). n = ", fig_rho$n[fig_rho$score == "pi6_2"], " (PI-6.2), ",
                        fig_rho$n[fig_rho$score == "pi6_3"], " (PI-6.3); not rated excluded.\n",
                        "Interim measure: legal form, not budget status (\"fund\" is any recipient the law calls a fund).",
                        " Earmarked\ninstruments: E2 + E3, social contributions excluded. Grades jittered vertically.",
                        " ρ: Spearman rank correlation.\nColour: IMF REO resource group. Associations, not effects.")) +
  theme(panel.spacing.x = unit(0.8, "cm"),
        legend.box = "vertical",
        legend.spacing.y = unit(0, "cm"))
save_fig(fig_b2, "12_B2_pefa", width = 10, height = 6.5)


## --- Summary ---
cat("B2 countries with a PEFA:", nrow(b2_data), " | graded PI-6 / 6.2 / 6.3:",
    paste(pefa_scores$n_expected, collapse = " / "), " | assessment years", min(b2_data$pefa_year), "-",
    max(b2_data$pefa_year), "\n")
cat("Assessments before 2018:", paste(b2_data$country[b2_data$pefa_year < 2018], b2_data$pefa_year[b2_data$pefa_year < 2018], collapse = ", "), "\n")
cat("Grade D (incl. D*): PI-6.2", sum(b2_data$pi6_2_ord %in% 1), "of 28 | PI-6.3", sum(b2_data$pi6_3_ord %in% 1),
    "of 29 | D*: PI-6.2", sum(b2_data$pi6_2_dstar %in% 1), ", PI-6.3", sum(b2_data$pi6_3_dstar %in% 1),
    " | overall PI-6 with '+':", n_plus, "\n")
print(b2 %>% select(version, legal_family, score, share, n, n_above_D, rho, loo_min, loo_max) %>% mutate(across(c(rho, loo_min, loo_max), ~ round(.x, 2))))


## --- Write the tables ---
write.csv(b2, file.path(dir_tables, "12_B2_pefa.csv"), row.names = FALSE)
write.csv(b2_countries, file.path(dir_tables, "12_B2_pefa_countries.csv"), row.names = FALSE)
cat("Saved: 12_B2_pefa.csv, 12_B2_pefa_countries.csv in", dir_tables, "; figure 12_B2_pefa in", dir_figures, "\n")
