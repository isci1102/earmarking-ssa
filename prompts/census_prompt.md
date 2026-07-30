# CENSUS EXTRACTION PROMPT

I am builing a census of tax/levies/charge extracted from legal documents. 
Extract a instrument census from a legal document: every revenue instrument it institutes or provides for.

**From projetc files read first and apply exactly as written — these govern, do not restate or reinterpret them:**
- `census_core_methodology.md` 
- `census_table_dictionary_v0_1.md` 

**Parameters:** 

country: {{country}}
document_id: {{document_id}}
document_type: {{document_type}}
document_year: {{document_year}}
structural_vector: {language: {{language}}, column_layout: detect,
                    length_class: {{length_class}},
                    earmark_density: {{earmark_density}},
                    content_form: {{content_form}},
                    numbering: {{numbering}}}
section_scope: {{section_scope}}
output_format: {{output_format}}
file: {{filename}}

**Run:**

1. A6 gate on the canonical file.
2. Sweep for **instrument-institution grammar, not assignment grammar**: the verbs by which a text creates a charge ( example (non exhaustive) fr: *il est institué / il est perçu / sont soumis à*; en: *there shall be levied / imposed / charged*), the charge nouns, and base/rate/liability cues. Declare the lexicon used in `run_meta`. No checklist of expected instruments.
3. Apply N1 to every hit; extract per the dictionary. `instrument_nature` is open, record the document's own verbatim term plus a provisional tag.
4. Produce all five N8 audits.
5. Serialize per dictionary §8. Filename `{country}_{document_id}_CENSUS`.
6. 
**Close-out:** parameter vector, lexicon used, divisions certified, rows extracted, boundary calls logged, hits dismissed.
