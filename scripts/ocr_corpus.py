#!/usr/bin/env python3
"""
OCR the scanned PDFs of a country corpus, so the extraction prompts can read them as text.

    python ocr_corpus.py COUNTRY_FOLDER [COUNTRY_FOLDER ...]            # dry run: only lists what it would do
    python ocr_corpus.py COUNTRY_FOLDER --run                           # does it (French + English)
    python ocr_corpus.py COUNTRY_FOLDER --run --lang por+eng            # Lusophone countries

What it does
- Looks at every PDF in COUNTRY_FOLDER/source_pdfs/ (subfolders included) and classifies it:
    text     usable text layer                         -> left alone
    scanned  (almost) no text: page images only         -> OCR
    mixed    some pages have text, some are images      -> OCR of the image pages only
    garbled  a text layer exists but is unreadable      -> OCR replacing that layer
             (typically a font with no Unicode map: text extracts as symbols)
- The OCR'd file takes the ORIGINAL NAME and place in source_pdfs/, so the prompts pick it up
  with no change. The original is never deleted: it is moved to
  COUNTRY_FOLDER/archive/scanned_originals/ (same sub-path).
- Appends to COUNTRY_FOLDER/{ISO3}_ocr_log.csv (one line per file per run). Re-running is safe: OCR'd files now have text and
  are skipped.

Requirements (install once): Tesseract (with French, English and Portuguese language data),
Ghostscript, and the Python package ocrmypdf. See the installation notes sent with this script.
"""
from __future__ import annotations

import argparse
import csv
import logging
import shutil
import sys
import time
from pathlib import Path

# pdfminer warns once per sampled page when a PDF carries a "no text extraction" permission
# flag (common in official gazettes). The flag does not stop reading; silence the noise.
logging.getLogger("pdfminer").setLevel(logging.ERROR)

SAMPLE_PAGES = 12          # pages sampled per file to classify it (spread over the document)
EMPTY_PAGE_CHARS = 25      # a sampled page with fewer extracted characters counts as an image page
SCANNED_SHARE = 0.8        # >= 80% image pages  -> scanned
MIXED_SHARE = 0.2          # >= 20% image pages  -> mixed
GARBLED_ALPHA = 0.5        # < 50% letters among non-space characters -> garbled text layer


def page_count(path: Path) -> int:
    import pikepdf
    with pikepdf.open(path) as pdf:
        return len(pdf.pages)


def classify(path: Path) -> tuple[str, int, float]:
    """Return (kind, pages, chars_per_sampled_page)."""
    from pdfminer.high_level import extract_text
    n = page_count(path)
    if n == 0:
        return "empty", 0, 0.0
    k = min(SAMPLE_PAGES, n)
    idx = sorted({round(i * (n - 1) / max(k - 1, 1)) for i in range(k)})
    texts = []
    for i in idx:
        try:
            texts.append(extract_text(str(path), page_numbers=[i]) or "")
        except Exception:
            texts.append("")
    lens = [len(t.strip()) for t in texts]
    empty_share = sum(l < EMPTY_PAGE_CHARS for l in lens) / len(lens)
    joined = "".join(texts)
    nonspace = [c for c in joined if not c.isspace()]
    alpha = sum(c.isalpha() for c in nonspace) / len(nonspace) if nonspace else 0.0
    cpp = sum(lens) / len(lens)
    if empty_share >= SCANNED_SHARE:
        return "scanned", n, cpp
    if empty_share >= MIXED_SHARE:
        return "mixed", n, cpp
    if alpha < GARBLED_ALPHA:
        return "garbled", n, cpp
    return "text", n, cpp


def unique(path: Path) -> Path:
    if not path.exists():
        return path
    i = 1
    while (p := path.with_name(f"{path.stem}_{i}{path.suffix}")).exists():
        i += 1
    return p


def ocr_file(src: Path, kind: str, lang: str) -> None:
    import ocrmypdf
    tmp = src.with_name(src.stem + ".ocr_tmp.pdf")
    ocrmypdf.ocr(
        src, tmp,
        language=lang.split("+"),
        skip_text=(kind != "garbled"),   # scanned/mixed: OCR only the pages without text
        force_ocr=(kind == "garbled"),   # garbled: rasterise and replace the broken text layer
        rotate_pages=True,               # fix pages scanned sideways or upside down
        output_type="pdf",               # plain PDF: faster and fewer failures than PDF/A
        optimize=0,
        progress_bar=False,
    )
    return tmp


def process_country(folder: Path, run: bool, lang: str) -> None:
    src_dir = folder / "source_pdfs"
    if not src_dir.is_dir():
        print(f"[{folder}] no source_pdfs/ folder, skipped")
        return
    iso3 = folder.name.upper()[:3]
    archive = folder / "archive" / "scanned_originals"
    pdfs = sorted(p for p in src_dir.rglob("*") if p.suffix.lower() == ".pdf" and ".ocr_tmp" not in p.name)
    log, todo_pages = [], 0
    print(f"\n{iso3}: {len(pdfs)} PDF files in source_pdfs/")
    for p in pdfs:
        rel = p.relative_to(src_dir)
        try:
            kind, n, cpp = classify(p)
        except Exception as e:  # unreadable or encrypted file
            log.append({"file": str(rel), "pages": "", "kind": "error", "status": "error",
                        "detail": f"{type(e).__name__}: {e}", "seconds": ""})
            print(f"  {'error':8} {rel}  ({type(e).__name__})")
            continue
        entry = {"file": str(rel), "pages": n, "kind": kind, "status": "", "detail": f"{cpp:.0f} chars/page", "seconds": ""}
        if kind in ("text", "empty"):
            entry["status"] = "kept"
        elif not run:
            entry["status"] = "would_ocr"
            todo_pages += n
        else:
            t0 = time.time()
            try:
                tmp = ocr_file(p, kind, lang)
                dest = unique(archive / rel)
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(p), str(dest))   # original kept in archive/
                tmp.replace(p)                   # OCR'd file takes the original name
                after, _, cpp2 = classify(p)
                entry["status"] = "ocr_ok" if after == "text" else "ocr_check"
                entry["detail"] = f"{cpp:.0f} -> {cpp2:.0f} chars/page; original in archive/scanned_originals/"
            except Exception as e:
                name = type(e).__name__
                hint = (" (install Tesseract/Ghostscript and check PATH)" if "MissingDependency" in name else "")
                entry["status"] = "failed"
                entry["detail"] = f"{name}: {e}{hint}"
                for t in p.parent.glob(p.stem + ".ocr_tmp*"):
                    t.unlink(missing_ok=True)
            entry["seconds"] = f"{time.time() - t0:.0f}"
        log.append(entry)
        if entry["status"] != "kept":
            print(f"  {entry['status']:9} {kind:8} {n:5} p  {rel}")

    counts = {}
    for e in log:
        counts[e["status"]] = counts.get(e["status"], 0) + 1
    print(f"{iso3}: " + ", ".join(f"{k} {v}" for k, v in sorted(counts.items())))
    if not run and todo_pages:
        print(f"{iso3}: {todo_pages} pages to OCR (roughly 1-3 s per page). Re-run with --run to do it.")
    if run:
        log_path = folder / f"{iso3}_ocr_log.csv"
        new_log = not log_path.exists()
        stamp = time.strftime("%Y-%m-%d %H:%M")
        with log_path.open("a", encoding="utf-8", newline="") as f:   # appended: keeps earlier runs
            w = csv.DictWriter(f, fieldnames=["run", "file", "pages", "kind", "status", "detail", "seconds"])
            if new_log:
                w.writeheader()
            w.writerows({"run": stamp, **e} for e in log)
        print(f"{iso3}: log -> {iso3}_ocr_log.csv")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("folders", nargs="+", type=Path)
    ap.add_argument("--run", action="store_true", help="actually OCR (default: dry run, lists only)")
    ap.add_argument("--lang", default="fra+eng", help="Tesseract languages, e.g. fra+eng, eng, por+eng")
    a = ap.parse_args()
    try:
        import pikepdf, pdfminer  # noqa: F401  (installed with ocrmypdf)
        if a.run:
            import ocrmypdf  # noqa: F401
    except ImportError as e:
        sys.exit(f"Missing Python package ({e.name}). Install it with:  pip install ocrmypdf")
    for folder in a.folders:
        process_country(folder, a.run, a.lang)


if __name__ == "__main__":
    main()
