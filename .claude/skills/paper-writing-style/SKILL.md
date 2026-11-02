---
name: paper-writing-style
description: Writing style for Alexandra's earmarking project (de jure revenue earmarking in 43 Sub-Saharan African countries; IMF working paper and database). Use when drafting or editing any prose of the project: paper sections, report comments in Quarto files, codebook text, notes to co-authors. Not for code comments or casual messages.
---
# Writing style: earmarking project

## Before drafting

- Turn the author's notes and the results files into prose. Do not add claims, results, interpretations or references that are not there.
- Copy numbers only from the results files (in a Quarto report, pull them inline from the CSV; never type them). Mark any number you cannot trace as [NUMBER?] and anything missing as [TO CHECK: ...].
- Definitions come from `docs/GLOSSARY.md`; formal rules from `docs/DERIVED_TABLE_SPEC.md` and `docs/ANALYSIS_SPEC.md`.

## Voice

- Simple, factual and well written. Ordinary words. The text should read as if a careful researcher wrote it, not a machine.
- Each sentence says one thing. Most sentences are 15 to 25 words; avoid sentences over 35 words. Vary the length a little so the text flows.
- One idea per paragraph. The first sentence states the point, the next sentences give the evidence and the qualification.
- Active voice with "we".
- Be concrete: name the unit, the set and the number.
- No grand openings ("In recent years...", "In today's world..."), no rhetorical questions, no hype.
- Be confident about what the evidence shows and plain about what it does not. Qualify once, in the right place, not in every sentence.
- No bullet lists in the body of the paper (report boxes and tables may use them).

## Punctuation

- Never use long dashes (— or --). Use a comma, parentheses, a colon or a new sentence.
- Few hyphens. Hyphenate a compound only when it is needed for clarity. If a sentence has several, rephrase.
- No comma before "and" in lists: "funds, agencies and special accounts". Use a comma before "and" only between two long independent clauses.
- Avoid chains of semicolons. Prefer two sentences.
- No bold or italics for emphasis in the text.

## Words to avoid

delve, crucial, crucially, pivotal, novel (unless it is literally a new method), landscape, shed light, underscore, notably, it is worth noting, interestingly, importantly, intricate, nuanced, leverage (as a verb), utilize, comprehensive, paramount, myriad, plethora, a testament to, in the realm of, navigate, foster, holistic, multifaceted, robust (except in its technical sense, as in "robustness checks"). Use "furthermore" and "moreover" rarely.

Prefer plain alternatives: use, show, find, suggest, consistent with, about, also, but.

## Claims specific to this project

- The data are de jure: they describe what the law assigns, not what is collected or spent. Say "the law assigns", not "countries spend".
- Counts are counts of legal assignments, not revenue. Never present a count as a magnitude, and compare countries with shares within the earmarked set, not raw counts.
- There is no census of instruments, so never write a prevalence ("x% of taxes are earmarked").
- Associations only: "anglophone countries have a higher share of hard commitments", never "legal tradition causes" or "the effect of CFA membership".
- Results are preliminary until validation. Do not write "2026" as the law year: write "the law in force as of the latest text in the corpus".
- State the unit (instrument, allocation, link, country) and the set (earmarked or assigned; with or without social contributions and placeholders) whenever a number could be read two ways.
- Use country names in prose, not ISO3 codes.

## Before returning a draft

Check that there are no long dashes and none of the words to avoid, that each paragraph makes one point, that every number is traceable, that there is no causal wording, no comma before "and" in lists and no sentence over 35 words. Return the draft with a short list of every [TO CHECK] or [NUMBER?] item.
