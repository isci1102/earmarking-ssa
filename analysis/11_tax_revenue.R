## ============================================================================
## 11_tax_revenue.R — B1: earmarking design and tax revenue (ANALYSIS_SPEC §3, B1 and common reporting)
## Question: are the design features of earmarking associated with how much tax a country collects?
## Inputs: the analysis .rds (00_load.R), the external indicators .rds (10_external_prepare.R), helpers.R
## (design shares, Spearman with leave-one-out), 01_tableA1.csv (check of the shares) and
## 10_external_sources.csv (check of the n of each revenue measure).
## Outputs: 11_B1_tax_revenue.csv (every revenue measure × share × version, incl. within legal family, without
## SACU and the counts row), 11_B1_country_data.csv (the country values behind the table) in dir_tables; figures
## 11_B1_tax_revenue (total tax revenue, 2×2 panels), one per main revenue type (11_B1_TaxInc, _TaxSal, _TaxTra,
## _NonTaxOth) and 11_B1_counts (context only).
## Unit: country, unweighted. Earmarking measures: the four Table A1 shares of the headline set (earmarked,
## social contributions excluded), never counts, because counts depend on the corpus. Revenue: WoRLD, % of GDP.
## Read as associations: causality can run both ways.
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

share_labels <- c(exclusive_share = "Exclusive (E3) share", hard_commitment_share = "Hard-commitment share",
                  fund_agency_share = "Fund-or-agency share", benefit_linked_share = "Benefit-linked share")

## Revenue measures (ANALYSIS_SPEC §3, B1). Main: total tax revenue and the four types observed in all 43
## countries. Secondary: sub-types observed in fewer countries, with their n. Robustness: total revenue, which
## also counts grants and social contributions (decision of 2 Nov 2026). Property taxes (20 countries) are left out.
revenue_measures <- data.frame(
  revenue_measure = c("TaxRev", "TaxInc", "TaxSal", "TaxTra", "NonTaxOth",
                      "TaxSalG", "TaxSalExc", "TaxIncI", "TaxIncC", "TotRev"),
  tier = c(rep("main", 5), rep("secondary", 4), "robustness"),
  revenue_label = c("Total tax revenue", "Taxes on income, profits and capital gains", "Taxes on goods and services",
                    "Taxes on international trade", "Other non-tax revenue (fees, fines, sales)",
                    "General taxes on goods and services (VAT)", "Excises", "Personal income tax",
                    "Corporate income tax", "Total revenue (incl. grants and social contributions)"),
  n_expected = c(43, 43, 43, 43, 43, 37, 34, 33, 34, 43)
)

## SACU members: their receipts from the SACU revenue pool are probably recorded as trade taxes in WoRLD (not
## verified), so trade taxes are also correlated without them (version decided on 2 Nov 2026, before the results).
sacu <- c("BWA", "LSO", "NAM", "SWZ", "ZAF")


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
for (s in names(share_labels)) check_share(shares[[s]], s)


## --- Country data: one row per country ---
## resource_group: IMF REO Sub-Saharan Africa, April 2026 (country_groups.csv, joined in 00_load.R)
country_info <- earmarks %>% distinct(country, legal_family, design_group, resource_group)
if (nrow(country_info) != 43 || n_distinct(country_info$country) != 43) stop("Expected 43 countries with one group each")

revenue_cols <- c(paste0(revenue_measures$revenue_measure, "_avg"), paste0(revenue_measures$revenue_measure, "_latest"),
                  paste0(revenue_measures$revenue_measure, "_latest_year"))
b1_data <- country_info %>%
  left_join(shares, by = "country") %>%
  left_join(external %>% select(country = iso3, all_of(revenue_cols)), by = "country") %>%
  mutate(sacu = country %in% sacu) %>%
  arrange(country)

if (nrow(b1_data) != 43) stop("B1: expected 43 countries, not ", nrow(b1_data))
if (sum(b1_data$sacu) != 5) stop("B1: the 5 SACU members are not all among the 43 countries")
n_oil <- sum(b1_data$resource_group == "oil_exporter")
if (n_oil != 7) stop("B1: expected 7 oil exporters, not ", n_oil)

## The n of each revenue measure is the one of 10_external_sources.csv and of the spec
for (i in 1:nrow(revenue_measures)) {
  m <- revenue_measures$revenue_measure[i]
  for (suffix in c("_avg", "_latest")) {
    n_data    <- sum(!is.na(b1_data[[paste0(m, suffix)]]))
    n_sources <- sources$n_countries[sources$variable == paste0(m, suffix)]
    if (length(n_sources) != 1 || n_data != n_sources || n_data != revenue_measures$n_expected[i]) {
      stop("B1: ", m, suffix, " has ", n_data, " countries; 10_external_sources.csv or the spec says otherwise")
    }
  }
}


## --- Spearman rho, n and leave-one-out range: every revenue measure × share × version ---
## Versions (ANALYSIS_SPEC §3, B1):
##   all:         all countries, mean 2022-2024 (main);
##   no_oil:      without the oil exporters, whose resource revenue moves their tax ratio for reasons unrelated
##                to earmarking;
##   latest_year: all countries, the latest observed year (2024, or 2023 where 2024 is not published);
##   no_sacu:     trade taxes only, without the 5 SACU members.
versions <- data.frame(
  version = c("all", "no_oil", "latest_year", "no_sacu"),
  suffix = c("_avg", "_avg", "_latest", "_avg"),
  version_label = c("All countries, mean 2022-2024",
                    "Without the 7 oil exporters, mean 2022-2024",
                    "All countries, latest observed year (2023 or 2024)",
                    "Without the 5 SACU members, mean 2022-2024 (trade taxes only)")
)

b1 <- data.frame()
for (i in 1:nrow(versions)) {
  v <- versions$version[i]
  rows_v <- b1_data
  if (v == "no_oil")  rows_v <- rows_v %>% filter(resource_group != "oil_exporter")
  if (v == "no_sacu") rows_v <- rows_v %>% filter(!sacu)
  measures_v <- if (v == "no_sacu") "TaxTra" else revenue_measures$revenue_measure

  for (m in measures_v) {
    revenue <- rows_v[[paste0(m, versions$suffix[i])]]
    for (s in names(share_labels)) {
      b1 <- bind_rows(b1, data.frame(version = v, revenue_measure = m, share = s,
                                     spearman_loo(rows_v[[s]], revenue, rows_v$country, paste(v, m, s))))
    }
  }
}

## Within legal tradition (decision of 2 Nov 2026): the whole main grid (5 main measures × 4 shares, mean
## 2022-2024), computed separately among the anglophone_common and francophone_civil countries of legal_family.
## All 40 correlations are reported; none is selected. The other 8 countries (5 lusophone, 2 mixed, 1
## hispanophone) enter neither. Design moves with legal tradition (A7), so a full-sample rho can reflect it.
families <- c("anglophone_common", "francophone_civil")
n_family <- c(anglophone_common = 18, francophone_civil = 17)
for (fam in families) {
  rows_f <- b1_data %>% filter(as.character(legal_family) == fam)
  if (nrow(rows_f) != n_family[[fam]]) stop("B1: expected ", n_family[[fam]], " ", fam, " countries, not ", nrow(rows_f))
  for (m in revenue_measures$revenue_measure[revenue_measures$tier == "main"]) {
    for (s in names(share_labels)) {
      b1 <- bind_rows(b1, data.frame(version = "within_family", legal_family = fam, revenue_measure = m, share = s,
                                     spearman_loo(rows_f[[s]], rows_f[[paste0(m, "_avg")]], rows_f$country,
                                                  paste("within_family", fam, m, s))))
    }
  }
}

## Counts, as context only (decision of 2 Nov 2026): the number of earmarked instruments (headline set) against
## total tax revenue. Counts depend on corpus completeness and on how each legal system splits charges, so this is
## not a measure of earmarking intensity.
b1 <- bind_rows(b1, data.frame(version = "counts", revenue_measure = "TaxRev", share = "n_earmarked",
                               spearman_loo(b1_data$n_earmarked, b1_data$TaxRev_avg, b1_data$country, "counts")))

## Without the SACU members, every main measure (follow-up of 2 Nov 2026, checked AFTER seeing the B1 figure, so
## not a pre-specified version): the 5 main measures × 4 shares without BWA, LSO, NAM, SWZ and ZAF, over all
## countries (legal_family NA) and within the anglophone_common countries (all 5 SACU members are anglophone).
## In the figure, the exclusive-share pattern appeared driven by the SACU members, Mauritius and Seychelles; only
## the SACU members are removed here.
for (grp in c("all", "anglophone_common")) {
  rows_g <- b1_data %>% filter(!sacu)
  if (grp != "all") rows_g <- rows_g %>% filter(as.character(legal_family) == grp)
  for (m in revenue_measures$revenue_measure[revenue_measures$tier == "main"]) {
    for (s in names(share_labels)) {
      b1 <- bind_rows(b1, data.frame(version = "no_sacu_all", legal_family = ifelse(grp == "all", NA, grp),
                                     revenue_measure = m, share = s,
                                     spearman_loo(rows_g[[s]], rows_g[[paste0(m, "_avg")]], rows_g$country,
                                                  paste("no_sacu_all", grp, m, s))))
    }
  }
}

versions_extra <- data.frame(
  version = c("within_family", "counts", "no_sacu_all"),
  version_label = c("Within legal family (anglophone_common or francophone_civil), mean 2022-2024",
                    "All countries, mean 2022-2024; number of earmarked instruments (context only)",
                    paste("Without the 5 SACU members, mean 2022-2024, all countries (legal_family NA) or within",
                          "anglophone_common; checked after seeing the B1 figure"))
)

b1 <- b1 %>%
  left_join(bind_rows(versions %>% select(version, version_label), versions_extra), by = "version") %>%
  left_join(revenue_measures %>% select(revenue_measure, tier, revenue_label), by = "revenue_measure") %>%
  mutate(share_label = ifelse(share == "n_earmarked", "Number of earmarked instruments (count)", share_labels[share]),
         unit = "country",
         note = case_when(version == "no_sacu" ~ "WoRLD treatment of SACU pool receipts not verified",
                          version == "no_sacu_all" ~ paste("checked after seeing the B1 figure;",
                                                           "WoRLD treatment of SACU pool receipts not verified"),
                          version == "counts" ~ paste("counts depend on corpus completeness and on how each legal system",
                                                      "splits charges; context, not a measure of earmarking intensity"),
                          revenue_measure == "TotRev" ~ "TotRev = TaxRev + SocialCon + Grants + RevOth",
                          TRUE ~ "")) %>%
  select(version, version_label, legal_family, tier, revenue_measure, revenue_label, share, share_label, unit, n, rho,
         loo_min, loo_max, loo_min_drop, loo_max_drop, loo_undefined, note)

## Checks: 10 measures × 4 shares × 3 versions, plus 4 trade-tax rows without SACU; 5 main measures × 4 shares ×
## 2 families within legal family; 1 counts row; n by version
if (sum(b1$version %in% versions$version) != 10 * 4 * 3 + 4) stop("B1: expected 124 rows in the first four versions")
if (sum(b1$version == "within_family") != 5 * 4 * 2) stop("B1: expected 40 within-family rows")
if (sum(b1$version == "counts") != 1 || b1$n[b1$version == "counts"] != 43) stop("B1: the counts row should have 43 countries")
for (fam in families) {
  if (any(b1$n[b1$version == "within_family" & b1$legal_family %in% fam] != n_family[[fam]])) stop("B1: n within ", fam)
}
## Without SACU: 5 main measures × 4 shares × 2 groups; 43 - 5 = 38 countries, 18 - 5 = 13 anglophone
if (sum(b1$version == "no_sacu_all") != 5 * 4 * 2) stop("B1: expected 40 rows without SACU")
if (any(b1$n[b1$version == "no_sacu_all" & is.na(b1$legal_family)] != 38) ||
    any(b1$n[b1$version == "no_sacu_all" & b1$legal_family %in% "anglophone_common"] != 13)) {
  stop("B1: without SACU, expected 38 countries (13 anglophone)")
}
if (any(is.na(b1$rho) | abs(b1$rho) > 1 | b1$loo_min < -1 | b1$loo_max > 1)) stop("B1: a rho outside [-1, 1]")
for (m in revenue_measures$revenue_measure) {
  n_all   <- b1$n[b1$version == "all" & b1$revenue_measure == m]
  n_oil_m <- sum(b1_data$resource_group == "oil_exporter" & !is.na(b1_data[[paste0(m, "_avg")]]))
  if (any(n_all != revenue_measures$n_expected[revenue_measures$revenue_measure == m])) stop("B1: n of ", m, " (all)")
  if (any(b1$n[b1$version == "no_oil" & b1$revenue_measure == m] != n_all - n_oil_m)) stop("B1: n of ", m, " (no_oil)")
}
if (any(b1$n[b1$revenue_measure %in% revenue_measures$revenue_measure[revenue_measures$tier == "main"] &
             b1$version == "all"] != 43)) stop("B1: the main measures should have 43 countries")
if (any(b1$n[b1$version == "no_sacu"] != 38)) stop("B1: trade taxes without SACU should have 38 countries")


## --- Figures: one revenue measure against each of the four shares ---
## Labelled points (ISO3), coloured by resource_group: the first 3 slots of pal_cat, the set that passes the
## all-pairs colour test (PLOT_STYLE rule 1: at most 3 colours in a scatter plot). rho and n of the main version
## in each panel. One figure for total tax revenue (11_B1_tax_revenue) and one per main revenue type
## (11_B1_{measure}, decision of 2 Nov 2026); all main measures are observed in the 43 countries.
resource_labels <- c(oil_exporter = "Oil exporters", other_resource_intensive = "Other resource-intensive",
                     non_resource_intensive = "Non-resource-intensive")
pal_resource <- setNames(pal_cat[1:3], names(resource_labels))

fig_b1_measure <- function(m, name) {
  revenue_label <- revenue_measures$revenue_label[revenue_measures$revenue_measure == m]
  fig_data <- b1_data %>%
    select(country, resource_group, revenue = all_of(paste0(m, "_avg")), all_of(names(share_labels))) %>%
    pivot_longer(all_of(names(share_labels)), names_to = "share", values_to = "value") %>%
    mutate(share_label = factor(share_labels[share], levels = share_labels))

  fig_rho <- b1 %>%
    filter(version == "all", revenue_measure == m) %>%
    mutate(share_label = factor(share_label, levels = share_labels),
           label = paste0("ρ = ", formatC(ifelse(abs(rho) < 0.005, 0, rho), format = "f", digits = 2), ", n = ", n))

  fig <- ggplot(fig_data, aes(x = value, y = revenue)) +
    geom_point(aes(colour = resource_group), size = 2.2, alpha = 0.9) +
    ggrepel::geom_text_repel(aes(label = country), size = 2.6, colour = col_ink, seed = 1, max.overlaps = Inf,
                             box.padding = 0.15, point.padding = 0.1, segment.colour = col_grey,
                             segment.size = 0.3, min.segment.length = 0.2) +
    geom_text(data = fig_rho, aes(x = -Inf, y = Inf, label = label), hjust = -0.05, vjust = 1.4,
              size = 3.6, colour = col_ink) +
    facet_wrap(~ share_label, ncol = 2) +
    scale_colour_manual(values = pal_resource, labels = resource_labels) +
    scale_x_continuous(labels = scales::percent, limits = c(0, 1), expand = expansion(mult = c(0.02, 0.04))) +
    scale_y_continuous(expand = expansion(mult = c(0.04, 0.12))) +
    labs(title = paste("Earmarking design and", tolower(revenue_label)),
         x = "Country share (headline set)", y = paste0(revenue_label, ", % of GDP (mean 2022-2024)"),
         caption = paste0("Unit: country (43). ", ifelse(m == "NonTaxOth", "Revenue", "Tax revenue"),
                          ": IMF WoRLD 2026, mean of 2022-2024 over the observed years.",
                          " Shares: earmarked instruments of the\ncountry (E2 + E3, social contributions excluded);",
                          " benefit-linked share: instrument x COFOG division links. ρ: Spearman rank\ncorrelation",
                          " over all 43 countries. Colour: IMF REO resource group. Associations, not effects.")) +
    theme(panel.spacing.x = unit(0.8, "cm"),
          panel.spacing.y = unit(0.5, "cm"))
  save_fig(fig, name, width = 10, height = 8.5)
}

fig_b1_measure("TaxRev", "11_B1_tax_revenue")
for (m in c("TaxInc", "TaxSal", "TaxTra", "NonTaxOth")) fig_b1_measure(m, paste0("11_B1_", m))


## --- Figure: number of earmarked instruments against total tax revenue (context only) ---
## Counts on a log scale (they run from about 10 to 150); rho is a rank correlation, so the scale does not change it.
counts_rho <- b1 %>% filter(version == "counts")
fig_counts <- ggplot(b1_data, aes(x = TaxRev_avg, y = n_earmarked)) +
  geom_point(aes(colour = resource_group), size = 2.2, alpha = 0.9) +
  ggrepel::geom_text_repel(aes(label = country), size = 2.6, colour = col_ink, seed = 1, max.overlaps = Inf,
                           box.padding = 0.15, point.padding = 0.1, segment.colour = col_grey,
                           segment.size = 0.3, min.segment.length = 0.2) +
  annotate("text", x = -Inf, y = Inf, hjust = -0.05, vjust = 1.4, size = 3.6, colour = col_ink,
           label = paste0("ρ = ", formatC(ifelse(abs(counts_rho$rho) < 0.005, 0, counts_rho$rho), format = "f", digits = 2), ", n = ", counts_rho$n)) +
  scale_colour_manual(values = pal_resource, labels = resource_labels) +
  scale_y_log10(breaks = c(10, 20, 30, 50, 100, 150), expand = expansion(mult = c(0.04, 0.12))) +
  labs(title = "Number of earmarked instruments and total tax revenue",
       x = "Total tax revenue, % of GDP (mean 2022-2024)", y = "Earmarked instruments (log scale)",
       caption = paste0("Unit: country (43). Earmarked instruments: E2 + E3, social contributions excluded (instruments and",
                        " classes of charges).\nCounts depend on corpus completeness and on how each legal system splits",
                        " charges; shown as context, not as a measure\nof earmarking intensity. Tax revenue: IMF WoRLD 2026,",
                        " mean of 2022-2024. ρ: Spearman rank correlation.\nColour: IMF REO resource group."))
save_fig(fig_counts, "11_B1_counts", width = 9, height = 6.5)


## --- Summary ---
cat("B1 countries:", nrow(b1_data), " | oil exporters:", n_oil, "(", paste(b1_data$country[b1_data$resource_group == "oil_exporter"], collapse = ", "),
    ") | SACU:", paste(sacu, collapse = ", "), "\n")
cat("Countries whose latest observed year is 2023 (latest_year version):\n")
for (m in revenue_measures$revenue_measure) {
  y <- b1_data[[paste0(m, "_latest_year")]]
  cat(sprintf("  %-10s %2d (%s)\n", m, sum(y %in% 2023), paste(b1_data$country[y %in% 2023], collapse = ", ")))
}
cat("Secondary measures, n:", paste(revenue_measures$revenue_measure[revenue_measures$tier == "secondary"],
                                    revenue_measures$n_expected[revenue_measures$tier == "secondary"], collapse = " | "), "\n")
cat("Correlations:", nrow(b1), " | main version, main measures:",
    sum(b1$version == "all" & b1$tier == "main"), "\n")
b1_main <- b1 %>% filter(version == "all", tier == "main")
cat("Main version, main measures: rho from", round(min(b1_main$rho), 2), "to", round(max(b1_main$rho), 2),
    " | |rho| >= 0.3:", sum(abs(b1_main$rho) >= 0.3), "of", nrow(b1_main), "\n")
cat("Total tax revenue (all):", paste0(b1$share[b1$version == "all" & b1$revenue_measure == "TaxRev"], " ",
                                       round(b1$rho[b1$version == "all" & b1$revenue_measure == "TaxRev"], 2), collapse = " | "), "\n")
for (fam in families) {
  b1_fam <- b1 %>% filter(version == "within_family", legal_family == fam)
  cat("Within", fam, "(n =", n_family[[fam]], "): 20 rho from", round(min(b1_fam$rho), 2), "to", round(max(b1_fam$rho), 2), "\n")
}
cat("Counts (n_earmarked) vs total tax revenue: rho", round(counts_rho$rho, 2), "n", counts_rho$n, "\n")
b1_ns <- b1 %>% filter(version == "no_sacu_all", revenue_measure == "TaxRev", share == "exclusive_share")
cat("Without SACU, total tax revenue x exclusive share: all countries rho", round(b1_ns$rho[is.na(b1_ns$legal_family)], 2),
    "n", b1_ns$n[is.na(b1_ns$legal_family)], " | anglophone rho", round(b1_ns$rho[!is.na(b1_ns$legal_family)], 2),
    "n", b1_ns$n[!is.na(b1_ns$legal_family)], "\n")


## --- Write the tables ---
country_out <- b1_data %>%
  mutate(unit = "country") %>%
  select(country, unit, legal_family, design_group, resource_group, sacu, n_earmarked, all_of(names(share_labels)),
         all_of(revenue_cols))
write.csv(b1, file.path(dir_tables, "11_B1_tax_revenue.csv"), row.names = FALSE)
write.csv(country_out, file.path(dir_tables, "11_B1_country_data.csv"), row.names = FALSE)
cat("Saved: 11_B1_tax_revenue.csv, 11_B1_country_data.csv in", dir_tables, "; figures 11_B1_tax_revenue,",
    "11_B1_TaxInc, 11_B1_TaxSal, 11_B1_TaxTra, 11_B1_NonTaxOth, 11_B1_counts in", dir_figures, "\n")
