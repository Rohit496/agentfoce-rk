import { beforeEach, describe, expect, it, vi } from "vitest";

// Mock the platform SDK so no real network/data call is made.
const mutateMock = vi.fn();
const queryMock = vi.fn();
vi.mock("@salesforce/platform-sdk", () => ({
	createDataSDK: vi.fn(async () => ({ graphql: { mutate: mutateMock, query: queryMock } })),
}));

import { updateLead, fetchLeadFieldInfo } from "./leadSearchService";

const RECORD_ID = "00Q5g00000ABCDEAA1";

function successResponse() {
	return {
		data: {
			uiapi: {
				LeadUpdate: {
					success: true,
					Record: {
						Id: RECORD_ID,
						FirstName: { value: "Jane", displayValue: "Jane" },
						LastName: { value: "Doe", displayValue: "Doe" },
						Company: { value: "Acme", displayValue: "Acme" },
					},
				},
			},
		},
	};
}

describe("updateLead", () => {
	beforeEach(() => {
		mutateMock.mockReset();
		queryMock.mockReset();
	});

	it("calls mutate with the LeadUpdate mutation and Id + Lead variables", async () => {
		mutateMock.mockResolvedValue(successResponse());

		await updateLead(RECORD_ID, { FirstName: "Jane", LastName: "Doe", Company: "Acme" });

		expect(mutateMock).toHaveBeenCalledTimes(1);
		const arg = mutateMock.mock.calls[0][0];
		expect(typeof arg.mutation).toBe("string");
		expect(arg.mutation).toContain("LeadUpdate");
		expect(arg.variables).toEqual({
			input: {
				Id: RECORD_ID,
				Lead: { FirstName: "Jane", LastName: "Doe", Company: "Acme" },
			},
		});
	});

	it("returns the updated record on success", async () => {
		mutateMock.mockResolvedValue(successResponse());

		const record = await updateLead(RECORD_ID, { LastName: "Doe", Company: "Acme" });

		expect(record.Id).toBe(RECORD_ID);
		expect(record.FirstName?.value).toBe("Jane");
	});

	it("throws when the mutation returns GraphQL errors", async () => {
		mutateMock.mockResolvedValue({
			data: undefined,
			errors: [{ message: "Insufficient access" }, { message: "Field invalid" }],
		});

		await expect(updateLead(RECORD_ID, { LastName: "Doe" })).rejects.toThrow(
			"Insufficient access; Field invalid",
		);
	});

	it("throws when the mutation does not report success", async () => {
		mutateMock.mockResolvedValue({
			data: { uiapi: { LeadUpdate: { success: false, Record: null } } },
		});

		await expect(updateLead(RECORD_ID, { LastName: "Doe" })).rejects.toThrow(
			"did not complete successfully",
		);
	});
});

describe("fetchLeadFieldInfo", () => {
	beforeEach(() => {
		queryMock.mockReset();
	});

	const RECORD_TYPE_ID = "012000000000001AAA";

	// Step 1: base field metadata + the org's default record type id.
	function baseResponse() {
		return {
			data: {
				uiapi: {
					objectInfos: [
						{
							ApiName: "Lead",
							defaultRecordTypeId: RECORD_TYPE_ID,
							fields: [
								{ ApiName: "Status", label: "Lead Status", updateable: true },
								{ ApiName: "Company", label: "Company", updateable: true },
							],
						},
					],
				},
			},
		};
	}

	// Step 2: picklist values scoped to the requested record type(s).
	function picklistResponse() {
		return {
			data: {
				uiapi: {
					objectInfos: [
						{
							fields: [
								{
									ApiName: "Status",
									picklistValuesByRecordTypeIDs: [
										{
											recordTypeID: RECORD_TYPE_ID,
											picklistValues: [
												{ value: "Open - Not Contacted", label: "Open - Not Contacted" },
												{ value: "Working - Contacted", label: "Working - Contacted" },
											],
										},
										{
											recordTypeID: "012000000000999AAA",
											picklistValues: [{ value: "Other", label: "Other" }],
										},
									],
								},
								{ ApiName: "Company" },
							],
						},
					],
				},
			},
		};
	}

	it("maps fields and merges picklist options, using the dynamic default record type", async () => {
		queryMock.mockResolvedValueOnce(baseResponse()).mockResolvedValueOnce(picklistResponse());

		const info = await fetchLeadFieldInfo();

		expect(info.Status.label).toBe("Lead Status");
		expect(info.Status.updateable).toBe(true);
		// Uses the DEFAULT record type's values, not the other record type's.
		expect(info.Status.options).toEqual([
			{ value: "Open - Not Contacted", label: "Open - Not Contacted" },
			{ value: "Working - Contacted", label: "Working - Contacted" },
		]);
		// Non-picklist field has no options.
		expect(info.Company.options).toEqual([]);

		// The record type id passed to step 2 is sourced dynamically from step 1 —
		// nothing is hardcoded.
		const step2Vars = queryMock.mock.calls[1][0].variables;
		expect(step2Vars).toEqual({ inputs: [{ apiName: "Lead", recordTypeIDs: [RECORD_TYPE_ID] }] });
	});

	it("falls back to text-only (no second query) when there's no record type", async () => {
		queryMock.mockResolvedValueOnce({
			data: { uiapi: { objectInfos: [{ ApiName: "Lead", defaultRecordTypeId: null, fields: [] }] } },
		});

		const info = await fetchLeadFieldInfo();

		expect(info).toEqual({});
		expect(queryMock).toHaveBeenCalledTimes(1); // step 2 skipped
	});

	it("throws when the metadata query returns errors", async () => {
		queryMock.mockResolvedValue({ data: undefined, errors: [{ message: "No access" }] });
		await expect(fetchLeadFieldInfo()).rejects.toThrow("No access");
	});
});
