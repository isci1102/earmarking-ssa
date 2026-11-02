## ============================================================================
## 03_sankey.R — A2c: one Sankey per country, base group -> COFOG division (ANALYSIS_SPEC §2, A2 row (c))
## Figures by docs/PLOT_STYLE.md §3 (ggalluvial).
## Inputs: the analysis .rds (00_load.R, with base_group and design_group), helpers.R, and 02_A2a_links.csv and
## 02_A1_by_country.csv (for the checks and the page titles).
## Set: headline only (earmarked E2 + E3, social contributions excluded), as the A2a heatmap.
## Unit: instrument × cofog_division link from get_link_pairs() (helpers.R), so the flows are the links of A2a.
## A flow counts links, not revenue: an instrument linked to two divisions is two links.
## Outputs: 03_sankey_flows.csv and 03_sankey_candidates.csv in dir_tables; 03_A2c_sankey_countries.pdf (one page
## per country) in dir_figures; one PNG per country (03_sankey_{ISO3}.png) in dir_figures_sankey; PDF + PNG of the
## main-text countries via save_fig() in dir_figures.
## ============================================================================

source(here::here("analysis", "paths.R"))
source(here::here("analysis", "helpers.R"))        # indicator legs and instrument × division links
source(here::here("analysis", "theme_earmark.R"))  # colours, theme, save_fig()

library(dplyr)
library(ggplot2)
library(ggalluvial)

earmarks <- readRDS(file_analysis_rds)
if (!all(c("base_group", "design_group") %in% names(earmarks))) stop("Re-run 00_load.R: the .rds has no base_group or design_group")

file_a2a <- file.path(dir_tables, "02_A2a_links.csv")
file_a1  <- file.path(dir_tables, "02_A1_by_country.csv")
for (f in c(file_a2a, file_a1)) {
  if (!file.exists(f)) stop("Run 02_composition.R first: ", f, " not found")
}
a2a_02 <- read.csv(file_a2a)
a1_02  <- read.csv(file_a1)

## Main-text countries (ANALYSIS_SPEC: one UEMOA, one CEMAC, one anglophone, one lusophone), chosen by hand from
## 03_sankey_candidates.csv. PROVISIONAL (choice of 2 Nov 2026). Ties at the group median broken by hand:
## anglophone ZMB over SWZ (lower class-placeholder share), lusophone CPV over AGO (resource variety: CPV is
## non-resource-intensive, the other three are resource-rich). The reasons are written to the candidates table.
## These four also get their own PDF + PNG via save_fig() in dir_figures.
main_text_countries <- c("NER", "COG", "ZMB", "CPV")

## Catch-all base groups: never among the coloured top 5 (PLOT_STYLE §3), since a residual colour says nothing
## about what is taxed
catch_all_groups <- "services_acts_other"


## --- Labels ---
## Node order is fixed across countries (PLOT_STYLE §3): base groups in spec order (the factor order of
## 00_load.R), divisions 701–710 then unallocated (function unknown) last.
division_levels <- c(as.character(701:710), "unallocated")
division_labels <- c("701" = "701 General public services", "702" = "702 Defence",
                     "703" = "703 Public order, safety", "704" = "704 Economic affairs",
                     "705" = "705 Environment", "706" = "706 Housing, community", "707" = "707 Health",
                     "708" = "708 Recreation, culture, religion", "709" = "709 Education",
                     "710" = "710 Social protection", "unallocated" = "Unallocated")
base_group_labels <- c(broad_bases = "Broad bases", extractive = "Extractive", fuel_energy = "Fuel and energy",
                       forestry_fisheries_agriculture = "Forestry, fisheries, agriculture",
                       environment_water = "Environment and water", telecom_media = "Telecom and media",
                       transport = "Transport", financial_insurance = "Financial and insurance",
                       harmful_consumption = "Harmful consumption", gambling_tourism = "Gambling and tourism",
                       payroll_property = "Payroll and property", services_acts_other = "Services, acts, other")
design_labels <- c(uemoa_francophone = "UEMOA, francophone", cemac_francophone = "CEMAC, francophone",
                   francophone_noncfa = "Francophone, non-CFA", anglophone_common = "Anglophone common law",
                   lusophone_noncfa = "Lusophone, non-CFA", cfa_nonfrancophone = "CFA, non-francophone",
                   mixed = "Mixed")
## Country names for the page titles (country_groups.csv has ISO3 only)
country_names <- c(AGO = "Angola", BDI = "Burundi", BEN = "Benin", BFA = "Burkina Faso", BWA = "Botswana",
                   CAF = "Central African Republic", CIV = "Côte d'Ivoire", CMR = "Cameroon",
                   COD = "Democratic Republic of the Congo", COG = "Republic of the Congo", COM = "Comoros",
                   CPV = "Cabo Verde", ETH = "Ethiopia", GAB = "Gabon", GHA = "Ghana", GIN = "Guinea",
                   GMB = "The Gambia", GNB = "Guinea-Bissau", GNQ = "Equatorial Guinea", KEN = "Kenya",
                   LBR = "Liberia", LSO = "Lesotho", MDG = "Madagascar", MLI = "Mali", MOZ = "Mozambique",
                   MUS = "Mauritius", MWI = "Malawi", NAM = "Namibia", NER = "Niger", NGA = "Nigeria",
                   RWA = "Rwanda", SEN = "Senegal", SLE = "Sierra Leone", STP = "São Tomé and Príncipe",
                   SWZ = "Eswatini", SYC = "Seychelles", TCD = "Chad", TGO = "Togo", TZA = "Tanzania",
                   UGA = "Uganda", ZAF = "South Africa", ZMB = "Zambia", ZWE = "Zimbabwe")


## --- Links (unit: instrument × cofog_division) ---
## Same rows and legs as the headline set of 02_composition.R. The n_links of get_link_pairs() counts benefit
## links on a pair; it is renamed so that n_links below always means a number of instrument × division links.
rows <- earmarks %>% filter(!social_contribution)
instruments <- rows %>% distinct(country, instrument_id, base_group, design_group, row_kind)
if (nrow(instruments) != nrow(distinct(rows, country, instrument_id))) stop("instrument attributes vary within an instrument")

links <- get_link_pairs(get_indicator_legs(rows)) %>%
  rename(n_benefit_links = n_links) %>%
  left_join(instruments, by = c("country", "instrument_id"))
bad_division <- setdiff(unique(links$cofog_division), division_levels)
if (length(bad_division) > 0) stop("cofog_division outside 701–710 / unallocated: ", paste(bad_division, collapse = ", "))
links$cofog_division <- factor(links$cofog_division, levels = division_levels)
if (any(is.na(links$base_group))) stop("links with no base_group")

## The total equals the A2a heatmap of 02_composition.R (headline set)
if (nrow(links) != sum(a2a_02$n_links)) {
  stop("Links (", nrow(links), ") differ from the A2a total of 02_A2a_links.csv (", sum(a2a_02$n_links), ")")
}


## --- Flows: links per country × base group × division ---
flows <- links %>%
  count(country, base_group, cofog_division, name = "n_links")

## Each country's flows sum to its number of links
check_flows <- flows %>%
  group_by(country) %>%
  summarise(n_flows = sum(n_links)) %>%
  full_join(links %>% count(country, name = "n_country"), by = "country")
if (any(is.na(check_flows$n_flows) | check_flows$n_flows != check_flows$n_country)) {
  stop("Flows of a country do not sum to its number of links")
}

write.csv(flows %>% mutate(base_group = as.character(base_group), cofog_division = as.character(cofog_division)),
          file.path(dir_tables, "03_sankey_flows.csv"), row.names = FALSE)


## --- Countries: page order, titles, n ---
## Ordered by design_group (factor order of 00_load.R), then ISO3. n_earmarked from 02_A1_by_country.csv.
countries <- links %>%
  count(country, design_group, name = "n_links") %>%
  left_join(a1_02 %>% select(country, n_earmarked), by = "country") %>%
  mutate(country_name = country_names[country]) %>%
  arrange(design_group, country)
if (nrow(countries) != 43) stop("Expected 43 countries with links, not ", nrow(countries))
if (any(is.na(countries$n_earmarked))) stop("A country is missing from 02_A1_by_country.csv")
if (any(is.na(countries$country_name))) stop("No name for: ", paste(countries$country[is.na(countries$country_name)], collapse = ", "))
if (any(is.na(countries$design_group))) stop("A country has no design_group")


## --- Flow colours: the 5 base groups with the most links, pooled over all countries ---
## The same 5 on every page, so the pages compare (PLOT_STYLE §3). Catch-all groups are left out of the ranking.
## Ties broken by spec order. The colours go to the 5 in spec order, so the legend reads in node order; the other
## base groups are folded into Other (grey).
top_groups <- links %>%
  filter(!base_group %in% catch_all_groups) %>%
  count(base_group, name = "n_links") %>%
  arrange(desc(n_links), base_group) %>%
  slice(1:5)
top5 <- levels(links$base_group)[levels(links$base_group) %in% top_groups$base_group]
fill_values <- c(setNames(pal_cat[1:5], base_group_labels[top5]), Other = col_grey)

flows <- flows %>%
  mutate(flow_group = ifelse(as.character(base_group) %in% top5, base_group_labels[as.character(base_group)], "Other"),
         flow_group = factor(flow_group, levels = names(fill_values)))

caption_set <- "Earmarked instruments and classes of charges (E2 + E3), social contributions excluded."


## --- One Sankey page ---
## Nodes: dark grey strata, labelled with their number of links, outside the strata (base groups on the left,
## divisions on the right); ggrepel moves labels of thin neighbouring nodes apart vertically only, with a
## fixed seed. Node labels carry the factor order, so only the nodes a country has are drawn,
## always in the same order (first level at the top). The legend always shows the 5 colours plus Other:
## limits + drop = FALSE keep the absent groups, and show.legend = TRUE draws their keys (ggplot2 >= 3.5
## leaves the key of an absent level empty otherwise).
make_sankey <- function(iso) {
  info <- countries %>% filter(country == iso)
  d <- flows %>%
    filter(country == iso) %>%
    mutate(base_node = factor(base_group_labels[as.character(base_group)], levels = base_group_labels),
           division_node = factor(division_labels[as.character(cofog_division)], levels = division_labels)) %>%
    mutate(base_node = droplevels(base_node), division_node = droplevels(division_node))

  ggplot(d, aes(y = n_links, axis1 = base_node, axis2 = division_node)) +
    geom_alluvium(aes(fill = flow_group), width = 1/10, alpha = 0.8, show.legend = TRUE) +
    geom_stratum(width = 1/10, fill = col_grey_dark, colour = "white", linewidth = 0.4) +
    ggrepel::geom_text_repel(stat = "stratum", na.rm = TRUE, hjust = 1, nudge_x = -0.07, direction = "y",
                             size = 3.4, colour = col_ink, segment.colour = col_grey, min.segment.length = 0.2,
                             box.padding = 0.1, seed = 1,
                             aes(label = after_stat(ifelse(as.integer(x) == 1, paste0(stratum, " (", count, ")"), NA)))) +
    ggrepel::geom_text_repel(stat = "stratum", na.rm = TRUE, hjust = 0, nudge_x = 0.07, direction = "y",
                             size = 3.4, colour = col_ink, segment.colour = col_grey, min.segment.length = 0.2,
                             box.padding = 0.1, seed = 1,
                             aes(label = after_stat(ifelse(as.integer(x) == 2, paste0(stratum, " (", count, ")"), NA)))) +
    scale_fill_manual(values = fill_values, limits = names(fill_values), drop = FALSE) +
    scale_x_discrete(limits = c("Base group (what is taxed)", "COFOG division (what is financed)"),
                     position = "top", expand = expansion(add = c(0.95, 0.95))) +
    guides(fill = guide_legend(nrow = 1)) +
    labs(title = info$country_name,
         subtitle = paste0(design_labels[as.character(info$design_group)], " · ", info$n_earmarked,
                           " earmarked instruments"),
         x = NULL, y = NULL,
         caption = paste0("Unit: instrument x COFOG division link (restricted legs; n = ", info$n_links,
                          " links). Flows: number of links, not revenue.\nIn brackets: number of links of the node.",
                          " Colours: the 5 base groups with the most links over all 43 countries\n",
                          "(catch-all Services, acts, other excluded); Other in grey.\n",
                          caption_set)) +
    theme(panel.grid.major = element_blank(),
          axis.text.y = element_blank(),
          axis.text.x = element_text(colour = col_grey_dark, face = "bold"),
          legend.text = element_text(size = rel(0.8)))
}


## --- All countries: one multi-page PDF, and one PNG per country ---
## The PNGs (country profiles, Quarto reports) go to their own folder, so the 43 files do not crowd figures/.
file_pdf <- file.path(dir_figures, "03_A2c_sankey_countries.pdf")
cairo_pdf(file_pdf, width = 11, height = 7.5, onefile = TRUE)
n_pages <- 0
for (iso in countries$country) {
  p <- make_sankey(iso)
  print(p)
  n_pages <- n_pages + 1
  ggsave(file.path(dir_figures_sankey, paste0("03_sankey_", iso, ".png")), p, width = 11, height = 7.5,
         dpi = 300, bg = "white")
}
dev.off()
if (n_pages != nrow(countries)) stop("PDF has ", n_pages, " pages for ", nrow(countries), " countries")

## One PNG per country in the folder, and no other 03_sankey_ PNG (e.g. left over from a dropped country)
png_files <- list.files(dir_figures_sankey, pattern = "^03_sankey_[A-Z]{3}\\.png$")
if (!setequal(png_files, paste0("03_sankey_", countries$country, ".png"))) {
  stop("PNGs in ", dir_figures_sankey, " do not match the ", nrow(countries), " countries")
}


## --- Main-text candidates ---
## For each of the four groups of the main text, the country whose number of links is closest to the group
## median; ties are all listed (a group with an even number of countries has a median between two of them).
## The choice is made by hand and written into main_text_countries above; the table records the facts used for
## the tie-break: the class-placeholder share of the country's earmarked instruments (headline set) and its
## resource_group (country_groups.csv).
candidate_groups <- c("uemoa_francophone", "cemac_francophone", "anglophone_common", "lusophone_noncfa")
placeholder_share <- instruments %>%
  semi_join(links, by = c("country", "instrument_id")) %>%
  group_by(country) %>%
  summarise(placeholder_share = mean(row_kind == "class_placeholder"))
resource <- read.csv(file_country_groups) %>% select(country = iso3, resource_group)

candidates <- countries %>%
  filter(design_group %in% candidate_groups) %>%
  group_by(design_group) %>%
  mutate(n_countries_in_group = n(),
         group_median_links = median(n_links),
         distance = abs(n_links - group_median_links)) %>%
  filter(distance == min(distance)) %>%
  mutate(n_tied = n()) %>%
  ungroup() %>%
  left_join(placeholder_share, by = "country") %>%
  left_join(resource, by = "country") %>%
  mutate(design_group = as.character(design_group),
         main_text = country %in% main_text_countries,
         note = case_when(
           n_tied == 1 ~ "single closest country",
           design_group == "anglophone_common" ~
             "tie at the median: ZMB chosen over SWZ for its lower class-placeholder share (provisional)",
           design_group == "lusophone_noncfa" ~
             "tie at the median: CPV chosen over AGO for resource variety, CPV non-resource-intensive, NER, COG, ZMB resource-rich (provisional)",
           TRUE ~ "tie at the median: no tie-break recorded")) %>%
  select(design_group, n_countries_in_group, group_median_links, country, country_name, n_links, distance,
         n_earmarked, placeholder_share, resource_group, main_text, note)
if (!setequal(candidates$design_group, candidate_groups)) stop("A main-text group has no candidate")
## Exactly one main-text country per group, taken from the candidates
chosen <- candidates %>% filter(main_text)
if (nrow(chosen) != length(main_text_countries) || !setequal(chosen$design_group, candidate_groups)) {
  stop("main_text_countries must hold one candidate of each of the four groups")
}
write.csv(candidates, file.path(dir_tables, "03_sankey_candidates.csv"), row.names = FALSE)


## --- Main-text countries: PDF + PNG ---
bad_main <- setdiff(main_text_countries, countries$country)
if (length(bad_main) > 0) stop("main_text_countries not among the 43 countries: ", paste(bad_main, collapse = ", "))
for (iso in main_text_countries) {
  save_fig(make_sankey(iso), paste0("03_A2c_sankey_", iso), width = 11, height = 7.5)
}


## --- Summary ---
cat("\nLinks (instrument x division), headline set:", nrow(links), "in", nrow(countries), "countries",
    "| flows (country x base group x division):", nrow(flows), "\n")
cat("Flow colours (top 5 base groups by links, pooled):",
    paste0(top_groups$base_group, " (", top_groups$n_links, ")", collapse = ", "), "\n")
cat("Links per country: median", median(countries$n_links), "| min", min(countries$n_links),
    "| max", max(countries$n_links), "\n")
cat("\nMain-text candidates (links closest to the group median):\n")
for (i in seq_len(nrow(candidates))) {
  cat(" ", candidates$design_group[i], "(median", candidates$group_median_links[i], "of",
      candidates$n_countries_in_group[i], "countries):", candidates$country[i], candidates$country_name[i],
      "-", candidates$n_links[i], "links\n")
}
cat("\nPDF:", n_pages, "pages in", file_pdf, "\n")
cat("Country PNGs:", length(png_files), "in", dir_figures_sankey, "\n")
cat("Main-text figures (PDF + PNG):", if (length(main_text_countries) > 0) paste(main_text_countries, collapse = ", ")
    else "none chosen yet", "\n")
cat("Tables: 03_sankey_flows.csv, 03_sankey_candidates.csv in", dir_tables, "\n")
