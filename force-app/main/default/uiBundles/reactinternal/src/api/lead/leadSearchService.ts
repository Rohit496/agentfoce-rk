import { createDataSDK } from "@salesforce/platform-sdk";
import SEARCH_LEADS_QUERY from "./query/searchLeads.graphql?raw";
import DISTINCT_INDUSTRIES_QUERY from "./query/distinctLeadIndustries.graphql?raw";
import DISTINCT_STATUSES_QUERY from "./query/distinctLeadStatuses.graphql?raw";
import UPDATE_LEAD_MUTATION from "./mutation/updateLead.graphql?raw";
import GET_LEAD_FIELD_INFO from "./query/getLeadFieldInfo.graphql?raw";
import GET_LEAD_PICKLIST_VALUES from "./query/getLeadPicklistValues.graphql?raw";
import {
	searchObjects,
	fetchDistinctValues,
	type ObjectSearchOptions,
	type PicklistOption,
} from "../../features/object-search/api/objectSearchService";
import type {
	SearchLeadsQuery,
	SearchLeadsQueryVariables,
	DistinctLeadIndustriesQuery,
	DistinctLeadStatusesQuery,
	UpdateLeadMutation,
	UpdateLeadMutationVariables,
	LeadUpdateRepresentation,
	GetLeadFieldInfoQuery,
	GetLeadFieldInfoQueryVariables,
	GetLeadPicklistValuesQuery,
	GetLeadPicklistValuesQueryVariables,
} from "../graphql-operations-types";

export type LeadSearchResult = NonNullable<SearchLeadsQuery["uiapi"]["query"]["Lead"]>;

/** Editable Lead fields accepted by {@link updateLead}. */
export type LeadUpdateFields = LeadUpdateRepresentation;

/** The Lead record returned by a successful {@link updateLead} call. */
export type UpdatedLeadRecord = NonNullable<
	NonNullable<UpdateLeadMutation["uiapi"]["LeadUpdate"]>["Record"]
>;

export type LeadSearchOptions = ObjectSearchOptions<
	SearchLeadsQueryVariables["where"],
	SearchLeadsQueryVariables["orderBy"]
>;

export type { PicklistOption };

/** A single picklist option `{ value, label }`. */
export type LeadFieldOption = { value: string; label: string };

/** Metadata for one Lead field: its label, whether it's updateable, and any picklist options. */
export type LeadFieldInfo = {
	label: string | null;
	updateable: boolean;
	options: LeadFieldOption[];
};

/** Map of Lead field API name → {@link LeadFieldInfo}. */
export type LeadFieldInfoMap = Record<string, LeadFieldInfo>;

export async function searchLeads(options: LeadSearchOptions = {}): Promise<LeadSearchResult> {
	return searchObjects<LeadSearchResult, SearchLeadsQuery, SearchLeadsQueryVariables>(
		SEARCH_LEADS_QUERY,
		"Lead",
		options,
	);
}

export async function fetchDistinctIndustries(): Promise<PicklistOption[]> {
	return fetchDistinctValues<DistinctLeadIndustriesQuery>(
		DISTINCT_INDUSTRIES_QUERY,
		"Lead",
		"Industry",
	);
}

export async function fetchDistinctStatuses(): Promise<PicklistOption[]> {
	return fetchDistinctValues<DistinctLeadStatusesQuery>(DISTINCT_STATUSES_QUERY, "Lead", "Status");
}

/**
 * Updates a Lead record via the `uiapi.LeadUpdate` GraphQL mutation.
 *
 * Mutations are request/response and do not touch the query cache, so callers
 * should refresh any related queries (e.g. re-run the detail query) after a
 * successful update to reflect the new values in the UI.
 *
 * @param recordId - The 18-character Id of the Lead to update.
 * @param fields - The subset of Lead fields to change. Only the provided
 *   fields are sent; omitted fields are left untouched.
 * @returns The updated Lead record returned by the mutation.
 * @throws If the mutation returns errors or does not report success.
 */
export async function updateLead(
	recordId: string,
	fields: LeadUpdateFields,
): Promise<UpdatedLeadRecord> {
	const data = await createDataSDK();
	const result = await data.graphql!.mutate<UpdateLeadMutation, UpdateLeadMutationVariables>({
		mutation: UPDATE_LEAD_MUTATION,
		variables: { input: { Id: recordId, Lead: fields } },
	});

	if (result.errors?.length) {
		throw new Error(result.errors.map((e) => e.message).join("; "));
	}

	const payload = result.data?.uiapi?.LeadUpdate;
	if (!payload?.success || !payload.Record) {
		throw new Error("Lead update did not complete successfully");
	}

	return payload.Record;
}

/**
 * Fetches Lead field metadata (labels, updateability, and picklist values) from
 * the UI API `objectInfos` so the edit form can render real picklist dropdowns
 * with the org's valid values — the same source the standard Salesforce UI uses.
 *
 * Done in two steps so nothing is hardcoded:
 *   1. Read the object's `defaultRecordTypeId` and field labels/updateability.
 *   2. Use that record type id to read picklist values — the picklist resolver
 *      requires a record-type context (`objectInfoInputs.recordTypeIDs`), so the
 *      id is sourced dynamically from step 1 rather than hardcoded.
 *
 * @returns A map keyed by field API name. Picklist values degrade gracefully to
 *   an empty `options` list if a record type can't be resolved.
 */
export async function fetchLeadFieldInfo(): Promise<LeadFieldInfoMap> {
	const data = await createDataSDK();

	// Step 1 — base field metadata + the org's default record type id.
	const baseResult = await data.graphql!.query<
		GetLeadFieldInfoQuery,
		GetLeadFieldInfoQueryVariables
	>({ query: GET_LEAD_FIELD_INFO });

	if (baseResult.errors?.length) {
		throw new Error(baseResult.errors.map((e) => e.message).join("; "));
	}

	const info = baseResult.data?.uiapi?.objectInfos?.[0];
	const recordTypeId = info?.defaultRecordTypeId ?? undefined;

	const map: LeadFieldInfoMap = {};
	for (const field of info?.fields ?? []) {
		if (!field) continue;
		map[field.ApiName] = {
			label: field.label ?? null,
			updateable: field.updateable,
			options: [],
		};
	}

	// Step 2 — picklist values for the resolved record type. Skipped (text-only
	// fallback) when there's no record type to scope the request to.
	if (!recordTypeId) {
		return map;
	}

	const picklistResult = await data.graphql!.query<
		GetLeadPicklistValuesQuery,
		GetLeadPicklistValuesQueryVariables
	>({
		query: GET_LEAD_PICKLIST_VALUES,
		variables: { inputs: [{ apiName: "Lead", recordTypeIDs: [recordTypeId] }] },
	});

	if (picklistResult.errors?.length) {
		throw new Error(picklistResult.errors.map((e) => e.message).join("; "));
	}

	for (const field of picklistResult.data?.uiapi?.objectInfos?.[0]?.fields ?? []) {
		if (!field || !("picklistValuesByRecordTypeIDs" in field)) continue;
		const picklists = field.picklistValuesByRecordTypeIDs;
		if (!picklists?.length) continue;

		const byRecordType = picklists.find((p) => p?.recordTypeID === recordTypeId) ?? picklists[0];
		const options = (byRecordType?.picklistValues ?? [])
			.map((v) => ({ value: v?.value ?? "", label: v?.label ?? v?.value ?? "" }))
			.filter((o) => o.value !== "");

		if (map[field.ApiName]) {
			map[field.ApiName].options = options;
		} else {
			map[field.ApiName] = { label: null, updateable: true, options };
		}
	}

	return map;
}
