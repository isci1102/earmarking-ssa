## Build-Ready Batch 4 — Slides 11–14

I rechecked these slides against the **methodology itself and the actual CIV production outputs**. This batch can now be genuinely built: the worked examples are identified, the exact fields are known, and the QA wording is aligned with what the files actually support. The methodology defines the census as the denominator, the allocation layer as the source→destination layer, and `census_ref` as the link that prevents multi-beneficiary instruments from being counted repeatedly in prevalence. 

---

# SLIDE 11 — Database architecture

## 1. Final title

**Measuring prevalence requires two linked databases**

---

## 2. Final on-slide copy

### Top

**COUNTRY LEGAL CORPUS**

Then split into two branches.

### Left branch

## **REVENUE-INSTRUMENT CENSUS**

**All distinct revenue instruments in the selected legal corpus**

↓

### **D**

**current instruments — denominator**

### Right branch

## **STATUTORY ALLOCATION LAYER**

**One revenue source → one statutory destination**

↓

### **M**

**allocation channels**

↓

### **N**

**distinct instruments with a purpose-restricted allocation**

Between the two branches:

### `census_ref`

**links allocation evidence back to the census**

At the bottom:

## **Earmarking prevalence = N / D**

Small qualifier:

> **A multi-beneficiary instrument counts once in N, but several times in M.**

This is exactly the distinction in the methodology: channel counts use distinct `pair_id`; instrument prevalence uses the census-linked instrument population; and prevalence is a share of instruments, not revenue. 

---

## 3. Worked example — exact asset

Use the **CIV tobacco-for-sport tax** as a small callout on the allocation side.

### **One revenue instrument**

*CIV — Taxe spéciale sur le tabac pour le développement du sport*

→ **50%** Fédération ivoirienne de Football
→ **35%** Other sports federations
→ **10%** Socio-sport infrastructure projects
→ **5%** Office national des Sports

Then immediately:

### **1 instrument · 4 allocation channels**

The final reconciled database assigns the instrument `CIV_INST_0021` and separate `pair_id`s to its four destinations; the allocation key closes at 100%.   

Do **not** display those IDs on the actual slide. They only verify the logic.

---

## 4. Visual composition

This is the **main methodology architecture figure**.

```text
                         COUNTRY LEGAL CORPUS
                               │
                 ┌─────────────┴─────────────┐
                 ↓                           ↓
       REVENUE-INSTRUMENT             STATUTORY
             CENSUS                 ALLOCATION LAYER
                 │                           │
        all instruments               source → destination
                 │                           │
                 D                           M
            denominator                 channels
                 │                           │
                 └────── census_ref ─────────┘
                              │
                              N
                      earmarked instruments

                      PREVALENCE = N / D
```

Place the CIV example as a **small inset beside `M`**, not as a second large diagram.

---

## 5. Exact asset

* Custom two-branch database architecture diagram.
* One small CIV `1 → 4` worked example.

No screenshot.

No raw JSON.

---

## 6. Final source line

**Source: Author's methodology and database; Côte d'Ivoire CGI 2026, Art. 1085-3°.**

---

## 7. Asset status

### **READY**

The conceptual architecture and worked example are both verified.

---

## 8. Build instructions

This slide should visually answer only:

> **Why do I need two databases?**

So:

* `D`, `N`, `M` may be visible because they prepare the audience for later statistics.
* `census_ref` should appear, but in smaller type.
* Do **not** introduce `instrument_id`, `pair_id`, `row_type`, etc.
* Do not put the 435/209/433 project totals here; slide 7 already did that.
* `N/D` should be the visual conclusion at the bottom.

Important hierarchy:

**D and N are required for prevalence. M answers a different question.**

---

## 9. Oral explanation

About **50–60 seconds**:

> “The central architecture is deliberately two-layered. The census contains the revenue-instrument universe and therefore gives me the denominator. Separately, the allocation layer records statutory source-to-destination relationships.”

Then:

> “The two are joined through `census_ref`. That matters because the allocation table cannot itself provide the denominator: instruments for which no assignment is observed would simply be absent.”

Then use the CIV example:

> “And it also prevents the opposite problem. This Côte d'Ivoire tobacco tax is one revenue instrument, but the law assigns its proceeds to four different destinations. It therefore counts once when I measure the prevalence of earmarking, but four times when I describe statutory allocation channels.”

Finish:

> **“So instrument prevalence and allocation density are deliberately different statistics.”**

---

## 10. Transition

> **“The first branch therefore requires reconstructing the revenue-instrument universe itself.”**

---

## 11. Remaining decision

**None.**

### Status: **BUILD READY**

---

# SLIDE 12 — Building the denominator

## 1. Final title

**Step 1 — Reconstruct the universe of revenue instruments**

---

## 2. Final on-slide copy

The pipeline:

### **FIND**

Charge-creating provisions

→

### **IDENTIFY**

Distinct revenue instruments

→

### **RECONCILE**

Repeated mentions · amendments · overlapping texts

→

### **CURRENT CENSUS**

One record per distinct instrument

Then a strong sentence beneath:

> **The denominator counts revenue instruments—not articles, rates or tariff bands.**

That is directly consistent with the census rules. The methodology explicitly states that a tariff schedule varying only by class, size, category or band remains one instrument and that repeated legal mentions are merged rather than treated as additional instruments. 

---

# 3. Exact worked example

Use:

## **CIV — Taxe sur les véhicules à moteur**

### Legal source

**Art. 910**

> *“La taxe sur les véhicules à moteur est due pour tous les véhicules à moteur…”*

Then visually show:

**Arts. 915–918**

`different rates by vehicle type · horsepower · age / status`

↓

### **ONE census instrument**

Not several taxes.

The actual CIV census records this as one `taxe sur les véhicules à moteur`, with the multiple tariffs stored as a **rate schedule**. Its notes explicitly say that Arts. 915, 917 and 918 are tariff lines of one charge rather than separate instruments.  

---

## 4. Simplified final row shown on-slide

Do **not** reproduce the raw JSON.

Use something like:

| **Census field** | **Extracted observation**                  |
| ---------------- | ------------------------------------------ |
| Instrument       | Taxe sur les véhicules à moteur            |
| Base             | Motor vehicles registered in Côte d'Ivoire |
| Rate             | **Schedule**                               |
| Current          | Yes                                        |
| Evidence         | Art. 910; tariffs Arts. 915–918            |

That's enough.

---

## 5. Visual composition

Recommended layout: **55/45 split**.

### Left — the general method

```text
FIND → IDENTIFY → RECONCILE → CURRENT CENSUS
```

### Right — worked example

```text
Art. 910
one vehicle tax
      +
Arts. 915–918
several tariff bands
      ↓
ONE CENSUS ROW
```

Then across the bottom:

> **Instrument identity is separated from rate variation.**

That captures one of the key methodological principles without using technical language.

---

## 6. Exact asset

* Short Article 910 excerpt.
* One simplified census-row rendering.
* Small notation that Arts. 915–918 provide tariff variation.

No need for a screenshot of the tax code.

---

## 7. Final source line

**Source: Côte d'Ivoire, CGI 2026, Arts. 910, 915–918; author's revenue-instrument census.**

---

## 8. Asset status

### **READY — worked example verified**

The actual census file confirms:

* one vehicle-tax record;
* rate stored as a schedule;
* multiple tariff provisions folded into the same instrument. 

---

## 9. Build instructions

The important word is:

### **ONE**

Make the slide visually teach:

> four tariff provisions ≠ four instruments.

Do **not** display every tariff amount. That would bury the methodological point.

Maybe show:

`5,000 · 12,000 · 19,000 · …`

then visually collapse them into:

**RATE SCHEDULE**

→ **1 instrument**

That is sufficient.

Do not explain the full identity decision ladder on-slide.

---

## 10. Oral explanation

Approximately **45–55 seconds**:

> “The denominator itself is not available off the shelf. I first search the selected legal corpus for provisions that create compulsory revenue instruments.”

Then:

> “The key issue is grain. I want one observation per economic revenue instrument—not one per article or one per rate. For example, Côte d'Ivoire's vehicle tax has several tariff provisions depending on the vehicle characteristics. Those rates belong to one instrument and are stored as a schedule rather than becoming several taxes.”

Then:

> “Repeated mentions and amendments are then reconciled so that the final census represents the current instrument universe used in the denominator.”

No need to describe every merge rule.

---

## 11. Transition

> **“Allocation clauses are a different search problem: they are much sparser, and missing one directly affects the numerator.”**

---

## 12. Remaining decision

**None.**

### Status: **BUILD READY**

---

# SLIDE 13 — Recovering statutory assignments

## 1. Final title

**Step 2 — Find sparse allocation clauses without losing recall**

Keep this title. It communicates why your method is staged.

---

## 2. Final on-slide copy

Three large stages:

### **1 · LOCATE**

**High-recall passage inventory**

*Where might a statutory assignment appear?*

→

### **2 · EXTRACT**

**Structured legal evidence**

*What source, destination and share does the clause establish?*

→

### **3 · RECONCILE**

**Canonical instruments and allocation channels**

*Which statements refer to the same source or destination relationship?*

Then a small footer:

> **LLM-assisted, using fixed stage-specific prompts, schemas and decision rules**

And below that:

> **Each stage remains traceable to the underlying legal text.**

This matches the method: allocation clauses are treated as sparse; LOCATE optimizes recall rather than classification; EXTRACT produces clause-level evidence and performs an independent recall check; reconciliation assigns entity and channel identity only after the evidence is visible. 

---

# 3. Exact worked example — this is a very strong one

Use again the **CIV tobacco-for-sport tax**, but now for a *different methodological reason*.

### LOCATE stage

The LOCATE passage captured:

**50%** Football Federation
**35%** other federations
**10%** socio-sport infrastructure

and its note said:

### **Observed key = 95%**

**Do not invent the missing 5%.**

The actual LOCATE file says exactly that: the visible trigger summed to 95%, so the pipeline should report an open sum check and **not impute a general-budget residual**. 

Then:

### EXTRACT stage

The full clause was recovered:

**+ 5% → Office national des Sports**

↓

### **Final key = 100%**

The EXTRACT/reconciled evidence explicitly records that the LOCATE trigger had been truncated before the 5% line and corrects the key to 50+35+10+5 = 100%.  

This is a superb demonstration of why the stages are not redundant.

---

## 4. Visual composition

Upper ~55%:

```text
       LOCATE            →          EXTRACT          →       RECONCILE
   high-recall scan              structured evidence         canonical links
```

Lower ~35%: actual example

```text
CIV Art. 1085

LOCATE
50 + 35 + 10 = 95%
     ↓
NO IMPUTATION

EXTRACT
+ 5% Office national des Sports
     ↓
100% CLOSED KEY
```

The example should look like a **quality-control story**, not another taxonomy story.

---

## 5. Exact asset

* CIV LOCATE result from Article 1085.
* CIV final EXTRACT/reconciled result from Article 1085-3°.

No raw JSON.

No screenshots required.

---

## 6. Final source line

**Source: Côte d'Ivoire CGI 2026, Art. 1085-3°; author's LOCATE and EXTRACT outputs.**

---

## 7. Asset status

### **READY — particularly strong verified example**

This example is better than a generic claim such as “the two-stage system improves recall,” because it shows an actual case in your production files where the second stage corrected an incomplete first-stage trigger.  

---

## 8. Build instructions

This slide should **not** become an AI-engineering slide.

Keep:

* LOCATE
* EXTRACT
* RECONCILE
* one line on fixed prompts/schemas/rules

Move to appendix:

* Claude/model version;
* Cowork;
* session structure;
* prompt length;
* API versus chat;
* file names;
* token details.

The audience should remember:

> **high recall first → structured evidence second → identity resolution third**

not:

> “She used Claude.”

Also do not say:

> “LOCATE missed the allocation.”

More accurate:

> **The LOCATE trigger was truncated before the final 5% line; the independent EXTRACT check recovered it.**

That is precisely what the files say.

---

## 9. Oral explanation

Approximately **60 seconds**:

> “The allocation branch is intentionally staged because these clauses are sparse. LOCATE is not the final classification step. Its job is to sweep the full document with high recall and produce a passage worklist.”

Then:

> “EXTRACT goes back to the legal evidence and populates the structured schema. It also performs an independent recall check. Only afterwards do I reconcile which source statements and allocation statements belong to the same instrument and channel.”

Then use the example:

> “This distinction mattered in practice. For the Côte d'Ivoire tobacco-for-sport tax, the LOCATE trigger captured 50, 35 and 10 percent—a 95-percent key. The rules explicitly prevented the model from inventing the residual. At extraction, the complete legal clause revealed the missing 5-percent allocation to the National Sports Office, closing the key at 100 percent.”

Then:

> **“So uncertainty or incomplete retrieval remains visible rather than being silently filled.”**

That sentence is excellent for your credibility.

---

## 10. Transition

> **“The final step is to transform this legal evidence into comparable analytical variables without losing the audit trail.”**

---

## 11. Remaining decision

**None.**

### Status: **BUILD READY**

---

# SLIDE 14 — Standardization and QA

## 1. Final title

**From legal evidence to comparable—and auditable—data**

Keep this. It simultaneously closes the methodology and opens the results.

---

## 2. Final on-slide copy

Use three stages.

### **LEGAL EVIDENCE**

**Exact clause**
**Article / section**
**Canonical page**

→

### **COMPARABLE OBSERVATION**

**Revenue source / base**
**Destination / share**
**Purpose restriction**
**Census link**
**Destination function**

→

### **QUALITY CONTROLS**

**Document coverage tracked**
**LOCATE ↔ EXTRACT reconciled**
**Restatements / conflicts retained**
**Contestable cases flagged**

Then the key bottom statement:

> **Every retained observation remains traceable to its legal evidence.**

Immediately underneath, smaller:

> **These checks expose omission risk; they do not prove perfect recall.**

That second sentence is important and comes directly from the methodology: the completeness checks make omissions visible and reproducible, but do not mathematically establish perfect recall. 

---

# 3. Exact worked example

Use the **CIV taxe routière** because it moves cleanly from raw law to analytical variables.

### Raw legal evidence

**CIV — Taxe routière**
**Art. 1086-2° et 4° · p. 262**

> *“Le produit de la taxe est affecté au financement et à l'entretien routier.”*

The final enriched record retains the longer wording that proceeds finance road repair, maintenance and potentially new works. 

### Show only the analytical fields that matter

| **Field**          | **Final coding**             |
| ------------------ | ---------------------------- |
| Destination        | Road financing & maintenance |
| Purpose restricted | **Yes**                      |
| Share basis        | Whole proceeds implied       |
| Recipient form     | Programme / stated purpose   |
| COFOG              | **7045 — Transport**         |
| Census link        | **Matched**                  |

The final CIV enriched record has:

* `allocation_nature = proceeds_share`;
* `share_basis = whole_proceeds_implied`;
* `is_purpose_restricted = 1`;
* `destination_function = 7045`;
* `destination_function_basis = stated`;
* a `census_ref` linking it to the census. 

This is exactly the transformation the slide is trying to show.

---

## 4. Important QA wording correction

Do **not** put:

> ❌ “All records manually validated.”

The production outputs we checked include records with:

`human_validation_status = unchecked`

including this CIV road-tax row. 

So the accurate claim is:

### **Every retained observation is auditable against its underlying legal evidence.**

and:

### **Contestable cases are explicitly flagged for review.**

That is fully supported by your methodology. The pipeline creates review priorities for low/medium confidence, boundary calls, conflicts, partial keys, unusual hierarchy, inferred functions and unmatched/tied census links. 

---

## 5. Visual composition

Recommended **left-to-right transformation**:

```text
LEGAL CLAUSE
Art. 1086, p.262

"Le produit de la taxe
est affecté au financement
et à l'entretien routier."
        │
        ↓
STANDARDIZED OBSERVATION

purpose restricted     YES
share basis             WHOLE PROCEEDS
destination             ROAD MAINTENANCE
COFOG                   7045 TRANSPORT
census link             MATCHED

        │
        ↓
AUDIT TRAIL / QA

article + page retained
coverage tracked
conflicts/restatements preserved
review flags retained
```

This is preferable to a generic checklist because the audience sees **what the QA protects**.

---

## 6. Exact asset

* Short road-tax legal excerpt.
* Simplified final analytical observation.
* Four-item QA list.

No external source needed.

No full JSON.

---

## 7. Final source line

**Source: Côte d'Ivoire, CGI 2026, Art. 1086; author's enriched legal database.**

---

## 8. Asset status

### **READY**

The legal evidence and final COFOG/census-linked record are verified.  

---

## 9. Build instructions

The slide should communicate **auditability**, not claim perfection.

So visually:

* show the quotation;
* show a few analytical fields;
* show evidence links remain attached.

Avoid a giant checklist of all validation rules.

Do not show:

* `ai_confidence`;
* full `boundary_calls`;
* full reconciliation ladder;
* hard-stop conditions;
* the complete COFOG taxonomy.

Those belong in appendix.

Also, I would **not use the South Africa plastic-bag example on this slide anymore**. It is interesting, but the road-tax example gives a cleaner end-to-end demonstration from legal clause → classification → COFOG → census link. The boundary issue is already well represented on slide 9 by the CIV general-budget example.

---

## 10. Oral explanation

About **55–65 seconds**:

> “The output of the pipeline is not just a collection of quotations. The legal evidence is transformed into common analytical variables, but the evidence is never discarded.”

Then walk through:

> “For example, the Côte d'Ivoire road-tax clause says that the proceeds finance road financing and maintenance. The final observation records this as a purpose-restricted assignment, notes that the whole proceeds are implied, links the allocation back to the corresponding census instrument, and codes the financed function as COFOG transport.”

Then QA:

> “At the same time, the article, page and verbatim excerpt remain attached. Coverage is tracked, LOCATE and EXTRACT are reconciled, duplicate legal statements are not double-counted, and conflicts or contestable judgments remain visible.”

Finish with the limitation:

> **“These procedures make omissions and uncertainty visible and reproducible; they cannot guarantee perfect recall, particularly when relevant subordinate texts are unavailable.”**

This is exactly the level of methodological caution your written method supports. 

---

## 11. Transition

This should clearly end Act II:

> **“With that measurement infrastructure in place, we can now ask what the new inventory reveals across the 19 countries.”**

Then results.

---

## 12. Remaining decision

**None.**

### Status: **BUILD READY**

---

# Batch 4 production checklist

|  Slide | Exact copy | Method verified | Worked example verified                                              | Exact asset                            | Build status |
| -----: | ---------- | --------------- | -------------------------------------------------------------------- | -------------------------------------- | ------------ |
| **11** | ✅          | ✅               | ✅ CIV tobacco tax: 1 instrument → 4 channels                         | Two-database diagram + inset           | **Ready**    |
| **12** | ✅          | ✅               | ✅ CIV vehicle tax: several tariff provisions → one census instrument | Clause → census row                    | **Ready**    |
| **13** | ✅          | ✅               | ✅ LOCATE 95% → EXTRACT recovers 5% → 100%                            | Three-stage pipeline + real QA example | **Ready**    |
| **14** | ✅          | ✅               | ✅ CIV road tax → purpose restriction + COFOG 7045 + census link      | Legal clause → analytical row → QA     | **Ready**    |

## One thing I would lock now for the full methodology sequence

Slides **8–14 should not all look like process diagrams**. They now have distinct visual jobs:

**8:** object definition — *source → law → destination*
**9:** classification — *taxonomy*
**10:** legal retrieval problem — *one document vs document network*
**11:** data architecture — *two databases*
**12:** census grain — *many legal provisions → one instrument*
**13:** extraction architecture — *LOCATE → EXTRACT → RECONCILE*
**14:** auditability — *law → analytical observation*

That differentiation will make seven methodology slides feel like an unfolding empirical argument rather than a long technical appendix.
