# PLOT STYLE — figures of the paper (v1.0, 1 Nov 2026)

Colours, theme and export are coded once in `analysis/theme_earmark.R`. Every figure script sources it; no script defines its own colours.

## 1. Colour does a job

| job | palette | use |
|---|---|---|
| one series | navy `#0A2B4F` | most bar and dot charts: the title names the series, no legend |
| two series | navy + light blue (`pal_two`) | E3 vs E2, instruments vs allocations |
| categories with no order | `pal_cat`: blue, teal, gold, plum, green, light blue, in this fixed order | legal family, recipient form, base groups |
| ordered categories | `pal_ord`: light → dark blue | commitment strength, bands |
| magnitude (heatmap counts) | continuous `seq_low` → navy | the source × function heatmap |
| emphasis | orange `#D75415` | **only** the one thing to see: reform candidates, a highlighted country or cell |
| context, other, not applicable | grey `#A3A9B0` (lighter greys for less) | "Other", non-earmark classes, comparison points |
| background highlight | sand `#E5E1A7` | a shaded band behind marks; never a mark (too light to read) |

**Fixed meanings** (`pal_eclass`, `pal_commitment`, `pal_benefit`, `pal_family`) keep the same colour in every figure. For example, E3 is always navy and "unlinked" is always orange.

## 2. Rules

1. **At most 6 colours.** A 7th category is never a new colour: fold the smallest into "Other" (grey), or use small multiples. Scatter plots use at most 3 colours.
2. **Orange is rare.** One accented element per figure; everything else is navy, blue or grey.
3. **De-emphasise with grey, emphasise with saturation.** Something less important, dropped or "not applicable" is grey; the point of the figure is the most saturated colour.
4. **Text is never coloured.** Labels, values and legends stay in ink or dark grey; the coloured mark next to them carries the identity.
5. **Readable at page width.** Base text size 14. Axis labels are horizontal (flip the chart if category names are long). No more than about 12 bars per panel.
6. **Light structure.** No minor grid, a light major grid, no box or chart junk. The legend sits at the bottom; with 2–4 series, label them directly instead.
7. **No dual axes, no 3D, no pie charts.** Shares are horizontal stacked bars, ordered by size.
8. **Every caption states the unit**: instrument, instrument × function, allocation or country, as in ANALYSIS_SPEC §0.

## 3. Sankey (A2c)

- Flows go from base group to COFOG division and count instrument–function links. The caption says "number of links, not revenue".
- Colour the flows by the **source** side with `pal_cat` (the top 5 base groups plus "Other" in grey).
- Catch-all groups (services_acts_other) are never among the coloured top 5.
- Nodes are dark grey bars with labels. Keep the same node order in every country, so the country pages can be compared.

## 4. Export

`save_fig(plot, name)` writes a PDF (for the paper) and a 300 dpi PNG (for the Quarto reports) to `dir_figures`, which is set in `paths.R`. The default size is 7 × 4.5 in.

The categorical palette and the ordinal ramp passed the dataviz palette validator (colour-blind separation, contrast on white). Re-run the validator if a colour changes.
