# Project health: errors, warnings and deprecations

Goal: the whole `ashish-rk` project free of errors, warnings and deprecated usage, on current versions.
Started 2026-10-14. This file tracks what was measured, what was fixed, and what is left.

## How health is measured

| Check | Command | Covers |
|---|---|---|
| Code Analyzer (PMD, ESLint, SLDS, RetireJS, CPD) | `sf code-analyzer run --workspace force-app --rule-selector Recommended --config-file code-analyzer.yml` | Apex, LWC, React UI bundle source |
| LWC lint | `npx eslint "force-app/**/{aura,lwc}/**/*.js"` | LWC/Aura JS |
| LWC unit tests | `npm test` | `force-app/main/default/lwc/**/__tests__` |
| UI bundles | in each `uiBundles/<bundle>`: `npx tsc -b`, `npx eslint .`, `npx vitest run`, `npm run build` | React apps |
| Apex compile + tests | `sf project deploy validate --source-dir force-app/main/default/classes --test-level RunLocalTests` | Compiles all Apex and runs every local test. **Changes nothing in the org.** |
| VS Code Problems panel | — | Open files only. Not a full check. |

`code-analyzer.yml` ignores only generated or third-party code: `uiBundles/*/dist`, `build`, `node_modules`, Node tooling of the bundles (checked by their own lint/tsc), and `*.d.ts`. It also disables `react/prop-types` (the bundles are TypeScript).

## Baseline (2026-10-14, before fixes)

- Code Analyzer: **5,744** findings. 4,707 of them came from built `dist/` output, leaving 1,037 real ones.
- Apex: **9 failing tests**; org-wide coverage **53%** (deploys need 75%).
- VS Code: `lwc/jsconfig.json` — `baseUrl` is deprecated (stops working in TypeScript 7).

## Fixed so far

| Area | Change | Verified |
|---|---|---|
| `lwc/jsconfig.json` | Removed deprecated `baseUrl`; `paths` → `"./*"` | VS Code diagnostics clean (the extension may regenerate it; see "Left to do") |
| LWC CSS (4 files) | Every `var(--slds-g-*)` has its official SLDS 2 fallback (from `@salesforce-ux/sds-metadata`) | Code Analyzer |
| LWC JS | `let` → `const` (2) | ESLint 0/0 |
| LWC tests | Timer-free `flushPromises` (`queueMicrotask`), no inline `eslint-disable`; selectors use `data-id` hooks instead of styling classes | **42/42 pass** |
| `jest.config.js` | `roots` limited to `lwc/`, so `npm test` no longer runs the UI bundles' Playwright e2e specs | `npm test` clean |
| UI bundles (both) | Removed every `any` (typed `SFDC_ENV.basePath`, `LucideProps`, tuple generics in `debounce`/`useDebouncedCallback`); accessible pagination anchor; typographic apostrophes; unused param; unused `eslint-disable` | `tsc` 0, `eslint` 0, vitest 16/16 (reactinternal), build OK |
| `ReactInternalAK` | Vitest only runs `src/` tests (not Playwright e2e) and passes with no tests; vendor chunk splitting (675 kB → largest 329 kB) | build has no warnings |
| Apex CRUD/FLS (17 classes) | 36 queries/DML converted to **user mode** (`WITH USER_MODE`, `insert/update/delete/upsert as user`) | compiles; tests pass |
| `OpportunityControllerTest` | The org requires `Account.Type` (validation rule in the org): test Accounts now set it. Fixed an inverted assertion (checked ascending, but the method is "descending"). `System.assert*` → `Assert.*` | **110/110 Apex tests pass** (was 101/110) |
| Embedded apps (5) | Checked | all build with no warnings or errors |

## Full-project sweep (every folder and file type, 2026-10-14)

| Folder / type | Check | Result |
|---|---|---|
| All `force-app` metadata (379 components: Apex, LWC, UI bundles, HXL widgets, Agentforce planners, lightningTypes, objects, flexipages, permission sets, CSP sites, MCP definitions) | `sf project deploy start --dry-run --source-dir force-app` | was **2 errors** → now **379/379, 0 errors** |
| HXL widget `accountRelatedAccordion` (both copies) | dry-run | **Fixed (deprecated block name).** On API 68.0 the accordion item block is camelCase `tile/accordionItem`; lowercase `tile/accordionitem` is now rejected. 4-line rename; the collapsible design is unchanged. HXL READMEs corrected. |
| Agentforce `Agentforce_Employee_Agent` → `Create_Opportunity` | dry-run | **Fixed:** added the missing `output/schema.json` (`message` text, matching `OpportunityCreateController.CreateOpportunityResponse`) |
| Apex tests (all 115) | validate + RunLocalTests | **115/115 pass**; no `SeeAllData`; 2 open redirects fixed (relative-URL check + 5 new security tests); `AccountTool` got `with sharing`; `UIBundleRegistration` username check is explicit `WITH SYSTEM_MODE` (guest signup) |
| JSON (66 files) | parsed (`.vscode` files as JSON-with-comments) | all valid |
| XML (129 files) | well-formedness | all valid |
| Embedded apps (React, Vue, Angular, Next.js, plain JS) | `npm run build` | all build with no warnings |
| `HXL-Account/` (separate SFDX project) | Code Analyzer | 24 findings (4 moderate, 20 low: ApexDoc, test runAs, `global`, NCSS); `deploy.sh` passes `bash -n` |
| `scripts/` (`hello.apex`, `account.soql`) | Code Analyzer | no findings |
| `manifest/`, `config/` | XML/JSON validity | valid |
| `expense-tracker/` | contents | only an auto-generated `next-env.d.ts` (leftover from a removed Next.js build) |
| `.DS_Store` (13) | — | macOS Finder files, git-ignored, harmless |

## VS Code Problems panel (2026-10-14)

| Error | Cause | Fix |
|---|---|---|
| `LWC1702` in `employeeList.test.js` and `opportunityList.test.js` (line 1) | `import { createElement } from 'lwc'` is an outdated Jest import that the current LWC compiler rejects ("Invalid LWC imported identifier") | Import from `@lwc/engine-dom` (current LWC docs / lwc-recipes). 42/42 tests pass. |
| `jsconfig.json`: `baseUrl` deprecated (TypeScript 7) | The LWC extension rewrites the file from its template on every start | Fixed in the file **and** in the extension template, via the self-healing `~/.config/sf-lwc-extension-fix` (LaunchAgent re-applies it after extension updates) |

After an extension patch, run **Developer: Reload Window** once.

## Apex assertions: `System.assert*` → `Assert` class (2026-10-14)

Every Apex test class in both projects (24 classes, **328 assertions**) now uses the `Assert` class with best practices:

| Rule | Before | After |
|---|---|---|
| Use the `Assert` class, not legacy `System.assert` / `assertEquals` / `assertNotEquals` | 104 legacy calls | **0** |
| Most specific method: `isNull` / `isNotNull` / `isTrue` / `isFalse` / `fail` instead of `areEqual(null, x)`, `assert(x == null)`, `assert(!x)`, `assert(false, …)` | 28 | **0** |
| Expected value first: `areEqual(expected, actual, msg)` | 8 reversed | **0** |
| Every assertion has a message, so a failure says what was checked | 166 without | **0** (existing messages kept word for word) |

The rewrite was done with a parser (strings, commas inside strings and nested calls handled), not find-and-replace.
Verified: **115/115** `force-app` tests and **8/8** `HXL-Account` tests pass; 0 compile errors.

Reference: the Salesforce Apex test-generation skill's assertion guidance. The developer.salesforce.com `Assert` class page couldn't be read from this environment (blocked, and it renders in a frame).

## Apex test coverage (2026-10-14, in progress)

- Org-wide coverage **55% → 78%** (deploys need 75%), all tests passing (181 at last run). 20 new test classes cover 22 classes that had 0%, most now at 95–100%. `TestDataFactory` gained `buildContacts` / `buildCases`.
- `ExtractContactInfoFromCaseDescription`: refactored so the prompt-parsing and Case update are testable (`applyCustomerInfo`). Only the Einstein `ConnectApi` call itself can't run in tests (42%).
- Still at 0%: the Weather classes (`WeatherService`, `WeatherController`, `ContactWeatherController`) and the `UIBundle*` auth endpoints.

### Bugs found while writing tests: **fixed 2026-10-14**
| Where | Bug | Fix | Verified |
|---|---|---|---|
| `AccountTool` (Agentforce "Create Account") | Inserted Accounts without `Type`, which this org requires, so the action always failed | New optional `accountType` input; defaults to `AccountDefaults.ACCOUNT_TYPE` (`Prospect`) | 100% coverage; success, custom-type and 201-record bulk tests |
| `OpportunityCreateController` (Agentforce "Create Opportunity") | Created new Accounts without `Type`, so the action failed for new account names | New Account gets `AccountDefaults.ACCOUNT_TYPE`. The Agentforce input (`c__opportunityData`) is unchanged. | 100% coverage |
| `WeatherService` | Hardcoded OpenWeatherMap API key in source, committed to git | Calls `callout:OpenWeatherMap`, the existing Named Credential, which sends the key from External Credential parameter `appid` as the `x-api-key` header (header auth checked against the live API: 200 with header, 401 without). New permission set `OpenWeatherMap_Access` grants the principal. The key is now in no source file. | 100% coverage; a test fails if a key appears in the URL |

New: `AccountDefaults` (shared default Account Type).
Full validation against `ashish-rk`: **406/406 components, 195/195 tests, 81% coverage**.

**Still needed from you:**
- **Rotate the OpenWeatherMap key.** The old key is still live (verified) and is in git history. Generate a new one at openweathermap.org, then set it in Setup → Named Credentials → External Credentials → OpenWeatherMap → principal → parameter `appid`.
- **Assign `OpenWeatherMap_Access`** to users who call `/weather-service` after you deploy.

## Apex integration tests (Winter '27 Developer Preview) — added 2026-10-14

A working example of real-callout integration tests: `PostalCodeService` with Named Credential `PostalCodeApi`, in its own `integration-tests/` package directory. Verified in the new scratch org `rk-it` (feature `ApexIntegrationTests`): **3/3 real-callout tests pass**, `@TearDown` cleanup confirmed. Full rules and commands: [`integration-tests/README.md`](integration-tests/README.md). Deploy to normal orgs with `--source-dir force-app`.

## Left to do

1. **Apex coverage 55% → 75%+**: 28 classes have 0% coverage (about 600 lines), e.g. `CaseManager`, `CaseInputController`, `UIBundleRegistration`, `CreateContactTask`, `OpportunityInvoker`, the Weather classes and the Agentforce tools.
2. **Apex findings left**:
   - 13 tests use `SeeAllData=true` and 2 classes have `ApexOpenRedirect`. All are in Salesforce's generated Experience Cloud login/self-registration templates.
   - `AccountTool` has no sharing keyword.
   - `UIBundleRegistration` needs an explicit, documented `WITH SYSTEM_MODE` (a guest user checking whether a username is taken).
   - About 190 moderate findings (naming, complexity, empty blocks, braces) and about 385 low ones (ApexDoc ×198, test `runAs` ×108, annotation casing ×55, debug statements).
3. **API version**: the org is on **68.0**; `sfdx-project.json` and the component meta files are on 62.0–67.0.
4. **`jsconfig.json` permanence**: the Salesforce LWC extension merges its template (with `baseUrl`) over the file on every start. It needs a self-healing patch, like `~/.config/sf-lwc-preview-fix`.
5. **Dependencies**: the UI bundles have 27–28 major upgrades pending, including `@salesforce/ui-bundle`, `platform-sdk` and `agentforce-conversation-client` 10.x/9.x → 12.x, React Router 7→8, Vite 7→8, TypeScript 5→7 and ESLint 9→10. The root project has ESLint 9→10, `eslint-plugin-jest` 28→29 and `lint-staged` 16→17; Angular has TypeScript 6→7. Major versions contain breaking changes, so this needs a migration plan.
6. **Informational only** (not errors or warnings): copy-paste detection across the two near-identical UI bundles and the 5 embedded-app wrapper LWCs.

Nothing above is committed or deployed yet.
