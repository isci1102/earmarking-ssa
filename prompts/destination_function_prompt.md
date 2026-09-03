{country}

**Input:** `countries/{country}/outputs/reconcile/{country}_{document_id}_CENSUS_REF.json`
**Output:** `countries/{country}/outputs/reconcile/{country}_{document_id}_EARMARKS.json` — the input file with four columns added. Row count, row order and every existing field unchanged.

COFOG per GFSM 2014 Table A8.6, coded at **group** level (four digits). Work from the document only — **do not search the web**; later law would contaminate an inventory dated to this document.

## Columns

Populate on `row_type = allocation`; `null` on `source` rows.

| column | rule |
|---|---|
| `destination_function` | COFOG group code, or a non-functional value. Always populated. |
| `destination_function_basis` | `stated` · `named_body` · `inferred` |
| `destination_function_multi` | `1` when the text names more than one function, else `0` |
| `destination_function_detail` | the other functions as group codes, semicolon-separated, in the order stated. Only when `_multi = 1`. |

## Choosing the code

Read `destination`, then `verbatim_excerpt` when the destination is truncated or names a body without saying what it does.

- **Code the function financed, not the recipient's form.** A fund, agency or programme is coded by what it does; `beneficiary_type` is not the answer. Each division covers the administration, regulation and supervision of its function, so a transport regulator is `7045` and a media regulator `7083` — regulators do not go to `701`.
- **Never code from the source.** The taxed sector is not the financed function: a fund fed by mining royalties that finances local development plans is not `7044`. Reading the base into the destination makes any later benefit-link variable true by construction.
- **R&D sits inside its function** — geological and mining research is `7048`. `7014` is only for basic research with no sectoral purpose.
- A route is not a recipient: a Treasury account feeding a named fund takes the fund's function.

## Destinations with no function

COFOG classifies expenditure by purpose. A destination with no stated purpose has none, and coding one would invent it. The test is the **stated restriction on use**, never the recipient's identity.

| value | when |
|---|---|
| `general_budget` | central State budget or Treasury, no purpose stated |
| `local_budget` | a tier's own budget, unrestricted — a derivation share to the tier where the base sits |
| `unallocated` | a destination is named but the text never says what it funds, and you cannot fix even its division |

A commune's general budget is `local_budget`; a commune's road fund is `7045` — a tier, but a stated purpose.

A pooled national fund redistributed across tiers by formula, for the tiers to spend **across sectors**, is `7018`. The tells are pooling, a distribution key, and no single identifiable function. Where a devolved transfer *is* purpose-specific, code that purpose — a tax shared to communes for a road fund is `7045`, not `7018`. `assignment_type` corroborates but does not decide: `tax_sharing_general` points to `local_budget`, `equalization_transfer` and `hybrid_devolved_earmark` point to `7018` only when the across-sectors test also holds.

## When the group won't pin down

Division known, group undeterminable → the division's `n.e.c.` group (`7056`, `7049`, `7016`…), `basis = inferred`. Use an `n.e.c.` group with `basis = stated` only when the text states an activity that genuinely falls outside the division's named groups.

Neither `n.e.c.` nor `701` is a dustbin. `701` is a real function — tax and customs administration, fiscal cadastre, debt service, general-character transfers. A destination you could not classify at all is `unallocated`.

## Multi-purpose destinations

Set `_multi = 1`, code `destination_function` to the function the text states **first**, and put the others in `_detail` as codes. Order of statement supplies a primary in every case, so there is no unrankable outcome; these clauses carry no amounts per purpose, so never split the row, average, or invent a ranking.

Compound wording is not multi-function. *« lutte contre le tabagisme, l'alcoolisme, la toxicomanie et les autres addictions »* is four activities and one code (`7074`), flag `0`. Set the flag only when the functions differ — *« réhabilitation et sécurisation des sites miniers et lutte contre l'usage de produits prohibés »* spans `705` and `703`, flag `1`. If you cannot name a second code, it was not multi-function.

## Basis — the triage field

It decides what a human checks, so do not inflate it.

| value | when |
|---|---|
| `stated` | the enacting clause names the purpose — *« au financement des actions de contrôle du trafic »* |
| `named_body` | the clause names only a body, but its name or mandate fixes the function unambiguously — *Office de Radiodiffusion et Télévision du Bénin* → `7083` |
| `inferred` | the code rests on a judgment that could reasonably go another way — *« plans régionaux et communaux de développement »*, unpinned between `7018`, `7062` and `local_budget` |

`named_body` when a competent reader would reach the same group from the body's name alone; `inferred` when they might not. If you are weighing two codes, it is `inferred`.

## COFOG groups (GFSM 2014, Table A8.6)

| division | groups |
|---|---|
| **701** General public services | `7011` executive and legislative organs, financial and fiscal affairs, external affairs · `7012` foreign economic aid · `7013` general services · `7014` basic research · `7015` R&D · `7016` n.e.c. · `7017` public debt transactions · `7018` transfers of a general character between levels of government |
| **702** Defence | `7021` military · `7022` civil · `7023` foreign military aid · `7024` R&D · `7025` n.e.c. |
| **703** Public order and safety | `7031` police · `7032` fire protection · `7033` law courts · `7034` prisons · `7035` R&D · `7036` n.e.c. |
| **704** Economic affairs | `7041` general economic, commercial and labour affairs · `7042` agriculture, forestry, fishing and hunting · `7043` fuel and energy · `7044` mining, manufacturing and construction · `7045` transport · `7046` communication — postal, telecom and ICT sector affairs · `7047` other industries · `7048` R&D · `7049` n.e.c. |
| **705** Environmental protection | `7051` waste management · `7052` waste water management · `7053` pollution abatement · `7054` protection of biodiversity and landscape · `7055` R&D · `7056` n.e.c. |
| **706** Housing and community amenities | `7061` housing development · `7062` community development · `7063` water supply · `7064` street lighting · `7065` R&D · `7066` n.e.c. |
| **707** Health | `7071` medical products, appliances and equipment · `7072` outpatient services · `7073` hospital services · `7074` public health services · `7075` R&D · `7076` n.e.c. — **care delivery, not income support** |
| **708** Recreation, culture and religion | `7081` recreational and sporting services · `7082` cultural services · `7083` broadcasting and publishing — **a national broadcaster is here, not `7046`** · `7084` religious and other community services · `7085` R&D · `7086` n.e.c. |
| **709** Education | `7091` pre-primary and primary · `7092` secondary · `7093` post-secondary non-tertiary · `7094` tertiary · `7095` not definable by level · `7096` subsidiary services · `7097` R&D · `7098` n.e.c. |
| **710** Social protection | `7101` sickness and disability · `7102` old age · `7103` survivors · `7104` family and children · `7105` unemployment · `7106` housing · `7107` social exclusion n.e.c. · `7108` R&D · `7109` n.e.c. — **a solidarity levy is here unless it funds care** |

## Report inline

- **Verification worklist** — every destination coded `inferred`: the wording it rests on, the code taken, the alternatives considered. The only list needing your time. Order by rows affected.
- rows coded `unallocated`, with the destination text and why
- every `_multi = 1` row: primary code, detail codes, and the wording each rests on
- any destination appearing under more than one code
- counts by `destination_function_basis`
