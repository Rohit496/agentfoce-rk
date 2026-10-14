# Lead Functionality

This document describes the **Lead** feature added to the `reactinternal` UI bundle. Lead
records are fetched through the Salesforce **GraphQL UI API** (via `@salesforce/platform-sdk`)
and rendered in React. The feature is a direct mirror of the existing **Account** module — same
architecture, folder structure, shared components, styling, data-fetching approach, and
loading/empty/error handling. **No Apex and no LWC are used.**

---

## 1. Files Created / Modified

### Created

| File | Purpose |
| --- | --- |
| `src/api/lead/query/searchLeads.graphql` | Paginated, filterable, sortable Lead list query. |
| `src/api/lead/query/getLeadDetail.graphql` | Single-record Lead detail query (by `Id`). |
| `src/api/lead/query/distinctLeadIndustries.graphql` | Aggregate `groupBy` query for the **Industry** picklist filter. |
| `src/api/lead/query/distinctLeadStatuses.graphql` | Aggregate `groupBy` query for the **Status** picklist filter. |
| `src/api/lead/mutation/updateLead.graphql` | **`uiapi.LeadUpdate`** GraphQL mutation document used to update a Lead record. |
| `src/api/lead/query/getLeadFieldInfo.graphql` | **`uiapi.objectInfos`** query for Lead field labels/updateability + the object's `defaultRecordTypeId` (step 1 of picklist loading). |
| `src/api/lead/query/getLeadPicklistValues.graphql` | **`uiapi.objectInfos(objectInfoInputs:…)`** query that returns picklist values for the resolved record type (step 2). |
| `src/api/lead/leadSearchService.ts` | Thin, typed service layer wrapping the shared object-search helpers. Also exposes `updateLead(...)` and `fetchLeadFieldInfo(...)` (see §8). |
| `src/pages/LeadSearch.tsx` | Lead list / search page (filters, sort, pagination, states). |
| `src/pages/LeadObjectDetailPage.tsx` | Lead detail page (sectioned record view, states). |
| `src/pages/EditLeadDialog.tsx` | **Edit Lead** dialog — mirrors the standard Salesforce Lead edit layout (two columns, picklist dropdowns, address block, custom fields, read-only Owner/Created/Modified). Validates input, calls `updateLead`, toasts, and refreshes the detail view on success (see §8). |
| `src/api/lead/leadUpdateService.test.ts` | Vitest unit tests for the `updateLead` service function. |
| `src/pages/EditLeadDialog.test.tsx` | Vitest + Testing Library component tests for the edit dialog. |
| `docs/LEAD_FEATURE.md` | This document. |

### Modified

| File | Change |
| --- | --- |
| `src/routes.tsx` | Registered `/leads` and `/leads/:recordId` routes; added `Leads` to the nav menu via `handle.showInNavigation`. |
| `src/api/lead/leadSearchService.ts` | Added `updateLead(...)` and `fetchLeadFieldInfo(...)` plus the `LeadUpdateFields` / `UpdatedLeadRecord` / `LeadFieldInfo` / `LeadFieldInfoMap` types. |
| `src/api/lead/query/getLeadDetail.graphql` | Added `MobilePhone`, `Fax`, `ProductInterest__c`, `SICCode__c`, `NumberofLocations__c`, `CurrentGenerators__c`, `Primary__c` so the edit form can pre-fill them. |
| `src/pages/LeadObjectDetailPage.tsx` | Added an **Edit** button (renders `EditLeadDialog`) in the detail header and a `reload` callback so the view refreshes after a successful update. |
| `src/hooks/useAsyncData.ts` | Added a `reload()` function to the result so callers can re-run the fetcher after a mutation. |
| `src/appLayout.tsx` | Mounted the `<Toaster />` so success/error toasts render app-wide; **removed the `AgentforceConversationClient`** (the floating "Start a chat" widget) — see §9. |
| `src/api/graphql-operations-types.ts` | Added the generated operation types (`SearchLeadsQuery`, `GetLeadDetailQuery`, `DistinctLeadIndustriesQuery`, `DistinctLeadStatusesQuery`, `UpdateLeadMutation`, `GetLeadFieldInfoQuery`, plus their `*Variables`) and the input types `Lead_OrderBy`, `LeadUpdateInput`, and `LeadUpdateRepresentation`. See the note in §7 about codegen. |

> The existing Account module was **not** functionally changed. The only edits to shared files
> (`routes.tsx`, `graphql-operations-types.ts`) are purely additive.

---

## 2. Implementation Steps

The Account module establishes a 4-layer pattern. Lead follows it exactly:

1. **GraphQL documents** (`src/api/lead/query/*.graphql`) — declare the queries. They mirror the
   Account documents, using `@optional` on every field so a missing/inaccessible field degrades
   gracefully instead of failing the whole query.
2. **Service layer** (`leadSearchService.ts`) — imports each `.graphql` file `?raw` and delegates
   to the **shared** `searchObjects` / `fetchDistinctValues` helpers in
   `features/object-search/api/objectSearchService.ts`. It exposes `searchLeads`,
   `fetchDistinctIndustries`, and `fetchDistinctStatuses`, plus the derived `LeadSearchResult` /
   `LeadSearchOptions` types.
3. **Pages** (`LeadSearch.tsx`, `LeadObjectDetailPage.tsx`) — consume the service through the
   shared `useAsyncData` hook and render with the shared UI/filter components.
4. **Routing & navigation** (`routes.tsx`) — wire the pages to URLs and surface a `Leads` nav item.

After authoring, the feature was verified with `tsc -b` (type-check), `eslint` (lint), and
`vite build` (production bundle) — all green.

---

## 3. How the GraphQL Query Fetches Lead Data

### List query — `searchLeads.graphql`

```graphql
query SearchLeads($first: Int, $after: String, $where: Lead_Filter, $orderBy: Lead_OrderBy) {
  uiapi {
    query {
      Lead(first: $first, after: $after, where: $where, orderBy: $orderBy) {
        edges { node { Id  Name @optional { value displayValue }  Company @optional { ... } ... } }
        pageInfo { hasNextPage hasPreviousPage endCursor startCursor }
        totalCount
      }
    }
  }
}
```

- Uses the standard UI API connection shape `uiapi.query.Lead` → `edges[].node`.
- **Pagination** is cursor-based: `$first` (page size) + `$after` (cursor), with `pageInfo` and
  `totalCount` returned for the controls.
- **Filtering** is driven by `$where: Lead_Filter` and **sorting** by `$orderBy: Lead_OrderBy`,
  both built generically from the page's filter/sort config (see §4).
- Each scalar field is wrapped as `{ value, displayValue }` and marked `@optional` so the query
  tolerates field-level permission/visibility differences.

### Detail query — `getLeadDetail.graphql`

Filters by `where: { Id: { eq: $id } }` and returns the first edge's node with the full field set
needed for the detail layout (identity, status/source, address, and system fields).

### Distinct-value queries — `distinctLead{Industries,Statuses}.graphql`

Use the UI API **aggregate** API with `groupBy` to return the distinct picklist values, which
populate the Industry (single-select) and Status (multi-select) filters.

### Polymorphic `Owner` (important difference from Account)

`Account.Owner` is always a `User`, so Account selects `Owner { Name { value } }` directly.
`Lead.Owner` is the **union** `Lead_Owner = Group | User` (a Lead can be owned by a User **or** a
Queue/Group). Selecting `Name` directly on a union is invalid GraphQL and fails the entire query,
so the Lead queries use inline fragments on each concrete type:

```graphql
Owner @optional {
  ... on User  { Name @optional { value displayValue } }
  ... on Group { Name @optional { value displayValue } }
}
```

Both members expose `Name`, so the generated union type lets the UI read `node.Owner?.Name`
uniformly. This is the one place the Lead queries deviate from a literal copy of Account.

### Execution path

The service passes the raw query string and variables to the shared helpers, which call
`createDataSDK()` → `data.graphql.query(...)`. GraphQL errors are surfaced as thrown `Error`s and
handled by the UI (see §4 error handling). This is the same `@salesforce/platform-sdk` data path
the Account module uses — **no Apex, no LWC.**

---

## 4. How the Data Is Processed and Displayed

### Search page (`LeadSearch.tsx`)

- `useObjectSearchParams(FILTER_CONFIGS, LEAD_SORT_CONFIGS, PAGINATION_CONFIG)` reads/writes
  filters, sort, and pagination to the URL query string and produces the `where` / `orderBy`
  objects.
- `useAsyncData(() => searchLeads({ where, orderBy, first, after }), [deps])` runs the fetch and
  re-runs whenever the query inputs change.
- Edges are reduced to a clean `LeadNode[]` (null edges/nodes filtered out) with `useMemo`.
- `fieldValue(...)` extracts the display string from each `{ value, displayValue }` field.
- Each result links to `/leads/:Id`. The list shows **Name** + **Company · Status** with
  **Phone** / **Owner** on the right — the same two-line row layout as Account.
- **States rendered:**
  - **Loading** → skeleton rows (`<Skeleton />`), count matches page size.
  - **Error** → `0 leads found` + destructive `<Alert>`.
  - **Empty** → centered `SearchX` empty-state ("No leads found").
  - **Success** → results list + a count line + pagination.

### Detail page (`LeadObjectDetailPage.tsx`)

- Reads `:recordId` from the route, fetches via `fetchLeadDetail`, and renders collapsible
  sections (`Additional Information`, `Address Information`, `System Information`).
- **Shows the full field set** — the same fields the edit form exposes: identity (Salutation,
  Name, Company, Title), contact (Phone, Mobile, Fax, Email, Website), status/source/rating,
  Annual Revenue, No. of Employees, the custom fields (Product Interest, Primary, SIC Code, Number
  of Locations, Current Generator(s)), the broken-out **Address** (Country, State/Province, City,
  Zip, Street), Description, and read-only Owner / Created By / Last Modified By.
- `formatDateTimeField(...)` formats the Created/Last-Modified timestamps from each field's **raw
  ISO `value`** (not the localized `displayValue`, which `new Date(...)` can mis-parse — a `DD/MM`
  string yielded *"Invalid Date"* and an ambiguous one showed the wrong month).
- Phone/Mobile render as `tel:` links and Email as a `mailto:` link.
- **States:** loading skeleton, destructive error alert (with Back/Retry), and a not-found card.

---

## 5. Reusable Components & Utilities Used

All of the following are **existing shared modules reused as-is** (nothing was duplicated):

- **Data helpers:** `features/object-search/api/objectSearchService.ts`
  (`searchObjects`, `fetchDistinctValues`, `ObjectSearchOptions`, `PicklistOption`).
- **Hook:** `hooks/useAsyncData` (loading/error/data with cancellation).
- **Search params hook:** `features/object-search/hooks/useObjectSearchParams`.
- **Filter components:** `FilterProvider` / `FilterResetButton`, `SearchFilter`, `TextFilter`,
  `SelectFilter`, `MultiSelectFilter`, `NumericRangeFilter`, `DateFilter`, `DateRangeFilter`,
  `ActiveFilters`, `SortControl`.
- **Navigation:** `ObjectBreadcrumb`, `PaginationControls`.
- **UI primitives:** `Alert`, `Card`, `Button`, `Collapsible`, `Skeleton`, `Separator`.
- **Field utilities:** `fieldValue`, `getAddressFieldLines`, `formatDateTimeField`.
- **Icons:** `lucide-react` (`AlertCircle`, `ChevronDown`, `ChevronRight`, `SearchX`,
  `FileQuestion`).

The only Lead-specific additions are the four `.graphql` documents, the `leadSearchService.ts`
wrapper, and the two page components.

---

## 6. How to Run and Test

All commands run from the bundle directory:
`force-app/main/default/uiBundles/reactinternal`.

```bash
# Install deps (first time)
npm install

# (Optional) refresh the GraphQL schema + regenerate types from a connected org
npm run graphql:schema      # writes schema.graphql at the repo root
# codegen then runs automatically on dev/build (see vite.config.ts)

# Run the dev server
npm run dev
# open the app, click "Leads" in the nav, or navigate to /leads

# Type-check, lint, build
npx tsc -b
npm run lint
npm run build               # tsc -b && vite build

# Unit/component tests (Vitest) — runs only files under src/
npm run test

# End-to-end tests (Playwright) — separate runner, serves built dist/
npm run build:e2e           # build + rewrite asset paths for the static server
npx playwright test         # uses playwright.config.ts (testDir: ./e2e)
```

> **Vitest vs. Playwright — two separate runners.** `npm run test` (Vitest) is scoped to
> `src/**` via the `include`/`exclude` settings in `vitest.config.ts`, and the `e2e/` suite is
> explicitly excluded. Without that exclusion Vitest tries to execute `e2e/app.spec.ts` and
> crashes with *"Playwright Test did not expect test.describe() to be called here"*, because
> Playwright specs must run under `@playwright/test`, not Vitest. Run the e2e suite with
> `npx playwright test`. (Note: `vitest.config.ts` is the config Vitest actually uses; the
> `test` block inside `vite.config.ts` is not picked up.)

### Manual test checklist

1. **List** – Go to `/leads`. Confirm rows render with Name, Company · Status, Phone, Owner.
2. **Filters** – Try the Search box, Name/Company text filters, Industry (single), Status (multi),
   Annual Revenue range, and the date filters. Confirm the list and the URL update.
3. **Sort** – Switch between Name / Company / Annual Revenue / Created Date.
4. **Pagination** – Page forward/back and change page size (7/14/28/42).
5. **Detail** – Click a row → `/leads/:id`; verify all sections and the `tel:` / `mailto:` links.
6. **Edit** – Click **Edit**, change a field, **Save changes**; confirm the success toast and that
   the detail view refreshes with the new value. Clear **Last Name** or **Company** to confirm the
   required-field validation blocks submit.
7. **States** – Verify loading skeletons, the empty state (over-constrain the filters), the error
   alert (e.g. disconnect), and the not-found card (visit `/leads/000000000000000000`).

> **Unit/component tests.** The Lead **update** feature ships Vitest tests:
> `src/api/lead/leadUpdateService.test.ts` (service) and `src/pages/EditLeadDialog.test.tsx`
> (dialog), alongside the existing `src/lib/utils.test.ts`. Run them with `npm run test`. The e2e
> spec (`e2e/app.spec.ts`) is a Playwright test run via `npx playwright test`, not Vitest.

---

## 7. Assumptions, Limitations & Notes

- **Field set / picklist filters.** Lead has a **single** address (`Street/City/State/PostalCode/
  Country`), unlike Account's Billing + Shipping split, so the detail page shows one Address block.
  The two distinct-value filters chosen for Lead are **Industry** (single-select) and **Status**
  (multi-select), paralleling Account's Industry + Type. `Company`, `Email`, `Status`, `LeadSource`,
  and `Rating` are Lead-specific fields surfaced in the list/detail views.
- **Generated types (`graphql-operations-types.ts`).** This file is produced by `graphql-codegen`
  from `schema.graphql`. The schema was fetched from the connected org (`npm run graphql:schema`)
  and `npm run graphql:codegen` was run, so the Lead operation types (`SearchLeadsQuery`,
  `GetLeadDetailQuery`, the two distinct queries, their `*Variables`) and `Lead_OrderBy` are now
  genuinely generated — and every Lead document was validated against the live schema in the
  process. `schema.graphql` is a large (~11 MB) local artifact at the repo root, regenerable any
  time with `npm run graphql:schema`; it was not present originally (the Vite plugin simply skips
  codegen when it is absent). Consider adding it to `.gitignore` if you don't want it committed.
- **Search fields.** The free-text Search filter targets `Name`, `Company`, and `Email`
  (`searchFields` in `FILTER_CONFIGS`); adjust this list to change the OR-search behavior.
- **No Apex / No LWC.** All data access goes through the GraphQL UI API via
  `@salesforce/platform-sdk`, consistent with the Account module.
- **Field-level security.** Every queried field uses `@optional`, so fields the running user can't
  see are simply omitted rather than erroring the page.
- **Page size default** is 7 (matching Account) with options 7/14/28/42.

---

## 8. Updating a Lead (GraphQL Mutation)

Users can update a Lead directly from the detail page (`/leads/:recordId`). This follows the
[React Data SDK — GraphQL mutation guide](https://developer.salesforce.com/docs/platform/einstein-for-devs/guide/reactdev-data-sdk-graphql-mutation.html):
mutations go through `data.graphql.mutate(...)`, are request/response only (no cache), and the
caller must **refresh related queries** to reflect the change in the UI.

### Mutation document — `src/api/lead/mutation/updateLead.graphql`

```graphql
mutation UpdateLead($input: LeadUpdateInput!) {
  uiapi {
    LeadUpdate(input: $input) {
      success
      Record {
        Id
        FirstName @optional { value displayValue }
        # …the editable fields…
      }
    }
  }
}
```

- The mutation lives under `uiapi.LeadUpdate` (the `UIAPIMutations` type), mirroring how queries
  live under `uiapi.query`.
- `$input: LeadUpdateInput!` is `{ Id: IdOrRef!, Lead: LeadUpdateRepresentation! }`. Only the fields
  present in `Lead` are changed; omitted fields are left untouched.
- Per the guide, the `Id` is included in the returned `Record` so the result can be tracked, and
  `success` is selected to confirm the write.

### Service function — `updateLead(...)` in `leadSearchService.ts`

```ts
export async function updateLead(
  recordId: string,
  fields: LeadUpdateFields,
): Promise<UpdatedLeadRecord> {
  const data = await createDataSDK();
  const result = await data.graphql!.mutate<UpdateLeadMutation, UpdateLeadMutationVariables>({
    mutation: UPDATE_LEAD_MUTATION,
    variables: { input: { Id: recordId, Lead: fields } },
  });

  if (result.errors?.length) {
    throw new Error(result.errors.map((e) => e.message).join("; "));
  }
  const payload = result.data?.uiapi?.LeadUpdate;
  if (!payload?.success || !payload.Record) {
    throw new Error("Lead update did not complete successfully");
  }
  return payload.Record;
}
```

GraphQL errors are surfaced as thrown `Error`s (same convention as the query helpers), and a
non-`success` payload is treated as a failure. `LeadUpdateFields` is the generated
`LeadUpdateRepresentation` input type.

### Picklist values — `fetchLeadFieldInfo(...)` + `getLeadFieldInfo.graphql`

So the dropdowns show the org's *valid* picklist values (not free text), the dialog reads field
metadata from the UI API — the same source the standard Salesforce UI uses:

```graphql
query GetLeadFieldInfo {
  uiapi {
    objectInfos(apiNames: ["Lead"]) {
      ApiName
      defaultRecordTypeId
      fields {
        ApiName
        label
        updateable
        ... on PicklistField {
          picklistValuesByRecordTypeIDs {
            recordTypeID
            picklistValues { value label }
          }
        }
      }
    }
  }
}
```

`fetchLeadFieldInfo()` does this in **two queries** so nothing is hardcoded, flattening the result
into a `Record<fieldApiName, { label, updateable, options }>`.

**Prefetched for instant open.** The metadata is fetched **in the background by the detail page**
(a second, non-blocking `useAsyncData(fetchLeadFieldInfo, [])`) while the user reads the record, and
passed into `EditLeadDialog` as the `fieldInfo` prop. So clicking **Edit** opens the modal
*immediately* with dropdowns already populated — no spinner and no wait on the two `objectInfos`
round-trips (previously ~1–2s). If the prefetch hasn't finished (or fails), the form still opens at
once with picklist fields as text inputs, and they upgrade to dropdowns as soon as `fieldInfo`
arrives.

1. **`getLeadFieldInfo.graphql`** — `objectInfos(apiNames: ["Lead"])` returns each field's label /
   updateability and the object's **`defaultRecordTypeId`**.
2. **`getLeadPicklistValues.graphql`** — `objectInfos(objectInfoInputs: [{ apiName: "Lead",
   recordTypeIDs: [<defaultRecordTypeId from step 1>] }])` returns `picklistValuesByRecordTypeIDs`,
   which are merged into the map.

> **Gotcha — `objectInfoInputs` is required for picklist values.** Selecting
> `picklistValuesByRecordTypeIDs` while calling `objectInfos(apiNames: ["Lead"])` fails at runtime
> with *"PicklistField fragment requires a recordTypeId argument."* The resolver needs a record-type
> context, supplied via `objectInfos(objectInfoInputs: [{ apiName: "Lead", recordTypeIDs: [...] }])`.
> The record type id is **sourced dynamically** from the object's `defaultRecordTypeId` (step 1) —
> nothing is hardcoded. If no record type resolves, step 2 is skipped and those fields fall back to
> free-text inputs (with a small notice); the form still works.

### UI — `EditLeadDialog.tsx`

- Rendered as an **Edit** button beside the title in the detail header.
- Mirrors the **standard Salesforce Lead edit layout**: a two-column dialog with the full field
  set — name group (Salutation/First/Last), Company, Title, Phone/Mobile/Fax, Email, Website,
  Lead Source, Industry, Lead Status, Rating, Annual Revenue, No. of Employees, the custom fields
  (Product Interest, SIC Code, Number of Locations, Current Generator(s), Primary), an **Address**
  block, and **Description** — plus read-only **Lead Owner / Created By / Last Modified By**.
  The only sub-section heading is **Address**; `Description` is a plain full-width field (it has no
  separate section heading — its label is the only "Description" shown).
- **Field types are data-driven:** any field with picklist values from `fetchLeadFieldInfo` renders
  as a **dropdown** (`Select`); the rest render as text/number/textarea inputs. If metadata can't be
  loaded, picklist fields gracefully fall back to free-text inputs (the form still works).
- Pre-fill is type-aware: text/picklist fields use the API **`value`** so a picklist value matches
  an option; numeric fields also use the **raw `value`** — **not** the formatted `displayValue`
  (e.g. `"$1,200,000"`), which a number `<input>` rejects and would render blank. *(This was a bug
  in the first cut: numeric fields appeared empty and silently never updated.)*
- **Client validation:** required fields are `Last Name`, `Company`, and `Lead Status`. Empty
  inputs are sent as `undefined` (omitted) so unset fields aren't accidentally cleared; numeric
  fields are parsed to numbers.
- On submit it calls `updateLead`, shows a success/error toast (`sonner`), closes on success, and
  calls `onUpdated`.

### Refresh-after-mutation (and the stale-cache gotcha)

Because mutations don't touch the query cache, `LeadObjectDetailPage` passes the `reload()`
function from `useAsyncData` as the dialog's `onUpdated` callback. After a successful update the
detail query re-runs and the page shows the new values.

> **Gotcha — the re-query must bypass the cache.** The GraphQL `query()` caches by default
> (300s TTL). Since the mutation doesn't write the cache, a plain `reload()` re-issued the *same*
> query and got a **cache hit on the stale record**, so the UI didn't reflect the edit until the TTL
> expired. The detail fetch therefore uses `cacheControl: "no-cache"`, which always fetches fresh
> from the network — so the post-update reload shows the new values immediately. Verified in a real
> browser against a connected org: editing a Lead's field and saving updates the detail view at
> once, and the change persists on full reload.

### Tests

- `src/api/lead/leadUpdateService.test.ts` — mocks `@salesforce/platform-sdk` and asserts: the
  `updateLead` mutation variables (`{ input: { Id, Lead } }`), success / GraphQL-errors /
  non-`success` paths; and `fetchLeadFieldInfo` mapping (labels, updateability, default-record-type
  picklist options, and the errors path).
- `src/pages/EditLeadDialog.test.tsx` — Testing Library tests for type-aware pre-fill (incl. the
  numeric raw-value fix), the read-only owner, a successful submit (correct args with parsed
  numbers + `onUpdated` + success toast), required-field validation, the failure toast, and that
  picklist fields render as dropdowns when the org returns values.

Run them with `npm run test` (Vitest). **Note:** the form's dropdowns are populated from a live org
(`fetchLeadFieldInfo`), so to see them filled and to persist a real update you must run the app
against a connected Salesforce org (`npm run dev`); the static/preview build has no data backend.

---

## 9. Agentforce "Start a chat" widget (hidden)

The floating **"Start a chat"** button in the bottom-right corner was the
`AgentforceConversationClient` component (`src/components/AgentforceConversationClient.tsx`), which
embeds Salesforce's Agentforce messaging client. It was mounted globally in `src/appLayout.tsx`, so
it appeared on every page. It was configured with a **placeholder** `agentId`
(`"<USER_AGENT_ID_18_CHAR_0Xx...>"`), so it couldn't connect and logged a LightningOut iframe error
in the console.

**It has been hidden** by removing both the import and the usage from `src/appLayout.tsx`:

```tsx
// Removed from src/appLayout.tsx:
import { AgentforceConversationClient } from "./components/AgentforceConversationClient";
// ...
<AgentforceConversationClient agentId="<USER_AGENT_ID_18_CHAR_0Xx...>" />
```

The `AgentforceConversationClient` component file itself is left in place (unused) — only its mount
was removed.

### To show it again

Re-add the import and render it inside the layout (next to `<Toaster />`), using a **real
18-character Agent ID** instead of the placeholder:

```tsx
import { AgentforceConversationClient } from "./components/AgentforceConversationClient";

// inside AppLayout's returned markup:
<AgentforceConversationClient agentId="0XxXXXXXXXXXXXXXXX" />
```

Without a valid `agentId` the widget renders the button but fails to initialize (the iframe error),
so only re-enable it once a real Agent is available.
