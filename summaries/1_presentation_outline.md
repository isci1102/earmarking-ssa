Yes — your instinct is right. **For this project, methodology should come before stylized facts**, because the core empirical contribution is not “I ran six descriptive graphs.” It is:

> **The object was not measured. I constructed a new way to identify it from law, built the first cross-country de jure inventory for this SSA sample, and the stylized facts are what this new measurement infrastructure reveals.**

That is a much stronger narrative.

Your literature review actually gives you the intellectual justification for doing exactly this: the causal chain runs from **de jure design → awareness/credibility → political authorization → collection → transfer → additional spending → expenditure quality → later trust/compliance**, and your project measures the **first node**, which is necessary before the downstream effects can be studied.  The literature also does not establish a causal effect of earmarking on net DRM in SSA, so you should not structure the talk as if your objective were to answer “does earmarking work?” 

## The central narrative I would use

There are really **four acts**:

**I. Why should we care — and what don't we know?**  
**II. How do you measure something that existing datasets do not measure?**  
**III. What does the new measurement reveal about SSA?**  
**IV. What can we now say, and what remains unanswered?**

That makes the database construction the center of the presentation rather than an annoying technical section before the “real results.”

### I would build the main deck approximately like this

1. **Title**

2. **The policy problem: SSA needs more domestic revenue**
   - Development financing needs.
   - Slow progress on DRM.
   - Declining aid/grants as additional pressure.
   - Keep this very short: you are establishing *why DRM matters*, not giving an SSA macro presentation.
   
   This follows the original project motivation very closely. 

3. **The earmarking puzzle: a potential political benefit comes with a fiscal cost**
   
   The question is not simply “earmarking is good.”
   
   It is:
   
   **Why do governments deliberately constrain the use of revenue?**
   
   Possible benefit: acceptability, visibility, trust, commitment to priorities.  
   Possible cost: rigidity, fragmentation, fungibility, weaker budget management.
   
   This is where I would introduce the tension that originally motivated the project.

4. **The literature suggests several channels — but no general answer**
   
   Here your literature review should become a conceptual slide rather than a traditional literature-review table:
   
   **De jure design → political authorization → collection → transfer → spending → outcomes**
   
   You can say that existing evidence is strongest for some political-authorization mechanisms, much more uncertain for compliance/net DRM, and conditional for expenditure additionality and quality. 
   
   This is literature slide 1.

5. **Before asking whether earmarking works, we need to know where it exists**
   
   This is your **research gap slide**, and I think it is extremely important.
   
   The message:
   
   > Despite a long-standing policy debate, there is no representative legal inventory telling us how prevalent statutory revenue assignments are across SSA, what revenues are assigned, where they go, or how strongly they are dedicated.
   
   Standard revenue classifications do not give you the revenue destination, and the literature itself identifies the lack of an SSA inventory. 
   
   Then the transition:
   
   > **This project therefore starts one step earlier: measurement.**

6. **Contribution: a new de jure map of statutory revenue assignment in SSA**
   
   This is your “avant-goût” slide.
   
   I would make **two contributions**, not one:
   
   **Measurement contribution**  
   New legal inventory linking revenue instruments to statutory destinations.
   
   **Methodological contribution**  
   An auditable LLM-assisted pipeline that can recover these relationships from heterogeneous legislation.
   
   Then your large numbers:
   
   **19 countries**  
   **X revenue instruments in the census**  
   **435 assigned revenue instruments**  
   **803 statutory allocation channels**  
   **209 purpose-restricted earmarked instruments**
   
   But I would verify your 435 = 226 + 209 classification against the final taxonomy before putting those numbers on the slide. In particular, “decentralization” and “earmarking” need to be mutually exclusive at the **instrument level**, and cost-recovery cases need to be handled consistently.

---

## Act II — Building the measurement infrastructure

This is where I would make your biggest change.

Do **not** call the section simply “Methodology.”

Call it something like:

### **Building a de jure map of earmarking**

It immediately sounds like part of the contribution rather than housekeeping.

7. **What exactly are we measuring?**
   
   This slide should establish four things:
   
   **Current legal snapshot** — most recent authoritative/consolidated legislation available.  
   **De jure** — what the law assigns, not what is actually collected or spent.  
   **Revenue instrument** — deliberately broader than “tax.”  
   **Two units** — revenue instruments and statutory allocation channels.
   
   And yes, your reasoning about “revenue instrument” is correct. Your methodology deliberately includes taxes, duties, levies, contributions, redevances, royalties, parafiscal charges, fees, etc., because legal systems use heterogeneous labels and not every compulsory revenue source is straightforwardly a “tax” in the narrow sense. 
   
   I would **not** spend time trying to give an exhaustive economic definition of a tax here. Say simply that you preserve the legal label and use the broader umbrella “revenue instrument.”

8. **Not every statutory assignment is an earmark**
   
   This is your audience-friendly taxonomy slide.
   
   I would simplify the full taxonomy to:
   
   **Unassigned → assigned but unrestricted → partial earmark → exclusive earmark**
   
   With cost recovery visually placed aside.
   
   This is intellectually important because otherwise someone will see all your decentralization transfers and think you are calling them earmarks. Your taxonomy explicitly says that unrestricted territorial assignments are **assigned but not earmarked**, while an earmark requires at least one purpose-restricted proceeds channel. 
   
   Use 2–3 real examples here. That will be much more convincing than definitions alone.

9. **Two linked databases solve two different measurement problems**
   
   This should probably be the **core methodology slide**.
   
   **CENSUS**  
   all revenue instruments in the selected corpus  
   → gives the denominator
   
   **ALLOCATION LAYER**  
   statutory revenue → destination links  
   → identifies assignments and earmarks
   
   **`census_ref`** joins the two.
   
   This is one of the strongest features of the design because an instrument with four beneficiaries must not count four times in prevalence. Your methodology explicitly separates the denominator from the allocation layer for exactly this reason. 

10. **Building the denominator: the revenue-instrument census**
    
    One slide, not more.
    
    Explain:
    
    legal corpus → identify charge-creating provisions → distinguish instruments from rates/modalities → reconcile duplicates/amendments → one current instrument record.
    
    Then show **one actual legal clause → one extracted census row**.
    
    The important intellectual message is:
    
    > “Before measuring earmarking prevalence, I first reconstruct the set of revenue instruments against which prevalence is defined.”

11. **Finding earmarks: high recall first, classification second**
    
    This should present your second branch:
    
    **LOCATE → EXTRACT → RECONCILE → CLASSIFY**
    
    Explain why LOCATE exists:
    
    > Assignment clauses are sparse and may be far away from the charging provision, so directly asking an LLM to extract the final table from hundreds of pages creates a false-negative risk.
    
    Then perhaps one real legal example: original text → located passage → source/allocation evidence → final channel.
    
    That makes the LLM method concrete.

12. **The same definition, different legal architectures**
    
    I think this deserves its own slide because it shows why your methodology is more interesting than “I prompted Claude.”
    
    **Francophone countries:** frequently one consolidated CGI → deep within-document search.  
    **Anglophone countries:** source and destination often distributed across several Acts → cross-document reconstruction and reconciliation.
    
    The substantive definition stays constant while the retrieval procedure adapts. That is explicitly one of the strengths of your methodology. 
    
    This also justifies why the Anglophone countries should later be interpreted somewhat differently in the coverage statistics.

13. **From legal evidence to comparable analytical variables**
    
    This is where you show that the project does not end at extracting quotations.
    
    Raw law gives you:
    
    revenue source → share → beneficiary/purpose
    
    You then derive comparable dimensions:
    
    tax/base type · source sector · destination function/COFOG · recipient type · partial/exclusive status · allocation depth/shares · etc.
    
    This is the bridge between **data construction** and **stylized facts**.
    
    Your taxonomy distinguishes the coding unit (`pair_id`), reporting unit (`instrument_id`) and country prevalence, and then rolls channels up to partial/exclusive earmarks. 

14. **How do we know the extraction is trustworthy?**
    
    Keep one validation slide.
    
    I would emphasize:
    
    legal quotation + article/page retained for every fact;  
    complete document coverage tracked;  
    LOCATE and EXTRACT independently cross-checked;  
    amendments/restatements reconciled;  
    detailed validation on selected countries/stages;  
    retained final records manually checked against the legal text.
    
    But I would **not say “there are no false positives.”**
    
    Better:
    
    > **All retained allocation records were reviewed against the underlying legal evidence; the remaining concern is primarily completeness rather than unsupported positive classifications.**
    
    And then explicitly:
    
    > Residual false negatives cannot be ruled out, especially where subordinate legal texts are unavailable.
    
    That is much more defensible. Your methodology itself says that completeness checks make omissions visible but cannot mathematically prove perfect recall. 

### What I would *not* put in the main methodology narrative

I would move the following to the appendix:

**“Claude Opus 5,” Chat interface versus API, one Cowork session per task, detailed prompt contents, file naming conventions, exact hard-stop rules.**

You can say on slide 11:

> “LLM-assisted extraction using fixed stage-specific prompts, data dictionaries, positive/negative examples, and deterministic reconciliation rules.”

That is enough.

The particular model/interface is an **implementation detail**, not the intellectual contribution. If someone asks, you have an appendix slide.

---

## Act III — What the new data reveal

Now the framing changes subtly.

Don't title the section merely **“Results.”**

I would call it:

### **What does the new inventory reveal?**

That keeps reminding the audience that these stylized facts are the output of a measurement contribution.

15. **What did the extraction uncover? — Database anatomy**
    
    This is where I would put the final coverage figures:
    
    countries, documents, census instruments, assigned instruments, allocation channels, functional earmarks.
    
    This slide says:
    
    > This is the empirical object I have constructed.

16. **How prevalent is statutory earmarking across countries?**
    
    This is your headline prevalence result.
    
    Remember that prevalence must use the census denominator; the allocation table is not itself the denominator. 

17. **Earmarking is not binary: partial versus exclusive dedication**
    
    This naturally follows prevalence and makes use of your taxonomy.
    
    It is also a substantive fact that earlier databases would miss.

18. **What revenue bases are governments willing to earmark?**
    
    Source-side composition:
    
    tax types / economic bases / sectors.
    
    The question is more interesting than “distribution of instrument_nature.”

19. **What functions receive earmarked revenue?**
    
    Destination-side composition:
    
    health, education, transport, environment, etc.
    
    Again phrase it as an economic question rather than a variable description.

20. **How are earmarks institutionally structured?**
    
    Pick your strongest remaining architecture fact:
    
    dedicated funds vs agencies/programs;  
    number of allocation channels per instrument;  
    partial shares / known dedication ratios;  
    payer–beneficiary linkage;  
    or something similar.
    
    Do **not** force five stylized-fact slides merely because you planned five. Keep only facts that tell you something qualitatively different.

21. **Country application / Ghana**
    
    If the Ghana budget work remains part of the final presentation, I would put it **after the cross-country stylized facts**, not inside the methodology.
    
    It then becomes:
    
    > “The legal inventory tells us what is earmarked; Ghana illustrates how large these schemes are relative to the budget.”
    
    That is a natural transition from de jure architecture toward the downstream questions that the cross-country database cannot yet answer.

---

## Act IV — What have we learned?

22. **What this project establishes — and what it does not**
    
    I would make the distinction explicit:
    
    **Establishes**
    
    prevalence, legal design, source bases, statutory destinations, allocation architecture, heterogeneity across countries.
    
    **Does not establish**
    
    causal effect on tax acceptance, compliance, net DRM, expenditure additionality or service outcomes.
    
    This is not apologetic. It tells the audience exactly where the new evidence sits in the conceptual chain.

23. **From a legal inventory to a research agenda**
    
    Future layers:
    
    de jure legal design  
    → actual collections/transfers  
    → expenditure additionality  
    → reform histories/panel  
    → causal evaluation.
    
    This directly returns to your conceptual framework: the current inventory identifies the institutional treatment and risk set; execution data and subsequent analysis would be needed for the downstream stages. 

24. **Conclusion: three takeaways**
    
    Not a generic “limitations” slide as your final impression.
    
    Something like:
    
    **1. Earmarking is a meaningful but previously unmapped part of SSA revenue architecture.**  
    **2. Measuring it requires distinguishing revenue instruments, statutory allocations and purpose restriction.**  
    **3. The new database creates the basis for studying whether these legal arrangements ultimately affect revenue and expenditure outcomes.**

---

### The most important change from your current draft

Your current implicit story is:

**Motivation → literature → long methodology → descriptive results.**

I would change the *meaning* of those sections to:

> **Policy question → measurement gap → measurement contribution → construction of new data → what the new data reveal → what this now makes possible.**

That is much stronger.

And it addresses exactly your concern that “too many results” might make the work look like an easy descriptive exercise. The stylized facts are no longer presented as the entirety of the research. They are presented as the **first empirical application of a new measurement infrastructure**.

I also think the sentence that should guide the entire deck is:

> **Before asking whether earmarking improves DRM, we first need to know where it exists, how it is designed, and what revenues it assigns to what purposes.**

Everything in the presentation should logically follow from that sentence.