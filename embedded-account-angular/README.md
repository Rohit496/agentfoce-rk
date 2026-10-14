# Account Insights — Angular example for `lightning-ui-embedding`

The same **Account Insights** app as [`embedded-account-react/`](../embedded-account-react) (React) and [`embedded-account-vue/`](../embedded-account-vue) (Vue 3), built with **Angular 22**. It is embedded in Salesforce with the `<lightning-ui-embedding>` base component.

It has its own Salesforce wrapper component, **Account Embedded Angular App** (`accountEmbeddedAngularApp`), which loads `http://localhost:5182` by default.

| | React | Vue | Angular (this one) |
|---|---|---|---|
| Folder | `embedded-account-react/` | `embedded-account-vue/` | `embedded-account-angular/` |
| Dev URL | `http://localhost:5180` | `http://localhost:5181` | `http://localhost:5182` |
| CSP Trusted Site | `AccountEmbeddedReactLocalhost` | `AccountEmbeddedVueLocalhost` | `AccountEmbeddedAngularLocalhost` |
| Salesforce wrapper | `accountEmbeddedReactApp` | `accountEmbeddedVueApp` | `accountEmbeddedAngularApp` |
| Stack | Vite 8 + React 19.3 | Vite 8 + Vue 3.5 | Angular 22.2 (CLI, TypeScript 6, zoneless, signals) |
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
embedded-account-angular/
├── angular.json                         # dev server pinned to port 5182
├── package.json
└── src/
    ├── index.html                       # <app-root>
    ├── main.ts                          # bootstrapApplication(App, appConfig)
    ├── styles.css                       # global styles (SLDS 2 hooks with fallbacks)
    └── app/
        ├── app.config.ts
        ├── app.ts / app.html            # root component: wires the service to the components
        ├── account.ts                   # types: AccountProps, AccountUiState, Rating
        ├── embedding.ts                 # Embedding service: all SDK code lives here
        ├── account-details/             # fields, rating pill, website link, change highlight
        │   ├── account-details.ts
        │   └── account-details.html
        └── rating-picker/               # coloured Hot/Warm/Cold buttons, saving state
            ├── rating-picker.ts
            └── rating-picker.html
```

**Design rule:** only `embedding.ts` imports the Salesforce SDK. The components are plain Angular (inputs in, outputs out), so they can be reused and tested without Salesforce.

---

## The service — `src/app/embedding.ts`

```ts
import '@salesforce/platform-sdk/ui-embedding';
import { getViewSDK, type ViewSDK } from '@salesforce/platform-sdk/view';

@Injectable({ providedIn: 'root' })
export class Embedding {
  readonly account = computed(() => this.state().props);   // host props, as a signal
  readonly styles = computed(() => this.state().styles);
  readonly embedded = signal(false);
  readonly updates = signal(0);

  onHostEvent<T>(type, handler): () => void { /* … */ }     // listen to the wrapper LWC
  async sendToHost(type, detail): Promise<void> { /* … */ } // fire an event on <lightning-ui-embedding>
}
```

| Member | What it gives you |
|---|---|
| `account`, `styles` | Read-only signals with the latest host snapshot. Templates and `computed()`/`effect()` react to them automatically |
| `embedded`, `updates` | Whether the SDK found a host, and how many live snapshots have arrived |
| `onHostEvent(type, handler)` | Listens for a custom event from the wrapper LWC (e.g. `localeInformation`). Returns a function that removes the listener |
| `sendToHost(type, detail)` | Sends a custom event. It fires on `<lightning-ui-embedding>` as `type` |

Why it is built this way:

- **`getViewSDK()` + a root-provided service:** Angular creates one `Embedding` instance for the whole app, and `getViewSDK()` caches one SDK instance, so there is only ever one connection and one UI-state subscription. Salesforce allows at most one UI-state subscription per session.
- **Signals, zoneless:** the app runs without `zone.js`. The SDK's `subscribe` callback sets a signal, and Angular re-renders only what reads it. No manual change detection is needed.
- **Typed UI state:** `getUiState<AccountUiState>()` types `state.props` as `AccountProps`.
- **Guarded calls:** every SDK call uses `?.`, because outside Salesforce the SDK resolves to `{}`.

Usage in `app.ts`:

```ts
private readonly embedding = inject(Embedding);
protected readonly account = this.embedding.account;

protected onSelectRating(rating: Rating): void {
  this.pendingRating.set(rating);
  void this.embedding.sendToHost('ratingchange', { rating });   // → onratingchange in accountEmbeddedAngularApp
  // …8 s confirmation timeout
}
```

The confirmation is an `effect()` that watches `account().rating`: when it equals the pending rating, the buttons unlock and "Rating saved as …" appears.

---

## Run it step by step

### 1. Install and start

```bash
cd embedded-account-angular
npm install
npm start            # ng serve → http://localhost:5182
```

Opening `http://localhost:5182` directly shows **"Not embedded — open this app from an Account record page."** with the buttons disabled. That is expected outside Salesforce.

### 2. Deploy the Salesforce side

Both are in the repo and already deployed:

| File | Purpose |
|---|---|
| `force-app/main/default/lwc/accountEmbeddedAngularApp/` | Wrapper LWC around `<lightning-ui-embedding>` (default URL `http://localhost:5182`) |
| `force-app/main/default/cspTrustedSites/AccountEmbeddedAngularLocalhost.cspTrustedSite-meta.xml` | Trusts `http://localhost:5182` for frames |

To deploy them again:

```bash
sf project deploy start \
  --source-dir force-app/main/default/lwc/accountEmbeddedAngularApp \
  --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedAngularLocalhost.cspTrustedSite-meta.xml \
  --wait 30
```

The wrapper has the same code as `accountEmbeddedVueApp`: props are sent only when the record data changes, and `ratingchange` is accepted only for `Hot`, `Warm` or `Cold`.

### 3. Put it on the Account page

1. Open an **Account** record → **⚙ → Edit Page**.
2. Drag **Account Embedded Angular App** onto the page.
3. (Optional) Change **Embedded Angular app URL** in the properties panel.
4. **Save** → **Activate**.

> All four wrappers (React 5180, Vue 5181, Angular 5182, External App 5183) can sit on the same page. They talk to the same record, so clicking **Hot** in one updates the others.

### 4. Test

| Action | Expected |
|---|---|
| Load the page | An **Angular** badge, a green dot and "Connected to Salesforce", then the Account fields |
| Edit the Account and save | The changed fields flash yellow, and the live-update counter goes up |
| Click **Warm** | The button pulses "Saving…", then turns amber-filled, the accent bar turns amber, and "Rating saved as Warm" appears |
| Toast | Salesforce also shows "Account updated — Rating set to Warm" |
| Stop `npm start` and reload | After about 30 s the wrapper shows the "app isn't available" banner described below |

#### When the app isn't running

If the Angular app is stopped or can't be reached, `lightning-ui-embedding` waits 30 s for the app's ready heartbeat, then fires `sf-embedding.component.error` with `bootstrap/HEARTBEAT_TIMEOUT`. The wrapper (`handleError` in `accountEmbeddedAngularApp.js`) hides the empty frame and shows a banner written for end users, with no URLs, error codes or developer terms:

> **Account Insights is temporarily unavailable**
> Nothing is wrong with this account or your data — only this section couldn't be displayed. Please refresh the page in a few minutes. If you still see this message, contact your Salesforce administrator.

| Situation | Title shown to the user |
|---|---|
| Error code `HEARTBEAT_TIMEOUT` (app stopped or unreachable) | Account Insights is temporarily unavailable |
| Any other embedding error | Something went wrong while loading Account Insights |
| `getRecord` fails | We couldn't load this account's details |

Every banner ends with the same advice: refresh in a few minutes, then contact the Salesforce administrator.

**Where the technical cause went:** it is written to the browser console (`logError`), not shown in the banner. An admin or developer opens DevTools and looks for:

```
[accountEmbeddedAngularApp] Embedded app at http://localhost:5182 failed to load. bootstrap/HEARTBEAT_TIMEOUT: Embedded document did not send sf-embedding/ready heartbeat within 30000ms
```

**Banner colours:** the banner is solid crimson (`--slds-g-color-error-1`) with white text (`--slds-g-color-neutral-base-100`) and a white icon. Don't use `--slds-g-color-on-error-1` for the text: in light mode it resolves to `#b60554`, the same as the background, which made the original banner's text invisible (only the icon showed).

**Banner layout:** the icon-and-text row uses the SLDS `slds-media` utility classes (`slds-media`, `slds-media__figure`, `slds-media__body`) in the template. Writing `display: flex` and `align-items` in the component CSS instead makes the SLDS validator flag them as errors ("Consider using a utility class").

After redeploying the wrapper, hard-reload the page (`⇧⌘R`). A normal reload can keep serving the cached component.

---

## What was verified, and how

Checked in a browser at `http://localhost:5182`, outside Salesforce. The host was simulated by setting the service's state signal through Angular's dev-mode debug API (`ng.getComponent`), and the rating buttons were clicked for real.

| State | Result |
|---|---|
| Not embedded | Grey dot, empty fields, buttons disabled |
| Connected | Green dot, fields filled, rating pill, website link, current rating filled, accent bar in the rating colour |
| Click a rating | `ratingchange` sent with `{ rating }`, clicked button shows "Saving…", all buttons locked |
| Host confirms | "Rating saved as Cold", buttons unlock, accent bar and current button switch |
| Host never confirms | After 8 s: "No confirmation from Salesforce — check the toast for details.", buttons unlock |
| Live field change | Changed fields highlighted |

**Not verified:** the app running inside a real Salesforce page (the handshake, real `props`, and the save through the wrapper). Run the test table above in the org to confirm.

---

## Production

1. `npm run build` → upload `dist/embedded-account-angular/browser/` to an **HTTPS** host.
2. Add a CSP Trusted Site for that origin with **frame-src**, and deactivate the localhost one.
3. Set **Embedded Angular app URL** in App Builder to the HTTPS origin.

---

## Notes

- The port **5182** must match in `angular.json` (`serve.options.port`), the CSP Trusted Site, and the wrapper's `baseUrl`.
- The project was scaffolded with `ng new` (`--zoneless --ssr=false --routing=false --skip-tests`). `@angular/router` and `@angular/forms` were removed because the app doesn't use them.
- `ng new` failed at its install step on npm 12 (`npm error EALLOWSCRIPTS`). Running `npm install` in the folder afterwards worked.
- `npm audit` reports 11 vulnerabilities. They come from the Salesforce SDK's own transitive dependencies (`@conduit-client/*`, `protobufjs`), the same as in the other two apps. A fresh Angular install without the SDK reported 0.
- See [`LIGHTNING_UI_EMBEDDING_IMPLEMENTATION.md`](../LIGHTNING_UI_EMBEDDING_IMPLEMENTATION.md) for the full implementation log.
