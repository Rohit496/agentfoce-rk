#!/usr/bin/env bash
# Deploys HXL for Account into a Salesforce org.
# Usage: ./deploy.sh <org-alias>
set -euo pipefail

ORG="${1:?Usage: ./deploy.sh <org-alias>}"
cd "$(dirname "$0")/force-app/main/default"

echo "==> Phase 1/2: custom fields + permission set, then Apex (runs AccountHxlToolsTest)"
# The Apex queries WITH USER_MODE, so the user needs FLS on the fields before the tests run.
sf project deploy start --target-org "$ORG" \
  -d objects/Account/fields \
  -d permissionsets \
  --wait 30
sf org assign permset --name HXL_Account_Access --target-org "$ORG" || true
sf project deploy start --target-org "$ORG" \
  -d classes/AccountDetails.cls \
  -d classes/AccountWithRelatedRecords.cls \
  -d classes/AccountHxlToolsTest.cls \
  --test-level RunSpecifiedTests --tests AccountHxlToolsTest \
  --wait 30

echo "==> Phase 2/2: Lightning Types, uiWidgets, MCP server"
sf project deploy start --target-org "$ORG" \
  -d lightningTypes \
  -d uiWidgets \
  -d mcpServerDefinitions \
  --wait 30

echo "==> Done. Reconnect your MCP client to 'HXL Account MCP Server'."
