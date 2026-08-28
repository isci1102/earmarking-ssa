Yes. Slides **8–10 should now move the audience through three questions in order**:

**What is the object? → Which assignments qualify as earmarks? → Why is recovering that object legally difficult across countries?**

That gives us a clean bridge from the contribution slide into the actual construction of the database.

---

# Slide 8 — What exactly do we measure?

| Field                | Decision                                                                                                                                                                                                                                                                                                                                                                |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Working title**    | **What exactly do we measure?**                                                                                                                                                                                                                                                                                                                                         |
| **Purpose**          | Define the empirical object before introducing the extraction pipeline or the databases.                                                                                                                                                                                                                                                                                |
| **Takeaway**         | The database is a **current-law, de jure map from revenue sources to legally specified destinations**. It measures statutory commitments—not collections, transfers, spending, or outcomes.                                                                                                                                                                             |
| **On-slide content** | Top annotation: **Current legal snapshot — what the law commits.** Center: `Revenue instrument → enacting assignment clause → recipient / purpose`. Underneath: **Instrument = one revenue source** · **Allocation channel = one source → destination link**. Small footer: `De jure ≠ collected ≠ transferred ≠ spent`.                                                |
| **Evidence/source**  | The methodology defines the database as a current legal snapshot and explicitly separates statutory assignment from actual collection, transfer, disbursement and expenditure. It also distinguishes `instrument_id` from `pair_id`.                                                                                                                                    |
| **Main asset**       | **One source → law → destination diagram**, optionally anchored by a very short real legal excerpt.                                                                                                                                                                                                                                                                     |
| **Asset status**     | **Ready conceptually.** We only need to choose whether to include an actual clause fragment.                                                                                                                                                                                                                                                                            |
| **Oral explanation** | Explain that **“revenue instrument” is deliberately broader than “tax”**: the legal systems use taxes, duties, levies, contributions, redevances, royalties, fees, etc. You preserve the legal label rather than forcing everything into “tax.” Then distinguish the two units: an instrument is the revenue source; a channel is one legal destination attached to it. |
| **Transition**       | “But observing a statutory destination is not enough to call the instrument earmarked.”                                                                                                                                                                                                                                                                                 |
| **Open decisions**   | Whether to anchor the slide with the CIV apprenticeship clause. I would use only a **very short highlighted fragment** if we have a clean one; otherwise the conceptual diagram is stronger.                                                                                                                                                                            |

### Exact core I would put on the slide

I would keep this extremely simple:

> **CURRENT-LAW, DE JURE SNAPSHOT**

**Revenue instrument**
*tax · duty · levy · contribution · …*

→ **legal assignment** →

**Recipient / purpose**

Then underneath:

**Instrument** = one revenue source
**Channel** = one source → one destination

And one small sentence:

> **The database records what the law assigns—not what is ultimately collected or spent.**

That last sentence matters because it protects the interpretation of **every result later in the presentation**. The methodology explicitly makes this distinction. 

### One thing I would not introduce yet

Do **not** explain `census_ref`, LOCATE, reconciliation, COFOG, `share_level`, etc.

Slide 8 is purely about the **empirical object**.

---

# Slide 9 — Not every statutory assignment is an earmark

This should be one of the most intuitive methodology slides because your legal examples make the taxonomy concrete.

| Field                | Decision                                                                                                                                                                                                                                                                                                                |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Working title**    | **Not every statutory assignment is an earmark**                                                                                                                                                                                                                                                                        |
| **Purpose**          | Establish the classification rule underlying the headline counts and later prevalence statistics.                                                                                                                                                                                                                       |
| **Takeaway**         | **Earmarking requires a legal restriction on use.** Merely routing revenue to the Treasury, a territorial government, or another recipient does not make it an earmark.                                                                                                                                                 |
| **On-slide content** | A simple four-part taxonomy: **No assignment observed → Assigned, unrestricted → Partial earmark → Exclusive earmark**. Visually bracket the final two as **EARMARKED**. Put **cost recovery** slightly outside the sequence: “recorded, then set aside.”                                                               |
| **Evidence/source**  | The taxonomy distinguishes E0 unassigned, E1 assigned/unrestricted, E2 partial and E3 exclusive; earmarked instruments are E2 ∪ E3. Cost-recovery channels are removed before the instrument-level roll-up.                                                                                                             |
| **Main asset**       | **Horizontal taxonomy + three real legal examples.**                                                                                                                                                                                                                                                                    |
| **Asset status**     | **Concept and examples ready.** Exact article/page citations still need to be inserted in slide production.                                                                                                                                                                                                             |
| **Oral explanation** | Explain the rule in plain English: first separate cost recovery; then ask whether any proceeds are legally restricted to a purpose. If none are restricted, it is assigned but not earmarked. If restricted and unrestricted proceeds coexist, it is partial. If all proceeds channels are restricted, it is exclusive. |
| **Transition**       | “The rule itself is simple. The harder problem is finding the relevant clauses consistently, because countries organize their revenue law very differently.”                                                                                                                                                            |
| **Open decisions**   | Whether to show E0/E1/E2/E3 labels. **I would omit the codes from the main slide** and keep them for the appendix/Q&A.                                                                                                                                                                                                  |

## The visual taxonomy I would use

### **No assignment observed**

No statutory destination found in the legal corpus

→

### **Assigned, unrestricted**

Revenue is legally routed, but its use is not restricted

→

### **Partial earmark**

Restricted **and** unrestricted proceeds coexist

→

### **Exclusive earmark**

All proceeds are purpose-restricted

And visually:

**EARMARKED = Partial + Exclusive**

with a smaller separate note:

> **Cost recovery:** recorded separately; not treated as earmarking.

That directly reflects your finalized taxonomy. 

### The three examples are excellent here

I would use them almost as miniature legal case studies.

**Assigned does not necessarily mean earmarked — South Africa**

> **Plastic-bag / tyre environmental levies**
> Environmental-policy purpose exists, but proceeds go to the **National Revenue Fund** rather than being legally dedicated to the environmental purpose.
> **→ Not coded as statutory earmarks**

This is especially useful because it teaches the audience your **evidentiary threshold**:

> **Policy purpose ≠ statutory earmark.**

A fund name, policy objective or explanatory statement is insufficient; you require an **enacting source-to-destination assignment**, which is also the operative rule in the methodology. 

Then the two clean positive examples:

**Partial earmark — Togo**

**Taxe sur les véhicules à moteur**

* **78%** → SAFER / road maintenance → restricted
* **10%** → Treasury → unrestricted
* **12%** → tax-administration cost recovery → set aside

**→ Partial earmark**

This is almost a perfect pedagogical case because it makes clear that the instrument is **not “90% earmarked.”** The 12% administrative component is analytically distinct; after setting it aside, restricted and unrestricted proceeds coexist. That is exactly your instrument roll-up logic. 

**Exclusive earmark — Côte d'Ivoire**

**Taxe d’apprentissage**

→ whole proceeds to the **Fonds de Développement pour la Formation professionnelle**

**→ Exclusive earmark**

I would not add a fourth example.

### One nuance to keep small

For the first category, technically the defensible wording is:

> **No assignment observed in the selected legal corpus**

rather than:

> “Not assigned.”

Your taxonomy explicitly warns that missing subordinate legislation may make absence unobservable rather than truly zero. 

That can be a tiny footnote or oral qualification; it does not need to dominate the slide.

---

# Slide 10 — The legal source architecture differs across countries

This slide should explain **why the methodological problem is actually difficult** without turning into a comparative-law lecture.

| Field                | Decision                                                                                                                                                                                                                                                                                                                                                                                                 |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Working title**    | **The legal source architecture differs across countries**                                                                                                                                                                                                                                                                                                                                               |
| **Purpose**          | Explain why one fixed search procedure cannot simply be run identically over every country, even though the substantive definition is common.                                                                                                                                                                                                                                                            |
| **Takeaway**         | **The definition and output schema stay fixed; the retrieval strategy adapts to the legal architecture.** In much of the Francophone sample, the relevant law is concentrated in a consolidated tax code; in the Anglophone pilots, the source and destination frequently have to be reconstructed across several Acts.                                                                                  |
| **On-slide content** | Two columns: **Typical Francophone corpus in this project** vs **Typical Anglophone corpus in this project**. Francophone: consolidated CGI at the core → possible fiscal/sectoral extensions. Anglophone: principal tax Acts + levy Acts + fund/agency Acts + finance laws + regulations/schedules. Bottom line: **Same legal definition → different retrieval architecture → common database schema.** |
| **Evidence/source**  | The methodology explicitly uses a consolidated CGI or equivalent as the usual core Francophone source, while Anglophone systems require reconstruction across principal tax Acts, levy-specific Acts, fund Acts, finance Acts, schedules, regulations and amendments. The substantive definition and schema remain common.                                                                               |
| **Main asset**       | **Two contrasting document stacks converging into the same standardized source → destination observation.**                                                                                                                                                                                                                                                                                              |
| **Asset status**     | **Ready conceptually.** Actual document-page screenshots can be selected later if useful.                                                                                                                                                                                                                                                                                                                |
| **Oral explanation** | Stress that you are **not using a different definition of earmarking by legal tradition**. What changes is the information-retrieval problem. In a consolidated code, the challenge is exhaustive search through a very long text; in fragmented systems, the charging provision may be in one Act and the assignment in another, requiring cross-document reconciliation.                               |
| **Transition**       | “That is why the measurement architecture separates the revenue-instrument census from the statutory-allocation layer and links them only after extraction.”                                                                                                                                                                                                                                             |
| **Open decisions**   | I would label the columns **“Typical Francophone corpus in this project”** and **“Typical Anglophone corpus in this project”**, rather than making a universal civil-law/common-law claim.                                                                                                                                                                                                               |

### The comparison should be very restrained

I would use something like:

| **Typical Francophone corpus**                                  | **Typical Anglophone corpus**                                           |
| --------------------------------------------------------------- | ----------------------------------------------------------------------- |
| Consolidated **Code général des impôts** at the core            | Revenue law distributed across **multiple Acts**                        |
| Source and assignment often recoverable within one large corpus | Charging provision and destination can occur in **different texts**     |
| Extensions where needed: fiscal annexes, sectoral/fund laws     | Tax Acts · levy Acts · fund Acts · finance Acts · schedules/regulations |
| Main problem: **deep within-document retrieval**                | Main problem: **cross-document reconstruction**                         |

Then below both columns:

> **Common definition · common evidence standard · common output schema**

That bottom sentence is the intellectual point of the slide.

The methodology explicitly says the legal definition, schema, null rules and evidence requirements remain the same; only the reading/retrieval procedure changes with document structure. 

### A useful oral detail

For the Anglophone cases, you can say:

> “Budget documents and revenue-agency lists can help identify which taxes and levies need to be traced, but they are discovery tools. They do not substitute for the operative legal clause.”

That reinforces the legal rigor of the database without adding another box to the slide. 

---

## What slides 8–10 now accomplish

By the end of slide 10, the audience should understand three things:

**Slide 8 — Object:**

> *I measure statutory revenue-to-destination relationships in current law.*

**Slide 9 — Definition:**

> *Only purpose-restricted assignments count as earmarks; routing alone does not.*

**Slide 10 — Measurement problem:**

> *Finding those relationships requires adapting retrieval to very different legal architectures.*

That leaves slide 11 with a very natural job:

> **Given those problems, what database architecture lets us measure prevalence correctly?**

And that is where the **census + allocation layer + `census_ref`** diagram becomes the centerpiece.

|  Slide | Load-bearing asset                                                       | Status                                 |
| -----: | ------------------------------------------------------------------------ | -------------------------------------- |
|  **8** | Source → legal assignment → destination + instrument/channel distinction | ✅ Ready                                |
|  **9** | Four-part taxonomy + CIV/TGO/ZAF legal examples                          | ✅ Ready; article/page anchors later    |
| **10** | Francophone/Anglophone legal-architecture comparison                     | ✅ Ready; document screenshots optional |

So I would consider **slides 8–10 content-locked** at this point.
