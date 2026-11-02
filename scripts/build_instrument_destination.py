#!/usr/bin/env python3
"""
Build the instrument x destination table from the two extraction outputs.

    outputs/instruments/{ISO3}_INSTRUMENTS.json         (one row per instrument)
  x outputs/allocations/{ISO3}_EARMARK_ALLOCATIONS.json (one row per instrument-or-pool -> destination)
  = outputs/derived/{ISO3}_INSTRUMENT_DESTINATION.csv   (one row per instrument_id x allocation_id)

Derived columns (definitions in DERIVED_TABLE_SPEC.md):
  leg_class, earmark_class, earmark_class_determinate, restricted_share_total,
  commitment_strength, benefit_link, benefit_link_basis.

No LLM step: every derived value is a deterministic function of extracted fields,
the signed-off concordance, and an optional overrides file. This is what makes the
classification replicable and keeps source and destination coding blind to each other.

Usage
  python build_instrument_destination.py COUNTRY_FOLDER [COUNTRY_FOLDER ...]
  python build_instrument_destination.py "countries/*" ...      (patterns are expanded by the script,
                                                                 so this also works in PowerShell / cmd)
         --concordance benefit_link_concordance.csv
         [--overrides benefit_link_overrides.csv]
         [--stacked all_countries_INSTRUMENT_DESTINATION.csv]

A country that fails a check is skipped and reported; the others are still built. With --stacked, a
build report ({stacked stem}_build_report.csv) lists every folder with its status and message, and the
stacked file contains the countries that passed only. The exit code is 1 if any country failed.
"""
from __future__ import annotations

import argparse
import glob
import json
import sys
from pathlib import Path

import pandas as pd


class CountryError(Exception):
    """A check failed for one country: that country is skipped, the run continues."""

# ---------------------------------------------------------------------------
# Closed vocabularies (must match the two extraction prompts)
# ---------------------------------------------------------------------------
BASE_CATEGORIES = {
    "general_income", "general_consumption", "general_trade", "general_revenue_class",
    "payroll_employment", "property_land", "financial_insurance", "harmful_consumption",
    "fuel_energy", "motor_vehicles_road", "air_maritime_rail_transport", "telecom_ict_postal",
    "media_advertising", "extractive_resources", "forestry_wildlife_fisheries",
    "agricultural_commodities", "water", "pollution_waste_environment", "gambling_lotteries",
    "tourism_hospitality", "construction_urban", "health_education_services",
    "public_administrative_acts", "regulated_activities_professions", "persons", "other_specific",
}
# Broad (ability-to-pay) bases: McCleary's "general tax". They feed the
# general_revenue class when no economic link applies.
BROAD_BASES = {"general_income", "general_consumption", "general_trade", "general_revenue_class"}

LINK_VALUES = {"corrective", "compensatory", "benefit", "sectoral",
               "general_revenue", "unlinked", "not_applicable"}
NON_FUNCTIONAL = {"general_budget", "subnational_unrestricted", "external_unrestricted",
                  "refund_reserve", "unallocated"}

# Vehicles with their own account or budget outside the annual ministerial vote.
# Used for commitment_strength (hard earmarks need a dedicated vehicle).
DEDICATED_FORMS = {"fund", "agency", "special_account", "social_security_institution",
                   "subnational_government", "supranational_body", "foreign_government",
                   "non_government_body"}
STRONG_RANKS = {"constitution", "organic_law", "ordinary_law"}
WEAK_RANKS = {"regulation", "other"}   # revocable by the executive -> soft

COMPLETE_BASES = {"whole_proceeds_implied", "residual"}
PCT_TOL = 0.5


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------
def load_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def load_country(folder: Path) -> tuple[str, pd.DataFrame, pd.DataFrame]:
    out = folder / "outputs"
    alloc_files = sorted((out / "allocations").glob("*_EARMARK_ALLOCATIONS.json"))
    if len(alloc_files) != 1:
        raise CountryError(f"[{folder}] expected exactly one *_EARMARK_ALLOCATIONS.json in outputs/allocations/")
    iso3 = alloc_files[0].name.split("_")[0]
    instr_path = out / "instruments" / f"{iso3}_INSTRUMENTS.json"
    if not instr_path.exists():
        raise CountryError(f"[{iso3}] missing {instr_path.name}")
    alloc = pd.DataFrame(load_json(alloc_files[0])["rows"])
    instr = pd.DataFrame(load_json(instr_path)["rows"])
    return iso3, alloc, instr


def load_concordance(path: Path) -> dict[tuple[str, str], str]:
    conc = pd.read_csv(path, dtype=str)
    bad_base = set(conc.base_category) - BASE_CATEGORIES
    bad_link = set(conc.benefit_link) - LINK_VALUES
    if bad_base or bad_link:
        sys.exit(f"concordance: unknown base_category {bad_base or ''} / benefit_link {bad_link or ''}")
    dup = conc.duplicated(["base_category", "cofog_code"])
    if dup.any():
        sys.exit(f"concordance: duplicated keys\n{conc[dup]}")
    return {(r.base_category, r.cofog_code): r.benefit_link for r in conc.itertuples()}


def load_overrides(path: Path | None) -> pd.DataFrame:
    if path is None or not path.exists():
        return pd.DataFrame(columns=["instrument_id", "allocation_id", "benefit_link", "reason"])
    ov = pd.read_csv(path, dtype=str)
    if (set(ov.benefit_link) - LINK_VALUES) or ov.reason.isna().any():
        sys.exit("overrides: invalid benefit_link or missing reason")
    return ov


# ---------------------------------------------------------------------------
# Leg-level classification (one allocation row)
# ---------------------------------------------------------------------------
def leg_class(a: pd.Series) -> str:
    """Economic role of one allocation leg. Order matters: the general-budget and
    refund legs are identified first, then administrative retentions (cost recovery,
    staff payments), which are kept out of the earmark numerator however restricted
    their use is in law."""
    if a.recipient_form == "general_budget":
        return "general_budget"
    if a.allocation_nature == "refund_reserve":
        return "refund_reserve"
    if a.allocation_nature == "cost_recovery":
        return "cost_recovery"
    if a.recipient_form == "staff_personal_payment":
        return "staff_payment"
    if int(a.is_purpose_restricted) == 1:
        return "restricted"
    return "unrestricted"


def commitment_strength(a: pd.Series) -> str:
    """Hard/firm/soft earmark (McCleary 1991; Brett & Keen 2000; Marsiliani &
    Renstrom 2000): how costly the assignment is to undo, read from the law alone."""
    if a.leg_class != "restricted":
        return "none"
    if a.determinacy != "determinate" or a.legal_rank in WEAK_RANKS:
        return "soft"
    if a.recipient_form in DEDICATED_FORMS and a.legal_rank in STRONG_RANKS:
        return "hard"
    return "firm"   # determinate, but annual finance law or a ministry vote / programme


# ---------------------------------------------------------------------------
# Group- and instrument-level earmark class (E0-E4)
# ---------------------------------------------------------------------------
ADMIN = {"cost_recovery", "staff_payment", "refund_reserve"}   # neutral for exclusivity
DIVERTING = {"general_budget", "unrestricted"}                  # break exclusivity


def _numeric_pct(legs: pd.DataFrame) -> bool:
    """True when every leg carries a pct value that can be summed (stated, or a
    residual the extraction already computed)."""
    return len(legs) > 0 and (legs.share_unit == "pct").all() and legs.share_value.notna().all()


def group_profile(legs: pd.DataFrame) -> dict:
    """Summarise one allocation group's level-1 key.

    Level-1 legs partition gross proceeds; deeper levels only subdivide a level-1
    leg, so completeness is judged at level 1. A group with restricted legs only at
    level >= 2 has an unobserved level-1 key -> completeness unknown.

    Administrative retentions (cost recovery, staff payments, refund reserve) are
    neutral: an instrument whose proceeds, net of these retentions, are all
    restricted is exclusive (E3). Only a general-budget or unrestricted leg, or a
    silent remainder, diverts proceeds."""
    l1 = legs[legs.share_level == 1]
    r_any = (legs.leg_class == "restricted").any()
    r1 = l1[l1.leg_class == "restricted"]
    # Diversion is checked at EVERY level: an unrestricted or general-budget share of
    # a sub-pool (e.g. SACU partner states' shares of the customs component, coded at
    # level 2 with no level-1 parent row) still takes part of the proceeds out of
    # restricted use.
    div1 = legs[legs.leg_class.isin(DIVERTING)]

    # covers_whole_proceeds (allocation prompt v1.1) is a group property: does the
    # clause assign the WHOLE proceeds to the group's destinations, whatever the
    # split between them? Exclusivity depends on this, not on share determinacy.
    covers = int(legs.covers_whole_proceeds.iloc[0])

    status, share = "no_restricted", None
    if r_any:
        if len(div1) > 0:
            status = "partial"                     # budget / unrestricted leg takes part
        elif len(r1) == 0:
            status = "unknown"                     # restricted legs only below level 1
        elif covers == 1:
            status = "complete"                    # all proceeds to restricted (+ admin) legs,
                                                   # even if the split is deferred or unstated
        else:
            status = "partial"                     # only a part is assigned; the rest stays
                                                   # in the general budget by default
        if len(r1) and r1.share_basis.eq("whole_proceeds_implied").any():
            share = 100.0
        elif _numeric_pct(r1):
            share = float(r1.share_value.sum())
        elif status == "complete":
            # Split among restricted legs unknown, but together they take everything
            # net of administrative retentions.
            admin1 = l1[l1.leg_class.isin(ADMIN)]
            if len(admin1) == 0:
                share = 100.0
            elif _numeric_pct(admin1):
                share = 100.0 - float(admin1.share_value.sum())
    return {
        "status": status,
        "restricted_share": share,
        "has_diverting": legs.leg_class.isin(DIVERTING).any(),
        "has_unrestricted": (legs.leg_class == "unrestricted").any(),
        "has_admin": legs.leg_class.isin(["cost_recovery", "staff_payment"]).any(),
    }


def instrument_class(profiles: list[dict]) -> tuple[str, int, float | None]:
    """Aggregate an instrument's groups into one E-class.

    The class is a property of the INSTRUMENT, computed over all allocations of
    all groups it belongs to.
    E3 exclusive: proceeds net of administrative retentions are all restricted
                  (no general-budget or unrestricted leg in any group).
    E2 partial:   restricted legs exist, but a general-budget or unrestricted leg
                  (or a silent remainder) takes part of the proceeds.
    The class does not depend on share determinacy: whole proceeds assigned to a
    fund and an agency with the split deferred is E3 (determinacy is recorded
    separately). earmark_class_determinate = 0 is left only for conflicting keys
    across groups and for restricted legs observed only below level 1.
    E1: no restricted leg; at least one unrestricted leg (e.g. tier general budgets).
    E4: only administrative retentions (cost recovery, staff payments), possibly
        beside a general-budget residual.
    E0: only a refund reserve (the assignment nets the tax; nothing is dedicated)."""
    st = [p["status"] for p in profiles]
    restricted = [s for s in st if s != "no_restricted"]
    if restricted:
        # A group without restricted legs that sends proceeds to the budget or an
        # unrestricted recipient also diverts part of the instrument's proceeds.
        diverted = ("partial" in st) or any(
            p["has_diverting"] for p in profiles if p["status"] == "no_restricted")
        shares = [p["restricted_share"] for p in profiles if p["status"] != "no_restricted"]
        share = shares[0] if len(shares) == 1 else None
        if "complete" in st and not diverted:
            # share = restricted proceeds only (e.g. 95 when 5% is cost recovery)
            return "E3", int("unknown" not in st), share
        if diverted:
            return "E2", int("complete" not in st), share   # complete+diverted = conflicting keys
        return "E2", 0, share                                  # only unknown keys
    if any(p["has_unrestricted"] for p in profiles):
        return "E1", 1, None
    if any(p["has_admin"] for p in profiles):
        return "E4", 1, None
    return "E0", 1, None


# ---------------------------------------------------------------------------
# Benefit link
# ---------------------------------------------------------------------------
def benefit_link(r: pd.Series, conc: dict) -> tuple[str | None, str]:
    """Ordered test of the 6-class typology (corrective > compensatory > benefit >
    sectoral > general_revenue > unlinked). Classes 1-4 come from the concordance
    (group code first, then division); compensatory also fires for restricted
    derivation transfers; general_revenue and unlinked are residual rules on the
    base alone. Primary COFOG function only; cofog_secondary is not used."""
    if r.leg_class != "restricted":
        return "not_applicable", "not_restricted"
    if r.cofog_division in NON_FUNCTIONAL:
        return None, "function_unallocated"
    hit, basis = None, None
    if isinstance(r.cofog_group, str) and (r.base_category, r.cofog_group) in conc:
        hit, basis = conc[(r.base_category, r.cofog_group)], "concordance_group"
    elif (r.base_category, r.cofog_division) in conc:
        hit, basis = conc[(r.base_category, r.cofog_division)], "concordance_division"
    if hit == "corrective":
        return hit, basis
    if r.assignment_type == "derivation_transfer":
        return "compensatory", "derivation_rule"
    if hit:
        return hit, basis
    if r.base_category in BROAD_BASES:
        return "general_revenue", "broad_base_rule"
    return "unlinked", "residual_rule"


# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
def build(iso3: str, alloc: pd.DataFrame, instr: pd.DataFrame,
          conc: dict, overrides: pd.DataFrame) -> pd.DataFrame:
    alloc = alloc.copy()
    if "covers_whole_proceeds" not in alloc.columns:
        raise CountryError(f"[{iso3}] allocation table lacks covers_whole_proceeds (needs allocation prompt v1.1)")
    incoherent = alloc.groupby("allocation_group_id").covers_whole_proceeds.nunique() > 1
    if incoherent.any() or alloc.covers_whole_proceeds.isna().any():
        raise CountryError(f"[{iso3}] covers_whole_proceeds null or not constant within groups: "
                 f"{sorted(incoherent[incoherent].index)}")
    alloc["leg_class"] = alloc.apply(leg_class, axis=1)
    alloc["commitment_strength"] = alloc.apply(commitment_strength, axis=1)

    # Bridge: one row per (instrument, group).
    bridge = instr[["instrument_id", "allocation_group_ids"]].explode("allocation_group_ids") \
        .rename(columns={"allocation_group_ids": "allocation_group_id"})

    # --- integrity of the link before joining
    g_alloc, g_instr = set(alloc.allocation_group_id), set(bridge.allocation_group_id)
    if g_alloc - g_instr:
        raise CountryError(f"[{iso3}] groups with no instrument: {sorted(g_alloc - g_instr)}")
    if g_instr - g_alloc:
        raise CountryError(f"[{iso3}] instrument rows point to unknown groups: {sorted(g_instr - g_alloc)}")

    # Instrument-level E-class from the profiles of all its groups.
    profiles = {g: group_profile(d) for g, d in alloc.groupby("allocation_group_id")}
    eclass = {}
    for iid, d in bridge.groupby("instrument_id"):
        eclass[iid] = instrument_class([profiles[g] for g in d.allocation_group_id])
    ec = pd.DataFrame.from_dict(eclass, orient="index",
                                columns=["earmark_class", "earmark_class_determinate",
                                         "restricted_share_total"]) \
        .rename_axis("instrument_id").reset_index()

    n_instr = bridge.groupby("allocation_group_id").size().rename("n_instruments_in_group")

    i_cols = ["instrument_id", "official_name", "row_kind", "instrument_type", "gfs_code",
              "base_category", "base_isic_division", "charging_provision_in_corpus",
              "legal_reference", "document_year", "ai_confidence"]
    a_cols = ["allocation_id", "allocation_group_id", "country", "is_pool", "destination_name",
              "recipient_form", "recipient_level", "cofog_division", "cofog_group", "cofog_basis",
              "is_purpose_restricted", "allocation_nature", "assignment_type", "share_value",
              "share_unit", "share_basis", "share_level", "share_pool",
              "covers_whole_proceeds", "determinacy",
              "deferred_to", "legal_rank", "leg_class", "commitment_strength",
              "legal_reference", "document_year", "ai_confidence"]

    df = (bridge
          .merge(instr[i_cols].rename(columns={"legal_reference": "instr_legal_reference",
                                               "document_year": "instr_document_year",
                                               "ai_confidence": "instr_ai_confidence"}),
                 on="instrument_id", how="left")
          .merge(alloc[a_cols].rename(columns={"legal_reference": "alloc_legal_reference",
                                               "document_year": "alloc_document_year",
                                               "ai_confidence": "alloc_ai_confidence"}),
                 on="allocation_group_id", how="left")
          .merge(n_instr, on="allocation_group_id", how="left")
          .merge(ec, on="instrument_id", how="left"))

    links = df.apply(lambda r: benefit_link(r, conc), axis=1, result_type="expand")
    df["benefit_link"], df["benefit_link_basis"] = links[0], links[1]

    # Overrides are applied last and are always logged in benefit_link_basis.
    for o in overrides.itertuples():
        m = (df.instrument_id == o.instrument_id) & (df.allocation_id == o.allocation_id)
        if m.sum() != 1:
            raise CountryError(f"[{iso3}] override matches {m.sum()} rows: {o.instrument_id} x {o.allocation_id}")
        df.loc[m, "benefit_link"] = o.benefit_link
        df.loc[m, "benefit_link_basis"] = "override: " + o.reason

    # --- identities
    expected = sum(n_instr[g] * n for g, n in alloc.groupby("allocation_group_id").size().items())
    if not (len(df) == expected):
        raise CountryError(f"[{iso3}] row count {len(df)} != sum_g nI(g)*nA(g) = {expected}")
    if not (not df.duplicated(["instrument_id", "allocation_id"]).any()):
        raise CountryError(f"[{iso3}] duplicate keys")
    if not (set(df.allocation_id) == set(alloc.allocation_id)):
        raise CountryError(f"[{iso3}] allocation lost in join")
    if not (set(df.instrument_id) == set(instr.instrument_id)):
        raise CountryError(f"[{iso3}] instrument lost in join")
    if not (set(df.base_category) <= BASE_CATEGORIES):
        raise CountryError(f"[{iso3}] unknown base_category")

    order = (["country", "instrument_id", "allocation_id", "allocation_group_id"]
             + [c for c in i_cols if c not in ("instrument_id", "legal_reference",
                                               "document_year", "ai_confidence")]
             + ["is_pool", "n_instruments_in_group"]
             + [c for c in a_cols[4:] if c not in ("leg_class", "commitment_strength",
                                                   "legal_reference", "document_year",
                                                   "ai_confidence")]
             + ["leg_class", "earmark_class", "earmark_class_determinate",
                "restricted_share_total", "commitment_strength", "benefit_link",
                "benefit_link_basis", "alloc_legal_reference", "instr_legal_reference",
                "alloc_document_year", "instr_document_year",
                "alloc_ai_confidence", "instr_ai_confidence"])
    return df[order].sort_values(["instrument_id", "allocation_id"]).reset_index(drop=True)


def expand_folders(args: list[str]) -> list[Path]:
    """Expand wildcard patterns here (PowerShell and cmd pass them unexpanded); keep folders only."""
    folders = []
    for a in args:
        matches = sorted(glob.glob(a)) if any(ch in a for ch in "*?[") else [a]
        if not matches:
            print(f"no folder matches: {a}")
        folders += [Path(m) for m in matches if Path(m).is_dir()]
    return list(dict.fromkeys(folders))          # drop duplicates, keep order


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("folders", nargs="+")
    p.add_argument("--concordance", type=Path, required=True)
    p.add_argument("--overrides", type=Path, default=None)
    p.add_argument("--stacked", type=Path, default=None)
    a = p.parse_args()

    folders = expand_folders(a.folders)
    if not folders:
        sys.exit("no country folder to build")

    # Concordance and overrides are shared by all countries: an error there stops the run.
    conc = load_concordance(a.concordance)
    overrides = load_overrides(a.overrides)

    frames, report = [], []
    for folder in folders:
        try:
            iso3, alloc, instr = load_country(folder)
            ov = overrides[overrides.instrument_id.str.startswith(iso3 + "_")] if len(overrides) else overrides
            df = build(iso3, alloc, instr, conc, ov)
        except CountryError as e:                       # a failed check: skip the country, keep going
            print(f"SKIPPED {folder}: {e}")
            report.append({"folder": str(folder), "country": None, "status": "failed_check",
                           "rows": None, "instruments": None, "allocations": None, "message": str(e)})
            continue
        except Exception as e:                          # unreadable file, missing column, ...
            print(f"SKIPPED {folder}: {type(e).__name__}: {e}")
            report.append({"folder": str(folder), "country": None, "status": "error",
                           "rows": None, "instruments": None, "allocations": None,
                           "message": f"{type(e).__name__}: {e}"})
            continue
        out = folder / "outputs" / "derived" / f"{iso3}_INSTRUMENT_DESTINATION.csv"
        out.parent.mkdir(parents=True, exist_ok=True)
        df.to_csv(out, index=False, encoding="utf-8")
        n_i, n_a = df.instrument_id.nunique(), df.allocation_id.nunique()
        print(f"{iso3}: {len(df)} rows | {n_i} instruments | {n_a} allocations | "
              f"E: {df.drop_duplicates('instrument_id').earmark_class.value_counts().to_dict()} -> {out}")
        report.append({"folder": str(folder), "country": iso3, "status": "built",
                       "rows": len(df), "instruments": n_i, "allocations": n_a, "message": None})
        frames.append(df)

    failed = [r for r in report if r["status"] != "built"]
    print(f"\nbuilt {len(frames)} of {len(folders)} folders; skipped {len(failed)}"
          + (": " + ", ".join(r["folder"] for r in failed) if failed else ""))

    if a.stacked:
        if frames:
            pd.concat(frames, ignore_index=True).to_csv(a.stacked, index=False, encoding="utf-8")
            print(f"stacked ({len(frames)} countries) -> {a.stacked}")
        report_path = a.stacked.with_name(a.stacked.stem + "_build_report.csv")
        rep = pd.DataFrame(report).astype({"rows": "Int64", "instruments": "Int64", "allocations": "Int64"})
        rep.to_csv(report_path, index=False, encoding="utf-8")
        print(f"build report -> {report_path}")

    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
