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

## `<w27-rating-stars>` contract

- **Attributes:** `value` (current rating), `max` (star count, default 5), `label` (accessible name).
- **Event:** `rate`, a `CustomEvent` with `detail: { value }`.
- **Theming:** CSS custom properties `--w27-star-color`, `--w27-star-empty-color`,
  `--w27-star-focus-color`, `--w27-star-size`. The host LWC maps them to SLDS 2 global hooks
  (`--slds-g-color-palette-orange-70` for filled stars, to match the article's orange).
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
  -m FlexiPage:Third_Party_Web_Component -m CustomTab:Third_Party_Web_Component
```

The Jest test loads the real IIFE, so it checks the actual custom element, not a stub.

The stock `sfdx-lwc-jest` transformer rejects complex template expressions (LWC1060). The
project's `jest.config.js` therefore uses [`jest/lwcTransformer.js`](../../../../../jest/lwcTransformer.js),
which is the same transformer with `experimentalComplexExpressions: true`. Every LWC in the project
can use template expressions and still be unit tested.
