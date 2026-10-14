# Transform Element Showcase — 6 Practical Use Cases

A single Salesforce Screen Flow that demonstrates **six different ways to use the Transform element**, each on one screen, using real data in the org.

- **Flow API Name:** `Transform_Element_Showcase`
- **Type:** Screen Flow · **Status:** Active
- **Org:** `ashish-rk` (`asagarwal-rkk-dev-ed`)
- **Run it:** `/flow/Transform_Element_Showcase` — or Setup → Flows → Transform Element Showcase → **Debug**
- **Reference:** [6 Things You Can Do With The Transform Element](https://salesforcebreak.com/2024/10/28/6-things-transform-element) (Salesforce Break)

---

## 1. The one-minute version (for your manager)

The Transform element lets a Flow reshape a whole collection of records **in a single step**, instead of looping over records one at a time.

Before Transform, each of these six tasks needed a **Loop + Assignment** (and often an extra variable or formula resource). This flow does all six with **no loops at all**.

| | Old way (Loop + Assignment) | This flow (Transform) |
|---|---|---|
| Flow elements needed | ~18–20 | **6** |
| Loops | 6 (one of them nested) | **0** |
| DML statements | up to 6 | **1** |
| Get Records queries | up to 8 | **5** |

**Why it matters:** loops are the usual cause of Flows hitting CPU-time and element limits at scale. A nested loop (Use Case 6) is the worst offender — joining 25 Opportunities to 27 Accounts by looping is 675 iterations; Transform does it as one inner join.

---

## 2. How to run the demo

1. Open the org and go to **`/flow/Transform_Element_Showcase`**
2. Click **Next** through 7 screens (1 intro + 6 use cases)
3. Each screen shows the live result of one Transform

**It is safe to run repeatedly.** Use Case 3 creates Task records, but the source query only picks up Tasks that are *not yet linked* to an Account — so re-runs don't multiply data.

### What you should see (verified)

| Screen | Use case | Expected result |
|---|---|---|
| 1 | Extract a Text Collection | A bracketed list of ~24 Opportunity Ids |
| 2 | Remove Ids | Table of **4** Tasks — "Invite to Company's annual event" |
| 3 | Add Ids | Same 4 Tasks, each now showing `WhatId = 001gL00000f5QC3QAM` |
| 4 | Sum and Count | **Total amount: 915,000** · **Number of opportunities: 5** |
| 5 | Build a Title String | e.g. `Dickenson Mobile Generators - Qualification - closes 2025-12-12` |
| 6 | Join Collections | Opportunity Name + Stage **+ Account Type** ("Customer - Direct") |

> Screen 4 is the easiest one to prove. Run this in Developer Console and the numbers must match:
> ```sql
> SELECT COUNT(Id), SUM(Amount) FROM Opportunity WHERE AccountId = '001gL00000f5QC3QAM'
> ```

---

## 3. Flow structure (execution order)

```
START
 └─ Screen_0_Welcome
 └─ Get_Open_Opportunities .................. Opportunity, IsClosed = false
     └─ Transform_1_Extract_Opportunity_Ids ............ USE CASE 1
         └─ Screen_1_Extract_Text_Collection
 └─ Get_Tasks_To_Clone ...................... Task, Subject = "Invite…", WhatId is null
     └─ Transform_2_Remove_Task_Ids ................... USE CASE 2
         └─ Screen_2_Remove_Ids
 └─ Get_Target_Account ...................... Account, Name = "Grand Hotels & Resorts Ltd"
     └─ Transform_3_Add_Account_Id_To_Tasks ........... USE CASE 3
         └─ Create_Cloned_Tasks  ← the ONLY DML in the flow
             └─ Screen_3_Add_Ids
 └─ Get_Opportunities_For_Target_Account .... Opportunity, AccountId = target Account
     └─ Transform_4_Summarize_Sum_And_Count ........... USE CASE 4
         └─ Screen_4_Sum_And_Count
 └─ Transform_5_Build_Opportunity_Titles .............. USE CASE 5  (reuses step 1's data)
     └─ Screen_5_Build_Title_String
 └─ Get_Accounts_For_Join ................... Account, all records
     └─ Transform_6_Join_Opportunities_With_Accounts ... USE CASE 6
         └─ Screen_6_Join_Collections
END
```

**Best practices applied**
- **No redundant queries** — Use Cases 5 and 6 reuse the collection from Use Case 1; Use Case 4 reuses the Account from Use Case 3.
- **One DML** — the 4 cloned Tasks are inserted as a single bulk Create Records.
- **No loops** — all six use cases are loop-free.
- **Clear naming** — every element is prefixed with its use case number.

---

## 4. The six use cases, step by step

### Use Case 1 — Extract a Text Collection

**What it does:** pulls just the `Id` out of every Opportunity into a plain text collection.

| | |
|---|---|
| **Source** | `Get_Open_Opportunities` (Opportunity collection, `IsClosed = false`) |
| **Target** | Text collection |
| **Mapping** | `Get_Open_Opportunities[$EachItem].Id` |

**Why Transform:** to build a list of Ids you previously had to Loop over the records and Assign each Id into a text collection. That's 2 extra elements and one iteration per record. Transform does it in one element.

**The payoff:** the resulting text collection can be dropped straight into another Get Records using the **In** operator — the standard way to fetch child records without a loop.

---

### Use Case 2 — Remove Ids

**What it does:** copies Tasks into a new collection **without their record Id**, making them clone-ready.

| | |
|---|---|
| **Source** | `Get_Tasks_To_Clone` (Task collection) |
| **Target** | Task collection |
| **Mapping** | `Subject`, `Status`, `Priority`, `ActivityDate`, `Description`, `WhoId`, `OwnerId` — **`Id` is deliberately not mapped** |

**Why it matters:** you cannot insert a record that still carries an `Id` — Salesforce treats it as an update, or throws a duplicate-Id error. The records must be stripped first.

**Why Transform:** the article's original workaround was a `SUBSTITUTE()` formula to blank out the Id. With Transform you simply **don't map the Id field** — no formula, no loop. Cleaner and easier to explain.

---

### Use Case 3 — Add Ids

**What it does:** takes the clone-ready Tasks from step 2 and points them all at a different parent record, then inserts them.

| | |
|---|---|
| **Source** | `Transform_2_Remove_Task_Ids` (output of the previous Transform) |
| **Target** | Task collection |
| **Key mapping** | `WhatId` ← `IF(ISBLANK({!Transform_2_Remove_Task_Ids[$EachItem].WhatId}), {!Get_Target_Account.Id}, {!Transform_2_Remove_Task_Ids[$EachItem].WhatId})` |

Reads as: *"if this Task isn't linked to anything yet, link it to the target Account; otherwise keep its existing link."*

**Why Transform:** re-parenting a whole collection used to mean a Loop + Assignment per record. Here one element rewrites the lookup on every row, and the collection then goes into **one** Create Records.

> **Note:** a plain value can't be mapped into a collection field — Flow requires the expression to reference the collection being iterated. That's why this is written as a formula rather than just `{!Get_Target_Account.Id}`. Useful gotcha to know.

---

### Use Case 4 — Calculate Sum and Count

**What it does:** totals the Amount and counts the records of a collection — in one element.

| | |
|---|---|
| **Source** | `Get_Opportunities_For_Target_Account` (Opportunities for Grand Hotels) |
| **Target** | **One** in-memory Opportunity record (never saved — it's just a carrier for the numbers) |
| **Mappings** | `Amount` ← **Sum** of `Amount` · `TotalOpportunityQuantity` ← **Count** of records |

**Why Transform:** this genuinely was not possible declaratively before. You needed a Loop with a running-total number variable and a counter variable, plus Assignments inside the loop. Now it's one element and two mappings.

**Verification:** the screen shows **915,000 / 5**, which matches the SOQL aggregate exactly.

---

### Use Case 5 — Summarize and Build a Title String

**What it does:** generates a readable one-line label for every Opportunity by combining several fields with fixed text.

| | |
|---|---|
| **Source** | `Get_Open_Opportunities` — **reused from Use Case 1, no second query** |
| **Target** | Opportunity collection (in memory) |
| **Mapping** | `Name` ← `{!Get_Open_Opportunities[$EachItem].Name} & " - " & TEXT({!...StageName}) & " - closes " & TEXT({!...CloseDate})` |

**Result:** `Dickenson Mobile Generators - Qualification - closes 2025-12-12`

**Why Transform:** building display strings per record previously meant a Loop plus a formula resource plus an Assignment. One Transform now formats the entire collection at once — handy for digest emails, screen summaries, or Agentforce prompt text.

---

### Use Case 6 — Join Collections

**What it does:** merges two separate collections into one, matching rows on a key — like a SQL `INNER JOIN`.

| | |
|---|---|
| **Left source** | `Get_Open_Opportunities` — join key `AccountId`, fields `Name`, `StageName`, `Amount` |
| **Right source** | `Get_Accounts_For_Join` — join key `Id`, field `Type` |
| **Join type** | **Inner Join** (only rows matching on both sides) |
| **Target** | One merged Opportunity collection |
| **Field mapping** | `Name` ← `LeftTable.Name` · `StageName` ← `LeftTable.StageName` · `Amount` ← `LeftTable.Amount` · `Type` ← **`RightTable.Type`** |

**Why Transform:** this is the headline one. Without it you'd nest a loop inside a loop and compare keys — 25 × 27 = 675 iterations for this data set, and it grows multiplicatively. Transform performs the join natively in one element.

**How to spot it working:** the **Type** column ("Customer - Direct", "Customer - Channel") is Account data appearing next to Opportunity data in the same row. Opportunities don't carry the Account's Type — it could only have come from the join.

---

## 5. Talking points for the demo

1. **Open the flow in Flow Builder first** — show that there is not a single Loop element on the canvas.
2. **Screen 4 is your proof point** — run the SOQL aggregate side by side; the numbers match.
3. **Screen 6 is your "wow"** — one column on that table is physically impossible without a join.
4. **Point at the single Create Records element** — 4 records, 1 DML, fully bulkified.

---

## 6. Notes and honest caveats

- **Use Case 5 targets a record collection, not a text collection.** Flow does not allow formulas on primitive/text collection targets. The article's own example (`{!Get_Tasks[$EachItem].Subject} & " - Reminder"`) also maps into a *field*, so this matches the source material.
- **Use Case 3 uses an `IF()` formula** rather than a bare Account Id, because Flow rejects mapping a single value into a collection field. The formula also reads more sensibly for a demo.
- **Use Case 4's target record is never saved.** It's an in-memory Opportunity used only to hold the two numbers; `TotalOpportunityQuantity` ("Quantity") is standing in for "number of opportunities".
- **Demo data dependency:** the flow expects the Account **"Grand Hotels & Resorts Ltd"** and Tasks with subject **"Invite to Company's annual event"** to exist. Both ship with standard Salesforce sample data in this org.

---

## 7. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Screen 2 shows 0 rows | All source Tasks already have a `WhatId`. Clear `WhatId` on a few "Invite to Company's annual event" Tasks, or change the filter in `Get_Tasks_To_Clone`. |
| Screen 4 shows blank/0 | The target Account has no Opportunities — check `Get_Target_Account` matched a record. |
| Screen 6 is empty | No Opportunity's `AccountId` matches an Account Id. An inner join returns only matching rows. |
| Row counts grow each run | The `WhatId is null` filter was removed from `Get_Tasks_To_Clone` — restore it. |

### Removing the demo Tasks afterwards

```bash
sf data query --query "SELECT Id FROM Task WHERE WhatId='001gL00000f5QC3QAM'" \
  --target-org ashish-rk --result-format csv > clone_ids.csv
sf data delete bulk --sobject Task --file clone_ids.csv --target-org ashish-rk --wait 10
```

---

## 8. Deploying to another org

```bash
sf project deploy start \
  --source-dir force-app/main/default/flows/Transform_Element_Showcase.flow-meta.xml \
  --target-org <alias>
```

> **Important:** a successful deploy does **not** guarantee a valid Flow. Always confirm afterwards:
> ```bash
> sf data query --use-tooling-api --target-org <alias> \
>   --query "SELECT Status FROM Flow WHERE MasterLabel='Transform Element Showcase' ORDER BY VersionNumber DESC LIMIT 1"
> ```
> `Draft` or `Active` = good. **`InvalidDraft` = the Flow deployed but is broken** — open it in Flow Builder and check the errors panel.
