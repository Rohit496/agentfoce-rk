# Account Insights — Next.js example for `lightning-ui-embedding`

An external **Next.js 16** app (App Router, React 19) embedded on the Salesforce Account record page with the `<lightning-ui-embedding>` base component. It has the same UI and behaviour as the [React](../embedded-account-react), [Vue](../embedded-account-vue), [Angular](../embedded-account-angular) and [plain JavaScript](../embedded-account-external-app) examples.

Its Salesforce wrapper component is **Account Embedded Next.js App** (`accountEmbeddedNextjsApp`), which loads `http://localhost:5184` by default.

| | Next.js (this one) | React | Vue | Angular | External App |
|---|---|---|---|---|---|
| Folder | `embedded-account-nextjs/` | `embedded-account-react/` | `embedded-account-vue/` | `embedded-account-angular/` | `embedded-account-external-app/` |
| Dev URL | `http://localhost:5184` | `:5180` | `:5181` | `:5182` | `:5183` |
| CSP Trusted Site | `AccountEmbeddedNextjsLocalhost` | `…ReactLocalhost` | `…VueLocalhost` | `…AngularLocalhost` | `…ExternalLocalhost` |
| Salesforce wrapper | `accountEmbeddedNextjsApp` | `accountEmbeddedReactApp` | `accountEmbeddedVueApp` | `accountEmbeddedAngularApp` | `accountEmbeddedExternalApp` |
| Stack | Next.js 16.4 + React 19.3 | Vite 8 + React 19.3 | Vite 8 + Vue 3.5 | Angular 22.2 | Vite 8 + plain JS |
| Start command | `npm run dev` | `npm run dev` | `npm run dev` | `npm start` | `npm run dev` |

---

## What is different about Next.js

The UI code is the React example's code. Three things are specific to Next.js:

| Topic | What this app does | Why |
|---|---|---|
| **Server rendering** | The page is rendered on the server first, showing "Connecting to Salesforce…". The SDK is only *called* in the browser, inside `useEffect` and event handlers | There is no Salesforce host on the server. Importing the SDK there is harmless (in Node it resolves to an empty object), but calling it must wait for the browser |
| **First paint** | A `ready` flag stays `false` on the server and until the SDK resolves in the browser. Until then the status reads "Connecting to Salesforce…" | The prerendered HTML is the first thing the user sees. Without the flag it would say "Not embedded", which is wrong inside Salesforce until the SDK has connected. State only changes inside effects, so the server HTML and the first browser render are the same and React reports no hydration mismatch |
| **Client components** | `components/AccountInsights.jsx` and `hooks/useEmbedding.js` start with `'use client'`. `app/page.jsx` is a server component that just renders `<AccountInsights />` | Hooks, state and the SDK only work in client components |

Configuration in `next.config.mjs`:

| Setting | Why |
|---|---|
| `output: 'export'` | The app is fully client-side, so `next build` produces plain static files in `out/`. Any HTTPS host can serve them, with no Node server |
| `devIndicators: false` | Keeps the Next.js dev badge out of the embedded frame |
| `turbopack: { root: import.meta.dirname }` | This app sits inside a larger repo with its own lockfile. Without this, Next.js picks the parent folder as the workspace root and prints a warning |

Next.js does not send an `X-Frame-Options` header by default, so the page can be framed by Salesforce. If you add security headers later (for example `X-Frame-Options: DENY` or a `frame-ancestors` CSP), the iframe will be blocked. Allow your Salesforce domain in `frame-ancestors` instead.

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
embedded-account-nextjs/
├── next.config.mjs                  # static export, no dev badge, Turbopack root
├── package.json                     # "dev": "next dev -p 5184"
├── app/
│   ├── layout.jsx                   # <html>, <body>, page title, global CSS
│   ├── page.jsx                     # server component: renders <AccountInsights />
│   └── globals.css                  # SLDS 2 variables with fallbacks (same as the other examples)
├── components/
│   ├── AccountInsights.jsx          # 'use client' — wires the hooks to the components
│   ├── AccountDetails.jsx           # fields, rating pill, website link, change highlight
│   └── RatingPicker.jsx             # coloured Hot/Warm/Cold buttons, saving state
└── hooks/
    └── useEmbedding.js              # 'use client' — all SDK code lives here
```

**Design rule:** only `hooks/useEmbedding.js` imports the Salesforce SDK. `AccountDetails.jsx` and `RatingPicker.jsx` are identical to the React example's files.

---

## The hooks — `hooks/useEmbedding.js`

```js
'use client';

import '@salesforce/platform-sdk/ui-embedding';
import { getViewSDK } from '@salesforce/platform-sdk/view';
```

| Export | What it gives you |
|---|---|
| `useUiState()` | `{ props, styles, embedded, updates, ready }`. Subscribes on mount and unsubscribes on unmount. `ready` turns `true` once the SDK has resolved in the browser |
| `useHostEvent(type, handler)` | Listens for a custom event from the wrapper LWC (e.g. `localeInformation`). Removes the listener on unmount |
| `sendToHost(type, detail)` | Sends a custom event. It fires on `<lightning-ui-embedding>` as `type` |

- **`getViewSDK()`** caches one SDK instance, so every component shares one connection and one UI-state subscription.
- Every SDK call is inside `useEffect` or an event handler, so nothing runs during server rendering.
- Every SDK call uses `?.`, because outside Salesforce the SDK resolves to `{}`.

---

## Run it step by step

### 1. Install and start

```bash
cd embedded-account-nextjs
npm install
npm run dev          # next dev → http://localhost:5184
```

Opening `http://localhost:5184` directly shows **"Not embedded — open this app from an Account record page."** with the buttons disabled. That is expected outside Salesforce.

### 2. Deploy the Salesforce side

Both are in the repo and already deployed:

| File | Purpose |
|---|---|
| `force-app/main/default/lwc/accountEmbeddedNextjsApp/` | Wrapper LWC around `<lightning-ui-embedding>` (default URL `http://localhost:5184`) |
| `force-app/main/default/cspTrustedSites/AccountEmbeddedNextjsLocalhost.cspTrustedSite-meta.xml` | Trusts `http://localhost:5184` for frames |

To deploy them again:

```bash
sf project deploy start \
  --source-dir force-app/main/default/lwc/accountEmbeddedNextjsApp \
  --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedNextjsLocalhost.cspTrustedSite-meta.xml \
  --wait 30
```

The wrapper has the same code as the other wrappers: props are sent only when the record data changes, and `ratingchange` is accepted only for `Hot`, `Warm` or `Cold`.

### 3. Put it on the Account page

1. Open an **Account** record → **⚙ → Edit Page**.
2. Drag **Account Embedded Next.js App** onto the page.
3. (Optional) Change **Embedded Next.js app URL** in the properties panel.
4. **Save** → **Activate**.

### 4. Test

| Action | Expected |
|---|---|
| Load the page | A **Next.js** badge, a green dot and "Connected to Salesforce", then the Account fields |
| Edit the Account and save | The changed fields flash yellow, and the live-update counter goes up |
| Click **Warm** | The button pulses "Saving…", then turns amber-filled, the accent bar turns amber, and "Rating saved as Warm" appears |
| Toast | Salesforce also shows "Account updated — Rating set to Warm" |
| Stop `npm run dev` and reload | The wrapper shows a red error banner (e.g. `bootstrap/HEARTBEAT_TIMEOUT`) |

---

## What was verified, and how

Checked in a browser at `http://localhost:5184` (the dev server), outside Salesforce. The host was simulated by calling the `AccountInsights` component's own state setters through its React fiber, and the rating buttons were clicked for real.

| State | Result |
|---|---|
| Build | `next build` prerenders `/` as static content; the HTML in `out/index.html` contains "Connecting to Salesforce…" |
| Page load | No hydration warnings in the console after a reload with console tracking on |
| Not embedded | Grey dot, empty fields, buttons disabled, no Next.js dev badge visible |
| Connected | Green dot, fields filled, rating pill, website link `https://…`, current rating filled, accent bar in the rating colour |
| Click a rating | Clicked button shows "Saving…", all buttons locked |
| Event sent | One `ratingchange` `CustomEvent` with `{ rating: 'Hot' }`, `bubbles: false`, `composed: false` |
| Host confirms | "Rating saved as Warm", buttons unlock, accent bar and current button switch, changed fields highlighted; message and highlight clear after ~3 s |
| Click the current rating | Nothing is sent |
| Host never confirms | After ~9 s: "No confirmation from Salesforce — check the toast for details.", buttons unlock |

How the "event sent" row was checked: outside Salesforce the SDK object has no `dispatchEvent`, and `sdk.dispatchEvent?.(new CustomEvent(…))` does not even build the event when the function is missing. So the test temporarily gave plain objects a recording `dispatchEvent`, which the empty SDK object inherited, and removed it afterwards.

**Not verified:**
- The app running inside a real Salesforce page (the handshake, real `props`, and the save through the wrapper).
- The static build in `out/` being served and embedded. Only the dev server was opened in a browser.

---

## Production

1. `npm run build` → upload the `out/` folder to an **HTTPS** host.
2. Add a CSP Trusted Site for that origin with **frame-src**, and deactivate the localhost one.
3. Set **Embedded Next.js app URL** in App Builder to the HTTPS origin.
4. Do not add `X-Frame-Options: DENY` or a `frame-ancestors` rule that excludes your Salesforce domain.

---

## Notes

- The port **5184** must match in the `dev` script in `package.json`, the CSP Trusted Site, and the wrapper's `baseUrl`.
- `npm audit` warnings come from the Salesforce SDK's own transitive dependencies (`@conduit-client/*`, `protobufjs`).
- The SDK reference and troubleshooting tables are in the [React README](../embedded-account-react/README.md#sdk-quick-reference).
- See [`LIGHTNING_UI_EMBEDDING_IMPLEMENTATION.md`](../LIGHTNING_UI_EMBEDDING_IMPLEMENTATION.md) for the full implementation log.
