# Account Insights — plain JavaScript example for `lightning-ui-embedding`

An external web app written in **plain JavaScript, with no framework**, embedded on the Salesforce Account record page with the `<lightning-ui-embedding>` base component. It has the same UI and behaviour as the [React](../embedded-account-react), [Vue](../embedded-account-vue) and [Angular](../embedded-account-angular) examples.

Use this one to see the embedding itself with nothing else in the way: static HTML, one stylesheet, and two small JavaScript modules.

Its Salesforce wrapper component is **Account Embedded External App** (`accountEmbeddedExternalApp`), which loads `http://localhost:5183` by default.

| | External App (this one) | React | Vue | Angular |
|---|---|---|---|---|
| Folder | `embedded-account-external-app/` | `embedded-account-react/` | `embedded-account-vue/` | `embedded-account-angular/` |
| Dev URL | `http://localhost:5183` | `http://localhost:5180` | `http://localhost:5181` | `http://localhost:5182` |
| CSP Trusted Site | `AccountEmbeddedExternalLocalhost` | `AccountEmbeddedReactLocalhost` | `AccountEmbeddedVueLocalhost` | `AccountEmbeddedAngularLocalhost` |
| Salesforce wrapper | `accountEmbeddedExternalApp` | `accountEmbeddedReactApp` | `accountEmbeddedVueApp` | `accountEmbeddedAngularApp` |
| Stack | Vite 8 + plain JS | Vite 8 + React 19.3 | Vite 8 + Vue 3.5 | Angular 22.2 |
| Built JS size | 25 kB | 246 kB | 88 kB | 150 kB |
| Start command | `npm run dev` | `npm run dev` | `npm run dev` | `npm start` |

> A **Next.js** example is in [`embedded-account-nextjs/`](../embedded-account-nextjs), with the wrapper `accountEmbeddedNextjsApp` on port 5184.

Vite is used only as the dev server and bundler (it resolves the `@salesforce/platform-sdk` import). There is no UI library.

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
embedded-account-external-app/
├── index.html                 # all the markup: header, fields, three rating buttons
├── package.json
├── vite.config.js             # port 5183 (strictPort)
└── src/
    ├── embedding.js           # all SDK code lives here
    ├── main.js                # state object + render() that updates the DOM
    └── style.css              # SLDS 2 variables with fallbacks (same as the other examples)
```

**Design rule:** only `src/embedding.js` imports the Salesforce SDK. `main.js` is ordinary DOM code.

---

## The SDK module — `src/embedding.js`

```js
import '@salesforce/platform-sdk/ui-embedding';
import { getViewSDK } from '@salesforce/platform-sdk/view';

export async function watchUiState(onState) {
    const sdk = await getViewSDK();
    const ui = sdk.getUiState?.();
    if (!ui) {
        return false;                       // not embedded
    }
    onState(ui.state, false);               // current snapshot
    ui.subscribe((next) => onState(next, true));   // every later snapshot
    return true;
}

export async function onHostEvent(type, handler) {
    const sdk = await getViewSDK();
    sdk.addEventListener?.(type, (event) => handler(event.detail));
}

export async function sendToHost(type, detail) {
    const sdk = await getViewSDK();
    sdk.dispatchEvent?.(new CustomEvent(type, { detail }));
}
```

| Export | What it does |
|---|---|
| `watchUiState(onState)` | Calls `onState(state, isUpdate)` with the current host snapshot, then again for every later one. Resolves to `false` when not embedded |
| `onHostEvent(type, handler)` | Listens for a custom event from the wrapper LWC (e.g. `localeInformation`) |
| `sendToHost(type, detail)` | Sends a custom event. It fires on `<lightning-ui-embedding>` as `type` |

- **`getViewSDK()`** caches one SDK instance, so all three functions share one connection and one UI-state subscription.
- Every SDK call uses `?.`, because outside Salesforce the SDK resolves to `{}`.

## The app — `src/main.js`

A small **state object + `render()`** pattern replaces what a framework would do:

```js
const state = { account: {}, embedded: false, updates: 0, pendingRating: null };

function onUiState(uiState, isUpdate) {
    const previous = state.account;
    state.account = uiState.props ?? {};
    // …confirm a pending rating, then:
    render();
    highlightChanges(previous, state.account);
}

function onSelectRating(rating) {
    state.pendingRating = rating;
    render();
    sendToHost('ratingchange', { rating });   // → onratingchange in accountEmbeddedExternalApp
    // …8 s confirmation timeout
}
```

- `render()` writes the whole state to the DOM each time: status, fields, button classes, hints, counter.
- **Field values are written as text nodes** (`textContent`, `createElement`), never as HTML, because they come from Salesforce records.
- Top-level `await watchUiState(onUiState)` is why the build target is `es2022`.
- Until the SDK resolves, the page shows the static text "Connecting to Salesforce…".

---

## Run it step by step

### 1. Install and start

```bash
cd embedded-account-external-app
npm install
npm run dev          # http://localhost:5183
```

Opening `http://localhost:5183` directly shows **"Not embedded — open this app from an Account record page."** with the buttons disabled. That is expected outside Salesforce.

### 2. Deploy the Salesforce side

Both are in the repo and already deployed:

| File | Purpose |
|---|---|
| `force-app/main/default/lwc/accountEmbeddedExternalApp/` | Wrapper LWC around `<lightning-ui-embedding>` (default URL `http://localhost:5183`) |
| `force-app/main/default/cspTrustedSites/AccountEmbeddedExternalLocalhost.cspTrustedSite-meta.xml` | Trusts `http://localhost:5183` for frames |

To deploy them again:

```bash
sf project deploy start \
  --source-dir force-app/main/default/lwc/accountEmbeddedExternalApp \
  --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedExternalLocalhost.cspTrustedSite-meta.xml \
  --wait 30
```

The wrapper has the same code as the React, Vue and Angular wrappers: props are sent only when the record data changes, and `ratingchange` is accepted only for `Hot`, `Warm` or `Cold`.

### 3. Put it on the Account page

1. Open an **Account** record → **⚙ → Edit Page**.
2. Drag **Account Embedded External App** onto the page.
3. (Optional) Change **Embedded external app URL** in the properties panel.
4. **Save** → **Activate**.

> All four wrappers (React 5180, Vue 5181, Angular 5182, External App 5183) can sit on the same page. They talk to the same record, so clicking **Hot** in one updates the others.

### 4. Test

| Action | Expected |
|---|---|
| Load the page | A **JavaScript** badge, a green dot and "Connected to Salesforce", then the Account fields |
| Edit the Account and save | The changed fields flash yellow, and the live-update counter goes up |
| Click **Warm** | The button pulses "Saving…", then turns amber-filled, the accent bar turns amber, and "Rating saved as Warm" appears |
| Toast | Salesforce also shows "Account updated — Rating set to Warm" |
| Stop `npm run dev` and reload | The wrapper shows a red error banner (e.g. `bootstrap/HEARTBEAT_TIMEOUT`) |

---

## What was verified, and how

Checked in a browser at `http://localhost:5183`, outside Salesforce. For the connected states the app was given a **fake host**: fake `getUiState`, `dispatchEvent` and `addEventListener` functions were attached to the cached SDK object before the app loaded. So the app's real subscription code ran, and the rating buttons were clicked for real.

| State | Result |
|---|---|
| Not embedded | Grey dot, empty fields, buttons disabled |
| Embedded, no record | "Embedded — place this component on an Account record page.", host CSS variable copied onto the page |
| Connected | Green dot, fields filled, rating pill, website link `https://…`, current rating filled, accent bar in the rating colour, nothing highlighted on first load |
| `localeInformation` event | `<html lang>` set to the locale sent |
| Click a rating | `ratingchange` sent with `{ rating }`, clicked button shows "Saving…", all buttons locked |
| Host confirms | "Rating saved as Warm", buttons unlock, accent bar and current button switch, changed fields highlighted, counter goes up; message and highlight clear after ~3 s |
| Click the current rating | Nothing is sent |
| Host never confirms | After ~9 s: "No confirmation from Salesforce — check the toast for details.", buttons unlock |

**Not verified:** the app running inside a real Salesforce page (the handshake, real `props`, and the save through the wrapper). Run the test table above in the org to confirm.

---

## Production

1. `npm run build` → upload `dist/` to an **HTTPS** host.
2. Add a CSP Trusted Site for that origin with **frame-src**, and deactivate the localhost one.
3. Set **Embedded external app URL** in App Builder to the HTTPS origin.

---

## Notes

- The port **5183** must match in `vite.config.js`, the CSP Trusted Site, and the wrapper's `baseUrl`. `strictPort: true` makes Vite fail rather than silently switch to a port Salesforce doesn't trust.
- `npm audit` warnings come from the Salesforce SDK's own transitive dependencies (`@conduit-client/*`, `protobufjs`).
- The SDK reference and troubleshooting tables are in the [React README](../embedded-account-react/README.md#sdk-quick-reference).
- See [`LIGHTNING_UI_EMBEDDING_IMPLEMENTATION.md`](../LIGHTNING_UI_EMBEDDING_IMPLEMENTATION.md) for the full implementation log.
