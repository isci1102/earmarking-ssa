COUNTRY: {{COUNTRY}}
DOCUMENT_IDS: 


## COUNTRY CONFIGURATION

Apply only the subsection matching COUNTRY.

### ZAF

- Manifest: `countries/ZAF/ZAF_LEGAL_CORPUS_MANIFEST.xlsx`, sheet `documents`
- LOCATE: `countries/ZAF/outputs/locate/ZAF_{document_id}_LOCATE.json`
- EXTRACT output folder: `countries/ZAF/outputs/extract/`
- Apply approved manifest/canonical-file overrides. 
- For Markdown documents use line numbers instead of page numbers.
  
### GHA

- Manifest: `countries/GHA/GHA_LEGAL_CORPUS_MANIFEST.xlsx`, sheet `documents`
- LOCATE: `countries/GHA/outputs/locate/GHA_{document_id}_LOCATE.json`
- EXTRACT: `countries/GHA/outputs/extract/`
- Public fund: Consolidated Fund.
- “Paid into the Consolidated Fund” is an inflow; “charged on the Consolidated Fund” is an outflow. Do not infer a levy allocation from an outflow alone.
- Register interactions with the Earmarked Funds Capping and Realignment regime and appropriation Acts for later reconciliation.
- Use `rate_basis = cross_reference` where another enactment determines the rate.
- Treat principal and amendment Acts independently unless the manifest identifies an approved consolidated canonical source.
- Do not run extraction until the manifest and LOCATE inventories exist.

## UNIVERSAL ORCHESTRATION

Read once and apply as written:

- `core_extraction_methodology.md`
- `retrieval_adapter_parameterized.md`
- `evidence_table_dictionary_v0.5.md`
- `decision_rules.md`
- `assumptions_register.md`
- `extract_prompt.md`

CORE governs any conflict.

Each document must match exactly one manifest row, resolve to an existing canonical file, and have its own LOCATE inventory. Missing or ambiguous inputs stop that document only.

Run `extract_prompt.md` independently for each document:

1. Use only that  document, manifest row and LOCATE inventory. Do not read another document or output.
2. Treat LOCATE as the worklist, not a ceiling. Extract any missed qualifying source or allocation passage, mark it `locate_miss`, and make the required logged LOCATE amendment.

## CROSS-DOCUMENT EVIDENCE

An allocation-only row is valid only when its own text identifies the revenue/proceeds—or precisely cites the source—and names the recipient. Do not manufacture an allocation from a title, generic appropriation, fund description or public-fund outflow.

Preserve external citations verbatim in `enabling_reference`. Add:

`CROSSDOC role=[source|allocation|recipient|rate]; citation=[exact citation]; unresolved.`

Never use `predecessor_ref` for source-to-allocation links. Do not open or import the cited document during extraction.

## OUTPUT AND STOP RULES

Write one output per document: in {country}/ouptput/extract/

If no anchored gold cases exist, emit `gold_scoring: []`.

Never overwrite a valid existing scope output; leave it untouched and continue missing scopes. 
An A6 or file failure stops only that document. A

After the batch extraction, give inline the allocations and sources of the same levies that where from different docs, and give inline one concise citation registry from the extraction outputs. 
Do not resolve the citations during extraction; resolve them later in a separate, logged reconciliation pass.