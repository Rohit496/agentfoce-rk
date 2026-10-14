# HXL for Account: install package

Adds two MCP tools that render Account data as HXL widgets in Slack, ChatGPT, Claude and Agentforce:

| The user asks | Tool | Widget |
|---|---|---|
| "Show me the details of account Acme" | `AccountDetails` | `accountDetailsCard`: the account only |
| "Show me Acme and its related records" / "Show all accounts with their related records" | `AccountWithRelatedRecords` | `accountRelatedAccordion`: an accordion with one section per account, each listing its Contacts, Cases and Opportunities |

The full build guide is in [docs/HXL_ACCOUNT_README.md](docs/HXL_ACCOUNT_README.md).

## What's inside

| Type | Components |
|---|---|
| CustomField | `Account.Region__c`, `Account.Active__c`, `Account.CustomerPriority__c` (picklists read by the Apex) |
| ApexClass | `AccountDetails`, `AccountWithRelatedRecords`, `AccountHxlToolsTest` |
| LightningTypeBundle | `accountDetailsResult`, `accountDetailsOutputValues`, `accountRelatedResult`, `accountRelatedOutputValues` |
| UiWidgetBundle | `accountDetailsCard`, `accountRelatedAccordion` |
| McpServerDefinition | `HXLAccountMCPServer` (label "HXL Account MCP Server") |

`manifest/package.xml` lists all 14 components.

## Prerequisites

- **Target org:** supports UiWidgetBundle, LightningTypeBundle and McpServerDefinition (API 67.0+).
- **Salesforce CLI (`sf`):** installed, and logged in to the target org (`sf org login web --alias <alias>`).
- **Other orgs:** if the target org already has `Region__c`, `Active__c` or `CustomerPriority__c` on Account with different picklist values, the deploy updates them to match this package. Review those three field files before deploying.

## Install

```bash
unzip HXL-Account.zip
cd HXL-Account
./deploy.sh <org-alias>
```

`deploy.sh` runs two deploys, because the MCP server can only find the Apex tools once the Apex is in the org:

1. Custom fields and Apex, running `AccountHxlToolsTest`.
2. Lightning Types, uiWidgets, and the MCP server.

To run the steps by hand:

```bash
cd force-app/main/default
sf project deploy start --target-org <alias> -d objects/Account/fields -d classes \
  --test-level RunSpecifiedTests --tests AccountHxlToolsTest
sf project deploy start --target-org <alias> -d lightningTypes -d uiWidgets -d mcpServerDefinitions
```

## After install

1. **Connect your MCP client** (Slack, ChatGPT, Claude or Agentforce) to **HXL Account MCP Server**.
2. **Ask a question**, for example:
   - "Show me the details of account Burlington"
   - "Show all accounts with their contacts, cases and opportunities"

## Adding the tools to an existing HXL server instead

If the org already has an HXL MCP server and you want these tools on it:

1. Copy the two `<resources>` and two `<tools>` blocks from `HXLAccountMCPServer.mcpServerDefinition-meta.xml` into that server's definition.
2. Deploy that server's definition. Skip deploying `HXLAccountMCPServer`.

Don't deploy an account-only file under an existing server's name. That would replace the server and remove its other tools.

## Troubleshooting

| Error | Fix |
|---|---|
| `No "aa:apex-…" identifier found for source "API_CATALOG"` | The Apex isn't in the org yet. Run step 1 first. |
| `FIELD_INTEGRITY_EXCEPTION … BillingCountry` in tests | The org has State/Country picklists that don't include "United States". Change the country in `AccountHxlToolsTest`. |
| A test fails on inserting a Contact, Case or Opportunity | A validation rule or required field in the target org. Add the required values in `AccountHxlToolsTest.setup()`. |
| `tile/accordionItem can't be the child of tile/accordion` | Use lowercase `tile/accordionitem`. The package already does. |
