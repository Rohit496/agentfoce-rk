# Builder Central (Beta) scratch org

Scratch org for trying Builder Central without the production-org limits
("not all features are enabled") seen in the `ashish-rk` Developer Edition org.
Builder Central treats this scratch org as a **Sandbox**.

## Org

| | |
|---|---|
| Alias | `builder-central` |
| Username | `test-hffj01tlqzgj@example.com` |
| Org ID | `00DAu00000JtPNpMAN` |
| Instance | https://dream-business-1881-dev-ed.scratch.my.salesforce.com |
| Dev Hub | `rohit007salesforce.d5fa3ddb8b4e@agentforce.com` (`ashish-rk`) |
| Created / expires | 2026-10-11 / 2026-11-10 (30 days) |
| Definition file | [builder-central-scratch-def.json](builder-central-scratch-def.json) |

## How it was set up

1. Create the org:
   ```bash
   sf org create scratch --definition-file config/builder-central-scratch-def.json \
     --target-dev-hub rohit007salesforce.d5fa3ddb8b4e@agentforce.com \
     --alias builder-central --duration-days 30 --wait 20
   ```
   The definition enables Agentforce (`Einstein1AIPlatform` feature,
   `agentPlatformSettings.enableAgentPlatform`, `einsteinGptSettings.enableEinsteinGptPlatform`).
2. Assign the standard permission sets to the admin user:
   ```bash
   sf org assign permset --name AccessBuilderCentral --name AgentPlatformBuilder --target-org builder-central
   ```
3. Setup → Quick Find → **Builder Central (Beta)** → turn on **Builder Central Availability**
   (done by hand in the UI; no metadata setting was used).
4. **Open Builder Central** on that Setup page, or go to
   `/lwr/application/ai/codey_studio-app`.

Reopen later with `sf org open --target-org builder-central`.

## Build attempt (2026-10-11): fails with "Something went wrong. Try again."

Prompt tried: "Build a simple employee onboarding application that tracks employees,
onboarding tasks, and task completion." Builder Central names the project and creates a
workspace, then the Build Agent immediately answers "Something went wrong. Try again."
The same error appears in the `ashish-rk` org with a different prompt.

What was checked:

- **Network:** every request succeeds at HTTP level. `POST /services/data/v67.0/codeystudio/workspaces`
  returns 201 and the Build Agent run
  (`api.salesforce.com/platform/dx-workspaces-proxy/.../agui/run`) returns 200. The failure
  is reported inside the agent's response stream, which could not be read from the page,
  so the underlying error text is still unknown.
- **Permission sets on the scratch admin:** `AccessBuilderCentral`, `AgentPlatformBuilder`,
  `UseSetupWithAgentforce`, `EinsteinGPTPromptTemplateManager`, `CopilotSalesforceAdmin`.
  Adding the last three did not change the result.
- **Einstein Setup:** "Turn on Einstein" is On.
- **Licensing:** the scratch org has no Data Cloud / Foundations permission set licenses.
  `ashish-rk` does have Data Cloud licenses (`GenieDataPlatformStarterPsl`) and the
  `AccessBuilderCentral` permission set, and fails the same way.
- **Salesforce docs:** the release note says Builder Central applies to Enterprise,
  Performance, Unlimited and Developer Editions "with Foundations or Agentforce 1 Editions".
  No public troubleshooting page for Builder Central was found.

To see the real error: open DevTools → Network in the Builder Central tab, resend the
prompt, and read the response body of the `agui/run` request.

## `asagarwal-rkk-dev-ed` Developer Edition org (checked 2026-10-12)

Org: https://asagarwal-rkk-dev-ed.develop.my.salesforce-setup.com/ (Developer Edition,
org name "IT"). Checked in Chrome against the ChatGPT "Salesforce Setup Guide" steps
(https://chatgpt.com/share/6acc43ac-a594-83ec-be85-f287dfcaa10b). Nothing had to be
changed; every setup step was already in place:

| Guide step | State found |
|---|---|
| Edition | Developer Edition (supported) |
| Einstein Setup → Turn on Einstein | On |
| Einstein Setup → Amazon Bedrock Models (Amazon and Anthropic) | On |
| Agentforce Agents → Agentforce | On |
| Builder Central (Beta) → Builder Central Availability | On |
| Access Builder Central permission | Not inspected directly; Builder Central opens for the logged-in admin, which requires it |
| Metadata Experts MCP Server (`platform.metadata-experts`) | Active |

Builder Central opens at
`https://asagarwal-rkk-dev-ed.develop.lightning.force.com/lwr/application/ai/codey_studio-app`.

**Build test: fails, root cause found.** A plan-only test prompt ("Equipment Request POC",
project "Equipment Request Planner") was sent twice. Both times the Build Agent answered
"Something went wrong. Try again." The `agui/run` response stream (captured by hooking
`fetch` inside the Builder Central iframe) ends with:

```
RUN_ERROR  code PROVIDER_ERROR
429 You have exceeded your rate limit. Please try again later.
limit 0, remaining 0, reset 60, key api minute
endpoint: /v1/model/sfdc_ai__DefaultBedrockAnthropicClaude47Opus/invoke-with-response-stream
core_tenant_id: core/prod/00DgL00000KfULCUA3   org_status: Free   model: advanced-models
```

Meaning: the org is classed as `Free` and its per-minute quota for the `advanced-models`
tier (the Claude Opus model the Build Agent calls) is **0**. Retrying cannot succeed, and
no Setup toggle in the guide changes this; it is an entitlement/quota limit on the org.
This is almost certainly the same cause as the scratch-org and `ashish-rk` failures above.

Untested idea: Einstein Setup → turn **off** "Turn on Beta Generative AI Models" to see
whether the Build Agent falls back to a model that has quota. The attempt to flip it was
blocked by the Claude Code permission guard, so it was not tried.

How to capture the error again: in the Builder Central tab, hook `fetch` on the first
iframe's `contentWindow` (the run request is made from the iframe, not the top window),
send a message, and read the `RUN_ERROR` event of the `.../agui/run` response.

Limits in a Developer Edition org (from the guide and the dialog): in-app Design view
works, but there is no separate Preview org and no Publish to Sandbox.

## `orgfarm-e45209ffbf-dev-ed` Developer Edition org (checked 2026-10-12)

Org: https://orgfarm-e45209ffbf-dev-ed.develop.lightning.force.com/ (org ID
`00Dg500000B9kBlEAJ`). Builder Central (Beta) is On and opens. A plan-only test prompt
(project "GearFlow POC") fails with "Something went wrong. Try again." and the **same**
`RUN_ERROR`: 429, `limit 0, remaining 0`, endpoint
`sfdc_ai__DefaultBedrockAnthropicClaude47Opus`, `org_status: Free`, `model: advanced-models`.

Conclusion: this org has no advanced-models quota either. Two different OrgFarm Developer
Edition orgs now show the identical zero limit, so the block is the `Free` org status, not
anything specific to one org.

## Next candidate: 30-day Salesforce Platform free trial (found 2026-10-12)

Salesforce's own Builder Central page (https://www.salesforce.com/headless/builder/) has a
"Try for free" button that goes to the 30-day Platform trial signup:
https://www.salesforce.com/platform/free-trial/signup/?d=pb (no credit card). The page does
not state that the trial includes Builder Central or advanced-models quota, so this is
unverified until a trial org is created and tested with the same plan-only prompt.
Signup has to be done by Rohit (account creation and agreement acceptance).

## Platform trial org `ddz000004ixjduaa` (set up and tested 2026-10-12)

Org: https://ddz000004ixjduaa.lightning.force.com/ (30-day Platform trial, org ID
`00DdZ000004ixjdUAA`, admin user "Rohit Kumar").

Setup done in Chrome:

| Step | Result |
|---|---|
| Turn on Einstein | Already On (no model-provider toggles shown on this org's page) |
| Agentforce | Already On |
| Builder Central (Beta) availability | Was Off → turned **On** |
| Access Builder Central permission set (`AccessBuilderCentral`) | Had no assignments → assigned to Rohit Kumar, never expires |
| Metadata Experts MCP Server | Was inactive → **Activated** |

Before the permission set was assigned, the app URL showed "Page doesn't exist". The first
open after that showed "We couldn't finish setting up your workspace."; **Try again**
fixed it (first-time workspace provisioning is slow).

**Build test: still fails.** Project "Equipment Request Manager POC", same `RUN_ERROR`:
429, `limit 0, remaining 0`, endpoint `sfdc_ai__DefaultBedrockAnthropicClaude47Opus`,
`model: advanced-models`, but `org_status: Trial` (not `Free`). So a trial org has zero
advanced-models quota as well.

**Likely missing piece: Salesforce Foundations.** Setup → Salesforce Foundations shows
"0 of 3 Items Completed" for the required products (Data Cloud, Foundations Features and
Settings, **Agentforce for Foundations** – "Agentforce requires usage entitlements...
Foundations give you a free allocation of credits"). The **Add to My Contract...** button
is disabled with the warning "To add products, this org needs access to Your Account."
Followed up the same day: Salesforce Help says Your Account is turned on from Setup →
**Manage Subscription**. In this trial org that page only shows "You haven't subscribed
yet" with a **Subscribe Now** button; there is no Your Account toggle. So Foundations
cannot be added until the org has a paid subscription. Stopped here (subscribing means
buying Salesforce). Whether Foundations would lift the advanced-models limit is unverified.

**Conclusion across all four orgs** (scratch, two Developer Editions, Platform trial):
Builder Central's Build Agent cannot run on any free or trial org tested; every one has
`advanced-models` limit 0. It needs a paid org with Foundations or Agentforce 1.

## Known gaps

- **Data 360 (Data Cloud) is not enabled.** The Dev Hub rejected the scratch features
  `CustomerDataPlatform` and `CustomerDataPlatformLite` ("not a valid Features value"),
  so they were removed from the definition file. Builder Central still opens; builds
  that depend on Data 360 may fail.
- The **Metadata Experts MCP Server** (optional, recommended on the Setup page) is not set up.
- During beta, Builder Central asks you to return every 7 days to keep builds and chats.
- The default Dev Hub `advancedflow` has an expired login
  (`sf org login web --alias advancedflow --set-default-dev-hub` to fix), which is why
  the `ashish-rk` hub was used.
