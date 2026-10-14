# Account Insights — React example for `lightning-ui-embedding`

An external **React 19** app embedded on the Salesforce Account record page with the `<lightning-ui-embedding>` base component. The same app also exists in [Vue](../embedded-account-vue) and [Angular](../embedded-account-angular).

Its Salesforce wrapper component is **Account Embedded React App** (`accountEmbeddedReactApp`), which loads `http://localhost:5180` by default.

> **Renamed.** This folder was `embedded-account-app/` and held a plain JavaScript app. It was converted to React and renamed so the three examples match. The wrapper `accountEmbeddedApp` became `accountEmbeddedReactApp`, and the trusted site `AccountEmbeddedAppLocalhost` became `AccountEmbeddedReactLocalhost`. The port (5180) did not change.

| | React (this one) | Vue | Angular |
|---|---|---|---|
| Folder | `embedded-account-react/` | `embedded-account-vue/` | `embedded-account-angular/` |
| Dev URL | `http://localhost:5180` | `http://localhost:5181` | `http://localhost:5182` |
| CSP Trusted Site | `AccountEmbeddedReactLocalhost` | `AccountEmbeddedVueLocalhost` | `AccountEmbeddedAngularLocalhost` |
| Salesforce wrapper | `accountEmbeddedReactApp` | `accountEmbeddedVueApp` | `accountEmbeddedAngularApp` |
| Stack | Vite 8 + React 19.3 | Vite 8 + Vue 3.5 | Angular 22.2 |
| Start command | `npm run dev` | `npm run dev` | `npm start` |

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
embedded-account-react/
├── index.html                       # mounts #root
├── package.json
├── vite.config.js                   # React plugin, port 5180 (strictPort)
└── src/
    ├── main.jsx                     # createRoot(...).render(<App />)
    ├── App.jsx                      # wires the hooks to the components
    ├── style.css                    # SLDS 2 variables with fallbacks
    ├── hooks/
    │   └── useEmbedding.js          # all SDK code lives here
    └── components/
        ├── AccountDetails.jsx       # fields, rating pill, website link, change highlight
        └── RatingPicker.jsx         # coloured Hot/Warm/Cold buttons, saving state
```

**Design rule:** only `hooks/useEmbedding.js` imports the Salesforce SDK. The components are plain React (props in, callbacks out), so they can be reused and tested without Salesforce.

---

## The hooks — `src/hooks/useEmbedding.js`

```js
import '@salesforce/platform-sdk/ui-embedding';
import { getViewSDK } from '@salesforce/platform-sdk/view';
```

| Export | What it gives you |
|---|---|
| `useUiState()` | `{ props, styles, embedded, updates }`. Subscribes on mount and unsubscribes on unmount |
| `useHostEvent(type, handler)` | Listens for a custom event from the wrapper LWC (e.g. `localeInformation`). Removes the listener on unmount |
| `sendToHost(type, detail)` | Sends a custom event. It fires on `<lightning-ui-embedding>` as `type` |

Why it is built this way:

- **`getViewSDK()`:** every component that calls these hooks gets the **same cached SDK instance**, so there is only ever one connection and one UI-state subscription. Salesforce allows at most one UI-state subscription per session. `createViewSDK()` would create a new instance on each call.
- **`active` flag:** `getViewSDK()` is async, so the effect checks the component is still mounted before subscribing. This also makes it safe under React `StrictMode`, which mounts effects twice in development.
- **Handler ref in `useHostEvent`:** the listener is attached once, and always calls the latest handler.
- **Guarded calls:** every SDK call uses `?.`, because outside Salesforce the SDK resolves to `{}`.

Usage in `App.jsx`:

```jsx
const { props: account, styles, embedded, updates } = useUiState();

useHostEvent('localeInformation', (detail) => {
    document.documentElement.lang = detail?.locale ?? 'en';
});

function onSelectRating(rating) {
    setPending(rating);
    sendToHost('ratingchange', { rating });   // → onratingchange in accountEmbeddedReactApp
    // …8 s confirmation timeout
}
```

The confirmation is a `useEffect` on `account.rating`: when it equals the pending rating, the buttons unlock and "Rating saved as …" appears. A ref mirrors the pending rating so the timeout callback reads the current value.

`ratingchange` is sent with the default `bubbles: false` and `composed: false`. That is enough here, because the wrapper binds `onratingchange` directly on the `<lightning-ui-embedding>` element.

---

## Run it step by step

### 1. Install and start

```bash
cd embedded-account-react
npm install
npm run dev          # http://localhost:5180
```

Opening `http://localhost:5180` directly shows **"Not embedded — open this app from an Account record page."** with the buttons disabled. That is expected outside Salesforce.

### 2. Deploy the Salesforce side

Both are in the repo and already deployed:

| File | Purpose |
|---|---|
| `force-app/main/default/lwc/accountEmbeddedReactApp/` | Wrapper LWC around `<lightning-ui-embedding>` (default URL `http://localhost:5180`) |
| `force-app/main/default/cspTrustedSites/AccountEmbeddedReactLocalhost.cspTrustedSite-meta.xml` | Trusts `http://localhost:5180` for frames |

To deploy them again:

```bash
sf project deploy start \
  --source-dir force-app/main/default/lwc/accountEmbeddedReactApp \
  --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedReactLocalhost.cspTrustedSite-meta.xml \
  --wait 30
```

The wrapper has the same code as the Vue and Angular wrappers: props are sent only when the record data changes, and `ratingchange` is accepted only for `Hot`, `Warm` or `Cold`.

### 3. Put it on the Account page

1. Open an **Account** record → **⚙ → Edit Page**.
2. Drag **Account Embedded React App** onto the page.
3. (Optional) Change **Embedded React app URL** in the properties panel.
4. **Save** → **Activate**.

> The old pre-rename component, **Account Embedded App**, has been deleted from the org. **Account_Record_Page** now uses this component in its place.
>
> All four wrappers (React 5180, Vue 5181, Angular 5182, External App 5183) can sit on the same page. They talk to the same record, so clicking **Hot** in one updates the others.

### 4. Test

| Action | Expected |
|---|---|
| Load the page | A **React** badge, a green dot and "Connected to Salesforce", then the Account fields |
| Edit the Account and save | The changed fields flash yellow, and the live-update counter goes up |
| Click **Warm** | The button pulses "Saving…", then turns amber-filled, the accent bar turns amber, and "Rating saved as Warm" appears |
| Toast | Salesforce also shows "Account updated — Rating set to Warm" |
| Stop `npm run dev` and reload | The wrapper shows a red error banner (e.g. `bootstrap/HEARTBEAT_TIMEOUT`) |

---

## What was verified, and how

Checked in a browser at `http://localhost:5180`, outside Salesforce. The host was simulated by calling the `App` component's own state setters through its React fiber, the SDK's `dispatchEvent` was replaced with a recorder, and the rating buttons were clicked for real.

| State | Result |
|---|---|
| Not embedded | Grey dot, empty fields, buttons disabled |
| Connected | Green dot, fields filled, rating pill, website link, current rating filled, accent bar in the rating colour |
| Click a rating | `ratingchange` sent with `{ rating }`, clicked button shows "Saving…", all buttons locked |
| Host confirms | "Rating saved as Warm", buttons unlock, accent bar and current button switch |
| Click the current rating | Nothing is sent |
| Host never confirms | After 8.6 s: "No confirmation from Salesforce — check the toast for details.", buttons unlock |
| Live field change | Changed fields highlighted, and the highlight clears |

**Not verified:** the React app running inside a real Salesforce page (the handshake, real `props`, and the save through the wrapper). Run the test table above in the org to confirm.

---

## SDK quick reference

`@salesforce/platform-sdk` (v12.11+). Entry points: `/ui-embedding` (side-effect import) and `/view`.

| API (on the SDK object) | Purpose |
|---|---|
| `await getViewSDK()` | **Recommended.** Connects to the host once and returns the same cached instance on every call. Resolves to an **empty object** outside an embedding, so use `?.` |
| `await createViewSDK()` | Creates a **new** instance (and new subscriptions) on every call. Only safe if called exactly once |
| `getUiState()` → `{ state, subscribe }` | `state.props` = host `props`, `state.styles.variables` = Salesforce CSS variables. `subscribe(fn)` returns an unsubscribe function. Each snapshot is a full replacement, not a diff |
| `dispatchEvent(new CustomEvent(type, { detail }))` | Sends an event to the host. It fires on `<lightning-ui-embedding>` as `type`. The event's `bubbles`, `composed` and `cancelable` flags are forwarded |
| `addEventListener(type, fn)` | Receives events the host dispatches on the embedding element |
| `resize(width, height)` | Sets the iframe size explicitly, e.g. `resize('', '800px')` |
| `markDirtyState(label)` / `clearDirtyState(label)` | Shows Salesforce's "unsaved changes" warning when the user navigates away |
| `getTheme()` | Returns `{ mode: 'light' \| 'dark' }` or `null` |

Host-side events on `<lightning-ui-embedding>`:

| Event | When | `event.detail` |
|---|---|---|
| `sf-embedding.component.ready` | The app finished the handshake | — |
| `sf-embedding.component.error` | Embedding failed | `{ phase, code, message, retryable }` |
| `<your custom type>` | The app called `dispatchEvent` | Your `detail` |

---

## Troubleshooting

| Symptom / code | Cause | Fix |
|---|---|---|
| Blank frame, "refused to frame" in the console | Origin not trusted | Add a CSP Trusted Site with **frame-src**, using the exact origin |
| `SAME_ORIGIN_SRC` | App is served from the Salesforce domain | Host it on a different origin |
| `MISSING_SRC` / `INVALID_SRC` | `src` is empty or malformed | Check the `baseUrl` property |
| `SESSION_BINDING_MUTATED` | `src` or `sandbox` changed after mount | Keep them constant. To switch apps, unmount and remount the component |
| `BLOCKED_SANDBOX_TOKEN` / `ALLOW_SCRIPTS_STRIPPED` | A sandbox token the component doesn't allow | Remove that token from `sandbox` |
| `HEARTBEAT_TIMEOUT` (retryable) | App didn't finish the handshake: not running, or SDK not loaded | Start the dev server. Make sure the SDK is imported. Remount |
| `WRONG_ORIGIN` / `PROTOCOL_VERSION_MISMATCH` | The app redirected elsewhere, or SDK versions don't match | Serve the app from the exact `src` origin. Update `@salesforce/platform-sdk` |
| `Port 5180 is already in use` | Another dev server is on that port | Stop it, or change the port in **all three** places: `vite.config.js`, the CSP Trusted Site, and the wrapper's `baseUrl` |
| App shows data but clicking a button does nothing | The event type doesn't match the wrapper's handler, or the record id is missing | The event type must be lowercase and match `on<type>` exactly. Place the component on a **record** page |

Full list of codes: [UI Embedding Error Codes](https://developer.salesforce.com/docs/platform/microfrontend/references/microfrontend-error-codes/error-codes.html).

---

## Production

1. `npm run build` → upload `dist/` to an **HTTPS** host.
2. Add a CSP Trusted Site for that origin with **frame-src**, and deactivate the localhost one.
3. Set **Embedded React app URL** in App Builder to the HTTPS origin.

---

## Notes

- The port **5180** must match in `vite.config.js`, the CSP Trusted Site, and the wrapper's `baseUrl`. `strictPort: true` makes Vite fail rather than silently switch to a port Salesforce doesn't trust.
- `npm audit` warnings come from the Salesforce SDK's own transitive dependencies (`@conduit-client/*`, `protobufjs`).
- See [`LIGHTNING_UI_EMBEDDING_IMPLEMENTATION.md`](../LIGHTNING_UI_EMBEDDING_IMPLEMENTATION.md) for the full implementation log.

## References

- [Get Started with UI Embedding](https://developer.salesforce.com/docs/platform/microfrontend/guide/get-started.html)
- [Exchange Data Between the Page and an Embedded App](https://developer.salesforce.com/docs/platform/microfrontend/guide/exchange-data.html)
- [Build the Embedding Bridge Without a Salesforce Package](https://developer.salesforce.com/docs/platform/microfrontend/guide/package-free-bridge.html)
- [`lightning-ui-embedding` component reference](https://developer.salesforce.com/docs/platform/lightning-component-reference/guide/lightning-ui-embedding.html)
- [Sample recipes — trailheadapps/multiframework-recipes](https://github.com/trailheadapps/multiframework-recipes/tree/main/force-app/main/microfrontend-recipes)
