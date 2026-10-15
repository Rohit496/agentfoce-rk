# externalComponent — third-party web component with `lwc:external` (Winter '27 GA)

Recreates the `lwc:external` example from the
[Salesforce Developer's Guide to the Winter '27 Release](https://developer.salesforce.com/blogs/2026/10/developers-guide-to-the-winter-27-release).

A plain, framework-free custom element, `<w27-rating-stars>`, is uploaded as an IIFE static
resource. The LWC loads it with `loadScript` and renders it natively with `lwc:external`:
no iframe and no rewrite.

## Files

| File                                                      | Purpose                                                                |
| --------------------------------------------------------- | ---------------------------------------------------------------------- |
| `staticresources/w27RatingStars.js`                       | The third-party element (IIFE). Knows nothing about LWC.               |
| `lwc/externalComponent/*`                                 | Host LWC: loads the resource, renders the element, mirrors its state.  |
| `flexipages/Third_Party_Web_Component.flexipage-meta.xml` | App page that hosts the demo.                                          |
| `tabs/Third_Party_Web_Component.tab-meta.xml`             | Tab for the app page (`/lightning/n/Third_Party_Web_Component`).       |
| `permissionsets/Third_Party_Web_Component_Demo...`        | Makes the tab visible. Assign it, then open the tab in a standard app. |
| `objects/Star_Rating__c/*`                                | Stores one record per star click, with a server timestamp.             |
| `tabs/Star_Rating__c.tab-meta.xml`                        | "Star Ratings" tab; the "All Star Ratings" list view shows every save. |

## Saving ratings

Each record has **one** `Star_Rating__c`. The first star click on a record creates it, and every
later click (by any user) updates that same record, through GraphQL mutations
(`Star_Rating__cCreate` / `Star_Rating__cUpdate` via `executeMutation` from `lightning/graphql`).
They run as the user, so object and field permissions apply. The permission set grants create,
read and edit, and the object's sharing is Public Read/Write so any user can update a record's
rating.

- `Related_Record_Id__c` is **unique**, so the database rejects a second rating for the same
  record. If two clicks race, or another tab or user rated first, the create fails with a
  duplicate error that names the existing rating ("... on record with id: a0A..."). The
  component takes that Id from the error and updates the existing rating instead ("Rating
  updated"). If the error has no Id, it reloads the rating via the wire's `refresh()` first.
- Tested in the org with two tabs on an unrated Account: tab B rates first, then tab A (still
  showing "unrated") rates. Tab A updates the same record, with no error.
- After a deploy, users must hard-reload (Cmd+Shift+R) or clear the browser cache. Lightning
  caches component code, and an old cached build that always created records would now show
  "Not saved: duplicate value found".
- On app and home pages (no record), the first click creates a rating with a blank
  `Related_Record_Id__c`, and later clicks on that page update it.

| Field                    | Value                                                                                                              |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| Name                     | Auto number `SR-000000`                                                                                            |
| `Rating__c`              | Stars clicked. The `Rating_In_Range` validation rule keeps it between 1 and `Max_Rating__c`.                       |
| `Max_Rating__c`          | Stars shown (5)                                                                                                    |
| `Rated_At__c`            | Label "First Rated At". Defaults to `NOW()` when the rating is created; not changed by later updates               |
| Last Modified Date       | When it was last rated (server time). Shown in the list view and the toast                                         |
| `Related_Record_Id__c`   | The record page it was rated on, such as an Account; unique; blank on app and home pages                           |
| `Related_Object__c`      | That record's object API name, e.g. `Account`                                                                      |
| `Related_Record_Name__c` | That record's Name when the rating was given; blank for objects without a Name field. Not shown in the list        |
| `Related_Record__c`      | Formula: a clickable link to the record, for any object. Shows only the object name (e.g. "Account"), never the Id |
| Last Modified By         | Who rated last (Created By is who rated first)                                                                     |

- The record Id comes from `@api recordId`. If that's unset (seen on a full page load), it comes
  from the page reference (`CurrentPageReference`, `standard__recordPage`).
- The object and name come from `getRecord` with `optionalFields: ['<Object>.Name']`. Objects
  without a Name field (such as Case) simply save no name.
- The "All Star Ratings" list view shows the clickable **Related Record** column. The link text
  is only the object name, and the record Id is used behind the scenes:
  `HYPERLINK("/" & Related_Record_Id__c, <object name>, "_blank")` opens the record page in a
  new browser tab, so the Star Ratings list stays open.
    - The object name comes from `Related_Object__c`, made readable (`Student__c` → "Student").
    - Ratings saved before `Related_Object__c` existed get the name from the Id prefix: `001`
      Account, `003` Contact, `006` Opportunity, `500` Case, `00Q` Lead; anything else shows
      "Record".
- Feedback uses toasts from `lightning/toast`: **success** ("Rating saved" for the first rating,
  "Rating updated" after that, with the rating, record number and time in the
  user's locale and time zone), **warning** (saved, but Salesforce also returned an error),
  **error** (save failed, or the star library didn't load). The saved record number and time
  appear only in the toast, not on the card. Under the stars the card shows just "Saving
  rating…", "Not saved: <reason>", or "Click a star to save a rating."
- Fast clicks each send a save for the same record. Only the newest response updates that line.

## Showing the saved rating

On a record page, the component loads that record's `Star_Rating__c` with a GraphQL wire
(`graphql` from `lightning/graphql`): filter on `Related_Record_Id__c`, sort by
`LastModifiedDate` then `Name` descending, `first: 1`. The stars show its rating, and its Id is
kept so the next click updates it. If the
record has no rating, the stars start empty (0). On pages without a record, the query doesn't run.

After each save the component calls the wire's `refresh()`, so the loaded rating stays current.
If the query fails, a **warning** toast says the saved rating couldn't be loaded.

## Star colours

A template expression sets a class on `<w27-rating-stars>`, and each class sets
`--w27-star-color`, which reaches the third-party shadow root:

| Rating      | Class           | Colour (SLDS 2 hook)                       |
| ----------- | --------------- | ------------------------------------------ |
| 1–2 (and 0) | `rating_low`    | red, `--slds-g-color-palette-red-50`       |
| 3           | `rating_medium` | yellow, `--slds-g-color-palette-yellow-70` |
| 4–5         | `rating_high`   | green, `--slds-g-color-palette-green-60`   |

## `<w27-rating-stars>` contract

- **Attributes:** `value` (current rating), `max` (star count, default 5), `label` (accessible name).
- **Event:** `rate`, a `CustomEvent` with `detail: { value }`.
- **Theming:** CSS custom properties `--w27-star-color`, `--w27-star-empty-color`,
  `--w27-star-focus-color`, `--w27-star-size`. The host LWC maps them to SLDS 2 global hooks
  (filled-star colour depends on the rating; see "Star colours").
- **Accessibility:** `radiogroup` of `radio` buttons, roving tabindex, arrow keys / Home / End.

## How the host LWC uses it

<!-- prettier-ignore -->
```html
<template lwc:if={libraryLoaded}>
    <w27-rating-stars
        lwc:external
        value={rating}
        max={max}
        lwc:spread={starProps}
        onrate={handleRate}
    ></w27-rating-stars>
</template>
```

```js
async connectedCallback() {
    await loadScript(this, RATING_STARS);
    this.libraryLoaded = true;
}
handleRate(event) {
    this.rating = event.detail.value;
}
```

It also shows a spinner while loading and an error message if `loadScript` fails.

## Rules from the release

- Third-party web components require **Lightning Web Security**.
- Load libraries as **IIFE or UMD**, because `loadScript` doesn't support ES modules.
- On an `lwc:external` element, LWC passes values as **attributes** by default. It sets
  **properties** only when the custom element defines them.

## Differences from the article

- `starProps` is `{ title: 'Product rating' }`, not `{ 'data-qa': 'product-rating' }`.
  `lwc:spread` sets properties, so a `data-*` key never becomes a DOM attribute and LWC logs an
  "Unknown public property" warning.
- The 🔥 is an inline template expression (GA, API 66.0+): `{rating >= 4 ? ' 🔥' : ''}`. No JS
  getter. The leading space is inside the string because the template compiler drops the
  line-break whitespace before an expression on its own line.

## Test and deploy

```bash
npx sfdx-lwc-jest -- force-app/main/default/lwc/externalComponent
sf project deploy start -m StaticResource:w27RatingStars -m LightningComponentBundle:externalComponent \
  -m FlexiPage:Third_Party_Web_Component -m CustomTab:Third_Party_Web_Component \
  -d force-app/main/default/objects/Star_Rating__c -m CustomTab:Star_Rating__c \
  -m PermissionSet:Third_Party_Web_Component_Demo
```

The Jest test loads the real IIFE, so it checks the actual custom element, not a stub. It mocks
`lightning/graphql` (sfdx-lwc-jest has no stub for it), spies on `Toast.show`, and emits
`CurrentPageReference` for the record-Id fallback.

After a deploy, clear the browser cache before checking it in the org. Lightning caches component
definitions, and an old build can keep running.

The stock `sfdx-lwc-jest` transformer rejects complex template expressions (LWC1060). The
project's `jest.config.js` therefore uses [`jest/lwcTransformer.js`](../../../../../jest/lwcTransformer.js),
which is the same transformer with `experimentalComplexExpressions: true`. Every LWC in the project
can use template expressions and still be unit tested.
