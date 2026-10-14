# Account Insights — Vue 3 example for `lightning-ui-embedding`

The same **Account Insights** app as [`embedded-account-react/`](../embedded-account-react) (React) and [`embedded-account-angular/`](../embedded-account-angular) (Angular), built with **Vue 3**. It is embedded in Salesforce with the `<lightning-ui-embedding>` base component.

It has its own Salesforce wrapper component, **Account Embedded Vue App** (`accountEmbeddedVueApp`), which loads `http://localhost:5181` by default.

| | React example | This Vue example |
|---|---|---|
| Folder | `embedded-account-react/` | `embedded-account-vue/` |
| Dev URL | `http://localhost:5180` | `http://localhost:5181` |
| CSP Trusted Site | `AccountEmbeddedReactLocalhost` | `AccountEmbeddedVueLocalhost` |
| Salesforce wrapper | `accountEmbeddedReactApp` | `accountEmbeddedVueApp` |
| Stack | Vite 8 + React 19.3 | Vite 8 + Vue 3.5 + `@vitejs/plugin-vue` 6 |

> A fourth example with **no framework** (plain JavaScript) is in [`embedded-account-external-app/`](../embedded-account-external-app), with the wrapper `accountEmbeddedExternalApp` on port 5183.
>
> A **Next.js** example is in [`embedded-account-nextjs/`](../embedded-account-nextjs), with the wrapper `accountEmbeddedNextjsApp` on port 5184.

---

## What it does

- **Salesforce → app:** shows the Account's Name, Rating, Type, Industry, Phone and Website, and updates live when the record changes.
- **App → Salesforce:** Hot / Warm / Cold buttons send a `ratingchange` event. The wrapper saves `Account.Rating` and shows a toast.
- **Locale:** receives the `localeInformation` event from the wrapper and sets `<html lang>`.
- **Theme:** copies Salesforce's CSS variables (`styles.variables`) onto the page.

### Interactive UI

| Feature | Behaviour |
|---|---|
| Rating colours | **Hot** = red, **Warm** = amber, **Cold** = blue. The current rating is filled in its colour, and the others are outlined in theirs |
| Hover / focus | Buttons lift and fill with a soft tint of their colour, with a visible keyboard focus ring |
| Saving state | The clicked button pulses and shows **Saving…**, and all buttons lock until the new rating comes back from Salesforce in `props` |
| Confirmation | "Rating saved as Hot" when Salesforce confirms. After 8 s without confirmation (e.g. the save failed), it shows a warning and unlocks the buttons |
| Live-change highlight | Fields that change in a live update flash yellow briefly |
| Rating pill + accent bar | The Rating field is a coloured pill, and a coloured bar at the top follows the rating |
| Website link | Opens in a new tab (allowed by `sandbox="allow-popups"` on the wrapper) |
| Connection dot | Green when connected to a record, grey otherwise |
| Reduced motion | Animations are turned off when the OS "reduce motion" setting is on |

Styling uses SLDS 2 global styling hooks (`--slds-g-*`), each with a fallback value, because inside the iframe the hooks exist only if Salesforce mirrors them into `styles.variables`.

---

## Project structure

```
embedded-account-vue/
├── index.html                       # mounts #app
├── package.json
├── vite.config.js                   # Vue plugin, port 5181 (strictPort)
└── src/
    ├── main.js                      # createApp(App).mount('#app')
    ├── App.vue                      # wires the composables to the components
    ├── style.css                    # SLDS 2 variables with fallbacks
    ├── composables/
    │   └── useEmbedding.js          # all SDK code lives here
    └── components/
        ├── AccountDetails.vue       # fields, rating pill, website link, change highlight
        └── RatingPicker.vue         # coloured Hot/Warm/Cold buttons, saving state (emits "select")
```

**Design rule:** only `composables/useEmbedding.js` imports the Salesforce SDK. The components are plain Vue (props in, events out), so they can be reused and tested without Salesforce.

---

## The composable — `src/composables/useEmbedding.js`

```js
import '@salesforce/platform-sdk/ui-embedding';
import { getViewSDK } from '@salesforce/platform-sdk/view';
```

| Export | What it gives you |
|---|---|
| `useUiState()` | Reactive `props`, `styles`, `embedded` and `updates`. Subscribes on mount and unsubscribes on unmount |
| `useHostEvent(type, handler)` | Listens for a custom event from the wrapper LWC (e.g. `localeInformation`). Removes the listener on unmount |
| `sendToHost(type, detail)` | Sends a custom event. It fires on `<lightning-ui-embedding>` as `type` |

**Why `getViewSDK()`:** every component that calls these composables gets the **same cached SDK instance**, so there is only ever one connection and one UI-state subscription. Salesforce allows at most one UI-state subscription per session. `createViewSDK()` would create a new instance on each call. In a component-based app like this, that is the main reason to use `getViewSDK()`.

Other details:
- `shallowRef` is used for `props` and `styles`, because each host snapshot is a full replacement, so deep reactivity isn't needed.
- An `active` flag stops a subscription from starting if the component unmounts before `getViewSDK()` resolves.
- Every SDK call uses `?.`, because outside Salesforce the SDK resolves to `{}`.

Usage in `App.vue`:

```js
const { props: account, styles, embedded, updates } = useUiState();

useHostEvent('localeInformation', (detail) => {
    document.documentElement.lang = detail?.locale ?? 'en';
});

function onSelectRating(rating) {
    sendToHost('ratingchange', { rating });   // → onratingchange in accountEmbeddedVueApp
}
```

---

## Run it step by step

### 1. Install and start

```bash
cd embedded-account-vue
npm install
npm run dev          # http://localhost:5181
```

Opening `http://localhost:5181` directly shows **"Not embedded — open this app from an Account record page."** with the buttons disabled. That is expected outside Salesforce.

### 2. Deploy the Salesforce side

Both are in the repo and already deployed:

| File | Purpose |
|---|---|
| `force-app/main/default/lwc/accountEmbeddedVueApp/` | Wrapper LWC around `<lightning-ui-embedding>` (default URL `http://localhost:5181`) |
| `force-app/main/default/cspTrustedSites/AccountEmbeddedVueLocalhost.cspTrustedSite-meta.xml` | Trusts `http://localhost:5181` for frames |

To deploy them again:

```bash
sf project deploy start \
  --source-dir force-app/main/default/lwc/accountEmbeddedVueApp \
  --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedVueLocalhost.cspTrustedSite-meta.xml \
  --wait 30
```

### 3. Put it on the Account page

1. Open an **Account** record → **⚙ → Edit Page**.
2. Drag **Account Embedded Vue App** onto the page.
3. (Optional) Change **Embedded Vue app URL** in the properties panel.
4. **Save** → **Activate**.

> You can place **Account Embedded React App** (5180), **Account Embedded Vue App** (5181), **Account Embedded Angular App** (5182) and **Account Embedded External App** (5183) on the same page. They all talk to the same record, which is a quick way to compare them. Clicking **Hot** in one updates the others too.

### What's different in `accountEmbeddedVueApp`

It follows the same contract as the original `accountEmbeddedApp` wrapper (since replaced by `accountEmbeddedReactApp`, which has the same code as this one), with two improvements over that original:

| Change | Why |
|---|---|
| `account` is a field set in the `@wire` handler, not a getter | Props are sent only when the record data actually changes, so re-renders (spinner hidden, etc.) no longer push duplicate snapshots, and the live-update counter counts only real changes |
| `ALLOWED_RATINGS = new Set(['Hot', 'Warm', 'Cold'])` | Events from the iframe are untrusted input, so only valid picklist values are saved |

### 4. Test

| Action | Expected |
|---|---|
| Load the page | A **Vue JS** badge, a green dot and "Connected to Salesforce", then the Account fields |
| Click **Warm** | The button pulses "Saving…", then turns amber-filled, the accent bar turns amber, and "Rating saved as Warm" appears |
| Edit the Account and save | The fields update by themselves, and the live-update counter goes up |
| Toast | Salesforce also shows "Account updated — Rating set to Warm" |
| Stop `npm run dev` and reload | The wrapper shows a red error banner (e.g. `bootstrap/HEARTBEAT_TIMEOUT`) |

---

## Production

1. `npm run build` → upload `dist/` to an **HTTPS** host.
2. Add a CSP Trusted Site for that origin with **frame-src**, and deactivate the localhost one.
3. Set **Embedded Vue app URL** in App Builder to the HTTPS origin.

---

## Notes

- The port **5181** must match in `vite.config.js`, the CSP Trusted Site, and the App Builder property. `strictPort: true` makes Vite fail rather than silently switch to a port Salesforce doesn't trust.
- `npm audit` warnings come from the SDK's own `@conduit-client/*` dependencies.
- See [`LIGHTNING_UI_EMBEDDING_IMPLEMENTATION.md`](../LIGHTNING_UI_EMBEDDING_IMPLEMENTATION.md) for the full implementation log, and how the LWC ↔ app communication works.
