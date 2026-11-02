## ============================================================================
## paths.R — every folder and input file of the analysis (ANALYSIS_SPEC §0, Folders)
## Source it first in every script:  source(here::here("analysis", "paths.R"))
## No other script hard-codes a path.
## ============================================================================

## --- Project root ---
## here() finds the root from the .git folder, so a script runs from any working directory
root <- here::here()

## --- Data folders ---
## supporting-data: raw external downloads (WoRLD, GRD, PEFA) and the hand-built country_groups.csv;
##                  never modified by scripts
## created-data:    every dataset a script creates (stacked CSV, .rds files)
dir_supporting <- file.path(root, "analysis_data", "supporting-data")
dir_created    <- file.path(root, "analysis_data", "created-data")

## --- Inputs ---
## Frozen stacked table (built by build_instrument_destination.py) and its build report.
## "prelim" becomes "validated" after the validation of ANALYSIS_SPEC §4.
file_stacked        <- file.path(dir_created, "ssa_earmarks_instrument_destination_prelim_2026-11.csv")
file_build_report   <- file.path(dir_created, "ssa_earmarks_instrument_destination_prelim_2026-11_build_report.csv")
file_country_groups <- file.path(dir_supporting, "country_groups.csv")

for (f in c(file_stacked, file_build_report, file_country_groups)) {
  if (!file.exists(f)) stop("Input file not found: ", f)
}

## --- Datasets created by the scripts ---
file_analysis_rds <- file.path(dir_created, "ssa_earmarks_analysis_prelim_2026-11.rds")

## --- Outputs of one pass ---
## The date is a constant, not Sys.Date(): every script of one pass writes to the same folder, and the
## qmd reports read from that one place. Change it by hand to start a new pass.
run_date    <- "2026-11-02"
dir_output  <- file.path(root, "analysis", "output")
out_dir     <- file.path(dir_output, run_date)
dir_tables  <- file.path(out_dir, "tables")
dir_figures <- file.path(out_dir, "figures")   # used by save_fig() in theme_earmark.R
dir.create(dir_tables,  recursive = TRUE, showWarnings = FALSE)
dir.create(dir_figures, recursive = TRUE, showWarnings = FALSE)
