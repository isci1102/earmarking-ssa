## ============================================================================
## 10_external_prepare.R — one country-level table of external indicators for section B
## ANALYSIS_SPEC §0 (external data window), §3 (B1–B3), §4 (WGI for the completeness index) and §6.
## Inputs (read only, analysis_data/supporting-data/): WoRLD 2026 (sheet Data), UNU-WIDER GRD 2025 (sheet
## Merged), PEFA 2016-framework scores, WGI 2026 (sheet ge), country_groups.csv (the 43 countries).
## Outputs: ssa_external_indicators_prelim_2026-11.rds (one row per country, 43 rows, NA where a source has
## nothing); 10_external_sources.csv in dir_tables (file, sheet or column, years and countries of each variable).
## Unit: country. Revenue variables are % of GDP (WoRLD) or ratios (shares in [0, 1]); no weighting.
## Windows (ANALYSIS_SPEC §0): the latest 3 available years, averaged over the years observed:
## WoRLD 2022–2024, GRD 2021–2023, WGI 2023–2025. The single latest observed year is kept for robustness.
## PEFA: the latest assessment under the 2016 framework, with its year.
## ============================================================================

source(here::here("analysis", "paths.R"))

library(dplyr)
library(tidyr)
library(readxl)

for (f in c(file_world, file_grd, file_pefa, file_wgi)) {
  if (!file.exists(f)) stop("External input not found: ", f)
}

## Windows of each source
years_world <- 2022:2024
years_grd   <- 2021:2023
years_wgi   <- 2023:2025

## The 43 countries of the database: every source is joined onto this list, so no country is dropped
countries <- read.csv(file_country_groups) %>% select(iso3)
if (nrow(countries) != 43 || n_distinct(countries$iso3) != 43) stop("country_groups.csv should have 43 distinct iso3")


## --- Helpers ---
## Window summary of a long table (one row per iso3 × year × variable, value possibly NA).
## Per country and variable, over the years where the value is observed: the mean (avg), the number of years
## in the mean (n_years), the value of the latest observed year (latest) and that year (latest_year).
## A variable never observed in the window gives no row, so it is NA after the join onto the 43 countries.
window_summary <- function(long, years, name) {
  bad_years <- setdiff(unique(long$year), years)
  if (length(bad_years) > 0) stop(name, ": years outside the window: ", paste(bad_years, collapse = ", "))
  long %>%
    filter(!is.na(value)) %>%
    group_by(iso3, variable) %>%
    summarise(avg = mean(value),
              n_years = n(),
              latest = value[which.max(year)],
              latest_year = max(year),
              .groups = "drop")
}

## Wide format: one row per country, columns {variable}_avg, _n_years, _latest, _latest_year
to_wide <- function(summary_long) {
  summary_long %>%
    pivot_wider(names_from = variable, values_from = c(avg, n_years, latest, latest_year),
                names_glue = "{variable}_{.value}", names_vary = "slowest")
}

## Years actually used per variable (for the sources table): first and last year with a value among the 43
years_used <- function(long) {
  long %>%
    filter(!is.na(value)) %>%
    group_by(variable) %>%
    summarise(years = paste0(min(year), "-", max(year)), .groups = "drop")
}

## Stop if a share is outside [0, 1]; NA is allowed here (a source can have nothing for a country).
## Tolerance 1e-9: a fully covered TaxRev gives a coverage of 1 + 2e-16 from floating-point sums.
check_share_na <- function(x, name) {
  if (any(!is.na(x) & (x < -1e-9 | x > 1 + 1e-9))) stop(name, ": share outside [0, 1]")
}


## --- WoRLD (IMF World Revenue Longitudinal Database 2026) ---
## Every variable is % of GDP (Summary sheet). TotRev includes grants and social contributions:
## TotRev = TaxRev + SocialCon + Grants + RevOth.
world_raw <- read_excel(file_world, sheet = "Data", guess_max = 100000)

world_vars <- c("TotRev", "TaxRev",
                "TaxInc", "TaxIncI", "TaxIncC", "TaxIncCRes", "TaxIncO", "TaxPro",
                "TaxSal", "TaxSalG", "TaxSalExc", "TaxSalUnal", "TaxTra", "TaxOth",
                "SocialCon", "Grants", "RevOth", "NonTaxRes", "NonTaxOth")
missing_cols <- setdiff(c("ISO3", "year", "ResourceRich", world_vars), names(world_raw))
if (length(missing_cols) > 0) stop("WoRLD: columns not found: ", paste(missing_cols, collapse = ", "))

world <- world_raw %>%
  rename(iso3 = ISO3) %>%
  mutate(year = as.integer(year)) %>%
  filter(iso3 %in% countries$iso3, year %in% years_world)

if (n_distinct(world$iso3) != 43) stop("WoRLD: ", n_distinct(world$iso3), " of the 43 countries in the window")
if (nrow(world) != 43 * length(years_world)) stop("WoRLD: expected one row per country × year, got ", nrow(world))

## Coverage: share of TaxRev accounted for by the non-missing detailed components, i.e. the leaves of the tax
## tree (TaxInc = I + C + O; TaxSal = G + Exc + Unal). TaxIncCRes is part of TaxIncC, so it is not a leaf.
## A parent observed without its children (e.g. AGO: TaxInc and TaxSal, no sub-components) counts as not covered.
## A year in which no leaf is observed at all has no detail published yet (3 countries in 2024): coverage is NA
## for that year rather than 0, so the year is left out of the average, as it is for the components themselves.
leaf_vars <- c("TaxIncI", "TaxIncC", "TaxIncO", "TaxPro", "TaxSalG", "TaxSalExc", "TaxSalUnal", "TaxTra", "TaxOth")

## Resource revenue share of total revenue: (non-tax resource revenue + CIT on extractive industries) / TotRev,
## only in years where both are observed (a missing component is never read as 0)
world <- world %>%
  mutate(n_leaves = rowSums(!is.na(across(all_of(leaf_vars)))),
         coverage = ifelse(n_leaves > 0, rowSums(across(all_of(leaf_vars)), na.rm = TRUE) / TaxRev, NA),
         resource_share_world = (NonTaxRes + TaxIncCRes) / TotRev)

cat("WoRLD country-years without any detailed tax component (coverage NA):", sum(world$n_leaves == 0),
    "(", paste(world$iso3[world$n_leaves == 0], world$year[world$n_leaves == 0], collapse = ", "), ")\n")

world_long <- world %>%
  select(iso3, year, all_of(world_vars), coverage, resource_share_world) %>%
  pivot_longer(-c(iso3, year), names_to = "variable", values_to = "value") %>%
  mutate(variable = factor(variable, levels = c(world_vars, "coverage", "resource_share_world")))   # column order

world_wide <- to_wide(window_summary(world_long, years_world, "WoRLD"))

## WoRLD resource-rich flag (IMF classification in WoRLD; country_groups.csv has the REO one used in B3).
## Stop if it changes within the window.
world_rr <- world %>%
  group_by(iso3) %>%
  summarise(n_values = n_distinct(ResourceRich), ResourceRich = first(ResourceRich), .groups = "drop")
if (any(world_rr$n_values != 1)) stop("WoRLD: ResourceRich changes within the window")
if (any(!world_rr$ResourceRich %in% c("Resource-rich", "Non-resource-rich"))) stop("WoRLD: unexpected ResourceRich value")
world_rr <- world_rr %>%
  transmute(iso3, resource_rich_world = as.integer(ResourceRich == "Resource-rich"))


## --- GRD (UNU-WIDER Government Revenue Dataset 2025, sheet Merged) ---
## The sheet has a 3-row header with merged cells: row 1 = block (e.g. "Total Revenue"), row 2 = sub-block
## ("Including Grants"), row 3 = detail ("Inc SC"). A name is built from the three rows: row 1 is filled to the
## right across its merged cells; row 2 is filled to the right only within its row-1 block.
## Values are ratios to GDP.
grd_header <- read_excel(file_grd, sheet = "Merged", col_names = FALSE, n_max = 3, col_types = "text",
                         .name_repair = "minimal")
h1 <- as.character(unlist(grd_header[1, ]))
h2 <- as.character(unlist(grd_header[2, ]))
h3 <- as.character(unlist(grd_header[3, ]))
for (j in 2:length(h1)) {
  if (is.na(h1[j])) {
    h1[j] <- h1[j - 1]
    if (is.na(h2[j])) h2[j] <- h2[j - 1]
  }
}
grd_names <- apply(cbind(h1, h2, h3), 1, function(x) paste(x[!is.na(x)], collapse = " | "))
if (any(duplicated(grd_names))) stop("GRD: duplicated column names: ", paste(grd_names[duplicated(grd_names)], collapse = "; "))

grd_raw <- read_excel(file_grd, sheet = "Merged", col_names = grd_names, skip = 3, guess_max = 100000)

## Columns used. Total revenue includes grants and social contributions, the same denominator as WoRLD TotRev.
## Caution 2: resource revenues are significant but cannot be isolated from total revenue, so resource revenue
## is missing or understated in that year.
grd_cols <- c(iso3 = "ISO", year = "Year", general = "General (=1 if General)",
              caution2 = grd_names[startsWith(grd_names, "Caution2")],
              total_revenue = "Total Revenue | Including Grants | Inc SC",
              resource_revenue = "Total Resource Revenue")
if (length(grd_cols) != 6 || any(!grd_cols %in% grd_names)) stop("GRD: a column used was not found")

grd <- grd_raw %>%
  select(all_of(grd_cols)) %>%
  mutate(year = as.integer(year)) %>%
  filter(iso3 %in% countries$iso3, year %in% years_grd)

if (nrow(grd) != 43 * length(years_grd)) stop("GRD: expected one row per country × year, got ", nrow(grd))
if (any(duplicated(grd[, c("iso3", "year")]))) stop("GRD: duplicated iso3 × year")
if (any(!grd$general %in% c(0, 1))) stop("GRD: General flag not 0/1")
if (any(!is.na(grd$caution2) & grd$caution2 != 1)) stop("GRD: Caution2 flag not 1/NA")

## Resource revenue share of total revenue, year by year. A missing resource revenue stays NA: in GRD it means
## the item is not reported separately, not that it is zero.
grd <- grd %>%
  mutate(resource_share_grd = resource_revenue / total_revenue)

grd_long <- grd %>%
  select(iso3, year, resource_share_grd) %>%
  pivot_longer(-c(iso3, year), names_to = "variable", values_to = "value")

grd_wide <- to_wide(window_summary(grd_long, years_grd, "GRD"))

## Flags: any Caution 2 in the window (all window years, since a caution is the reason a share can be missing);
## share of the years entering the average that are general (not central) government
grd_flags <- grd %>%
  group_by(iso3) %>%
  summarise(grd_caution2 = as.integer(any(caution2 %in% 1)),
            grd_general_share = ifelse(any(!is.na(resource_share_grd)),
                                       mean(general[!is.na(resource_share_grd)] == 1), NA),
            .groups = "drop")


## --- PEFA PI-6 (2016 framework) ---
## Read every cell as text, with only empty cells as NA, so that the PEFA codes "NA" (not applicable) and
## "NR" (not rated) are seen and recoded explicitly below.
pefa_raw <- read.csv(file_pefa, check.names = FALSE, na.strings = "", colClasses = "character")
if (any(pefa_raw$Framework != "2016")) stop("PEFA: assessments outside the 2016 framework")

## Country names → ISO3, written by hand. Mauritania is outside the 43 countries and is dropped.
pefa_iso3 <- c("Botswana" = "BWA", "Burkina Faso" = "BFA", "Burundi" = "BDI", "Cameroon" = "CMR",
               "Chad" = "TCD", "Cote d'Ivoire" = "CIV", "Democratic Republic of Congo" = "COD",
               "Ethiopia" = "ETH", "Gabon" = "GAB", "Ghana" = "GHA", "Guinea" = "GIN", "Kenya" = "KEN",
               "Lesotho" = "LSO", "Liberia" = "LBR", "Madagascar" = "MDG", "Malawi" = "MWI", "Mali" = "MLI",
               "Mozambique" = "MOZ", "Niger" = "NER", "Nigeria" = "NGA", "Rwanda" = "RWA",
               "Sao Tome and Principe" = "STP", "Senegal" = "SEN", "Seychelles" = "SYC",
               "Sierra Leone" = "SLE", "Tanzania" = "TZA", "The Gambia" = "GMB", "Togo" = "TGO",
               "Uganda" = "UGA", "Zambia" = "ZMB", "Zimbabwe" = "ZWE")
if (any(!pefa_iso3 %in% countries$iso3)) stop("PEFA map: ISO3 outside the 43 countries")

pefa_dropped <- c("Mauritania")
unmatched <- setdiff(unique(pefa_raw$Country), c(names(pefa_iso3), pefa_dropped))
if (length(unmatched) > 0) stop("PEFA: country names without ISO3: ", paste(unmatched, collapse = ", "))
cat("PEFA: dropped (not among the 43):", paste(pefa_dropped, collapse = ", "), "-",
    sum(pefa_raw$Country %in% pefa_dropped), "assessments\n")

## Latest assessment per country
pefa_latest <- pefa_raw %>%
  filter(!Country %in% pefa_dropped) %>%
  mutate(iso3 = unname(pefa_iso3[Country]), pefa_year = as.integer(Year)) %>%
  group_by(iso3) %>%
  filter(pefa_year == max(pefa_year)) %>%
  ungroup()
if (any(duplicated(pefa_latest$iso3))) stop("PEFA: two assessments in the latest year for one country")

## Letters, ordinal and D* flag of PI-6 and its three dimensions.
## - D* (insufficient information, scored D) is coded D, with a flag;
## - NR (not rated) and NA (not applicable) are NA;
## - "+" exists only in the overall PI-6 (M2 aggregation); it is kept in the letter, and the ordinal uses the
##   letter only (A = 4, B = 3, C = 2, D = 1), so D+ = 1.
pefa_scores <- c(pi6 = "PI-06", pi6_1 = "PI-06.1", pi6_2 = "PI-06.2", pi6_3 = "PI-06.3")
grade_points <- c(A = 4, B = 3, C = 2, D = 1)
for (s in names(pefa_scores)) {
  code <- pefa_latest[[pefa_scores[[s]]]]
  allowed <- c("A", "B", "C", "D", "D*", "NR", "NA")
  if (s == "pi6") allowed <- c(allowed, "B+", "C+", "D+")
  if (any(is.na(code) | !code %in% allowed)) stop("PEFA ", pefa_scores[[s]], ": unexpected code ",
                                                   paste(setdiff(code, allowed), collapse = ", "))
  letter <- ifelse(code %in% c("NR", "NA"), NA, sub("*", "", code, fixed = TRUE))
  pefa_latest[[paste0(s, "_letter")]] <- letter
  pefa_latest[[paste0(s, "_ord")]] <- unname(grade_points[substr(letter, 1, 1)])
  pefa_latest[[paste0(s, "_dstar")]] <- as.integer(code == "D*")
}

pefa <- pefa_latest %>%
  select(iso3, pefa_year, starts_with("pi6_", ignore.case = FALSE))


## --- WGI government effectiveness (WGI 2026, sheet ge) ---
## Estimate on the -2.5 to +2.5 scale and its standard error. The mean of the SE over the window is a
## descriptive summary, not the SE of the mean.
wgi_raw <- read_excel(file_wgi, sheet = "ge", guess_max = 100000)

wgi <- wgi_raw %>%
  select(iso3 = `Economy (code)`, year = Year,
         wgi_ge = `Governance estimate (approx. -2.5 to +2.5)`, wgi_ge_se = `Standard error (estimate)`) %>%
  mutate(year = as.integer(year)) %>%
  filter(iso3 %in% countries$iso3, year %in% years_wgi)

## The WGI file writes missing values as ".."; anything else that is not a number stops the script
for (v in c("wgi_ge", "wgi_ge_se")) {
  x <- as.character(wgi[[v]])
  x[x == ".."] <- NA
  if (any(!is.na(x) & is.na(suppressWarnings(as.numeric(x))))) stop("WGI ", v, ": non-numeric values")
  wgi[[v]] <- as.numeric(x)
}
if (nrow(wgi) != 43 * length(years_wgi)) stop("WGI: expected one row per country × year, got ", nrow(wgi))

wgi_long <- wgi %>%
  pivot_longer(-c(iso3, year), names_to = "variable", values_to = "value")

wgi_wide <- to_wide(window_summary(wgi_long, years_wgi, "WGI"))


## --- One row per country ---
external <- countries %>%
  left_join(world_wide, by = "iso3") %>%
  left_join(world_rr, by = "iso3") %>%
  left_join(grd_wide, by = "iso3") %>%
  left_join(grd_flags, by = "iso3") %>%
  left_join(pefa, by = "iso3") %>%
  left_join(wgi_wide, by = "iso3")


## --- Checks ---
if (nrow(external) != 43) stop("Expected 43 rows, not ", nrow(external))
if (any(duplicated(external$iso3))) stop("Duplicated iso3")

## Every expected column exists (a variable never observed in its window would have no column)
expected_vars <- c(world_vars, "coverage", "resource_share_world", "resource_share_grd", "wgi_ge", "wgi_ge_se")
expected_cols <- c(as.vector(outer(expected_vars, c("_avg", "_n_years", "_latest", "_latest_year"), paste0)),
                   "resource_rich_world", "grd_caution2", "grd_general_share", "pefa_year",
                   paste0(rep(names(pefa_scores), each = 3), c("_letter", "_ord", "_dstar")))
missing_cols <- setdiff(expected_cols, names(external))
if (length(missing_cols) > 0) stop("Columns missing from the output: ", paste(missing_cols, collapse = ", "))

for (v in c("coverage", "resource_share_world", "resource_share_grd")) {
  check_share_na(external[[paste0(v, "_avg")]], paste0(v, "_avg"))
  check_share_na(external[[paste0(v, "_latest")]], paste0(v, "_latest"))
}
check_share_na(external$grd_general_share, "grd_general_share")

## Window years: every latest year and number of years within the source's window
check_window <- function(vars, years, name) {
  for (v in vars) {
    y <- external[[paste0(v, "_latest_year")]]
    n <- external[[paste0(v, "_n_years")]]
    if (any(!is.na(y) & !y %in% years)) stop(name, " ", v, ": latest year outside ", min(years), "-", max(years))
    if (any(!is.na(n) & (n < 1 | n > length(years)))) stop(name, " ", v, ": n_years outside 1-", length(years))
  }
}
check_window(c(world_vars, "coverage", "resource_share_world"), years_world, "WoRLD")
check_window("resource_share_grd", years_grd, "GRD")
check_window(c("wgi_ge", "wgi_ge_se"), years_wgi, "WGI")

for (s in names(pefa_scores)) {
  x <- external[[paste0(s, "_ord")]]
  if (any(!is.na(x) & !x %in% 1:4)) stop("PEFA ", s, ": ordinal outside 1-4")
}
if (any(is.na(external$resource_rich_world))) stop("WoRLD ResourceRich missing for a country")


## --- Sources table: one row per value column ---
## n_countries: countries with a non-missing value among the 43
years_long <- bind_rows(years_used(world_long), years_used(grd_long), years_used(wgi_long))

sources <- data.frame()
for (v in c(world_vars, "coverage", "resource_share_world")) {
  column <- case_when(v == "coverage" ~ paste0("Data: (", paste(leaf_vars, collapse = " + "), ") / TaxRev"),
                      v == "resource_share_world" ~ "Data: (NonTaxRes + TaxIncCRes) / TotRev",
                      TRUE ~ paste0("Data: ", v))
  yrs <- years_long$years[years_long$variable == v]
  sources <- bind_rows(sources,
    data.frame(variable = paste0(v, c("_avg", "_latest")), file = basename(file_world), sheet_or_column = column,
               years_used = paste0(c("mean over observed years in ", "latest observed year in "), yrs)))
}
sources <- bind_rows(sources,
  data.frame(variable = "resource_rich_world", file = basename(file_world), sheet_or_column = "Data: ResourceRich",
             years_used = paste0(min(years_world), "-", max(years_world), " (constant)")),
  data.frame(variable = paste0("resource_share_grd", c("_avg", "_latest")), file = basename(file_grd),
             sheet_or_column = paste0("Merged: ", grd_cols[["resource_revenue"]], " / ", grd_cols[["total_revenue"]]),
             years_used = paste0(c("mean over observed years in ", "latest observed year in "),
                                 years_long$years[years_long$variable == "resource_share_grd"])),
  data.frame(variable = c("grd_caution2", "grd_general_share"), file = basename(file_grd),
             sheet_or_column = c(paste0("Merged: ", grd_cols[["caution2"]]), "Merged: General (=1 if General)"),
             years_used = c(paste0(min(years_grd), "-", max(years_grd), " (any year)"),
                            "years entering resource_share_grd_avg")),
  data.frame(variable = c("pefa_year", paste0(rep(names(pefa_scores), each = 3), c("_letter", "_ord", "_dstar"))),
             file = basename(file_pefa),
             sheet_or_column = c("Year", rep(unname(pefa_scores), each = 3)),
             years_used = paste0("latest 2016-framework assessment (", min(external$pefa_year, na.rm = TRUE), "-",
                                 max(external$pefa_year, na.rm = TRUE), ")")))
for (v in c("wgi_ge", "wgi_ge_se")) {
  column <- ifelse(v == "wgi_ge", "Governance estimate (approx. -2.5 to +2.5)", "Standard error (estimate)")
  yrs <- years_long$years[years_long$variable == v]
  sources <- bind_rows(sources,
    data.frame(variable = paste0(v, c("_avg", "_latest")), file = basename(file_wgi),
               sheet_or_column = paste0("ge: ", column),
               years_used = paste0(c("mean over observed years in ", "latest observed year in "), yrs)))
}
sources$n_countries <- sapply(sources$variable, function(v) sum(!is.na(external[[v]])))
if (any(!sources$variable %in% names(external))) stop("Sources table names a column not in the output")


## --- Coverage summary ---
key_vars <- c("TotRev_avg", "TaxRev_avg", "TaxIncC_avg", "TaxSalG_avg", "TaxTra_avg", "SocialCon_avg",
              "NonTaxRes_avg", "TaxIncCRes_avg", "coverage_avg", "resource_share_world_avg",
              "resource_share_grd_avg", "pi6_letter", "pi6_2_letter", "pi6_3_letter", "wgi_ge_avg")
cat("\nCountries with a value (of 43):\n")
for (v in key_vars) cat(sprintf("  %-26s %2d\n", v, sum(!is.na(external[[v]]))))

cat("Years in the average (countries with 1 / 2 / 3 years):\n")
for (v in c("TotRev", "TaxIncC", "coverage", "resource_share_world", "resource_share_grd", "wgi_ge")) {
  n <- external[[paste0(v, "_n_years")]]
  cat(sprintf("  %-22s %2d / %2d / %2d\n", v, sum(n %in% 1), sum(n %in% 2), sum(n %in% 3)))
}
cat("Coverage (mean over the window), median over countries:", round(median(external$coverage_avg, na.rm = TRUE), 3),
    " | below 0.9:", sum(external$coverage_avg < 0.9, na.rm = TRUE), "countries\n")
cat("Resource share: both sources", sum(!is.na(external$resource_share_world_avg) & !is.na(external$resource_share_grd_avg)),
    " | either", sum(!is.na(external$resource_share_world_avg) | !is.na(external$resource_share_grd_avg)),
    " | GRD Caution 2 in window:", sum(external$grd_caution2 == 1), "countries\n")
cat("WoRLD resource-rich:", sum(external$resource_rich_world), "of 43\n")
cat("PEFA: countries with an assessment", sum(!is.na(external$pefa_year)),
    " | latest assessment before 2018:", sum(external$pefa_year < 2018, na.rm = TRUE),
    " | any D* in PI-6:", sum(external$pi6_1_dstar %in% 1 | external$pi6_2_dstar %in% 1 | external$pi6_3_dstar %in% 1), "\n")


## --- Save ---
write.csv(sources, file.path(dir_tables, "10_external_sources.csv"), row.names = FALSE)
saveRDS(external, file_external_rds)
cat("Saved:", file_external_rds, "\n")
