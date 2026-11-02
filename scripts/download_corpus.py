#!/usr/bin/env python3
"""
Download a country's legal corpus from {ISO3}_corpus.csv (written by the discovery prompt).

    python download_corpus.py COUNTRY_FOLDER [--insecure] [--retry-failed]

- Reads   COUNTRY_FOLDER/{ISO3}_corpus.csv
- Saves   COUNTRY_FOLDER/source_pdfs/{file_name}   (the corpus folder the extraction prompts read)
- Logs    COUNTRY_FOLDER/{ISO3}_download_log.csv  (file_name, status, detail, bytes)

Never overwrites an existing file. Three url_types:
- direct_file:    the file is downloaded; an HTML response (blocked site, login wall)
                  is rejected and logged `failed`, so a web page is never read as a law;
- html_full_text: the page itself holds the full text of the law (Laws.Africa / LII
                  consolidated Acts) and is saved as .html;
- landing_page:   the page is opened and the link to the document is followed when one
                  link clearly matches the title/year (or is the only document on the
                  page); otherwise logged `manual`, with the best candidate links listed.
                  A direct_file link that returns a web page is treated the same way.

Standard library only: runs on any Python 3.9+ without installing anything.
"""
from __future__ import annotations

import argparse
import csv
import html.parser
import io
import re
import ssl
import urllib.parse
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")
TIMEOUT = 60
RETRIES = 2

# Magic bytes of the formats a legal corpus legitimately contains.
SIGNATURES = {
    b"%PDF": "pdf",
    b"PK\x03\x04": "zip/docx/xlsx",
    b"\xd0\xcf\x11\xe0": "doc/xls (OLE)",
    b"{\\rtf": "rtf",
}


def sniff(head: bytes) -> str | None:
    for sig, kind in SIGNATURES.items():
        if head.startswith(sig):
            return kind
    text = head[:512].lstrip().lower()
    if text.startswith((b"<!doctype html", b"<html")) or b"<html" in text:
        return "html"
    return None


def _unwrap_excel_lines(text: str) -> str:
    """Undo Excel's 'double wrapping'. A CSV opened in Excel with the wrong separator
    lands with each whole line in ONE cell; saving then writes every line as a single
    quoted field, with its inner quotes doubled ("") and often a trailing ';'.
    Detected on the header line; each wrapped line is unwrapped textually (outer quotes
    removed, "" -> "), which is robust to stray separators inside the notes."""
    lines = text.splitlines()
    head = next((l for l in lines if l.strip()), "").strip()

    def n_fields(line: str, d: str) -> int:
        return sum(1 for c in next(csv.reader([line], delimiter=d)) if c.strip())

    # Wrapped = the header is ONE quoted cell under both separators, and that cell
    # holds the column names. A normal CSV (quoted or not) splits into many fields.
    inner = next(csv.reader([head], delimiter=","))[0] if head else ""
    wrapped = (head.startswith('"') and n_fields(head, ",") == 1 and n_fields(head, ";") == 1
               and ("," in inner or ";" in inner))
    if not wrapped:
        return text              # a normal CSV: leave it alone
    out = []
    for l in lines:
        t = l.strip().rstrip(";").strip()
        if t.startswith('"') and t.endswith('"') and len(t) >= 2:
            t = t[1:-1].replace('""', '"')
        out.append(t.rstrip(";"))
    return "\n".join(out)


URL_TYPES = {"direct_file", "html_full_text", "landing_page"}


def read_corpus(path: Path) -> list[dict]:
    """Read the corpus CSV robustly. Handles: ',' or ';' separators (Excel with
    French/European settings), Windows-1252 encoding, a BOM, padded headers, Excel
    'double-wrapped' lines, stray trailing ';', and rows broken by unquoted commas
    inside titles or notes. A broken row is recovered from its anchors: file_name is
    the first field, url the first field starting with http, url_type the field after it."""
    raw = path.read_bytes()
    for enc in ("utf-8-sig", "cp1252"):
        try:
            text = raw.decode(enc)
            break
        except UnicodeDecodeError:
            continue
    text = _unwrap_excel_lines(text)
    lines = [l.rstrip().rstrip(";").rstrip() for l in text.splitlines() if l.strip()]
    if not lines:
        sys.exit(f"{path.name}: empty file")
    delim = max([",", ";", "\t"], key=lines[0].count)
    table = list(csv.reader(lines, delimiter=delim))
    header = [(f or "").replace("\ufeff", "").replace("\u00ef\u00bb\u00bf", "")  # BOM, incl. mis-decoded
              .strip().strip('"').strip(";").strip().lower() for f in table[0]]
    missing = {"file_name", "url"} - set(header)
    if missing:
        sys.exit(f"{path.name}: column(s) {sorted(missing)} not found. Header read as: {header}")
    rows, recovered = [], 0
    for cells in table[1:]:
        cells = [c.strip() for c in cells]
        r = dict(zip(header, cells)) if len(cells) == len(header) else {}
        if not (r.get("url", "").startswith("http") and r.get("url_type", "") in URL_TYPES):
            # Broken row: fall back on anchors that do not depend on column positions.
            i = next((k for k, c in enumerate(cells) if c.lower().startswith(("http://", "https://"))), None)
            if i is None or not cells or not cells[0]:
                print(f"  skipped unreadable row: {';'.join(cells)[:80]}")
                continue
            nxt = cells[i + 1] if i + 1 < len(cells) else ""
            r = {"file_name": cells[0], "url": cells[i],
                 "url_type": nxt if nxt in URL_TYPES else "direct_file"}
            recovered += 1
        if r.get("file_name") and r.get("url"):
            rows.append(r)
    if recovered:
        print(f"{path.name}: {recovered} row(s) had shifted columns (unquoted commas); recovered from file_name/url.")
    return rows


def fetch(url: str, insecure: bool) -> bytes:
    ctx = ssl._create_unverified_context() if insecure else ssl.create_default_context()
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "*/*"})
    last = None
    for attempt in range(RETRIES + 1):
        try:
            with urllib.request.urlopen(req, timeout=TIMEOUT, context=ctx) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            if 400 <= e.code < 500:      # 404, 403 …: retrying will not help
                raise
            last = e
            time.sleep(2 * (attempt + 1))
        except (urllib.error.URLError, TimeoutError, ConnectionError) as e:
            last = e
            time.sleep(2 * (attempt + 1))
    raise last


FILE_EXT = (".pdf", ".doc", ".docx", ".rtf")
STOP = {"the", "and", "of", "for", "act", "law", "loi", "lei", "de", "du", "des", "la", "le", "les", "da",
        "do", "dos", "das", "no", "n", "portant", "relative", "relatif", "sur", "pdf", "html", "doc", "docx"}


class _Links(html.parser.HTMLParser):
    """Collect (href, anchor text) pairs from a page."""
    def __init__(self):
        super().__init__()
        self.links, self._href, self._text = [], None, []

    def handle_starttag(self, tag, attrs):
        if tag == "a":
            self._href, self._text = dict(attrs).get("href"), []

    def handle_data(self, data):
        if self._href is not None:
            self._text.append(data)

    def handle_endtag(self, tag):
        if tag == "a" and self._href:
            self.links.append((self._href, " ".join(self._text).strip()))
            self._href = None


def _tokens(s: str) -> set[str]:
    s = urllib.parse.unquote(s or "").lower()
    return {w for w in re.findall(r"[a-z0-9\u00c0-\u017f]+", s) if len(w) >= 3 and w not in STOP}


def file_links(page: bytes, base: str) -> list[tuple[str, str]]:
    """Links on a page that look like documents: a file extension, or a 'download' link."""
    parser = _Links()
    try:
        parser.feed(page.decode("utf-8", errors="replace"))
    except Exception:
        return []
    seen, out = set(), []
    for href, text in parser.links:
        if href.startswith(("mailto:", "javascript:", "#")):
            continue
        absu = urllib.parse.urljoin(base, href)
        path = urllib.parse.urlparse(absu).path.lower()
        looks_file = path.endswith(FILE_EXT) or "download" in absu.lower() or "getobject" in absu.lower() \
            or re.search(r"\b(pdf|download|télécharger|telecharger|descarregar|baixar)\b", text.lower())
        if looks_file and absu not in seen:
            seen.add(absu)
            out.append((absu, text))
    return out


def pick_link(cands: list[tuple[str, str]], row: dict) -> tuple[str | None, list[str]]:
    """Choose the link matching the document. Returns (chosen or None, ranked candidates)."""
    if not cands:
        return None, []
    want = _tokens(row.get("title", "")) | _tokens(re.sub(r"_", " ", Path(row["file_name"]).stem))
    year = (row.get("year") or "").strip() or next(iter(re.findall(r"(19|20)\d\d", row["file_name"])), "")
    def score(c):
        got = _tokens(c[0]) | _tokens(c[1])
        return len(want & got) + (2 if year and year in (c[0] + c[1]) else 0)
    ranked = sorted(cands, key=score, reverse=True)
    scores = [score(c) for c in ranked]
    if len(ranked) == 1:
        return ranked[0][0], [ranked[0][0]]                 # single document on the page
    if scores[0] >= 2 and scores[0] > scores[1]:
        return ranked[0][0], [c[0] for c in ranked[:3]]     # one clear best match
    return None, [c[0] for c in ranked[:3]]                 # ambiguous: leave to the user


def resolve_landing(url: str, page: bytes | None, row: dict, insecure: bool):
    """Follow a landing page to the document it links to (up to two pages deep).
    Returns (data, kind, final_url, candidates)."""
    cands_seen: list[str] = []
    for _ in range(2):
        if page is None:
            page = fetch(url, insecure)
        chosen, cands = pick_link(file_links(page, url), row)
        cands_seen = cands_seen or cands
        if not chosen:
            return None, None, None, cands_seen
        data = fetch(chosen, insecure)
        kind = sniff(data[:1024])
        if kind and kind != "html":
            return data, kind, chosen, cands_seen
        url, page = chosen, data                            # an intermediate page: one more hop
    return None, None, None, cands_seen


def glob_escape(s: str) -> str:
    return re.sub(r"([*?\[])", r"[\1]", s)


def _suffix_for(kind: str, target: Path) -> Path:
    if kind == "doc/xls (OLE)" and target.suffix.lower() == ".pdf":
        return target.with_suffix(".doc")
    if kind == "zip/docx/xlsx" and target.suffix.lower() == ".pdf":
        return target.with_suffix(".docx")
    return target


def _try_resolve(url: str, page: bytes | None, row: dict, target: Path, insecure: bool, log) -> None:
    name = row["file_name"].strip()
    try:
        data, kind, final, cands = resolve_landing(url, page, row, insecure)
    except Exception as e:  # noqa: BLE001
        log.append({"file_name": name, "status": "manual", "detail": f"{url} (page not reachable: {type(e).__name__})",
                    "bytes": ""})
        return
    if data is None:
        more = f" | candidate links: {' ; '.join(cands)}" if cands else ""
        log.append({"file_name": name, "status": "manual", "detail": url + more, "bytes": ""})
        return
    target = _suffix_for(kind, target)
    tmp = target.with_suffix(target.suffix + ".part")
    tmp.write_bytes(data)
    tmp.replace(target)
    log.append({"file_name": target.name, "status": "ok", "detail": f"{kind}, found via landing page: {final}",
                "bytes": len(data)})


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("folder", type=Path)
    p.add_argument("--insecure", action="store_true",
                   help="skip TLS certificate checks (many government sites have expired certificates)")
    p.add_argument("--retry-failed", action="store_true",
                   help="only retry rows logged 'failed' or 'manual' in the previous run")
    p.add_argument("--no-resolve", action="store_true",
                   help="do not try to find the document behind landing pages")
    a = p.parse_args()

    csvs = sorted(a.folder.glob("*_corpus.csv"))
    if len(csvs) != 1:
        sys.exit(f"expected exactly one *_corpus.csv in {a.folder}")
    iso3 = csvs[0].name.split("_")[0]
    rows = read_corpus(csvs[0])
    out_dir = a.folder / "source_pdfs"
    out_dir.mkdir(exist_ok=True)
    log_path = a.folder / f"{iso3}_download_log.csv"

    previous = {}
    if log_path.exists():
        previous = {r["file_name"]: r for r in csv.DictReader(log_path.open(encoding="utf-8"))}

    log = []

    class _Log(list):
        def append(self, r):            # print one status line per row, whatever the branch
            super().append(r)
            print(f"{r['status']:>7}  {r['file_name']}")
    log = _Log()

    for row in rows:
        name, url = row["file_name"].strip(), row["url"].strip()
        target = out_dir / name
        prev = previous.get(name) or next((v for k, v in previous.items() if Path(k).stem == target.stem), {})
        if a.retry_failed and prev.get("status") not in ("failed", "manual"):
            log.append(prev or {"file_name": name, "status": "skipped", "detail": "", "bytes": ""})
            continue
        # Already downloaded, under this name or with another extension (.doc/.docx/.html)?
        same = [f for f in out_dir.glob(glob_escape(target.stem) + ".*")
                if f.suffix.lower() in (".pdf", ".doc", ".docx", ".rtf", ".html", ".htm")]
        if same:
            log.append({"file_name": same[0].name, "status": "exists", "detail": "not overwritten",
                        "bytes": same[0].stat().st_size})
            continue
        url_type = row.get("url_type", "").strip()
        if url_type == "landing_page":
            if a.no_resolve:
                log.append({"file_name": name, "status": "manual", "detail": url, "bytes": ""})
                continue
            _try_resolve(url, None, row, target, a.insecure, log)
            continue
        try:
            data = fetch(url, a.insecure)
            kind = sniff(data[:1024])
            if url_type == "html_full_text":
                # The page itself is the law (Laws.Africa / LII consolidated Acts):
                # keep it as HTML; the extraction prompts read HTML directly.
                if kind not in ("html", None) or len(data) < 20_000:
                    log.append({"file_name": name, "status": "failed",
                                "detail": f"expected a full-text web page, got {kind or 'a short page'}: {url}",
                                "bytes": len(data)})
                    continue
                if target.suffix.lower() not in (".html", ".htm"):
                    target = target.with_suffix(".html")
                target.write_bytes(data)
                log.append({"file_name": target.name, "status": "ok", "detail": "html_full_text",
                            "bytes": len(data)})
                continue
            if kind == "html":
                if a.no_resolve:
                    log.append({"file_name": name, "status": "failed",
                                "detail": f"got an HTML page, not a file: {url}", "bytes": len(data)})
                else:
                    _try_resolve(url, data, row, target, a.insecure, log)
                continue
            tmp = target.with_suffix(target.suffix + ".part")
            tmp.write_bytes(data)
            tmp.replace(target)
            detail = kind or "unrecognised format, check the file"
            log.append({"file_name": name, "status": "ok", "detail": detail, "bytes": len(data)})
        except Exception as e:  # noqa: BLE001 — every failure is logged, never fatal
            hint = " (try --insecure)" if isinstance(e, urllib.error.URLError) and "CERTIFICATE" in str(e) else ""
            log.append({"file_name": name, "status": "failed", "detail": f"{type(e).__name__}: {e}{hint}",
                        "bytes": ""})

    with log_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["file_name", "status", "detail", "bytes"])
        w.writeheader()
        w.writerows(log)

    counts = {}
    for r in log:
        counts[r["status"]] = counts.get(r["status"], 0) + 1
    print(f"\n{iso3}: " + ", ".join(f"{k} {v}" for k, v in sorted(counts.items())) + f"  -> {log_path.name}")
    todo = [r for r in log if r["status"] in ("failed", "manual")]
    if todo:
        print("To download by hand (save into source_pdfs/ with the file_name shown):")
        for r in todo:
            print(f"  {r['file_name']}: {r['detail']}")


if __name__ == "__main__":
    main()
