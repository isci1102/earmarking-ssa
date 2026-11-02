## ============================================================================
## theme_earmark.R — colours, theme and figure export for every figure of the paper
## Rules in docs/PLOT_STYLE.md. Source it after paths.R:  source("analysis/theme_earmark.R")
## ============================================================================

library(ggplot2)

## --- Brand anchors ---
## Navy carries single-series charts. Orange is reserved for emphasis (the one thing the
## reader must see: reform candidates, a highlighted country); it is never an ordinary category.
## Grey means "context, other, not applicable": anything the reader should look past.
col_navy      <- "#0A2B4F"
col_accent    <- "#D75415"
col_grey      <- "#A3A9B0"
col_grey_dark <- "#5F6670"   # secondary text, axis titles
col_ink       <- "#1F2933"   # main text
col_band      <- "#E5E1A7"   # background highlight band behind marks only, never a mark (too light)

## --- Two series: dark and light blue (e.g. E3 vs E2, instruments vs allocations) ---
pal_two <- c("#0A2B4F", "#86AEDD")

## --- Categorical: up to 6 categories, fixed order, never cycled ---
## Validated on white (dataviz validator, 1 Nov 2026): lightness band, chroma, colour-blind
## separation of neighbours (worst ΔE 13.5), normal-vision floor (17.7), contrast >= 3:1.
## The first 3 also pass the all-pairs test, so scatter plots use at most 3 colours.
## A 7th category is never a new colour: fold the smallest ones into "Other" (col_grey).
pal_cat <- c("#245C9E",   # blue
             "#11948F",   # teal
             "#B8821C",   # gold
             "#8E5DA3",   # plum
             "#729A22",   # green
             "#4D93CB")   # light blue

## --- Ordinal / sequential: one hue, light -> dark (validated as an ordinal ramp) ---
pal_ord <- c("#86AEDD", "#4D85C4", "#245C9E", "#0A2B4F")
## Continuous version for heatmaps (counts): white-ish to navy
seq_low  <- "#EEF3F9"
seq_high <- "#0A2B4F"

## --- Semantic maps: the colour says what the category means ---
## E-classes: earmarks in blues (exclusive darkest), non-earmarks in greys.
pal_eclass <- c(E3 = "#0A2B4F", E2 = "#4D85C4",
                E1 = "#8C939C", E4 = "#B8BEC6", E0 = "#DADDE1")

## Commitment strength: ordinal blues, "none" in grey.
pal_commitment <- c(hard = "#0A2B4F", firm = "#245C9E", soft = "#86AEDD", none = "#DADDE1")

## Benefit link: the four linked classes in distinct hues, general revenue in grey (no
## specific base), unlinked in the accent (the policy-relevant class). Keep this stacking
## order: green and orange collapse for colour-blind readers, and grey sits between them.
pal_benefit <- c(corrective      = "#11948F",
                 compensatory    = "#B8821C",
                 benefit         = "#245C9E",
                 sectoral        = "#729A22",
                 general_revenue = "#A3A9B0",
                 unlinked        = "#D75415",
                 not_applicable  = "#DADDE1")

## Legal family: categorical slots in fixed order. Names are the codes of
## country_groups.csv (legal_family), so scale_*_manual() matches them.
pal_family <- c(francophone_civil  = "#245C9E",
                anglophone_common  = "#11948F",
                lusophone_civil    = "#B8821C",
                hispanophone_civil = "#8E5DA3",
                mixed              = "#729A22")

## Design group (A7): the first 5 slots of pal_cat, the validated contiguous set, so the
## three francophone groups stay distinguishable. The two 2-country groups are labelled
## grey points, never groups with a colour of their own (ANALYSIS_SPEC A7).
pal_design <- c(uemoa_francophone  = "#245C9E",
                cemac_francophone  = "#8E5DA3",
                francophone_noncfa = "#729A22",
                anglophone_common  = "#11948F",
                lusophone_noncfa   = "#B8821C",
                cfa_nonfrancophone = "#A3A9B0",
                mixed              = "#A3A9B0")

## --- Theme: large, readable text; recessive grid ---
## base_size 14 so that axis labels stay readable when the figure is shrunk to page width.
theme_earmark <- function(base_size = 14) {
  theme_minimal(base_size = base_size) +
    theme(
      text               = element_text(colour = col_ink),
      plot.title         = element_text(face = "bold", size = rel(1.15), hjust = 0),
      plot.subtitle      = element_text(colour = col_grey_dark, hjust = 0),
      plot.caption       = element_text(colour = col_grey_dark, size = rel(0.8), hjust = 0),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      axis.title         = element_text(colour = col_grey_dark, size = rel(0.95)),
      axis.text          = element_text(colour = col_ink, size = rel(0.9)),
      panel.grid.minor   = element_blank(),
      panel.grid.major   = element_line(colour = "#E6E8EB", linewidth = 0.4),
      legend.position    = "bottom",
      legend.title       = element_blank(),
      legend.text        = element_text(size = rel(0.9)),
      strip.text         = element_text(face = "bold", hjust = 0),
      plot.margin        = margin(10, 14, 10, 10)
    )
}
theme_set(theme_earmark())

## --- Export: PDF for the paper, PNG for the Quarto reports ---
## dir_figures comes from paths.R. Default size fits a page width at full text size.
save_fig <- function(plot, name, width = 7, height = 4.5) {
  ggsave(file.path(dir_figures, paste0(name, ".pdf")), plot, width = width, height = height,
         device = cairo_pdf)
  ggsave(file.path(dir_figures, paste0(name, ".png")), plot, width = width, height = height,
         dpi = 300, bg = "white")
}
