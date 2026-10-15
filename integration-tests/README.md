# Apex integration tests (Winter '27, Developer Preview)

Integration tests make **real callouts** to the real service, so they catch a broken Named Credential, endpoint or payload contract that an `HttpCalloutMock` unit test would hide.

This folder is a **separate package directory** (`sfdx-project.json` → `integration-tests`). `@IntegrationTest` only compiles in scratch orgs created with the `ApexIntegrationTests` feature. In any other org it fails with *"Annotation is not valid in your org: IntegrationTest"*, so keep it out of normal deploys.

## What's here

| File | Purpose |
|---|---|
| `main/default/classes/PostalCodeServiceIntegrationTest.cls` | 3 real-callout tests for `PostalCodeService` (in `force-app`): real 200, real 404, and creating an Account from a real lookup |

The rest of the feature lives in `force-app` and deploys to every org:
- `PostalCodeService`: postal-code lookup, Account billing-address enrichment, and create-Account-with-address. It uses user mode, input validation and a typed result.
- `PostalCodeServiceTest`: 10 unit tests with `HttpCalloutMock`, 100% coverage. **Integration tests don't count toward coverage**, so these are still required.
- `PostalCodeApi` External Credential (`Custom` protocol, no auth parameters) and Named Credential (`https://api.zippopotam.us`).
- `Postal_Code_API_Access` permission set: Apex class access plus access to the named principal (required for the callout).

## Feature rules (verified 2026-10-14)

| Rule | Detail |
|---|---|
| Where | Scratch orgs only, created with `"features": ["ApexIntegrationTests"]` (`config/integration-tests-scratch-def.json`). Not available in production, Developer Edition or sandbox orgs. A feature can't be added to an existing scratch org. |
| Annotations | `@IntegrationTest` on the class **and** on each test method; `@TearDown` on the cleanup method. No `@IsTest` needed. |
| Data | **Not rolled back.** `@TearDown` runs after **each** test method, so delete only what that method created (here, Accounts named `IT PostalCode …`). |
| Commit | **Not auto-committed either.** A callout after DML in the same test fails with *"You have uncommitted work pending"*. Call out first, then do the DML (that's why `createAccountWithAddress` looks up before it inserts). |
| Running | Asynchronous only, one integration test class per org at a time: `sf apex run test` **without** `--synchronous` (`--wait` just polls). |
| Mocks | A registered `Test.setMock()` still wins, so don't set one in an integration test. |
| Access | The running user needs the permission set that grants the named principal (`Postal_Code_API_Access`). |

## Commands

```bash
# 1. Scratch org with the feature (once; 7 days)
sf org create scratch --definition-file config/integration-tests-scratch-def.json \
  --target-dev-hub rohit007salesforce.d5fa3ddb8b4e@agentforce.com --alias rk-it --duration-days 7

# 2. Deploy the service, credentials, permission set and both test classes
sf project deploy start --target-org rk-it \
  --source-dir force-app/main/default/externalCredentials/PostalCodeApi.externalCredential-meta.xml \
  --source-dir force-app/main/default/namedCredentials/PostalCodeApi.namedCredential-meta.xml \
  --source-dir force-app/main/default/permissionsets/Postal_Code_API_Access.permissionset-meta.xml \
  --source-dir force-app/main/default/classes/PostalCodeService.cls \
  --source-dir force-app/main/default/classes/PostalCodeServiceTest.cls \
  --source-dir force-app/main/default/classes/TestDataFactory.cls \
  --source-dir integration-tests
sf org assign permset --name Postal_Code_API_Access --target-org rk-it

# 3. Unit tests (mocked, coverage)
sf apex run test --class-names PostalCodeServiceTest --target-org rk-it --code-coverage --wait 15

# 4. Integration tests (real callouts, async)
sf apex run test --class-names PostalCodeServiceIntegrationTest --target-org rk-it --wait 15
```

Deploying to a normal org (e.g. `ashish-rk`)? Use `--source-dir force-app`. A bare `sf project deploy start` deploys **every** package directory, including this one, and fails there.

## Results (2026-10-14, scratch org `rk-it`)
- `PostalCodeServiceTest`: **10/10 pass**, `PostalCodeService` **100%** coverage.
- `PostalCodeServiceIntegrationTest`: **3/3 pass** with real callouts. `@TearDown` cleanup verified: 0 leftover test Accounts.
- Main org `ashish-rk`: the `force-app` pieces dry-run **6/6** with 10/10 unit tests passing.
