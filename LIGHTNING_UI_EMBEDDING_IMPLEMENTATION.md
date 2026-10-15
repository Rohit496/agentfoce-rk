# lightning-ui-embedding — Implementation Log

This is the step-by-step record of how `<lightning-ui-embedding>` was implemented in the **ashish-rk** project and org, in the order it was done. It includes the research, decisions, commands, problems and fixes.

**Result:** five Account record page components (**Account Embedded React App**, **Account Embedded Vue App**, **Account Embedded Angular App**, the framework-free **Account Embedded External App**, and **Account Embedded Next.js App**). Each loads an external web app inside Salesforce, sends it the Account's fields, and saves a Rating chosen in the app back to the record.

> **Names changed in Step 17.** Steps 1 to 12 describe the first example as it was built: a plain JavaScript app in `embedded-account-app/` with the wrapper `accountEmbeddedApp` and the trusted site `AccountEmbeddedAppLocalhost`. That app was later converted to React and renamed to `embedded-account-react/`, `accountEmbeddedReactApp` and `AccountEmbeddedReactLocalhost`. The older steps keep the original names because they record what was done at the time. The code shown in Steps 3 and 5 is the original version and no longer exists in the repo.

| Item | Value |
|---|---|
| Org | `ashish-rk` dev org (`asagarwal-rkk-dev-ed.develop.my.salesforce.com`), API 67.0 |
| Salesforce CLI | `@salesforce/cli/2.153.5` |
| SDK | `@salesforce/platform-sdk` 12.11.0 |
| Date | 2026-10-08 |

---

## Step 1 — Research what `lightning-ui-embedding` is

**Sources read:**
- Salesforce guide: *Get Started with UI Embedding*, *Exchange Data*, *Build the Bridge Without a Package*, *Error Codes*, and the component reference page
- The official samples repo `trailheadapps/multiframework-recipes`, folder `force-app/main/microfrontend-recipes`

**What was learned:**

1. It is a Salesforce **base component**, now GA. It loads an external web app in a **sandboxed iframe** and opens a secure two-way channel to it.
2. Org requirements: Enterprise / Performance / Unlimited / Developer / Partner Developer edition, on **Hyperforce**, with **English** as the default language.
3. The app's origin must be **trusted for frames**, and must **not** be the same origin as Salesforce.
4. There are two ways to connect. This project uses the first:
   - **With the Salesforce package.** The app imports `@salesforce/platform-sdk`.
   - **Without a package.** The app implements the `sf-embedding` protocol itself.
5. Key rules:
   - `src` is required and **cannot change after mount** (error `SESSION_BINDING_MUTATED`).
   - Lifecycle events `sf-embedding.component.ready` / `.error` contain dots, so they must be bound with `addEventListener`, not `on…` in the template.
   - Data passed to the app must be structured-clone safe.
6. Real attributes, confirmed from the samples: `src`, `title`, `sandbox`, `props`. Custom events from the app arrive on the element as normal DOM events (e.g. `onratingchange`).
7. **The docs and the samples differ.** The samples use `shell-title` and `getViewSDK()`. The GA guide snippets use `title` and `createViewSDK()`. `title` from the GA guide was followed. For the SDK call, `getViewSDK()` was chosen after more research (see [Step 10](#step-10--switch-from-createviewsdk-to-getviewsdk)).

**Checked locally:**
```bash
npm view @salesforce/platform-sdk version exports   # 12.11.0, has ./view and ./ui-embedding exports
sf template generate ui-embedding --help           # CLI generator exists (needs --name, --src, --sandbox, --title)
```

---

## Step 2 — Decide what to embed

The repo had no external app with source code to embed (`expense-tracker/` held only Next.js build output). So a **new small app** was created, `embedded-account-app/` (Vite + plain JavaScript), to demonstrate both directions:

- **Salesforce → app:** the Account's Name, Rating, Type, Industry, Phone and Website
- **App → Salesforce:** Hot / Warm / Cold buttons that update `Account.Rating`

It was placed on the **Account record page**, and the app URL was made configurable in App Builder.

---

## Step 3 — Create the wrapper LWC `accountEmbeddedApp`

Path: `force-app/main/default/lwc/accountEmbeddedApp/`

### 3.1 `accountEmbeddedApp.html`

```html
<template>
    <lightning-card title="Account Insights" icon-name="standard:account">
        <div class="slds-var-p-horizontal_small">
            <template lwc:if={errorMessage}>
                <div class="error-banner" role="alert">
                    <lightning-icon
                        icon-name="utility:error"
                        alternative-text="Error"
                        size="x-small"
                        variant="inverse"
                    ></lightning-icon>
                    <p>{errorMessage}</p>
                </div>
            </template>
            <template lwc:if={isLoading}>
                <lightning-spinner
                    alternative-text="Loading embedded app"
                    size="small"
                ></lightning-spinner>
            </template>
            <lightning-ui-embedding
                lwc:ref="embedding"
                src={computedSrc}
                title="Account Insights"
                sandbox="allow-popups"
                props={account}
                onratingchange={handleRatingChange}
            ></lightning-ui-embedding>
        </div>
    </lightning-card>
</template>
```

| Attribute | Why |
|---|---|
| `src={computedSrc}` | The app URL, taken from the `baseUrl` page property |
| `title` | Accessible name for the iframe |
| `sandbox="allow-popups"` | Lets links in the app open new tabs |
| `props={account}` | The Account data sent to the app |
| `lwc:ref="embedding"` | Needed so the JS can attach the dotted lifecycle events |
| `onratingchange` | Receives the app's `ratingchange` event |

### 3.2 `accountEmbeddedApp.js`

```js
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import locale from '@salesforce/i18n/locale';
import NAME from '@salesforce/schema/Account.Name';
import RATING from '@salesforce/schema/Account.Rating';
import TYPE from '@salesforce/schema/Account.Type';
import INDUSTRY from '@salesforce/schema/Account.Industry';
import PHONE from '@salesforce/schema/Account.Phone';
import WEBSITE from '@salesforce/schema/Account.Website';

const FIELDS = [NAME, RATING, TYPE, INDUSTRY, PHONE, WEBSITE];

export default class AccountEmbeddedApp extends LightningElement {
    @api recordId;
    @api baseUrl = 'http://localhost:5180';

    isLoading = true;
    errorMessage;
    hasWiredEvents = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    record;

    // src binds the embedding session; it must not change after mount.
    get computedSrc() {
        return this.baseUrl;
    }

    // A new object on every wire emission, so the embedding pushes a fresh UI-state snapshot.
    get account() {
        const data = this.record?.data;
        return {
            recordId: this.recordId,
            name: getFieldValue(data, NAME),
            rating: getFieldValue(data, RATING),
            type: getFieldValue(data, TYPE),
            industry: getFieldValue(data, INDUSTRY),
            phone: getFieldValue(data, PHONE),
            website: getFieldValue(data, WEBSITE)
        };
    }

    // Event names contain dots, so they can't be bound with on* template attributes.
    renderedCallback() {
        if (this.hasWiredEvents) {
            return;
        }
        this.hasWiredEvents = true;

        const el = this.refs.embedding;
        el.addEventListener('sf-embedding.component.ready', this.handleReady);
        el.addEventListener('sf-embedding.component.error', this.handleError);
    }

    handleReady = () => {
        this.isLoading = false;
        this.errorMessage = undefined;
        this.refs.embedding.dispatchEvent(
            new CustomEvent('localeInformation', { detail: { locale } })
        );
    };

    handleError = (event) => {
        const { phase, code, message } = event.detail ?? {};
        this.isLoading = false;
        this.errorMessage = `Embedded app failed to load (${phase}/${code}): ${message}`;
    };

    async handleRatingChange(event) {
        const { rating } = event.detail ?? {};
        if (!this.recordId || !rating) {
            return;
        }
        try {
            await updateRecord({ fields: { Id: this.recordId, Rating: rating } });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Account updated',
                    message: `Rating set to ${rating}.`,
                    variant: 'success'
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Update failed',
                    message: error?.body?.message ?? error?.message ?? 'Unknown error',
                    variant: 'error'
                })
            );
        }
    }
}
```

What it does:
1. `@wire(getRecord)` loads the Account and reloads it whenever the record changes.
2. The `account` getter builds the `props` object sent to the app.
3. `renderedCallback` attaches the **ready** and **error** listeners once.
4. On **ready**, it hides the spinner and sends the user's locale to the app.
5. On **error**, it shows the error's phase, code and message in a banner.
6. On **ratingchange**, it saves `Rating` with `updateRecord` and shows a success or error toast.

### 3.3 `accountEmbeddedApp.js-meta.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>67.0</apiVersion>
    <description>Embeds an external web app on the Account record page with lightning-ui-embedding.</description>
    <isExposed>true</isExposed>
    <masterLabel>Account Embedded App</masterLabel>
    <targets>
        <target>lightning__RecordPage</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__RecordPage">
            <objects>
                <object>Account</object>
            </objects>
            <property
                name="baseUrl"
                type="String"
                label="Embedded app URL"
                description="Origin that serves the embedded app. Must also be a CSP Trusted Site with frame-src enabled."
                default="http://localhost:5180"
            />
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

> **Problem hit:** the IDE showed an XSD error because `<description>` came after `<isExposed>`.
> **Fix:** moved `<description>` above `<isExposed>`.

### 3.4 `accountEmbeddedApp.css`

Added later, in Step 9, for the SLDS 2 fix.

---

## Step 4 — Trust the app's origin (CSP Trusted Site)

Path: `force-app/main/default/cspTrustedSites/AccountEmbeddedAppLocalhost.cspTrustedSite-meta.xml`

This uses the same pattern as Salesforce's own sample.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CspTrustedSite xmlns="http://soap.sforce.com/2006/04/metadata">
    <canAccessCamera>false</canAccessCamera>
    <canAccessMicrophone>false</canAccessMicrophone>
    <context>All</context>
    <description>Lets the lightning-ui-embedding iframe in accountEmbeddedApp load the embedded app from the local Vite dev server. Replace with your HTTPS host for production.</description>
    <endpointUrl>http://localhost:5180</endpointUrl>
    <isActive>true</isActive>
    <isApplicableToConnectSrc>false</isApplicableToConnectSrc>
    <isApplicableToFontSrc>false</isApplicableToFontSrc>
    <isApplicableToFrameSrc>true</isApplicableToFrameSrc>
    <isApplicableToImgSrc>false</isApplicableToImgSrc>
    <isApplicableToMediaSrc>false</isApplicableToMediaSrc>
    <isApplicableToStyleSrc>false</isApplicableToStyleSrc>
</CspTrustedSite>
```

The important setting is `isApplicableToFrameSrc = true`, which allows the origin inside an iframe.

---

## Step 5 — Create the external app `embedded-account-app/`

### 5.1 Create the project and install

```bash
mkdir embedded-account-app && cd embedded-account-app
# package.json created with "type": "module" and dev/build/preview scripts
npm install --save @salesforce/platform-sdk@^12.11.0
npm install --save-dev vite@^7
```

The SDK's type definitions (`node_modules/@salesforce/platform-sdk/dist/view/*.d.ts`) were read to confirm the GA API:

| API | Meaning |
|---|---|
| `getViewSDK()` | **Used here.** Connects to Salesforce once and returns the same cached instance on every call. Returns `{}` when not embedded |
| `createViewSDK()` | Builds a **new** instance on each call. `getViewSDK()` calls it internally |
| `getUiState()` → `{ state, subscribe }` | `state.props` and `state.styles` |
| `dispatchEvent(CustomEvent)` | Sends an event to Salesforce |
| `addEventListener(type, fn)` | Receives events from Salesforce |
| `resize()`, `markDirtyState()`, `clearDirtyState()` | Optional extras |

### 5.2 Files

| File | Content |
|---|---|
| `package.json` | Scripts `dev`, `build` and `preview`; the SDK as a dependency; Vite as a dev dependency |
| `vite.config.js` | `server: { port: 5180, strictPort: true }` and `build: { target: 'es2022' }` (for top-level `await`) |
| `index.html` | Field list (Rating, Type, Industry, Phone, Website) and Hot / Warm / Cold buttons |
| `src/main.js` | SDK logic, shown below |
| `src/style.css` | Styling that uses SLDS 2 variables, with fallbacks |
| `.gitignore` | `node_modules/` and `dist/` |

### 5.3 `src/main.js`, the key parts

```js
import '@salesforce/platform-sdk/ui-embedding';
import { getViewSDK } from '@salesforce/platform-sdk/view';

// getViewSDK caches one instance, so repeat calls never open a second UI-state subscription.
const viewSdk = await getViewSDK();

// Read Account data from Salesforce and re-render on every update
const uiState = viewSdk.getUiState?.();
if (uiState) {
    applySnapshot(uiState.state);
    uiState.subscribe((next) => {
        applySnapshot(next);
        updateCount += 1;   // the "N live updates received from Salesforce" counter
    });
}

// Receive the locale sent by the wrapper
viewSdk.addEventListener?.('localeInformation', (event) => {
    document.documentElement.lang = event.detail?.locale ?? 'en';
});

// Button click → send "ratingchange" to Salesforce
viewSdk.dispatchEvent?.(new CustomEvent('ratingchange', { detail: { rating } }));
```

`applySnapshot` fills the fields from `state.props` and copies `state.styles.variables` (Salesforce's CSS variables) onto the page.

### 5.4 Build check

```bash
npx vite build
# ✓ 12 modules transformed … ✓ built in 87ms
npx eslint force-app/main/default/lwc/accountEmbeddedApp   # no errors
```

> `npm install` reported **11 vulnerabilities**. They are all inside the SDK's own dependencies (`@conduit-client/*`), not in packages added here.

---

## Step 6 — Validate and deploy to the org

```bash
# Validate first
sf project deploy start --dry-run \
  --source-dir force-app/main/default/lwc/accountEmbeddedApp \
  --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedAppLocalhost.cspTrustedSite-meta.xml \
  --wait 30 --json
# → Succeeded (this also confirmed the org supports lightning-ui-embedding)

# Deploy
sf project deploy start \
  --source-dir force-app/main/default/lwc/accountEmbeddedApp \
  --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedAppLocalhost.cspTrustedSite-meta.xml \
  --wait 30 --json
# → Succeeded (deploy id 0AfgL00000ZpL6ISAV)
```

---

## Step 7 — Problem: port 5173 already in use

The app was first set to port **5173**. Running `npm run dev` failed:

```
Error: Port 5173 is already in use
```

Another React dev server on the machine (PID 60245) already used 5173. It was left running, and this app was moved to **5180**.

The port appears in **3 places** that must always match:

| File | Value |
|---|---|
| `embedded-account-app/vite.config.js` | `port: 5180` |
| `AccountEmbeddedAppLocalhost.cspTrustedSite-meta.xml` | `<endpointUrl>http://localhost:5180</endpointUrl>` |
| `accountEmbeddedApp.js` and `.js-meta.xml` | `baseUrl` default `http://localhost:5180` |

The component and CSP site were then redeployed (Succeeded), and the dev server was started:

```bash
cd embedded-account-app && npm run dev
curl -s -o /dev/null -w "%{http_code}" http://localhost:5180/   # 200
```

---

## Step 8 — Problem: 1K+ changes showing in Source Control

Only 11 of the changes came from this work. The rest were already there:

| Count | Path | What it was |
|---|---|---|
| 642 | `expense-tracker/.next/` | Next.js build output that git wasn't ignoring |
| ~257 | `force-app/main/default/uiBundles/*` | Uncommitted React UI bundle source |
| rest | `HXL-Account/`, `lightningTypes`, `uiWidgets`, classes | Earlier uncommitted work |

**Fix:** added `.next/` to the root `.gitignore`. The count went from **1,135 to 495**.

---

## Step 9 — Problem: deprecated SLDS class

The VS Code SLDS linter flagged the first version of the error banner:

```
'slds-notify' is currently deprecated in the new design for Lightning UI.  (SLDS2_DEPRECATED)
```

**Fix:** replaced the `slds-notify slds-notify_alert slds-alert_error` blueprint with a `lightning-icon` and a `<div class="error-banner" role="alert">`. A new CSS file styles it with **SLDS 2 global styling hooks**:

`accountEmbeddedApp.css`
```css
.error-banner {
    display: flex;
    align-items: center;
    gap: var(--slds-g-spacing-2);
    padding: var(--slds-g-spacing-2) var(--slds-g-spacing-3);
    margin-block-end: var(--slds-g-spacing-3);
    border-radius: var(--slds-g-radius-border-2);
    background-color: var(--slds-g-color-error-1);
    color: var(--slds-g-color-on-error-1);
}
```

Afterwards the SLDS linter and ESLint reported no issues, and the component was redeployed (Succeeded).

**Standing rule:** always use the latest SLDS (SLDS 2), with no deprecated classes.

---

## Step 10 — Switch from `createViewSDK()` to `getViewSDK()`

**Question:** the official samples use `getViewSDK()`, but the first version of this app used `createViewSDK()`. Which one is best practice?

**Research:**

| Source | Finding |
|---|---|
| GitHub code search (`forcedotcom`, `salesforce`, `trailheadapps` orgs) | `getViewSDK` appears in 30+ files: every React and Angular embedding sample and its tests. `createViewSDK` appears in **0** files |
| `trailheadapps/multiframework-recipes` history | The samples were added on 2026-09-03 (commit `0321947`), so they are recent, not an old API |
| GA guide | Uses `createViewSDK()`, but only in short snippets that call it once |
| SDK source (`dist/view/index.js`, v12.11.0) | `getViewSDK()` calls `createViewSDK()` **once** and caches the result. Each `createViewSDK()` call creates a **new** instance, and each instance opens its own UI-state and host-event subscriptions |
| GA guide | "At most one active UI-state subscription per session" |
| Deprecation | Neither function is marked `@deprecated` |

Compiled `getViewSDK` from the SDK (names restored):
```js
function getViewSDK(opts) {
  return cached || (cached = createViewSDK(opts).then(sdk => (instance = sdk, sdk))), cached;
}
```

**Decision:** use **`getViewSDK()`**. It matches Salesforce's own samples and is safe to call from anywhere: it can never open a second subscription. `createViewSDK()` is only safe if it is called exactly once.

**Change** in `embedded-account-app/src/main.js`:
```diff
- import { createViewSDK } from '@salesforce/platform-sdk/view';
+ import { getViewSDK } from '@salesforce/platform-sdk/view';
  ...
- const viewSdk = await createViewSDK();
+ // getViewSDK caches one instance, so repeat calls never open a second UI-state subscription.
+ const viewSdk = await getViewSDK();
```

**Verified:** `npx vite build` passed, and the running dev server on `http://localhost:5180` served the updated file.

> **No Salesforce deploy was needed for this change.** The external app runs outside Salesforce (on the Vite dev server now, on your HTTPS host in production), and the iframe loads it fresh on every page load. The LWC and CSP Trusted Site did not change. For production, rebuild with `npm run build` and re-upload `dist/`.

---

## Step 11 — Add the component to the Account page (manual)

1. Make sure the app is running: `cd embedded-account-app && npm run dev`.
2. Open any **Account** record → **⚙ → Edit Page**.
3. Drag **Account Embedded App** onto the page.
4. (Optional) Change **Embedded app URL** in the properties panel.
5. **Save** → **Activate**.

---

## Step 12 — How to check it works

| Action | Expected result |
|---|---|
| Open the Account page | A spinner, then the app shows the Account's fields |
| Edit the Account in Salesforce and save | The app updates by itself, and the "live updates" counter goes up |
| Click **Hot** in the app | Toast "Account updated — Rating set to Hot", and the Rating field changes |
| Stop the dev server and reload | After about 30 s a banner shows the error code (e.g. `bootstrap/HEARTBEAT_TIMEOUT`). See 16.3.1 for the readable version in the Angular wrapper |

> **About "N live updates received from Salesforce":** this counts every snapshot Salesforce sends to the app. On page load it can show about 4 before any edit, because the wrapper's `account` getter creates a new object on each re-render (loading → data arrived → ready). Only one or two of those carry real changes. To count only real changes, rebuild the `account` object only when `record.data` changes.

---

## Step 13 — Second example: the same app in Vue 3 (`embedded-account-vue/`)

**Goal:** show that `lightning-ui-embedding` works with any framework, using the **same** wrapper LWC.

### 13.1 Create the project

Port 5181 was checked and free.

```bash
mkdir embedded-account-vue && cd embedded-account-vue
# package.json with "type": "module" and dev/build/preview scripts
npm install --save vue@^3.5 @salesforce/platform-sdk@^12.11.0
npm install --save-dev vite@^8 @vitejs/plugin-vue@^6
```

Installed: `vue` 3.5.43, `vite` 8.3.3, `@vitejs/plugin-vue` 6.0.9, `@salesforce/platform-sdk` 12.11.0.

### 13.2 Files

| File | Purpose |
|---|---|
| `vite.config.js` | `plugins: [vue()]`, `server: { port: 5181, strictPort: true }` |
| `src/composables/useEmbedding.js` | **All SDK code.** `useUiState()`, `useHostEvent()`, `sendToHost()`, built on `getViewSDK()` |
| `src/App.vue` | Connects the composables to the components; copies host styles; handles the locale |
| `src/components/AccountDetails.vue` | Shows the fields (plain Vue, no SDK) |
| `src/components/RatingPicker.vue` | Hot/Warm/Cold buttons, emits `select` (plain Vue, no SDK) |
| `src/main.js`, `index.html`, `src/style.css`, `.gitignore` | App entry point and shared styles |

**Why a composable plus `getViewSDK()`:** several Vue components can each call `useUiState()` or `sendToHost()`, and they all share **one** cached SDK instance, so there is only ever one UI-state subscription. This is exactly the case from [Step 10](#step-10--switch-from-createviewsdk-to-getviewsdk) where `getViewSDK()` is the right choice.

### 13.3 Trust the new origin

New file `force-app/main/default/cspTrustedSites/AccountEmbeddedVueLocalhost.cspTrustedSite-meta.xml`. It is the same as the first CSP site, but with `<endpointUrl>http://localhost:5181</endpointUrl>`.

```bash
sf project deploy start --dry-run --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedVueLocalhost.cspTrustedSite-meta.xml --wait 30 --json   # Succeeded
sf project deploy start           --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedVueLocalhost.cspTrustedSite-meta.xml --wait 30 --json   # Succeeded
```

**No LWC change was needed.** `accountEmbeddedApp` already takes the app URL as a page property.

### 13.4 Verify

```bash
npx vite build        # ✓ built in 268ms
npm run dev           # VITE v8.3.3 ready — http://localhost:5181/
# App.vue, AccountDetails.vue, RatingPicker.vue, useEmbedding.js all compile (HTTP 200)
```

### 13.5 Use it

In App Builder, set **Embedded app URL** on Account Embedded App to `http://localhost:5181`. Or place a **second** copy of the component, so the plain JS (5180) and Vue (5181) versions run side by side on the same record.

Full guide: [`embedded-account-vue/README.md`](embedded-account-vue/README.md).

> This sharing of one wrapper was later replaced by a dedicated Vue wrapper LWC. See Step 14.

---

## Step 14 — Dedicated wrapper LWC for the Vue app: `accountEmbeddedVueApp`

**Goal:** give the Vue example its own Salesforce component, so admins pick **Account Embedded Vue App** in App Builder and it points to the Vue app by default.

Path: `force-app/main/default/lwc/accountEmbeddedVueApp/`

| File | Content |
|---|---|
| `accountEmbeddedVueApp.html` | Same structure as `accountEmbeddedApp`. Card and iframe titled **Account Insights (Vue)** |
| `accountEmbeddedVueApp.js` | Same contract: `props`, ready/error listeners, `localeInformation`, `ratingchange` → `updateRecord` + toast. `baseUrl` defaults to `http://localhost:5181` |
| `accountEmbeddedVueApp.css` | SLDS 2 styling hooks for the error banner |
| `accountEmbeddedVueApp.js-meta.xml` | Label **Account Embedded Vue App**, Account record page, property **Embedded Vue app URL** |

**Two improvements over `accountEmbeddedApp`:**

1. **No duplicate snapshots.** `account` is now a field reassigned only inside the `@wire` handler, instead of a getter that built a new object on every render:
   ```js
   account = {};

   connectedCallback() {
       this.account = { recordId: this.recordId };
   }

   @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
   wiredRecord({ data, error }) {
       if (data) {
           this.account = { recordId: this.recordId, name: getFieldValue(data, NAME), /* … */ };
       } else if (error) {
           this.errorMessage = error?.body?.message ?? 'Unable to load the Account.';
       }
   }
   ```
   Re-renders (e.g. hiding the spinner) no longer send the app a new snapshot, so the "live updates" counter counts only real record changes. It also shows a banner if the record fails to load.
2. **Validated input from the iframe:**
   ```js
   const ALLOWED_RATINGS = new Set(['Hot', 'Warm', 'Cold']);
   // …
   if (!this.recordId || !ALLOWED_RATINGS.has(rating)) {
       return;
   }
   ```

The description of `AccountEmbeddedVueLocalhost` CSP site was updated to name `accountEmbeddedVueApp`. The `vite.config.js` comment was updated too.

**Checks:** ESLint passed, and VS Code SLDS and XML diagnostics reported no issues for the new bundle.

**Deploy:**
```bash
sf project deploy start --dry-run \
  --source-dir force-app/main/default/lwc/accountEmbeddedVueApp \
  --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedVueLocalhost.cspTrustedSite-meta.xml \
  --wait 30 --json        # Succeeded
sf project deploy start \
  --source-dir force-app/main/default/lwc/accountEmbeddedVueApp \
  --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedVueLocalhost.cspTrustedSite-meta.xml \
  --wait 30 --json        # Succeeded (deploy id 0AfgL00000ZpZXRSA3)
```

> **Small gotcha hit here:** storing the flags in a shell variable (`A="--source-dir … --json"`, then `sf … $A`) printed nothing in zsh, because zsh doesn't split unquoted variables into separate words. Write the flags out in full, or use an array.

**Use it:** Account record → **Edit Page** → drag **Account Embedded Vue App** → **Save** → **Activate**. Keep `npm run dev` running in `embedded-account-vue/`.

---

## Step 15 — Interactive Vue UI with rating colours, and the "Vue JS" label

**Request:** make the Vue UI more interactive, colour the buttons by rating, and show "Vue JS" instead of "Vue". This came after the first screenshot confirmed the Vue app working inside Salesforce on the account *Dickenson plc*.

**Changes (Vue app only, plus a label in the LWC):**

| File | Change |
|---|---|
| `src/components/RatingPicker.vue` | Buttons coloured by rating (`rating--hot/warm/cold`), with a hint line (*High priority / Engaged / Low activity*, *Current*, *Saving…*). Accepts a `pending` prop. Clicking the current rating does nothing |
| `src/components/AccountDetails.vue` | Rating shown as a coloured pill. Website is a link (new tab). Fields that change in a live update briefly highlight (`watch` compares the previous and new `account`) |
| `src/App.vue` | `pendingRating` state: buttons lock and the clicked one shows *Saving…* until `account.rating` from Salesforce matches. Then a "Rating saved as …" message appears. After 8 s it falls back to a warning. Also adds the coloured accent bar (`data-rating`), the connection dot, and the **Vue JS** badge |
| `src/style.css` | Rating tones (Hot `#ba0517`, Warm `#a96404`, Cold `#0b5cab`, with soft tints), hover, focus and pending animations, and `prefers-reduced-motion`. Static values were replaced by SLDS 2 hooks with fallbacks (e.g. `var(--slds-g-radius-border-2, 0.25rem)`) where the SLDS linter suggested one |
| `index.html` | Page title **Account Insights (Vue JS)** |
| `lwc/accountEmbeddedVueApp/accountEmbeddedVueApp.html` | Card title, iframe title and spinner text → **Vue JS** |

**Why the confirmation waits for `props`:** the app can't see the result of `updateRecord`, because that happens in the LWC. The reliable signal is the new rating arriving back through `props`, after `@wire(getRecord)` refreshes. If the save fails, the rating never changes, so the 8 s timeout unlocks the buttons and the LWC's error toast explains why.

**Checks:**
- `npx vite build` passed.
- SLDS linter: all SLDS 2 hook suggestions with an available hook were applied. What remains is informational: values with no hook (font weights, `50%`, `999px`) and legacy SLDS 1 design-token hints.
- Visual check in the browser (connected state simulated in the DOM): the colours, the filled current button and the hover tint render as intended.

**Deploy:** only the LWC label changed on the Salesforce side.
```bash
sf project deploy start --source-dir force-app/main/default/lwc/accountEmbeddedVueApp --wait 30 --json
# → Succeeded (deploy id 0AfgL00000ZpcFBSAZ)
```
The Vue app itself is served by the running dev server (`npm run dev` on 5181), so a page reload picks up the new UI.

---

## Step 16 — Third example: the same app in Angular 22 (`embedded-account-angular/`)

**Goal:** an Angular version with the same behaviour and UI as the Vue one, its own wrapper LWC, its own trusted origin, and its own port.

### 16.1 Scaffold

Checked first: Angular CLI and core are both 22.2.2, and port 5182 was free. (Ports 5180 and 5181 had nothing listening, so the earlier dev servers had stopped.)

```bash
npx -y @angular/cli@22 new embedded-account-angular \
  --style=css --ssr=false --routing=false --zoneless \
  --skip-git --skip-tests --ai-config=none --package-manager=npm --defaults
```

> **Problem hit:** the CLI created the files but its install step failed on npm 12.0.2:
> `npm error code EALLOWSCRIPTS — --allow-scripts is not allowed in project-scoped installs`.
> **Fix:** ran the install directly, which worked (0 vulnerabilities before the SDK was added).

```bash
cd embedded-account-angular
npm install
npm install --save @salesforce/platform-sdk@^12.11.0
npm uninstall @angular/forms @angular/router      # not used by this app
```

Also tidied: `serve.options.port = 5182` in `angular.json`, the debug URL in `.vscode/launch.json` (4200 → 5182), and removed the `test` script and `tsconfig.spec.json`, because `--skip-tests` leaves no test setup behind them.

### 16.2 Files

| File | Purpose |
|---|---|
| `src/app/account.ts` | Types: `Rating`, `AccountProps`, `AccountUiState extends UiState` |
| `src/app/embedding.ts` | **All SDK code.** Root-provided `Embedding` service on `getViewSDK()`: signals `account`, `styles`, `embedded`, `updates`, plus `onHostEvent()` and `sendToHost()` |
| `src/app/app.ts` / `app.html` | Root component: pending/feedback state, 8 s confirmation timeout, host styles, locale |
| `src/app/account-details/` | Fields, rating pill, website link, change highlight (an `effect()` compares the previous and new account) |
| `src/app/rating-picker/` | Coloured Hot/Warm/Cold buttons with `current`, `pending`, `disabled` inputs and a `ratingSelect` output |
| `src/styles.css` | The Vue app's stylesheet (SLDS 2 hooks with fallbacks), plus `display: block` for the Angular host elements |

**Angular-specific choices:**
- **Standalone components, signals, zoneless.** The SDK's `subscribe` callback sets a signal, and Angular re-renders what reads it. There is no `zone.js` and no manual change detection.
- **Built-in control flow** (`@if`, `@for`) in the templates.
- **One service instance + `getViewSDK()`**, so there is one connection and one UI-state subscription (see [Step 10](#step-10--switch-from-createviewsdk-to-getviewsdk)).
- **Typed SDK use.** The SDK types `getUiState`, `dispatchEvent` and `addEventListener` as optional members of `ViewSDK`, so every call is `?.`-guarded and `getUiState<AccountUiState>()` types the props.
- The output is named `ratingSelect`, not `select`, to avoid clashing with the native DOM `select` event.

### 16.3 Salesforce side

| File | Content |
|---|---|
| `lwc/accountEmbeddedAngularApp/` | Same code as `accountEmbeddedVueApp` (props sent only on record change, validated `ratingchange`). Label **Account Embedded Angular App**, titles "Account Insights (Angular)", `baseUrl` default `http://localhost:5182` |
| `cspTrustedSites/AccountEmbeddedAngularLocalhost.cspTrustedSite-meta.xml` | frame-src trust for `http://localhost:5182` |

ESLint passed, and the VS Code SLDS diagnostics reported no issues for the new bundle.

```bash
sf project deploy start --dry-run \
  --source-dir force-app/main/default/lwc/accountEmbeddedAngularApp \
  --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedAngularLocalhost.cspTrustedSite-meta.xml \
  --wait 30 --json        # Succeeded
sf project deploy start \
  --source-dir force-app/main/default/lwc/accountEmbeddedAngularApp \
  --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedAngularLocalhost.cspTrustedSite-meta.xml \
  --wait 30 --json        # Succeeded (deploy id 0AfgL00000a24duSAA)
```

### 16.3.1 Readable "app isn't available" banner (Angular wrapper only)

With the Angular dev server stopped, the wrapper's error banner appeared as an empty crimson box with only an icon. The message was in the DOM, but invisible: `--slds-g-color-error-1` (background) and `--slds-g-color-on-error-1` (text) both resolve to `#b60554` in light mode.

Changes in `lwc/accountEmbeddedAngularApp/`:

| File | Change |
|---|---|
| `.css` | Background stays `--slds-g-color-error-1` (solid crimson); text changed to `--slds-g-color-neutral-base-100` (white in light mode); new `.error-title` |
| `.js` | `errorMessage` string replaced by an `error` object (`title`, `message`) worded for non-technical users: no URL, error code or developer terms. `HEARTBEAT_TIMEOUT` gives "Account Insights is temporarily unavailable"; other codes give "Something went wrong while loading Account Insights". `hasLoadFailed` hides the empty embedding frame. New `logError` writes the raw `phase/code: message` and the `baseUrl` to the browser console |
| `.html` | Banner shows a bold title and one message line, laid out with the SLDS `slds-media` utility classes. Custom `display: flex` / `align-items` in the CSS made the SLDS validator report two `UTILITY_CLASS` errors, so they were removed |

Verified on an Account record page with nothing listening on 5182: after the 30 s heartbeat timeout the banner read "Account Insights is temporarily unavailable / Nothing is wrong with this account or your data — only this section couldn't be displayed. Please refresh the page in a few minutes. If you still see this message, contact your Salesforce administrator.", text `rgb(255, 255, 255)` on `rgb(182, 5, 84)`. The console showed `[accountEmbeddedAngularApp] Embedded app at http://localhost:5182 failed to load. bootstrap/HEARTBEAT_TIMEOUT: …`. It needed a hard reload (`⇧⌘R`) after the deploy; normal reloads kept serving the cached bundle.

The React, Vue, Next.js and External App wrappers still have the original banner code and the same invisible-text problem.

### 16.4 Verify

```bash
npx ng build      # Application bundle generation complete — main 150.13 kB (44.72 kB transfer)
npm start         # ng serve → http://localhost:5182 (HTTP 200)
```

**Visual check in the browser, outside Salesforce.** The host was simulated by setting the service's state signal through Angular's dev-mode debug API (`ng.getComponent`), and the rating buttons were clicked for real.

| State | Result |
|---|---|
| Not embedded | Grey dot, empty fields, buttons disabled |
| Connected (Hot) | Green dot, fields, Hot pill, website link `https://…`, Hot filled, red accent bar |
| Click a rating | `ratingchange` sent with `{ rating }`, "Saving…" on the clicked button, all buttons locked |
| Host confirms | "Rating saved as Cold", buttons unlock, accent bar and current button switch |
| Host never confirms | After 8.6 s: "No confirmation from Salesforce — check the toast for details.", buttons unlock |
| Live field change | Changed fields (Rating, Industry) highlighted |

> **A false alarm during this check:** the first "host confirms" test showed an empty feedback line with the warning style. The steps had taken longer than the 8 s timeout, so the timeout path had already fired and cleared. Re-running both paths inside a single script (confirm after 0.3 s, and separately wait past 8 s) showed both working.

**Not verified:** the Angular app inside a real Salesforce page. The handshake, real `props` and the save through the wrapper still need a check in the org.

### 16.5 Use it

Account record → **Edit Page** → drag **Account Embedded Angular App** → **Save** → **Activate**. Keep `npm start` running in `embedded-account-angular/`.

Full guide: [`embedded-account-angular/README.md`](embedded-account-angular/README.md).

---

## Step 17 — Convert the first example to React and rename it

**Why:** the first example (`embedded-account-app/` + `accountEmbeddedApp`) was plain JavaScript with no framework, while the other two were named for theirs (Vue, Angular). To get a matching React / Vue / Angular set, the app was rebuilt in React and everything was renamed.

| | Before | After |
|---|---|---|
| App folder | `embedded-account-app/` (plain JS, Vite 7) | `embedded-account-react/` (React 19.3, Vite 8) |
| Wrapper LWC | `accountEmbeddedApp` — label *Account Embedded App* | `accountEmbeddedReactApp` — label *Account Embedded React App* |
| CSP Trusted Site | `AccountEmbeddedAppLocalhost` | `AccountEmbeddedReactLocalhost` |
| Port | 5180 | 5180 (unchanged) |

### 17.1 App

Port 5180 had nothing listening, so the folder could be moved safely.

```bash
mv embedded-account-app embedded-account-react
cd embedded-account-react
# package.json "name" → embedded-account-react
npm install --save react@^19 react-dom@^19
npm install --save-dev vite@^8 @vitejs/plugin-react@^6
rm src/main.js          # the plain JS entry point
```

| File | Purpose |
|---|---|
| `vite.config.js` | `plugins: [react()]`, port 5180 with `strictPort` |
| `index.html` | `#root`, title **Account Insights (React)** |
| `src/main.jsx` | `createRoot(...).render(<StrictMode><App /></StrictMode>)` |
| `src/hooks/useEmbedding.js` | **All SDK code.** `useUiState()`, `useHostEvent()`, `sendToHost()`, built on `getViewSDK()` |
| `src/App.jsx` | Pending/feedback state, 8 s confirmation timeout, host styles, locale, **React** badge |
| `src/components/AccountDetails.jsx` | Fields, rating pill, website link, change highlight |
| `src/components/RatingPicker.jsx` | Coloured Hot/Warm/Cold buttons, saving state |
| `src/style.css` | The same stylesheet as the Vue app |

This also brings the first example up to the same UI as Vue and Angular. The plain JS version never had the rating colours, saving state or highlights.

**Two mistakes caught before the build:**
- `AccountDetails` first wrapped each label/value pair in a `<div>` to carry the React `key`. That would have broken the two-column CSS grid, which expects `<dt>`/`<dd>` as direct children. It was changed to a keyed `<Fragment>`.
- The timeout first called `showFeedback` inside a `setState` updater function. Updaters must be pure (React `StrictMode` runs them twice in development), so a ref now mirrors the pending rating and the timeout reads that.

### 17.2 Salesforce side

`accountEmbeddedReactApp` was generated from `accountEmbeddedAngularApp` with the names, titles and port swapped. So the React wrapper now has the two improvements the original lacked: props are sent only when the record data changes, and `ratingchange` is accepted only for `Hot`, `Warm` or `Cold`.

The old local files were removed as part of the rename: `lwc/accountEmbeddedApp/` and `cspTrustedSites/AccountEmbeddedAppLocalhost.cspTrustedSite-meta.xml`. Neither was tracked in git. The original wrapper code is still shown in Step 3.

ESLint passed for the new bundle.

```bash
sf project deploy start --dry-run --source-dir force-app/main/default/lwc/accountEmbeddedReactApp --wait 30 --json   # Succeeded
sf project deploy start           --source-dir force-app/main/default/lwc/accountEmbeddedReactApp --wait 30 --json   # Succeeded (0AfgL00000a2CQ9SAM)

sf project deploy start --dry-run --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedReactLocalhost.cspTrustedSite-meta.xml --wait 30 --json   # Succeeded
sf project deploy start           --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedReactLocalhost.cspTrustedSite-meta.xml --wait 30 --json   # Succeeded (0AfgL00000a2CYDSA2)
```

> **Finding:** Salesforce accepted a second CSP Trusted Site for the same address (`http://localhost:5180`), so the new site could be added without deleting the old one first.

### 17.3 Still in the org under the old names (cleaned up later in Step 19)

Nothing was deleted from the org. These two remain there and are no longer in the local source:

| Org component | Status |
|---|---|
| LWC `accountEmbeddedApp` (*Account Embedded App*) | Old version. If it is on the Account page, it still works, because it loads `http://localhost:5180`, which now serves the React app |
| CSP Trusted Site `AccountEmbeddedAppLocalhost` | Duplicate of `AccountEmbeddedReactLocalhost` |

To finish the rename in the org: replace *Account Embedded App* with *Account Embedded React App* on the Account page, then delete both old components (a destructive deploy, or Setup → Lightning Components and Setup → Trusted URLs).

### 17.4 Verify

```bash
npx vite build        # ✓ built — index.js 245.78 kB (77.10 kB gzip)
npm run dev           # http://localhost:5180 (HTTP 200)
```

**Visual check in the browser, outside Salesforce.** The host was simulated by calling the `App` component's own state setters through its React fiber, the SDK's `dispatchEvent` was replaced with a recorder, and the rating buttons were clicked for real.

| State | Result |
|---|---|
| Not embedded | Grey dot, empty fields, buttons disabled, two-column grid intact |
| Connected (Hot) | Green dot, fields, Hot pill, website link `https://…`, Hot filled, red accent bar |
| Click Warm | `ratingchange` sent with `{ rating: 'Warm' }` (`bubbles: false`), "Saving…", all buttons locked |
| Host confirms | "Rating saved as Warm", buttons unlock, amber accent bar; Rating and Industry highlighted; message and highlight clear after ~3 s |
| Click the current rating | Nothing sent |
| Host never confirms | After 8.6 s: "No confirmation from Salesforce — check the toast for details.", buttons unlock |

**Not verified:** the React app inside a real Salesforce page.

### 17.5 Docs

- `embedded-account-react/README.md` was rewritten for React. It replaces the general how-to guide that was written around the plain JS code, and keeps that guide's SDK reference and troubleshooting tables.
- `embedded-account-vue/README.md` and `embedded-account-angular/README.md` now compare against the React example and use the new names.

---

## Step 18 — Fourth example: plain JavaScript, no framework (`embedded-account-external-app/`)

**Why:** after Step 17 turned the original plain JavaScript app into React, there was no framework-free example left. This one shows the embedding with nothing else in the way, and has the same UI as the other three.

| Item | Value |
|---|---|
| App folder | `embedded-account-external-app/` (Vite 8 as dev server and bundler only, no UI library) |
| Port | 5183 (checked free) |
| Wrapper LWC | `accountEmbeddedExternalApp` — label *Account Embedded External App*, title "Account Insights (External App)" |
| CSP Trusted Site | `AccountEmbeddedExternalLocalhost` |

### 18.1 App

```bash
mkdir -p embedded-account-external-app/src && cd embedded-account-external-app
# package.json ("type": "module", dev/build/preview scripts) and vite.config.js (port 5183, strictPort, es2022)
npm install --save @salesforce/platform-sdk@^12.11.0
npm install --save-dev vite@^8
```

| File | Purpose |
|---|---|
| `index.html` | All the markup: header with a **JavaScript** badge, the fields, and the three rating buttons |
| `src/embedding.js` | **All SDK code.** `watchUiState()`, `onHostEvent()`, `sendToHost()`, built on `getViewSDK()` |
| `src/main.js` | A `state` object and a `render()` function that writes it to the DOM; pending/feedback logic, 8 s timeout, change highlight |
| `src/style.css` | The same stylesheet as the other examples |

Points specific to the no-framework version:
- `render()` rewrites the whole view from `state` each time, which is what a framework would otherwise do.
- Field values are written as **text nodes** (`textContent`, `createElement`), never as HTML, because they come from Salesforce records.
- The page shows static text "Connecting to Salesforce…" until the SDK resolves. An early version called `render()` before that, which would have flashed "Not embedded" first. That call was removed.

### 18.2 Salesforce side

`accountEmbeddedExternalApp` and `AccountEmbeddedExternalLocalhost` were generated from the React ones with the names, titles and port swapped. ESLint passed.

```bash
sf project deploy start --dry-run \
  --source-dir force-app/main/default/lwc/accountEmbeddedExternalApp \
  --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedExternalLocalhost.cspTrustedSite-meta.xml \
  --wait 30 --json        # Succeeded
sf project deploy start \
  --source-dir force-app/main/default/lwc/accountEmbeddedExternalApp \
  --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedExternalLocalhost.cspTrustedSite-meta.xml \
  --wait 30 --json        # Succeeded (deploy id 0AfgL00000a20DiSAI)
```

### 18.3 Verify

```bash
npx vite build        # ✓ built — index.js 25.49 kB (8.68 kB gzip)
npm run dev           # http://localhost:5183 (HTTP 200)
```

Built JavaScript size of the four examples: External App 25 kB, Vue 88 kB, Angular 150 kB, React 246 kB.

**Visual check in the browser, outside Salesforce, with a fake host.** A plain JS app has no framework state to reach into, so the test attached fake `getUiState`, `dispatchEvent` and `addEventListener` functions to the cached SDK object **before** the app loaded. This was done on a blank same-origin page (`/package.json`): import the SDK module, patch it, then write the app's `index.html` into the document. The app's real subscription code then ran against the fake host, and the buttons were clicked for real.

| State | Result |
|---|---|
| Not embedded (normal load) | Grey dot, empty fields, buttons disabled |
| Embedded, no record | "Embedded — place this component on an Account record page.", host CSS variable copied onto the page |
| Connected (Hot) | Green dot, fields, Hot pill, website link `https://…`, Hot filled, red accent bar, nothing highlighted on first load |
| `localeInformation` event | `<html lang>` became `fr` |
| Click Warm | `ratingchange` sent with `{ rating: 'Warm' }`, "Saving…", all buttons locked |
| Host confirms | "Rating saved as Warm", buttons unlock, amber accent bar, Rating and Industry highlighted, counter "2 live updates"; message and highlight clear after ~3 s |
| Click the current rating | Nothing sent |
| Host never confirms | After ~9 s: "No confirmation from Salesforce — check the toast for details.", buttons unlock |

**Not verified:** the app inside a real Salesforce page.

### 18.4 Docs

- New `embedded-account-external-app/README.md`.
- The React, Vue and Angular READMEs each got a pointer to this fourth example.

---

## Step 19 — Remove the old `accountEmbeddedApp` from the org

**Trigger:** the App Builder component list for the Account record page showed five entries: Angular, External, React, Vue, and an extra **Account Embedded App**. Only the four named examples should exist.

**Cause:** Step 17 deployed the renamed React component but left the old one in the org, because deleting is not reversible and had not been confirmed.

### 19.1 Find where it is used

```bash
sf data query --use-tooling-api -q "SELECT Id, DeveloperName, MasterLabel, LastModifiedDate FROM LightningComponentBundle WHERE DeveloperName LIKE 'accountEmbedded%' ORDER BY DeveloperName" --json
sf data query --use-tooling-api -q "SELECT MetadataComponentName, MetadataComponentType, RefMetadataComponentId FROM MetadataComponentDependency WHERE RefMetadataComponentId IN ('<ids>')" --json
```

Result: `accountEmbeddedApp` (last modified 2026-10-08) was still there, and the FlexiPage **Account_Record_Page** used two of the components: `accountEmbeddedVueApp` and the old `accountEmbeddedApp`.

> **Query gotcha:** filtering `MetadataComponentDependency` by `RefMetadataComponentName` or `MetadataComponentName` returned "… is unknown". Filtering by `RefMetadataComponentId` worked.

Salesforce does not delete a component that a page still uses, so the page had to change first.

### 19.2 Swap the component on the page

```bash
sf project retrieve start --metadata FlexiPage:Account_Record_Page --json
```

This added `force-app/main/default/flexipages/Account_Record_Page.flexipage-meta.xml` to the project. Two lines were changed, in the same slot on the page, keeping its `baseUrl` of `http://localhost:5180`:

```diff
- <componentName>accountEmbeddedApp</componentName>
- <identifier>c_accountEmbeddedApp</identifier>
+ <componentName>accountEmbeddedReactApp</componentName>
+ <identifier>c_accountEmbeddedReactApp</identifier>
```

```bash
sf project deploy start --dry-run --source-dir force-app/main/default/flexipages/Account_Record_Page.flexipage-meta.xml --wait 30 --json   # Succeeded
sf project deploy start           --source-dir force-app/main/default/flexipages/Account_Record_Page.flexipage-meta.xml --wait 30 --json   # Succeeded (0AfgL00000a2JeXSAU)
```

### 19.3 Delete the old component and trusted site

Checks first: the org is a Developer Edition (the deploy gate classifies it as `trial`, not production), and nothing in `force-app/` referenced the old names.

The manifest was written to its own folder, `manifest/remove-old-embedded-app/`, so the existing `manifest/package.xml` was not touched:

- `package.xml` — empty, version 67.0
- `destructiveChangesPost.xml` — `LightningComponentBundle: accountEmbeddedApp` and `CspTrustedSite: AccountEmbeddedAppLocalhost`

```bash
# Validate
sf project deploy start --dry-run \
  --manifest manifest/remove-old-embedded-app/package.xml \
  --post-destructive-changes manifest/remove-old-embedded-app/destructiveChangesPost.xml \
  --wait 30 --json        # Succeeded: both components deleted=true, nothing else

# Delete (no --purge-on-delete)
sf project deploy start \
  --manifest manifest/remove-old-embedded-app/package.xml \
  --post-destructive-changes manifest/remove-old-embedded-app/destructiveChangesPost.xml \
  --wait 30 --json        # Succeeded (0AfgL00000a2JoDSAU)
```

### 19.4 Org state afterwards (queried)

| Component | Trusted site | Address |
|---|---|---|
| Account Embedded React App (`accountEmbeddedReactApp`) | `AccountEmbeddedReactLocalhost` | `http://localhost:5180` |
| Account Embedded Vue App (`accountEmbeddedVueApp`) | `AccountEmbeddedVueLocalhost` | `http://localhost:5181` |
| Account Embedded Angular App (`accountEmbeddedAngularApp`) | `AccountEmbeddedAngularLocalhost` | `http://localhost:5182` |
| Account Embedded External App (`accountEmbeddedExternalApp`) | `AccountEmbeddedExternalLocalhost` | `http://localhost:5183` |

**Account_Record_Page** now uses `accountEmbeddedVueApp` and `accountEmbeddedReactApp`. The Angular and External components are deployed but not placed on the page.

**Not verified:** the page was not opened in a browser after the swap.

---

## Step 20 — Fifth example: Next.js 16 (`embedded-account-nextjs/`)

| Item | Value |
|---|---|
| App folder | `embedded-account-nextjs/` (Next.js 16.4, App Router, React 19.3, JavaScript) |
| Port | 5184 (checked free) |
| Wrapper LWC | `accountEmbeddedNextjsApp` — label *Account Embedded Next.js App*, title "Account Insights (Next.js)" |
| CSP Trusted Site | `AccountEmbeddedNextjsLocalhost` |

### 20.1 The Next.js-specific question: server rendering

Next.js renders pages on the server first, where there is no Salesforce host. So the first check was whether the SDK can even be imported in Node:

```bash
node --input-type=module -e "await import('@salesforce/platform-sdk/ui-embedding'); const { getViewSDK } = await import('@salesforce/platform-sdk/view'); console.log(Object.keys(await getViewSDK()))"
# import ok for both entry points; getViewSDK() on the server resolves to an empty object: []
```

**Decision:** normal `import` statements are safe. The SDK is only *called* in the browser, inside `useEffect` and event handlers. Dynamic imports or `ssr: false` were not needed.

### 20.2 App

The project was set up by hand, not with `create-next-app`, to keep it as small as the other examples.

```bash
mkdir -p embedded-account-nextjs/{app,components,hooks} && cd embedded-account-nextjs
# package.json: "dev": "next dev -p 5184", "build": "next build"
npm install --save next@^16 react@^19 react-dom@^19 @salesforce/platform-sdk@^12.11.0
```

| File | Purpose |
|---|---|
| `next.config.mjs` | `output: 'export'` (static files in `out/`), `devIndicators: false`, `turbopack.root` pinned to this folder |
| `app/layout.jsx` | `<html>`, `<body>`, title **Account Insights (Next.js)**, global CSS |
| `app/page.jsx` | Server component that renders `<AccountInsights />` |
| `app/globals.css` | The same stylesheet as the other examples |
| `components/AccountInsights.jsx` | `'use client'`. The React example's `App.jsx`, with a **Next.js** badge and a "Connecting to Salesforce…" state |
| `components/AccountDetails.jsx`, `RatingPicker.jsx` | Copied unchanged from the React example |
| `hooks/useEmbedding.js` | `'use client'`. The React hooks plus a `ready` flag |

**Differences from the React example:**
- `'use client'` on the root component and the hooks file.
- A `ready` flag in `useUiState()`. It is `false` on the server and until the SDK resolves in the browser, so the prerendered HTML says "Connecting to Salesforce…" instead of a wrong "Not embedded".
- `.gitignore` covers `.next/`, `out/` and `next-env.d.ts`.

> **Problem hit:** the first `next build` warned that it had detected additional lockfiles and inferred the parent folder as the workspace root, because the main project has its own `package-lock.json`. **Fix:** `turbopack: { root: import.meta.dirname }` in `next.config.mjs`. The warning went away.
>
> A `start` script using `npx serve out` was removed before finishing, because it would silently download another package. With `output: 'export'`, `next start` does not apply; the `out/` folder is served by any static host.

### 20.3 Salesforce side

`accountEmbeddedNextjsApp` and `AccountEmbeddedNextjsLocalhost` were generated from the React ones with the names, titles and port swapped. ESLint passed.

```bash
sf project deploy start --dry-run \
  --source-dir force-app/main/default/lwc/accountEmbeddedNextjsApp \
  --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedNextjsLocalhost.cspTrustedSite-meta.xml \
  --wait 30 --json        # Succeeded
sf project deploy start \
  --source-dir force-app/main/default/lwc/accountEmbeddedNextjsApp \
  --source-dir force-app/main/default/cspTrustedSites/AccountEmbeddedNextjsLocalhost.cspTrustedSite-meta.xml \
  --wait 30 --json        # Succeeded (deploy id 0AfgL00000a2KifSAE)
```

### 20.4 Verify

```bash
npx next build        # ✓ Compiled successfully; "/" prerendered as static content
npm run dev           # http://localhost:5184 (HTTP 200)
```

`out/index.html` contains "Connecting to Salesforce…", confirming the prerendered state.

**Visual check in the browser against the dev server, outside Salesforce.** The host was simulated through the `AccountInsights` component's state setters (via its React fiber), and the buttons were clicked for real.

| State | Result |
|---|---|
| Page load | No hydration warnings in the console after a reload with tracking on |
| Not embedded | Grey dot, empty fields, buttons disabled, no Next.js dev badge visible |
| Connected (Hot) | Green dot, fields, Hot pill, website link `https://…`, Hot filled, red accent bar |
| Click Warm | "Saving…", all buttons locked |
| Host confirms | "Rating saved as Warm", buttons unlock, amber accent bar, Rating and Industry highlighted; message and highlight clear after ~3 s |
| Click the current rating | Nothing sent |
| Event sent | One `ratingchange` `CustomEvent` with `{ rating: 'Hot' }`, `bubbles: false`, `composed: false` |
| Host never confirms | After ~9 s: "No confirmation from Salesforce — check the toast for details.", buttons unlock |

> **Two test problems, both in the test and not the app:**
> 1. A recorder that wrapped the `CustomEvent` constructor captured nothing. Outside Salesforce the SDK object has no `dispatchEvent`, and `sdk.dispatchEvent?.(new CustomEvent(…))` does not evaluate its arguments when the function is missing, so no event was ever built. The React test had not hit this because it replaced `dispatchEvent` on the SDK object directly, which a bundled Next.js app does not expose. **Fix:** temporarily define a recording `dispatchEvent` on `Object.prototype`, which the empty SDK object inherits, then remove it.
> 2. The first timeout check read the page 19 s after the click, by which time the warning had already shown and cleared. It was rerun inside one script and read at 9.2 s.

**Not verified:** the app inside a real Salesforce page, and the static `out/` build being served and embedded (only the dev server was opened in a browser).

### 20.5 Docs

- New `embedded-account-nextjs/README.md`, including a section on what is different about Next.js.
- The React, Vue, Angular and External App READMEs each got a pointer to this example.

---

## Final file list

```
force-app/main/default/
├── flexipages/
│   └── Account_Record_Page.flexipage-meta.xml               (retrieved in Step 19; uses the Vue and React wrappers)
├── cspTrustedSites/
│   ├── AccountEmbeddedReactLocalhost.cspTrustedSite-meta.xml (frame-src trust for localhost:5180)
│   ├── AccountEmbeddedVueLocalhost.cspTrustedSite-meta.xml   (frame-src trust for localhost:5181)
│   ├── AccountEmbeddedAngularLocalhost.cspTrustedSite-meta.xml (frame-src trust for localhost:5182)
│   ├── AccountEmbeddedExternalLocalhost.cspTrustedSite-meta.xml (frame-src trust for localhost:5183)
│   └── AccountEmbeddedNextjsLocalhost.cspTrustedSite-meta.xml (frame-src trust for localhost:5184)
├── lwc/accountEmbeddedReactApp/        (wrapper for the React app, default URL localhost:5180)
│   ├── accountEmbeddedReactApp.html   (<lightning-ui-embedding> wrapper)
│   ├── accountEmbeddedReactApp.js     (props set only on record change, lifecycle events, validated ratingchange → updateRecord)
│   ├── accountEmbeddedReactApp.css    (SLDS 2 styling hooks)
│   └── accountEmbeddedReactApp.js-meta.xml (Account record page target, baseUrl property)
├── lwc/accountEmbeddedVueApp/          (wrapper for the Vue app, default URL localhost:5181)
│   ├── accountEmbeddedVueApp.html
│   ├── accountEmbeddedVueApp.js       (props set only on record change, validated ratingchange)
│   ├── accountEmbeddedVueApp.css
│   └── accountEmbeddedVueApp.js-meta.xml
├── lwc/accountEmbeddedAngularApp/      (wrapper for the Angular app, default URL localhost:5182)
│   ├── accountEmbeddedAngularApp.html
│   ├── accountEmbeddedAngularApp.js
│   ├── accountEmbeddedAngularApp.css
│   └── accountEmbeddedAngularApp.js-meta.xml
├── lwc/accountEmbeddedExternalApp/     (wrapper for the plain JS app, default URL localhost:5183)
│   ├── accountEmbeddedExternalApp.html
│   ├── accountEmbeddedExternalApp.js
│   ├── accountEmbeddedExternalApp.css
│   └── accountEmbeddedExternalApp.js-meta.xml
└── lwc/accountEmbeddedNextjsApp/       (wrapper for the Next.js app, default URL localhost:5184)
    ├── accountEmbeddedNextjsApp.html
    ├── accountEmbeddedNextjsApp.js
    ├── accountEmbeddedNextjsApp.css
    └── accountEmbeddedNextjsApp.js-meta.xml

embedded-account-react/                 (React 19 app, not deployed to Salesforce; was embedded-account-app/)
├── package.json
├── vite.config.js
├── index.html
├── src/main.jsx
├── src/App.jsx
├── src/style.css
├── src/hooks/useEmbedding.js
├── src/components/AccountDetails.jsx
├── src/components/RatingPicker.jsx
├── README.md
└── .gitignore

embedded-account-vue/                   (Vue 3 version of the same app, not deployed to Salesforce)
├── package.json
├── vite.config.js
├── index.html
├── src/main.js
├── src/App.vue
├── src/style.css
├── src/composables/useEmbedding.js
├── src/components/AccountDetails.vue
├── src/components/RatingPicker.vue
├── README.md
└── .gitignore

embedded-account-angular/               (Angular 22 version of the same app, not deployed to Salesforce)
├── angular.json                        (dev server port 5182)
├── package.json
├── src/index.html
├── src/main.ts
├── src/styles.css
├── src/app/app.config.ts
├── src/app/app.ts + app.html
├── src/app/account.ts
├── src/app/embedding.ts
├── src/app/account-details/account-details.ts + .html
├── src/app/rating-picker/rating-picker.ts + .html
├── README.md
└── .gitignore

embedded-account-external-app/          (plain JavaScript, no framework; not deployed to Salesforce)
├── package.json
├── vite.config.js
├── index.html
├── src/embedding.js
├── src/main.js
├── src/style.css
├── README.md
└── .gitignore

embedded-account-nextjs/                (Next.js 16 app, not deployed to Salesforce)
├── next.config.mjs
├── package.json
├── app/layout.jsx
├── app/page.jsx
├── app/globals.css
├── components/AccountInsights.jsx
├── components/AccountDetails.jsx
├── components/RatingPicker.jsx
├── hooks/useEmbedding.js
├── README.md
└── .gitignore

manifest/remove-old-embedded-app/       (Step 19: the manifest used to delete the old component and site)
├── package.xml
└── destructiveChangesPost.xml

.gitignore                              (added .next/)
```

---

## Step 21 — SLDS 2 CSS cleanup across all LWC components (2026-10-14)

**Problem:** the SLDS 2 extension reported `SLDS/UTILITY_CLASS` errors. Custom CSS used `display: flex`, `align-items`, `flex-direction` and `padding: 0` where SLDS utility classes exist. `employeeList`, `opportunityList` and `opportunityInputForm` also had hardcoded hex colours, px/rem values, `rgba` shadows, gradients and a hardcoded font family, none of which work in dark mode or with theming.

**Bug fixed along the way:** the React, Vue, Next.js and External wrappers paired `--slds-g-color-on-error-1` text with an `--slds-g-color-error-1` background. In light mode those are the same red, so the error text was invisible. The Angular wrapper had already noted this.

**Rule applied:** SLDS blueprints and utility classes first. Custom CSS only for what no class covers, and then only `--slds-g-*` global hooks, with no hardcoded fallbacks.

| Component | Change | CSS left |
|---|---|---|
| `accountEmbedded{React,Vue,Nextjs,External,Angular}App` | Error banner → SLDS **scoped notification** blueprint (`slds-scoped-notification slds-media slds-media_center slds-theme_error`). The theme sets accessible text colour in light and dark mode. Angular's title → `<strong>`. | **none**: the 5 `.css` files were removed (`git rm`) |
| `templateExpressionsDemo` | Heading/summary/list/row layout → `slds-text-heading_small`, `slds-text-color_weak`, `slds-grid slds-grid_align-spread slds-grid_vertical-align-center`, spacing utilities | Stock-status accent (`.item`, `.item_out-of-stock`, `.item-qty`) using hooks only |
| `employeeList`, `opportunityList` | Card → `slds-box` + `slds-media`. The select button moved into `slds-media__figure_reverse`, which removed `position: absolute` and the `padding-right` workaround. Text → `slds-text-heading_small`, `slds-text-body_small`, `slds-text-color_weak`, `slds-hyphenate`. Pagination → `slds-grid … slds-border_top`. | `.list-card:hover` shadow (`--slds-g-shadow-2`), plus `.detail-emphasis` weight in opportunityList |
| `opportunityInputForm` | Header → `slds-border_bottom` + `slds-text-heading_medium`. Gradient icon wrapper removed (the standard icon has its own colour). Label rows/icons → spacing utilities. Unused `.form-actions` removed. | `.form-wrapper` surface (`--slds-g-color-surface-container-1`, `--slds-g-radius-border-3`, `--slds-g-shadow-2`) |

**Kept:** `data-emp-id` / `data-opp-id` (read by the JS click handlers) and all JS behaviour. No JS files changed.

**Visual changes to expect:** the gradients and the custom blue label colours are gone (SLDS neutral styling instead). The Account name in `opportunityList` uses the default text colour instead of dark blue. The amount stays bold.

**Verified:**
```bash
# VS Code SLDS diagnostics on every changed CSS/HTML file → 0 problems
sf project deploy start --dry-run --wait 30 --json \
  --source-dir force-app/main/default/lwc/<each of the 9 bundles>   # Succeeded, 9/9 components, 0 errors
```
Local Lightning Preview rendered `employeeList` (empty state) correctly.
- **Not visually checked:** cards with data. `employeeList`/`opportunityList` get data only through `@api value` from Agentforce, so check them in an agent response or on a page with data.
- **Not visually checked:** `templateExpressionsDemo`. Its preview is blank because the org now serves API **68.0**, but the local `lexBundler.js` patch is only in the `sfdx-local-dev-dist-67.0` folder (see the second-brain how-to `fix-lwc-preview-blank-template-expressions`).

---

## Before production

1. Build the app (`npm run build`) and host `dist/` on an **HTTPS** domain you own.
2. Add a CSP Trusted Site for that HTTPS origin with **frame-src**, and deactivate the localhost one.
3. Set **Embedded app URL** in App Builder to the HTTPS origin.
4. Validate event data before acting on it, e.g. allow only the Rating picklist values.

---

## References

- [Get Started with UI Embedding](https://developer.salesforce.com/docs/platform/microfrontend/guide/get-started.html)
- [Exchange Data Between the Page and an Embedded App](https://developer.salesforce.com/docs/platform/microfrontend/guide/exchange-data.html)
- [Build the Embedding Bridge Without a Salesforce Package](https://developer.salesforce.com/docs/platform/microfrontend/guide/package-free-bridge.html)
- [UI Embedding Error Codes](https://developer.salesforce.com/docs/platform/microfrontend/references/microfrontend-error-codes/error-codes.html)
- [lightning-ui-embedding component reference](https://developer.salesforce.com/docs/platform/lightning-component-reference/guide/lightning-ui-embedding.html)
- [trailheadapps/multiframework-recipes — microfrontend-recipes](https://github.com/trailheadapps/multiframework-recipes/tree/main/force-app/main/microfrontend-recipes)
