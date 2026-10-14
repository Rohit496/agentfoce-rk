# HXL for Account

Two MCP tools on the **HXL MCP Server** that answer questions about Accounts and render the answer as an HXL (Headless Experience Layer) widget in any MCP host: Slack, ChatGPT, Claude, Agentforce.

| The user asks | Tool | Widget | What renders |
|---|---|---|---|
| "Show me the details of account Acme" | `AccountDetails` | `accountDetailsCard` | The account only |
| "Show me Acme and its related records" / "Show all accounts with their related records" | `AccountWithRelatedRecords` | `accountRelatedAccordion` | An accordion with one section per account, each listing its Contacts, Cases and Opportunities |

The MCP host chooses a tool from its `descriptionOverride`. The details tool's description says it returns the account only; the related-records tool's description says it includes related records.

---

## How it fits together

```
User question
   │
   ▼
MCP host (Slack / ChatGPT / Claude / Agentforce)
   │  picks a tool on HXLAccountMCPServer
   ▼
Invocable Apex  (AccountDetails / AccountWithRelatedRecords)
   │  returns { actionName, isSuccess, outputValues }
   ▼
Lightning Type  c__accountDetailsResult / c__accountRelatedResult
   │  schema.json describes the envelope; renderer.json maps outputValues → widget attributes
   ▼
uiWidget  @widget/c/accountDetailsCard / @widget/c/accountRelatedAccordion
   │  UEM tree of tile/* blocks bound with {!$attrs.x}
   ▼
Rendered natively in the host
```

Each tool has four parts:

1. **Invocable Apex class**: queries the data and returns display-ready strings, colours and booleans.
2. **Lightning Types** (2 bundles):
   - `…Result`: the invocable-action envelope, plus `renderer.json` pointing at the widget.
   - `…OutputValues`: the shape of `outputValues`.
3. **uiWidget bundle**: the widget JSON, its `schema.json`, and a `.uiwidget-meta.xml`.
4. **MCP server entry**: a `<resources>` element (the widget URI) and a `<tools>` element (the Apex action, linked through `<uiResource>`).

---

## Files

```
force-app/main/default/
├── classes/
│   ├── AccountDetails.cls                    # tool 1: single account
│   ├── AccountWithRelatedRecords.cls         # tool 2: accounts + contacts/cases/opportunities
│   └── AccountHxlToolsTest.cls               # 8 tests covering both classes
├── lightningTypes/
│   ├── accountDetailsResult/                 # schema.json + renderer.json → @widget/c/accountDetailsCard
│   ├── accountDetailsOutputValues/           # schema.json
│   ├── accountRelatedResult/                 # schema.json + renderer.json → @widget/c/accountRelatedAccordion
│   └── accountRelatedOutputValues/           # schema.json (accounts → @apexClassType/c__AccountWithRelatedRecords$AccountRow)
├── uiWidgets/
│   ├── accountDetailsCard/                   # .json, schema.json, .uiwidget-meta.xml
│   └── accountRelatedAccordion/              # .json, schema.json, .uiwidget-meta.xml
└── mcpServerDefinitions/
    └── HXLAccountMCPServer.mcpServerDefinition-meta.xml   # + 2 resources, + 2 tools
```

---

## Step by step: how this was built

### Step 1: Plan the HXL chain

Every HXL tool follows the same chain: Apex → Lightning Type → renderer → uiWidget → MCP server entry. The account tools need two shapes:

- **Single object:** `AccountDetails` → `accountDetailsResult` → `accountDetailsCard`
- **List with nested lists** (`forEach`): `AccountWithRelatedRecords` → `accountRelatedResult` → `accountRelatedAccordion`

### Step 2: Check which blocks the org supports

These calls use the `execute_metadata_action` MCP tool (Salesforce metadata experts), with `metadataType: "FRAGMENT"`:

- `discoverUiComponents` lists the `tile/*` blocks the org supports. This confirmed `tile/accordion` and `tile/accordionitem`.
- `getUiComponentSchemas` returns each block's attributes. For an accordion item these are `title` (required), `subtitle`, `iconName`, `iconAlt` and `isExpanded`. The same call returns the allowed `iconName` values, such as `building`, `users`, `ticket`, `trending-up`, `briefcase` and `tag`.

The [HXL Playground](https://www.headlessexperiencelayer.com/playground/?renderer=mcp-app&theme=slack#components/accordion) → Components → Accordion was the design reference: an accordion wraps item children, and each item holds a column of content.

### Step 3: Write the Apex so it returns what the widget displays

Widgets cannot compute anything. Bindings support no comparisons, arithmetic or string formatting, so the Apex returns every value ready to display:

- **Formatted strings:** currency (`$1,000,000.00`), `City, State, Country`, and `—` for blanks.
- **Colour tokens for badges:** customer priority maps High → `error`, Medium → `warning`, Low → `success`. Case status: open → `warning`, closed → `success`. Opportunity stage: open → `info`, won → `success`, lost → `error`.
- **Section titles with counts:** `Contacts (3)`, `Cases (2)`, `Opportunities (1)`.
- **Booleans for empty states:** `found` / `notFound`, `hasPriority` (hides the badge when priority is blank), `hasDescription` (hides the bottom separator and description when blank), `noAccounts`, and `noContacts` / `noCases` / `noOpportunities`. A widget's `meta.if` only works with a `lightning__booleanType`, and it cannot negate, so both sides are sent.

What each class does:

- **`AccountDetails.getDetails(List<String> accountName)`** tries an exact name match first, then `LIKE %name%`, and returns one account. It uses `WITH USER_MODE`.
- **`AccountWithRelatedRecords.getAccounts(List<String> accountName)`** uses a `LIKE` filter; a blank name returns all accounts. It returns up to **10 accounts** with up to **5 of each child**, fetched through subqueries in a single SOQL statement (`WITH USER_MODE`).

Both classes use `@InvocableMethod` and `@InvocableVariable`. The platform registers each class in the API Catalog automatically as `aa:apex-<ClassName>`.

### Step 4: Lightning Types

For each tool there are two bundles:

- **`…OutputValues/schema.json`** lists each `outputValues` field with a `lightning:type`. A list of Apex inner-class rows is referenced as `@apexClassType/c__<Class>$<InnerClass>`.
- **`…Result/schema.json`** is the envelope: `actionName`, `isSuccess`, and `outputValues` of type `c__…OutputValues`.
- **`…Result/renderer.json`** maps `{!$attrs.outputValues.x}` to the widget attributes of `@widget/c/<widgetName>`.

### Step 5: uiWidgets

Each widget is a bundle of three files. `schema.json` wraps its fields in `properties.attributes`.

**`accountDetailsCard`** (single object)
- A `tile/callout` warning appears when `notFound`.
- When `found`, it shows:
  - the name, industry and type
  - a priority `tile/badge`
  - two groups of fields, "Company" and "Classification"
  - the description

**`accountRelatedAccordion`** (list + accordion)
- A summary line, plus a `tile/callout` when `noAccounts`.
- A `tile/accordion` whose `tile/accordionitem` repeats with `forEach: {!$attrs.accounts}` and `forItem: $account`. Each item has:
  - `title` set to the account name, `subtitle` set to industry • type, and the `building` icon
  - key account fields
  - three headed sections, each with an inner `forEach` and its own empty state:
    - Contacts: `$contact`, icon `users`
    - Cases: `$case`, icon `ticket`
    - Opportunities: `$opportunity`, icon `trending-up`

Nested loops use their own `forItem` names. Inside a loop, bindings use `{!$account.x}`, `{!$contact.x}`, and so on; `{!$attrs.accounts.x}` does not resolve inside a loop.

### Step 6: Register on the MCP server

Changes to `HXLAccountMCPServer.mcpServerDefinition-meta.xml`:

- **2 `<resources>`:** `accountDetailsWidget` → `ui://widget/lightningType/c__accountDetailsResult`, and `accountRelatedWidget` → `ui://widget/lightningType/c__accountRelatedResult`.
- **2 `<tools>`:** `apiIdentifier` is `aa:apex-AccountDetails` or `aa:apex-AccountWithRelatedRecords`, `apiSource` is `API_CATALOG`, `uiResource` points at the resource above, and `readOnly` and `idempotent` are both `true`.
- **`descriptionOverride`:** each tool's description says when to use it, so the host picks details-only vs related records correctly.

### Step 7: Test

`AccountHxlToolsTest` has 8 tests. They cover exact match, partial match, not found, blank input, child records and colours, all accounts, empty child lists, and no accounts.

Coverage: `AccountDetails` 93%, `AccountWithRelatedRecords` 98%.

### Step 8: Deploy (two phases)

The MCP server resolves `aa:apex-<Class>` from the API Catalog, so **the Apex must be in the org before the server definition deploys.**

```bash
cd force-app/main/default

# Phase 1: Apex + tests
sf project deploy start --target-org <alias> \
  -d classes/AccountDetails.cls \
  -d classes/AccountWithRelatedRecords.cls \
  -d classes/AccountHxlToolsTest.cls \
  --test-level RunSpecifiedTests --tests AccountHxlToolsTest

# Phase 2: types, widgets, MCP server
sf project deploy start --target-org <alias> \
  -d lightningTypes/accountDetailsOutputValues \
  -d lightningTypes/accountDetailsResult \
  -d lightningTypes/accountRelatedOutputValues \
  -d lightningTypes/accountRelatedResult \
  -d uiWidgets/accountDetailsCard \
  -d uiWidgets/accountRelatedAccordion \
  -d mcpServerDefinitions/HXLAccountMCPServer.mcpServerDefinition-meta.xml
```

Deploy by path (`-d`), not by metadata name (`-m`). A name-based deploy scans the whole project and currently fails on an unrelated `uiBundles/myapp2` bundle.

### Step 9: Try it

Reconnect your MCP client to the HXL server so it picks up the new tools, then ask:

- "Show me the details of account Acme"
- "Show me Acme and its related records"
- "Show all accounts with their contacts, cases and opportunities"

---

## Gotchas found while deploying

| Error | Cause | Fix |
|---|---|---|
| `tile/accordionItem can't be the child of the block tile/accordion` | The Playground uses camelCase `tile/accordionItem`. The org's parent/child check only accepts the lowercase form returned by `discoverUiComponents`. | Use **`tile/accordionitem`**. |
| `The block tile/column … can have only 10 children` | A column accepts at most 10 child blocks. | Group fields into sub-columns (e.g. "Company", "Classification"). |
| `No "aa:apex-<Class>" identifier found for source "API_CATALOG"` | The Apex class wasn't compiled in the org yet. | Deploy the Apex first (two-phase deploy). |
| `An unexpected error occurred` on a Lightning Type | Its `@apexClassType/...` reference points at a class that failed to compile. | Fix the Apex; the type then deploys. |
| `FIELD_INTEGRITY_EXCEPTION … BillingCountry` in tests | The org has State/Country picklists enabled. | Use a valid picklist value, e.g. `United States`, not `USA`. |
| `meta.if` renders unpredictably | `if` bound to a string or number. | Bind only to `lightning__booleanType`, and send both `found` and `notFound` from Apex. |

---

## Extending it

To add another related object (for example Tasks):

1. Add a `TaskRow` inner class, a subquery, a `tasksTitle` string, a `noTasks` boolean and a `List<TaskRow> tasks` to `AccountWithRelatedRecords.AccountRow`.
2. Add `tasksTitle`, `noTasks` and `tasks` (with item properties) to `uiWidgets/accountRelatedAccordion/schema.json`.
3. Add a headed section with `forEach: {!$account.tasks}` to the widget JSON. Keep every column at 10 children or fewer.
4. Extend `AccountHxlToolsTest`, then redeploy using the two phases in Step 8.

## References

- HXL Playground (components, tutorials, live editor): https://www.headlessexperiencelayer.com/playground/
- Salesforce Headless 360 / Headless Toolkit: https://www.salesforce.com/blog/headless-salesforce-development/