## Build-Ready Batch 3 — Slides 8–10

For this batch, the claims come almost entirely from **your methodology, taxonomy, and actual CIV extraction outputs**, so I checked the wording against those rather than adding general legal-system claims. In particular, slide 10 is framed as **“typical architecture in this project”**, not as a universal civil-law/common-law distinction. Your methodology explicitly says the substantive definition stays fixed while the retrieval procedure changes with document structure. 

---

# SLIDE 8 — The empirical object

## 1. Final title

**What exactly do we measure?**

Keep it simple. This is the first methodology slide, so it should answer the question before introducing any pipeline.

---

## 2. Final on-slide copy

At the top, a small qualifier:

### **CURRENT LEGAL SNAPSHOT · DE JURE**

Then the central visual:

### **REVENUE INSTRUMENT**

*one distinct revenue source*

→

### **ENACTING ASSIGNMENT**

*the law specifies where proceeds go*

→

### **RECIPIENT / PURPOSE**

Underneath, two definitions:

**Revenue instrument**
Tax · duty · levy · contribution · redevance · royalty · other compulsory revenue source

**Allocation channel**
One revenue instrument → one statutory destination

At the bottom:

> **The database records what the law assigns—not what is actually collected, transferred or spent.**

---

## 3. Verification

This wording follows the methodology directly.

The database is explicitly defined as a **de jure legal inventory** that records statutory assignments rather than actual collections, transfers, disbursements or expenditure execution. The standard production run is a current legal snapshot based on the most recent consolidated or otherwise authoritative texts available at extraction. 

The methodology deliberately uses the umbrella **revenue instrument** because the legal source universe includes taxes, duties, levies, contributions, redevances, royalties, parafiscal charges, fees, fines/penalties and other compulsory sources recognized by the text; it does not assume that every observation is a “tax” in the narrow economic sense. 

It also distinguishes the revenue source from the allocation channel: the channel is one instrument-to-destination relationship, while the instrument remains the reporting unit for prevalence. 

---

## 4. Visual composition

Do **not** show a real legal document yet.

This slide should establish the abstraction first.

Recommended composition:

```text
TITLE

               CURRENT LEGAL SNAPSHOT · DE JURE


 REVENUE INSTRUMENT  ─────→  ENACTING ASSIGNMENT  ─────→  RECIPIENT / PURPOSE
 one revenue source           what the law says             where proceeds go


 Revenue instrument                       Allocation channel
 tax · duty · levy · ...                   one source → one destination


─────────────────────────────────────────────────────────────────
 Records statutory design — not collections, transfers or spending
```

The three-node relation is the dominant object.

---

## 5. Exact asset

**Custom source → law → destination diagram.**

No screenshot.

No database table.

No code.

This is important because slide 11 will later show the actual database architecture; slide 8 should not anticipate it.

---

## 6. Final source line

**Source: Author's methodology.**

If you want slightly more detail:

**Source: Author's methodology and database taxonomy.**

Nothing longer is needed on-slide.

---

## 7. Asset status

**READY.**

No external retrieval or factual check remains.

---

## 8. Build instructions

Visual hierarchy:

1. the three-node relationship;
2. `CURRENT LEGAL SNAPSHOT · DE JURE`;
3. the two unit definitions;
4. de jure caveat;
5. source.

Do not visually emphasize the list:

> tax · duty · levy · contribution...

It is there simply to explain why your terminology says **revenue instrument** rather than only **tax**.

Do not display `instrument_id` or `pair_id` yet. Those belong on slide 11 / appendix.

---

## 9. Oral explanation

About **40–50 seconds**:

> “The object is a current-law, de jure relationship. I start with a revenue instrument—which I define deliberately more broadly than a tax, because legal systems use labels such as tax, duty, levy, contribution or redevance—and then ask whether an operative legal clause assigns its proceeds to a specific recipient or purpose.”

Then:

> “There are two units that will matter throughout the presentation. The revenue instrument is the source itself. An allocation channel is one legal source-to-destination relationship. One instrument can therefore generate several channels.”

And:

> “Importantly, this is not execution data. The database tells us what the law commits, not whether the money was ultimately collected, transferred or spent.”

---

## 10. Transition

> **“And a statutory destination by itself is still not enough for me to call the instrument earmarked.”**

Perfect entry into slide 9.

---

## 11. Remaining decision

**None.**

### Status: **BUILD READY**

---

# SLIDE 9 — The taxonomy

## 1. Final title

**Not every statutory assignment is an earmark**

Keep this title.

This is arguably the most important definitional slide in the deck because it explains why **435 assigned instruments ≠ 435 earmarked instruments**.

---

## 2. Final on-slide copy

The main taxonomy should read:

### **NO ASSIGNMENT OBSERVED**

No statutory assignment found in the selected corpus

→

### **ASSIGNED, UNRESTRICTED**

Proceeds are routed, but their use is not restricted

→

### **PARTIAL EARMARK**

Restricted **and** unrestricted proceeds coexist

→

### **EXCLUSIVE EARMARK**

All proceeds channels are purpose-restricted

Visually bracket the last two:

## **EARMARKED**

Then put a small separate annotation—not a fifth point in the sequence:

> **Cost recovery** is recorded separately and set aside before classifying the instrument.

This exactly reflects the taxonomy: E1 is assigned but unrestricted; E2 contains both restricted and unrestricted proceeds; E3 has only restricted proceeds; and earmarked = E2 ∪ E3. Cost recovery is removed before the instrument-level roll-up. 

---

# 3. Exact legal examples

I recommend **three CIV examples rather than CIV + Togo + South Africa** on this slide.

Why? Because this creates a controlled comparison:

> **same country + same CGI + same evidentiary standard → three different classifications.**

That makes the taxonomy—not cross-country legal variation—the variable changing on the slide.

### A. Assigned, unrestricted

**CIV — Taxe environnementale sur les mégots de cigarette**

**Art. 1137 bis · p. 270**

> *“Le produit de la taxe est affecté au Budget de l'État.”*

Therefore:

### **Assigned, unrestricted**

The extraction explicitly treats this environmentally labelled tax as a counterexample: despite the environmental policy label, its proceeds go to the general budget and no purpose restriction is observed. 

This is an excellent legal example because it establishes:

> **Policy label ≠ earmark.**

---

### B. Partial earmark

**CIV — Taxe sur les activités polluantes**

**Art. 1137 ter-2° · p. 270**

Use only the allocation, not the full quotation:

**40%** → Budget de l'État
**40%** → Ministry of Environment
**20%** → CIAPOL

Then underneath:

### **40% unrestricted · 60% restricted → Partial earmark**

The actual clause states precisely this 40/40/20 allocation and closes at 100%. The general-budget channel is coded unrestricted, while the environmental destinations are purpose-restricted. 

Your finalized taxonomy independently uses this instrument as its worked partial-earmark example: class E2 with a 60% dedication ratio. 

---

### C. Exclusive earmark

**CIV — Taxe spéciale sur le tabac pour le développement du sport**

**Art. 1085-3° · p. 262**

Use:

**50%** Football Federation
**35%** other sports federations
**10%** socio-sport infrastructure projects
**5%** National Sports Office

Then:

### **100% purpose-restricted → Exclusive earmark**

The reconciled evidence confirms the complete 50+35+10+5 allocation key, with no general-budget residual. 

This is a much cleaner exclusive-earmark example than the apprenticeship tax because the final evidence closes at 100% without the competing-recipient issue we identified previously.

---

## 4. Visual composition

Do **not** put long quotations beneath all four taxonomy categories.

The taxonomy occupies the upper half.

The three examples occupy the lower half:

```text
NO ASSIGNMENT       ASSIGNED,          PARTIAL           EXCLUSIVE
OBSERVED            UNRESTRICTED       EARMARK           EARMARK
                                         └──────── EARMARKED ────────┘


─────────────────────────────────────────────────────────────────────

CIV                   CIV                       CIV
Cigarette-butt        Polluting activities      Tobacco-for-sport

100% State budget     40% State budget           50 / 35 / 10 / 5
                      60% environment            all sport purposes

ASSIGNED              PARTIAL                    EXCLUSIVE
UNRESTRICTED
```

There is no example needed underneath **No assignment observed**.

Why? Because by definition there is no positive allocation clause to show.

---

## 5. Exact asset

**Three small legal-example panels generated from actual CIV evidence.**

No screenshots necessary.

For each:

* instrument name;
* article/page;
* very short allocation;
* classification.

If you later decide to use a cropped screenshot of the CGI, use **one**, not three.

---

## 6. Final source line

**Source: Côte d'Ivoire, CGI 2026, Arts. 1085-3°, 1137 bis and 1137 ter-2°; author's taxonomy.**

That is a very good concise legal citation line.

---

## 7. Asset status

### **READY — examples verified against extraction outputs.**

This batch resolves one earlier uncertainty:

* **CIV tobacco-for-sport:** use.
* **CIV polluting-activities tax:** use.
* **CIV cigarette-butt environmental tax:** use.
* **CIV apprenticeship tax:** not needed here.
* **Togo 78/10/12:** still useful elsewhere, but not needed for this slide.

---

## 8. Build instructions

Taxonomy is the slide; examples are evidence.

So:

* taxonomy ≈ **55% of attention**;
* legal examples ≈ **40%**;
* citations ≈ **5%**.

Use one visual distinction between:

**unrestricted**

and

**restricted**

Then use the same distinction in the examples.

Do not introduce:

* E0/E1/E2/E3 labels;
* R-G/R-T/R-M;
* structural fullness;
* dedication ratio;
* purpose breadth;
* assignment type.

Those are database variables/results, not necessary for this slide.

---

## 9. Oral explanation

Approximately **60–70 seconds**:

> “The broad allocation layer deliberately records more than earmarks. The key test is whether the law restricts the use of the proceeds.”

Then walk quickly across:

> “If I find no assignment clause in the selected corpus, the instrument sits in the no-assignment-observed group. If the law routes the proceeds but does not restrict their use—for example to the general budget or an unrestricted territorial budget—the instrument is assigned, but it is not earmarked.”

Then:

> “If restricted and unrestricted proceeds coexist, I call it a partial earmark. If every proceeds channel is restricted, it is an exclusive earmark.”

Then use the CIV examples:

> “The contrast is visible even inside one tax code. A Côte d'Ivoire environmental tax on cigarette butts goes entirely to the general budget, so its environmental label does not make it an earmark. The tax on polluting activities sends 40 percent to the general budget and 60 percent to environmental destinations, so it is partial. The tobacco-for-sport tax distributes its entire proceeds across four sport-related destinations, so it is exclusive.”

Then:

> “Administrative cost recovery is recorded, but set aside before this classification.”

---

## 10. Important oral caveat

For **No assignment observed**, say if needed:

> “This means no assignment was found in the selected legal corpus—it is not a claim that no subordinate provision could exist outside the available corpus.”

Your taxonomy explicitly requires this coverage qualifier. 

Do **not** put that entire sentence in the main taxonomy; it can be a very small footnote:

> *No assignment observed = none found in the selected legal corpus.*

---

## 11. Transition

> **“The definition is common across countries. The retrieval problem is not.”**

Excellent transition to slide 10.

---

## 12. Remaining decision

**None.**

### Status: **BUILD READY**

---

# SLIDE 10 — Different legal architectures

## 1. Final title

**The legal source architecture differs across countries**

Keep this title.

The important safeguard is to make clear that this describes **your corpus construction**, rather than claiming an absolute divide between all Francophone and all Anglophone legal systems.

---

## 2. Final on-slide copy

Use two columns.

### **TYPICAL FRANCOPHONE CORPUS IN THIS PROJECT**

**Consolidated tax code at the core**

`Code général des impôts`

↓

Source instruments **and** many allocation provisions often recoverable within one large corpus

↓

**Main retrieval problem:**
deep, exhaustive search inside a long document

Small underneath:

*Extensions where needed: fiscal annexes · sectoral codes · fund laws*

---

### **TYPICAL ANGLOPHONE CORPUS IN THIS PROJECT**

**Relevant law distributed across several Acts**

`principal tax Acts`
`levy-specific Acts`
`fund / agency Acts`
`finance Acts`
`schedules / regulations`

↓

Charging provision and statutory destination may appear in **different documents**

↓

**Main retrieval problem:**
cross-document reconstruction and reconciliation

---

Then one line spanning both columns:

## **Same definition · same evidence standard · same output schema**

---

## 3. Verification

This is directly supported by the methodology.

For Francophone countries, the core legal source is normally the latest available **Code général des impôts or equivalent consolidated tax code**, potentially extended with fiscal annexes, sectoral codes, fund laws and other texts needed to complete the chain. 

For the Anglophone workflow, the methodology says the relevant legal system commonly requires a library spanning principal tax Acts, levy-specific Acts, finance Acts, fund/agency Acts, schedules, regulations and amendments; source and assignment may therefore have to be reconciled across different Acts. 

Critically, the methodology then says:

> **the legal definition and schema remain fixed across countries; only the reading procedure changes with document structure.**

That is the substantive point of the slide. 

---

## 4. Visual composition

Two **document architectures**, not two text boxes.

Something like:

```text
TITLE


       TYPICAL FRANCOPHONE                         TYPICAL ANGLOPHONE
       CORPUS IN THIS PROJECT                      CORPUS IN THIS PROJECT


               ┌────────┐                            ┌──────┐ ┌──────┐
               │  CGI   │                            │ TAX  │ │ LEVY │
               │        │                            │ ACT  │ │ ACT  │
               │        │                            └──────┘ └──────┘
               └────────┘                            ┌──────┐ ┌──────┐
                   │                                 │ FUND │ │ FIN. │
                   ↓                                 │ ACT  │ │ ACT  │
          source + allocation                        └──────┘ └──────┘
        often in one large corpus                         \    /
                   │                                       ↓
                   ↓                               cross-document links

        DEEP WITHIN-DOCUMENT                   CROSS-DOCUMENT
             RETRIEVAL                         RECONSTRUCTION


────────────────────────────────────────────────────────────────────
        SAME DEFINITION · SAME EVIDENCE STANDARD · SAME SCHEMA
```

This visual is much stronger than a comparison table.

---

## 5. Exact asset

**Custom two-column document-stack diagram.**

Do not depend on actual legal-document cover screenshots.

Why?

Because a cover page tells the audience very little about the information architecture, while stylized document stacks immediately show:

**one large corpus versus several linked legal texts.**

You can label the left central document:

> **CGI**

and the right stack:

> **Tax Act · Levy Act · Fund Act · Finance Act**

No country flags are necessary.

---

## 6. Final source line

**Source: Author's legal-corpus methodology.**

That's sufficient.

---

## 7. Asset status

**READY.**

No external legal research needed.

---

## 8. Build instructions

Keep both columns visually equal.

Do **not** imply:

> Francophone = easy
> Anglophone = difficult

Both have different problems.

So the bottom labels should say:

**Deep within-document retrieval**

versus

**Cross-document reconstruction**

not:

> simple / complex.

Potential small visual distinction:

* left: one tall document;
* right: 4–5 smaller overlapping documents with dotted links.

Do not show a full pipeline here. That comes next.

---

## 9. Oral explanation

About **45–60 seconds**:

> “The definition I just showed is held constant across the sample, but the legal retrieval problem is not.”

Then:

> “In the Francophone countries in this project, the most recent consolidated tax code usually gives a broad view of the revenue system in one large source, sometimes supplemented by fiscal annexes or sectoral laws. So the main challenge is exhaustive retrieval within a very long document.”

Then:

> “In the Anglophone pilots, the charging provision and the allocation can be distributed across principal tax Acts, levy Acts, fund-establishing Acts, finance Acts or regulations. The extraction therefore has to reconstruct relationships across documents.”

Finish:

> **“What changes is the retrieval architecture—not the definition of an earmark or the evidence standard.”**

That's the key sentence.

---

## 10. Transition

The slide 11 transition should now be:

> **“To handle both architectures—and to measure prevalence correctly—I separate the task into two linked databases.”**

That makes slide 11 feel like the solution to slides 8–10.

---

## 11. Remaining decision

**None.**

### Status: **BUILD READY**

---

# Batch 3 production checklist

|  Slide | Exact copy | Methodological verification | Legal examples                | Asset                          | Build status |
| -----: | ---------- | --------------------------- | ----------------------------- | ------------------------------ | ------------ |
|  **8** | ✅          | ✅ methodology               | Not needed                    | Source→law→destination diagram | **Ready**    |
|  **9** | ✅          | ✅ taxonomy                  | ✅ three CIV examples verified | Taxonomy + legal mini-cases    | **Ready**    |
| **10** | ✅          | ✅ corpus methodology        | Not needed                    | Two document architectures     | **Ready**    |

### One substantive improvement from our earlier plan

I would now **definitively use the three-CIV comparison on slide 9** rather than mixing CIV, Togo and South Africa.

It creates a cleaner empirical demonstration:

**same legal code → same extraction rules → three different statutory designs**

* environmental label + 100% general budget → **assigned, unrestricted**; 
* 40% Treasury + 60% restricted environmental purposes → **partial earmark**; 
* 50/35/10/5 all restricted to sport → **exclusive earmark**. 

That makes slide 9 both **simpler and more convincing** than using three countries.

Batch 3 is therefore ready for slide construction.
