#!/usr/bin/env python3
"""
find_hits.py -- recall checklist for the earmark extraction (run BEFORE the prompt).

Scans every document listed in the country manifest for assignment language and
writes two CSV files:

  {COUNTRY}_hits.csv         one row per legal unit (section / article / item)
                             containing at least one STRONG assignment cue.
                             This is the checklist the extraction prompt must
                             account for in its recall_audit.
  {COUNTRY}_doc_quality.csv  one row per document: text-layer quality, grouping
                             method used, hit counts, weak-cue counts.

Design choices (why the script looks the way it does):
  * The script does NOT extract anything. It only guarantees that every passage
    carrying a high-precision assignment cue is put in front of the model, so
    recall does not depend on the model's own attention. The model still reads
    every document in full.
  * Two cue tiers. STRONG cues (assignment phrases) create hits. WEAK cues
    ("fund", "levy", ...) are only counted per document: they are too frequent
    in long Acts to be audited hit by hit.
  * Matches are grouped by legal unit, not listed one by one. Five cues inside
    one section = one hit. If a unit's matches are far apart (> GAP pages or
    lines), the unit is split into separate hits so a hit always points to a
    readable passage.
  * If section headings cannot be detected reliably, grouping falls back to
    pages (PDF) or fixed line blocks (.md). The fallback is recorded.
  * Matching is done on text re-joined across line breaks (and de-hyphenated),
    because legal phrases such as "paid into the Fund" often break across lines.

Usage (from the country folder, e.g. Cowork Playground/countries/ZAF):
  pip install pandas openpyxl pymupdf        # pymupdf is optional; pypdf also works
  python find_hits.py --manifest ZAF_LEGAL_CORPUS_MANIFEST.xlsx --base . --out outputs/earmark

Existing output files are never overwritten unless --overwrite is given.
"""

import argparse
import csv
import re
import sys
import unicodedata
from pathlib import Path

import pandas as pd

# ---------------------------------------------------------------------------
# PDF backend: PyMuPDF is faster and handles more fonts; pypdf is the fallback.
# ---------------------------------------------------------------------------
try:
    import fitz  # PyMuPDF

    def read_pdf_pages(path):
        with fitz.open(path) as doc:
            return [page.get_text("text") for page in doc]
    PDF_BACKEND = "pymupdf"
except ImportError:
    from pypdf import PdfReader

    def read_pdf_pages(path):
        return [(p.extract_text() or "") for p in PdfReader(str(path)).pages]
    PDF_BACKEND = "pypdf"


# ---------------------------------------------------------------------------
# Lexicon
# ---------------------------------------------------------------------------
# STRONG cues: phrases that, in enacting text, almost always route proceeds
# somewhere. Kept deliberately broad (recall over precision): the model
# dismisses false positives with a code, which is cheap. Each entry is
# (label, regex). Labels appear in hits.csv so the user can see which cue fired.
_N = r"(?:\d+(?:[.,]\d+)?|[A-Za-z]+(?:-[A-Za-z]+)?)"   # 20, 2.5, 2,5 or "two", "twenty-five"

# Recipient nouns. Generic verbs ("transferred to", "for the benefit of",
# "accrue to") are extremely frequent in income-tax law (trusts, disposals,
# accruals to persons). Requiring a public-body noun within a few words keeps
# the English cues specific without losing Westminster fund-Act wording.
_RCP = (r"(?-i:Fund|Account|Board|Authority|Agency|Trust|Council|Corporation|Commission|"
        r"Institute|Foundation|SETAs?|Tribunal|Ombud\w*|Regulator|[Mm]unicipalit\w*|"
        r"[Mm]etropolitan\w*|[Pp]rovinc\w*|[Ll]ocal\s+[Gg]overnment|Government)")
# (?-i:...) keeps recipient nouns case-sensitive: statutes capitalise named
# bodies ("the Fund", "the Board"), while "a trust" / "the fund of a person" in
# income-tax law are lower case and should not fire.
_NEAR = r"\s+(?:the\s+)?(?:[\w'-]+\s+){0,5}?" + _RCP + r"\b"

STRONG_EN = [
    ("paid into",            r"\bpa(?:id|y|yable|yment)\s+(?:over\s+)?into\b"),
    ("paid over to",         r"\bpaid\s+over\s+to\b"),
    ("deposited into",       r"\bdeposit(?:ed)?\s+(?:in|into|with)" + _NEAR),
    ("credited to",          r"\bcredit(?:ed)?\s+to" + _NEAR),
    ("for the credit of",    r"\b(?:for|to)\s+the\s+credit\s+of\b"),
    ("direct charge",        r"\bdirect\s+charge\b"),
    ("accrue to",            r"\baccrue[sd]?\s+to" + _NEAR),
    ("shall be <verb>",      r"\bshall\s+be\s+(?:transferred|allocated|distributed|remitted|"
                             r"disbursed|apportioned|appropriated|set\s+aside|divided)\b"),
    ("used exclusively for", r"\b(?:used|utili[sz]ed|applied|spent)\s+(?:exclusively|solely|only)\s+"
                             r"(?:for|to|towards|on)\b"),
    ("earmarked",            r"\bear-?marked\b"),
    ("ring-fenced",          r"\bring-?fenced\b"),
    ("dedicated to",         r"\bdedicated\s+(?:to|for)\b"),
    ("allocated to",         r"\ballocat(?:ed|e|es)\s+(?:to|among|between)" + _NEAR),
    ("allocation of levy",   r"\ballocation\s+of\s+(?:the\s+)?(?:levy|levies|proceeds|revenue|"
                             r"amounts?\s+levied|moneys|monies|funds)\b"),
    ("distribution of levy", r"\bdistribution\s+of\s+(?:the\s+)?(?:levy|levies|proceeds|revenue|"
                             r"moneys|monies|funds|collections?)\b"),
    ("distributed to",       r"\bdistributed\s+(?:to|among|between)" + _NEAR),
    ("sharing of revenue",   r"\bshar(?:ing|e)\s+of\s+(?:the\s+)?(?:\w+\s+){0,2}?(?:revenue|proceeds|"
                             r"levy|levies|collections?)\b"),
    ("transferred to",       r"\btransferr?(?:ed|s)?\s+to" + _NEAR),
    ("retained by",          r"\bretained\s+by" + _NEAR + r"|\bretain(?:ed|s)?\b[^.;]{0,40}?"
                             r"(?:per\s*cent|%|portion|share)"),
    ("funds of the <body>",  r"\b(?:moneys?|monies|funds|sources?\s+of\s+(?:funds|income|revenue)|"
                             r"revenue|income|assets)\s+(?:and\s+assets\s+)?of\s+the\s+"
                             r"(?:[\w'-]+\s+){0,3}?" + _RCP + r"\b"),
    ("shall consist of",     r"\b(?:Fund|funds|moneys|monies|income|revenue)\b[^.;]{0,60}?"
                             r"\bshall\s+consist\s+of\b"),
    ("financing of",         r"\bfinanc(?:ed|ing)\s+(?:of|by|from)\s+the\b"),
    ("funded by/from",       r"\bfunded\s+(?:by|from|out\s+of)\b"),
    ("proceeds of levy",     r"\bproceeds\s+of\s+(?:the|any|such|this|that|a)\s+(?:\w+\s+){0,2}?"
                             r"(?:levy|tax|duty|charge|contribution|fee|royalty)\b"),
    ("for the benefit of",   r"\bfor\s+the\s+benefit\s+of" + _NEAR),
    ("levied for purpose",   r"\blevied\s+(?:for|in\s+order\s+to)\b"),
    ("pct of proceeds",      _N + r"\s*(?:%|per\s*cent(?:um)?)\s+of\s+(?:the\s+|all\s+|such\s+)?"
                             r"(?:levy|levies|proceeds|revenue|amounts?\s+(?:levied|collected)|"
                             r"collections?|moneys|monies|contributions?|inflows)\b"),
    ("pct to recipient",     _N + r"\s*(?:%|per\s*cent(?:um)?)\s+(?:shall\s+be\s+\w+\s+)?to" + _NEAR),
    ("revenue fund",         r"\b(?:National\s+Revenue|Consolidated)\s+Fund\b"),
]

STRONG_FR = [
    ("affecté",              r"\baffect(?:é|e|ée|és|ées|ation)\b"),
    ("au profit de",         r"\bau\s+profit\s+(?:de|du|des)\b"),
    ("au bénéfice de",       r"\bau\s+b[ée]n[ée]fice\s+(?:de|du|des)\b"),
    ("reversé",              r"\brevers(?:é|e|ée|és|ées|ement)\b"),
    ("réparti",              r"\br[ée]parti(?:e|s|es|tion)?\b"),
    ("quote-part",           r"\bquote-?\s?parts?\b"),
    ("quotité",              r"\bquotit[ée]s?\b"),
    ("produit de la taxe",   r"\bproduits?\s+(?:de\s+la|de\s+cette|de\s+ces|du|des|de\s+l['’])\s*"
                             r"(?:taxe|redevance|droit|contribution|pr[ée]l[èe]vement|imp[ôo]t|"
                             r"surtaxe|cotisation)"),
    ("alimente",             r"\baliment(?:e|é|ent|ée|ation)\b"),
    ("ristourne",            r"\bristourn(?:e|es|é|ée)\b"),
    ("compte spécial",       r"\bcompte\s+(?:sp[ée]cial|d['’]affectation)"),
    ("financé par",          r"\bfinanc[ée]e?s?\s+par\b"),
    ("versé au",             r"\bvers[ée]e?s?\s+(?:au|à\s+la|aux|à\s+l['’]|dans)\b"),
    ("rétrocession",         r"\br[ée]troc(?:ession|[ée]d[ée]e?s?)\b"),
    ("destiné au financement", r"\bdestin[ée]e?s?\s+au\s+financement\b"),
    ("pct à",                _N + r"\s*%\s+(?:au|à\s+la|aux|à\s+l['’]|pour\s+(?:le|la|les))\b"),
]

# WEAK cues: counted per document only (never create hits).
WEAK = {
    "en": [r"\bfunds?\b", r"\blev(?:y|ies)\b", r"\ballocat\w*", r"\btransfer\w*",
           r"\bproceeds\b", r"\bboard\b", r"\bauthority\b", r"\btrust\b"],
    "fr": [r"\bfonds\b", r"\bredevances?\b", r"\bparafiscal\w*", r"\bpr[ée]l[èe]vements?\b"],
}

STRONG = [(lab, re.compile(rx, re.IGNORECASE)) for lab, rx in STRONG_EN + STRONG_FR]
WEAK_RX = [re.compile(rx, re.IGNORECASE) for rx in WEAK["en"] + WEAK["fr"]]


# ---------------------------------------------------------------------------
# Legal-unit heading detection
# ---------------------------------------------------------------------------
# Containers reset section numbering (a Schedule restarts at item 1).
RX_CONTAINER = re.compile(
    r"^\s*(PART|Part|CHAPTER|Chapter|SCHEDULE|Schedule|TITRE|Titre|CHAPITRE|Chapitre|"
    r"LIVRE|Livre|ANNEXE|Annexe)\s+([0-9IVXLC]+[A-Z]?|premier|première|unique)?\b"
)
# A numbered section: "8. Distribution of levies", "8 Distribution", "12A. Rate".
# Requires a capital letter or "(" after the number, which excludes tariff codes
# (01.01), page numbers alone and most amounts.
RX_SECTION = re.compile(r"^\s*(?:Section\s+|SECTION\s+|Item\s+|ITEM\s+)?(\d{1,4}[A-Z]{0,4})\.?\s+(?=[A-Z(\[])")
RX_ARTICLE = re.compile(r"^\s*Art(?:icle|\.)\s*(\d+[\w\-]*(?:\s+(?:bis|ter|quater|quinquies))?|premier|1er)\b",
                        re.IGNORECASE)
RX_MD_HEADING = re.compile(r"^\s*#{1,6}\s+(.{1,80})")


def section_int(label):
    m = re.match(r"\d+", label)
    return int(m.group()) if m else None


# ---------------------------------------------------------------------------
# Text normalisation
# ---------------------------------------------------------------------------
LIGATURES = {"\ufb00": "ff", "\ufb01": "fi", "\ufb02": "fl", "\ufb03": "ffi", "\ufb04": "ffl",
             "\u00ad": "", "\u00a0": " ", "\u2019": "'", "\u2018": "'", "\u201c": '"', "\u201d": '"',
             "\u2013": "-", "\u2014": "-"}


def normalise(s):
    for k, v in LIGATURES.items():
        s = s.replace(k, v)
    return unicodedata.normalize("NFC", s)


def garbled_share(text):
    """Share of characters that signal a broken text layer (replacement chars,
    private-use glyphs, pdf '(cid:' artefacts). High values = unreliable text."""
    if not text:
        return 0.0
    bad = text.count("\ufffd") + sum(1 for c in text if "\ue000" <= c <= "\uf8ff")
    bad += 5 * text.count("(cid:")
    return bad / len(text)


# ---------------------------------------------------------------------------
# Core scan
# ---------------------------------------------------------------------------
def load_lines(path):
    """Return (anchor_unit, [(anchor, text_line), ...], n_pages_or_lines, raw_text).
    anchor = page number (PDF) or line number (.md/.txt)."""
    suffix = path.suffix.lower()
    if suffix == ".pdf":
        pages = read_pdf_pages(path)
        lines = [(i + 1, normalise(ln)) for i, pg in enumerate(pages) for ln in pg.splitlines()]
        return "page", lines, len(pages), "\n".join(pages)
    raw = path.read_text(encoding="utf-8", errors="replace")
    lines = [(i + 1, normalise(ln)) for i, ln in enumerate(raw.splitlines())]
    return "line", lines, len(lines), raw


def split_units(lines, anchor_unit, n_anchor):
    """Assign each line to a legal unit. Returns (unit_labels_per_line, method)."""
    labels, container, current = [], "", "front matter"
    last_sec, last_lab, n_detected = None, None, 0
    for _, txt in lines:
        m_c, m_a = RX_CONTAINER.match(txt), RX_ARTICLE.match(txt)
        m_s = RX_SECTION.match(txt)
        m_h = RX_MD_HEADING.match(txt) if anchor_unit == "line" else None
        if m_c:
            container = " ".join(x for x in m_c.groups() if x)
            current, last_sec, last_lab = container, None, None   # numbering restarts in a new container
            n_detected += 1
        elif m_a:
            current = f"{container} > art {m_a.group(1)}".strip(" >")
            n_detected += 1
        elif m_s:
            k = section_int(m_s.group(1))
            # Monotonicity guard: a numbered line only opens a new section if its
            # number does not go backwards and does not jump implausibly. This
            # rejects numbered sub-lists ("1. The Minister ...") inside a section.
            lab_s = m_s.group(1)
            ok = (last_sec is None or last_sec < k <= last_sec + 50
                  or (k == last_sec and lab_s != last_lab))          # 12 -> 12A is a new section
            if ok:
                current = f"{container} > s {lab_s}".strip(" >")
                last_sec, last_lab, n_detected = k, lab_s, n_detected + 1
        elif m_h:
            current = m_h.group(1).strip()
            n_detected += 1
        labels.append(current)

    # Fallback: too few headings -> section detection is unreliable for this
    # document; group by page (PDF) or 60-line blocks (.md) instead.
    min_units = max(3, n_anchor // (40 if anchor_unit == "page" else 400))
    if n_detected < min_units:
        if anchor_unit == "page":
            return [f"p. {a}" for a, _ in lines], "page_fallback"
        return [f"lines {((a - 1) // 60) * 60 + 1}-{((a - 1) // 60 + 1) * 60}" for a, _ in lines], "block_fallback"
    return labels, "legal_unit"


def scan_document(doc_id, path, gap):
    anchor_unit, lines, n_anchor, raw = load_lines(path)
    labels, method = split_units(lines, anchor_unit, n_anchor)

    # Re-join each unit's lines into one string (de-hyphenating across line
    # breaks) and keep an offset -> anchor map so each match gets a page/line.
    units = {}
    order = []
    for (anchor, txt), lab in zip(lines, labels):
        if lab not in units:
            units[lab] = {"text": "", "offsets": []}
            order.append(lab)
        u = units[lab]
        t = txt.strip()
        if not t:
            continue
        if u["text"].endswith("-") and t[:1].islower():
            u["text"] = u["text"][:-1]            # join a word split across lines
        elif u["text"]:
            u["text"] += " "
        u["offsets"].append((len(u["text"]), anchor))
        u["text"] += t

    def anchor_at(offsets, pos):
        a = offsets[0][1]
        for off, anc in offsets:
            if off > pos:
                break
            a = anc
        return a

    hits = []
    for lab in order:
        u = units[lab]
        if not u["text"]:
            continue
        found = []
        for cue, rx in STRONG:
            for m in rx.finditer(u["text"]):
                found.append((m.start(), anchor_at(u["offsets"], m.start()), cue))
        if not found:
            continue
        found.sort()
        # Split a unit into several hits if its matches are far apart.
        cluster = [found[0]]
        for f in found[1:]:
            if f[1] - cluster[-1][1] > gap:
                hits.append((lab, cluster, u["text"]))
                cluster = []
            cluster.append(f)
        hits.append((lab, cluster, u["text"]))

    rows = []
    for i, (lab, cl, text) in enumerate(hits, start=1):
        first = cl[0][0]
        snippet = text[max(0, first - 120): first + 200].replace("\n", " ")
        cues = list(dict.fromkeys(c for _, _, c in cl))        # unique, in order of appearance
        rows.append({
            "hit_id": f"{doc_id}::H{i:04d}",
            "document_id": doc_id,
            "legal_unit": lab,
            "anchor_unit": anchor_unit,
            "anchor_start": cl[0][1],
            "anchor_end": cl[-1][1],
            "n_matches": len(cl),
            "cues": "; ".join(cues),
            "snippet": re.sub(r"\s+", " ", snippet).strip(),
        })

    text_chars = sum(len(t.strip()) for _, t in lines)
    per = text_chars / max(n_anchor, 1)
    g = garbled_share(raw)
    if anchor_unit == "page":
        flag = "no_text_ocr_needed" if per < 50 else ("low_text" if per < 400 else "ok")
    else:
        flag = "no_text" if text_chars < 1000 else "ok"
    if g > 0.005:
        flag = "garbled"
    quality = {
        "document_id": doc_id, "file": str(path), "status": "scanned", "anchor_unit": anchor_unit,
        "n_pages_or_lines": n_anchor, "chars_per_page" if anchor_unit == "page" else "chars_per_line": round(per, 1),
        "garbled_share": round(g, 5), "text_flag": flag, "grouping": method,
        "n_hits": len(rows), "n_strong_matches": sum(r["n_matches"] for r in rows),
        "n_weak_matches": sum(len(rx.findall(raw)) for rx in WEAK_RX),
    }
    return rows, quality


# ---------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--manifest", required=True, help="manifest .xlsx (sheet 'documents') or .csv")
    ap.add_argument("--base", default=".", help="folder that relative_path values are relative to")
    ap.add_argument("--out", default="outputs/earmark", help="output folder")
    ap.add_argument("--gap", type=int, default=None,
                    help="split a unit's hits when matches are more than GAP pages (PDF) apart; "
                         "lines are scaled x50 for .md. Default 2.")
    ap.add_argument("--overwrite", action="store_true", help="allow overwriting existing outputs")
    args = ap.parse_args()

    mpath = Path(args.manifest)
    man = (pd.read_excel(mpath, sheet_name="documents") if mpath.suffix.lower() in (".xlsx", ".xls")
           else pd.read_csv(mpath))
    for col in ("document_id", "relative_path"):
        if col not in man.columns:
            sys.exit(f"Manifest is missing column '{col}'.")
    if man["document_id"].duplicated().any():
        sys.exit(f"Duplicate document_id in manifest: {man.loc[man.document_id.duplicated(), 'document_id'].tolist()}")
    country = str(man["country"].iloc[0]) if "country" in man.columns else "XXX"

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    f_hits, f_q = out / f"{country}_hits.csv", out / f"{country}_doc_quality.csv"
    existing = [str(f) for f in (f_hits, f_q) if f.exists()]
    if existing and not args.overwrite:
        sys.exit(f"Output already exists: {existing}. Re-run with --overwrite to replace it.")

    gap_pages = args.gap if args.gap is not None else 2
    all_hits, all_q = [], []
    for _, r in man.iterrows():
        doc_id, path = str(r["document_id"]), Path(args.base) / str(r["relative_path"])
        if not path.exists():
            all_q.append({"document_id": doc_id, "file": str(path), "status": "missing_file"})
            print(f"  MISSING  {doc_id}  ({path})")
            continue
        try:
            gap = gap_pages if path.suffix.lower() == ".pdf" else gap_pages * 50
            hits, q = scan_document(doc_id, path, gap)
        except Exception as e:                       # keep going; report the failure
            all_q.append({"document_id": doc_id, "file": str(path), "status": f"error: {e}"})
            print(f"  ERROR    {doc_id}: {e}")
            continue
        all_hits += hits
        all_q.append(q)
        print(f"  {q['text_flag']:<20} {doc_id:<42} hits={q['n_hits']:<5} grouping={q['grouping']}")

    hit_cols = ["hit_id", "document_id", "legal_unit", "anchor_unit", "anchor_start", "anchor_end",
                "n_matches", "cues", "snippet"]
    pd.DataFrame(all_hits, columns=hit_cols).to_csv(f_hits, index=False, encoding="utf-8-sig",
                                                    quoting=csv.QUOTE_MINIMAL)
    q = pd.DataFrame(all_q)
    for c in ("n_pages_or_lines", "n_hits", "n_strong_matches", "n_weak_matches"):
        if c in q:
            q[c] = q[c].astype("Int64")
    q.to_csv(f_q, index=False, encoding="utf-8-sig")

    n_bad = sum(1 for q in all_q if q.get("status") != "scanned" or q.get("text_flag") != "ok")
    print(f"\nPDF backend: {PDF_BACKEND}")
    print(f"Documents: {len(man)} | hits: {len(all_hits)} | documents needing attention: {n_bad}")
    print(f"Wrote {f_hits}\nWrote {f_q}")


if __name__ == "__main__":
    main()