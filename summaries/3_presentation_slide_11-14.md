Yes. These four slides should complete the **measurement contribution**. The sequence is now:

**database architecture → denominator → allocation extraction → comparability/auditability.**

That is exactly the structure already anticipated in the presentation architecture. 

# Slide 11 — Measuring prevalence requires two linked databases

| Field                | Decision                                                                                                                                                                                                                                                                                                                                                                         |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Working title**    | **Measuring prevalence requires two linked databases**                                                                                                                                                                                                                                                                                                                           |
| **Purpose**          | Explain the central architecture of the database and why a simple table of earmarks would not be enough.                                                                                                                                                                                                                                                                         |
| **Takeaway**         | **The census supplies the denominator; the allocation layer identifies statutory destinations.** Keeping them separate prevents multi-beneficiary instruments from being counted several times in prevalence.                                                                                                                                                                    |
| **On-slide content** | One common **legal corpus** splitting into two branches. **Revenue Instrument Census:** all distinct current instruments in the selected corpus → denominator **D**. **Statutory Allocation Layer:** source → destination channels → identifies earmarked instruments **N** and allocation channels **M**. `census_ref` links the two. Small formula: **Prevalence = N / D**.    |
| **Evidence/source**  | The methodology explicitly defines `XXX_CENSUS` as the denominator and `XXX_EARMARK_ALLOCATION` as the source→destination layer, linked through `census_ref`; it distinguishes instrument counts from `pair_id` channel counts.                                                                                                                                                  |
| **Main asset**       | **The main methodology diagram:** two branches from the legal corpus, joined through `census_ref`.                                                                                                                                                                                                                                                                               |
| **Asset status**     | **Ready.** Exact denominator filters still need to be locked before slide 16.                                                                                                                                                                                                                                                                                                    |
| **Oral explanation** | “If I only collected allocation clauses, I could tell you where assigned revenues go, but I could not tell you how common earmarking is because instruments with no observed assignment would be absent. And an instrument financing four destinations would appear four times. The census solves the denominator problem; the allocation layer solves the destination problem.” |
| **Transition**       | “The first task is therefore to reconstruct the revenue-instrument universe against which earmarking is measured.”                                                                                                                                                                                                                                                               |
| **Open decisions**   | Exact denominator filters—especially penalties and `referenced_not_enacted_here`—should be fixed during the results audit. **Do not put those technical filters on this slide.**                                                                                                                                                                                                 |

## The visual should basically say

```text
                    COUNTRY LEGAL CORPUS
                          /        \
                         /          \
                        ↓            ↓

          REVENUE INSTRUMENT     STATUTORY ALLOCATION
                CENSUS                  LAYER

          one row / instrument     one source → destination
                    ↓                       ↓
             denominator D          channels M
                                    earmarked instruments N
                        \            /
                         \ census_ref
                          \        /

                   PREVALENCE = N / D
```

This is probably the **single most important methodology figure** in the presentation.

### Use the CIV tobacco example as the intuition

Your CIV tobacco-for-sport tax is ideal as a tiny callout:

**1 revenue instrument**

→ 50% destination A
→ 35% destination B
→ 10% destination C
→ 5% destination D

Therefore:

> **+1 earmarked instrument, but +4 allocation channels**

That directly demonstrates why `instrument_id` and `pair_id` cannot be treated as the same unit. You had already identified this as the natural slide 11 example. 

I would **not** put 209, 433 or 16% here. This slide explains how those quantities are constructed; the results come later.

---

# Slide 12 — Step 1: Reconstruct the universe of revenue instruments

| Field                | Decision                                                                                                                                                                                                                                                                                                                                   |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Working title**    | **Step 1 — Reconstruct the universe of revenue instruments**                                                                                                                                                                                                                                                                               |
| **Purpose**          | Show that the denominator itself has to be constructed from law; it is not available from the allocation extraction.                                                                                                                                                                                                                       |
| **Takeaway**         | A defensible prevalence measure first requires identifying **one current record per distinct revenue instrument**, rather than counting articles, rates, or legal mentions.                                                                                                                                                                |
| **On-slide content** | `Legal corpus → charge-creating provisions → distinct instruments → reconcile duplicates/amendments → current census`. Underneath, one short line: **Denominator = distinct current instruments in the selected legal corpus.** Ideally show **one actual legal clause → one simplified census row**.                                      |
| **Evidence/source**  | The census searches charge-creating provisions, applies instrument-grain rules, merges repeated mentions, reconciles overlapping documents when necessary, and produces one surviving country-level record per distinct instrument.                                                                                                        |
| **Main asset**       | **Actual charge-creating clause → structured census observation.**                                                                                                                                                                                                                                                                         |
| **Asset status**     | **Pipeline ready; legal example still to select.**                                                                                                                                                                                                                                                                                         |
| **Oral explanation** | Explain that articles are not the unit. One tax can be described in several provisions, contain several rates, or be amended elsewhere. Conversely, two separately instituted charges can appear near each other. The reconciliation rules are designed to recover the economic revenue instrument rather than count legal text fragments. |
| **Transition**       | “Once the denominator exists, the second—and harder—task is to find the relatively sparse clauses that specify where proceeds go.”                                                                                                                                                                                                         |
| **Open decisions**   | **Select one very clean census clause.** Ideally use an instrument that is not already visually dominant on slide 9. Also lock the analytical denominator filters before slide 16.                                                                                                                                                         |

## Keep the on-slide pipeline short

I would use:

**1. Find charge-creating provisions**

→

**2. Identify distinct revenue instruments**

→

**3. Reconcile repetitions & amendments**

→

### **Current revenue-instrument census**

Then perhaps under the final step:

> **one instrument = one denominator observation**

This slide should make one important distinction obvious:

> **The denominator is not the number of tax articles.**

Your methodology explicitly handles schedules, amendments, cross-references, repeals and overlapping documents to avoid precisely that problem. 

### What the example row should show

We do not need the 30-variable schema.

Just something like:

| Legal label    | Taxed base |     Rate | Current? | Evidence     |
| -------------- | ---------- | -------: | -------- | ------------ |
| *[instrument]* | *[base]*   | *[rate]* | Yes      | Art. X, p. Y |

And perhaps visually highlight:

**No destination information yet.**

That reinforces why there are two databases.

### One denominator caveat to keep oral

The methodology makes the denominator conditional on the **selected legal corpus** and requires choices such as whether penalties or referenced-but-not-enacted instruments are retained. 

We need those choices nailed down analytically, but they would clutter this slide.

---

# Slide 13 — Step 2: Find sparse allocation clauses without losing recall

This is the slide where the **LLM-assisted architecture** should be visible.

| Field                | Decision                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Working title**    | **Step 2 — Find sparse allocation clauses without losing recall**                                                                                                                                                                                                                                                                                                                                                                                                                          |
| **Purpose**          | Explain why the earmark extraction is staged rather than asking an LLM to read hundreds of pages and directly produce a final database.                                                                                                                                                                                                                                                                                                                                                    |
| **Takeaway**         | Because assignment clauses are sparse and can be far from the charging provision, the pipeline separates **high-recall retrieval from structured extraction and reconciliation**.                                                                                                                                                                                                                                                                                                          |
| **On-slide content** | **LOCATE → EXTRACT → RECONCILE**. `LOCATE`: sweep the complete document for candidate assignment clauses, optimizing recall. `EXTRACT`: convert clauses into structured source/allocation evidence; one destination = one allocation row; retain verbatim text + page. `RECONCILE`: resolve instrument/channel identity, duplicate statements, amendments and cross-document relationships. Small footer: **LLM-assisted using fixed stage-specific prompts, schemas and decision rules.** |
| **Evidence/source**  | The methodology says a direct full-schema extraction from long documents creates a high false-negative risk, so passage location, field extraction and reconciliation are separate stages. LOCATE is deliberately recall-oriented and EXTRACT performs its own independent recall check.                                                                                                                                                                                                   |
| **Main asset**       | **One real assignment clause progressing through LOCATE → structured rows → reconciled channel(s).**                                                                                                                                                                                                                                                                                                                                                                                       |
| **Asset status**     | **Method ready; actual legal excerpt needed for production.**                                                                                                                                                                                                                                                                                                                                                                                                                              |
| **Oral explanation** | “LOCATE does not decide whether something is an earmark. It creates a high-recall worklist. EXTRACT then reads those clauses under the fixed evidence schema, and reconciliation only assigns instrument and channel identities once the full evidence set is visible. This separation is deliberate: the main extraction risk in a 500-page tax code is omission.”                                                                                                                        |
| **Transition**       | “The final challenge is to make those heterogeneous legal observations comparable across countries without severing them from the underlying evidence.”                                                                                                                                                                                                                                                                                                                                    |
| **Open decisions**   | Select the legal example. The CIV 50/35/10/5 allocation would work very well if we want continuity from slide 11; otherwise use another clean clause to avoid repetition.                                                                                                                                                                                                                                                                                                                  |

## I would make the three stages extremely precise

### **LOCATE**

**Where might an assignment exist?**

* full-document sweep
* high recall
* candidate passages
* coverage certificate

→

### **EXTRACT**

**What does the clause establish?**

* source
* destination
* share
* purpose restriction
* verbatim evidence + page

→

### **RECONCILE**

**What is the canonical instrument/channel?**

* duplicate statements
* amendments
* cross-references
* cross-Act links
* `instrument_id` / `pair_id`

This follows the actual method closely. 

### One sentence on the LLM is enough

At the bottom:

> **LLM-assisted extraction with fixed stage-specific prompts, data dictionaries and decision rules**

Do **not** add:

* model version;
* Cowork;
* chat versus API;
* number of sessions;
* file naming;
* token-management details.

Those are implementation details, not the empirical contribution. The existing architecture already deliberately relegates them to appendix/Q&A. 

### An important detail worth saying orally

EXTRACT does not merely trust LOCATE: the methodology specifies an **independent recall check**, so EXTRACT can identify passages missed by LOCATE; those misses are logged and the inventory is amended. 

That is a much stronger explanation than saying “I used two prompts.”

---

# Slide 14 — From legal evidence to comparable—and auditable—data

This should be the **payoff of the methodology section**.

| Field                | Decision                                                                                                                                                                                                                                                                                                                                                                                                                             |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Working title**    | **From legal evidence to comparable—and auditable—data**                                                                                                                                                                                                                                                                                                                                                                             |
| **Purpose**          | Show that the method does not end at extracting quotations: it converts them into common analytical variables while preserving a legal audit trail.                                                                                                                                                                                                                                                                                  |
| **Takeaway**         | **Every analytical observation can be traced back to its legal evidence, while common classifications make heterogeneous national legislation comparable.**                                                                                                                                                                                                                                                                          |
| **On-slide content** | A three-step progression: **LEGAL EVIDENCE → STANDARDIZED OBSERVATION → QUALITY CONTROLS.** Evidence: exact clause + article/page. Standardization: census link, source base/sector, destination function/COFOG, recipient type, share/restriction, canonical governing statement. QA: coverage checks, LOCATE↔EXTRACT reconciliation, duplicates/restatements/conflicts, flagged human review. Small ZAF boundary example if space. |
| **Evidence/source**  | The methodology retains exact evidence and page anchors, attaches `census_ref`, adds destination functions using COFOG, preserves uncertainty rather than silently correcting it, and uses multiple coverage/reconciliation checks. It explicitly says these checks make omissions visible and reproducible but do **not** prove perfect recall.                                                                                     |
| **Main asset**       | **One raw legal clause → one final analytical observation**, with the evidence fields visibly retained.                                                                                                                                                                                                                                                                                                                              |
| **Asset status**     | **Concept ready. Need one final worked observation + exact ZAF citations if the boundary example remains.**                                                                                                                                                                                                                                                                                                                          |
| **Oral explanation** | “The objective is not merely to produce an LLM classification. Every observation retains the underlying legal quotation and page. We then add common classifications—for example the economic sector of the taxed base and the COFOG function financed—and reconcile duplicate or competing legal statements. Ambiguous cases remain flagged rather than silently resolved.”                                                         |
| **Transition**       | “With that measurement infrastructure in place, we can now ask what the new inventory actually reveals.”                                                                                                                                                                                                                                                                                                                             |
| **Open decisions**   | 1. Choose the worked row. 2. Keep the South Africa boundary example only if we insert the exact legal Act/section citation. 3. Do **not** claim complete manual validation unless we can document it.                                                                                                                                                                                                                                |

## The structure I would use

### 1. **LEGAL EVIDENCE**

> exact statutory clause
> article / section
> canonical page

→

### 2. **COMPARABLE DATA**

**Source**

* instrument
* taxed base / sector

**Assignment**

* destination
* share
* purpose restriction

**Derived**

* recipient type
* COFOG function
* current governing statement

→

### 3. **AUDITABILITY / QA**

* coverage tracked
* LOCATE ↔ EXTRACT reconciled
* restatements not double-counted
* conflicts retained
* contestable cases flagged for review

The methodology supports all of those elements. 

---

## The South Africa example is still useful here—but only as a small boundary callout

Something like:

> **Boundary check**
> Environmental policy rationale
> ≠
> statutory earmark
>
> **Plastic-bag / tyre levies → National Revenue Fund → not coded as earmarked**

The point is not South Africa itself.

The point is:

> **The method requires legal source→destination evidence; it does not infer earmarking from the apparent policy purpose of a levy.**

That is a very persuasive QA example. We already identified it as the stronger alternative to inventing a generic “validation exercise.” 

But before production, I would attach the exact Act/section to that callout. Until then its asset status is **legal citation pending**.

---

# Be careful about the validation claim

I would **not** put:

> “All observations were manually validated.”

The methodology as currently documented supports something slightly different:

* exact legal evidence retained;
* coverage checked;
* LOCATE and EXTRACT reconciled;
* conflicts and ambiguous cases flagged;
* human-validation status exists;
* contestable cases form a review worklist. 

Unless you have actually documented full manual review of every final record, the defensible claim is:

> **Every retained observation is auditable against the underlying legal evidence; contestable cases are explicitly flagged for review.**

And then orally:

> “The remaining concern is completeness: these procedures reduce and expose omission risk, but they cannot prove that no assignment clause was missed—particularly where subordinate texts were unavailable.”

That is completely consistent with the methodology's own limitations. 

---

# Slides 11–14 now form one continuous argument

### Slide 11 — Architecture

> “To measure prevalence correctly, I need both a denominator and a destination layer.”

### Slide 12 — Denominator

> “So I first reconstruct the universe of current revenue instruments.”

### Slide 13 — Allocation recovery

> “I then use a staged, high-recall process to find the much sparser assignment clauses.”

### Slide 14 — Comparable evidence

> “Finally, I standardize those legal observations while preserving a complete audit trail back to the source.”

Then:

> **“What does this new measurement reveal?”**

And we enter the stylized facts.

---

## Asset status after slides 8–14

|  Slide | Load-bearing asset                            | Status                                         |
| -----: | --------------------------------------------- | ---------------------------------------------- |
|  **8** | Source → legal assignment → destination       | ✅ Ready                                        |
|  **9** | Assignment taxonomy + CIV/TGO examples        | ✅ Ready; exact legal anchors later             |
| **10** | Francophone vs Anglophone source architecture | ✅ Ready                                        |
| **11** | Census + allocation-layer architecture        | ✅ Ready                                        |
| **12** | Charge clause → census row                    | 🟡 Need one clean legal example                |
| **13** | Allocation clause → LOCATE/EXTRACT/RECONCILE  | 🟡 Need one clean clause/excerpt               |
| **14** | Raw evidence → analytical row + QA            | 🟡 Need worked row; ZAF exact citation pending |

At this point, I would consider the **methodology narrative itself content-locked**. The next step should be the **results audit for slides 15–20**: inventory every statistic/graph you currently have, decide which four or five findings actually advance the argument, and only then finalize the results-slide content sheets.
