import { beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { LeadFieldInfoMap } from "../api/lead/leadSearchService";

// Mock the data layer and toast notifications.
const updateLeadMock = vi.fn();
vi.mock("../api/lead/leadSearchService", () => ({
	updateLead: (...args: unknown[]) => updateLeadMock(...args),
}));
const toastSuccess = vi.fn();
const toastError = vi.fn();
vi.mock("../components/ui/sonner", () => ({
	toast: {
		success: (...a: unknown[]) => toastSuccess(...a),
		error: (...a: unknown[]) => toastError(...a),
	},
	Toaster: () => null,
}));

import { EditLeadDialog, type EditableLead } from "./EditLeadDialog";

// Radix Dialog/Select rely on a few DOM APIs jsdom doesn't implement.
beforeAll(() => {
	if (!Element.prototype.hasPointerCapture) Element.prototype.hasPointerCapture = () => false;
	if (!Element.prototype.scrollIntoView) Element.prototype.scrollIntoView = () => {};
});

const f = (value: unknown, displayValue?: string) => ({ value, displayValue });

const lead: EditableLead = {
	Id: "00Q5g00000ABCDEAA1",
	FirstName: f("Jane", "Jane"),
	LastName: f("Doe", "Doe"),
	Company: f("Acme", "Acme"),
	Email: f("jane@acme.com", "jane@acme.com"),
	Status: f("Open - Not Contacted", "Open - Not Contacted"),
	// Numeric: raw value is a number, displayValue is formatted.
	NumberOfEmployees: f(1200, "1,200"),
	AnnualRevenue: f(1200000, "$1,200,000"),
	Owner: { Name: f("OrgFarm EPIC", "OrgFarm EPIC") },
};

async function openDialog() {
	const user = userEvent.setup();
	await user.click(screen.getByRole("button", { name: /edit/i }));
	await screen.findByRole("dialog");
	return user;
}

describe("EditLeadDialog", () => {
	beforeEach(() => {
		updateLeadMock.mockReset();
		toastSuccess.mockReset();
		toastError.mockReset();
	});

	it("opens instantly with current values pre-filled and numeric fields using raw values", async () => {
		render(<EditLeadDialog lead={lead} fieldInfo={null} />);
		await openDialog();

		// Form is present immediately — no metadata fetch gate.
		expect(screen.getByLabelText(/first name/i)).toHaveValue("Jane");
		expect(screen.getByLabelText(/company/i)).toHaveValue("Acme");
		// Raw numeric value, NOT the formatted "1,200" / "$1,200,000".
		expect(screen.getByLabelText(/no\. of employees/i)).toHaveValue(1200);
		expect(screen.getByLabelText(/annual revenue/i)).toHaveValue(1200000);
	});

	it("shows the read-only Lead Owner", async () => {
		render(<EditLeadDialog lead={lead} fieldInfo={null} />);
		await openDialog();
		expect(screen.getByText("Lead Owner")).toBeInTheDocument();
		expect(screen.getByText("OrgFarm EPIC")).toBeInTheDocument();
	});

	it("submits changed values (numbers parsed) and calls onUpdated on success", async () => {
		updateLeadMock.mockResolvedValue({ Id: lead.Id });
		const onUpdated = vi.fn();
		render(<EditLeadDialog lead={lead} fieldInfo={null} onUpdated={onUpdated} />);
		const user = await openDialog();

		const firstName = screen.getByLabelText(/first name/i);
		await user.clear(firstName);
		await user.type(firstName, "Janet");
		const employees = screen.getByLabelText(/no\. of employees/i);
		await user.clear(employees);
		await user.type(employees, "4500");

		await user.click(screen.getByRole("button", { name: /save changes/i }));

		await waitFor(() => expect(updateLeadMock).toHaveBeenCalledTimes(1));
		const [id, fields] = updateLeadMock.mock.calls[0];
		expect(id).toBe(lead.Id);
		expect(fields.FirstName).toBe("Janet");
		expect(fields.Company).toBe("Acme");
		expect(fields.NumberOfEmployees).toBe(4500); // number, not "4500"
		expect(onUpdated).toHaveBeenCalledWith({ Id: lead.Id });
		expect(toastSuccess).toHaveBeenCalled();
	});

	it("blocks submit and shows an error when a required field is empty", async () => {
		render(<EditLeadDialog lead={lead} fieldInfo={null} />);
		const user = await openDialog();

		await user.clear(screen.getByLabelText(/last name/i));
		await user.click(screen.getByRole("button", { name: /save changes/i }));

		expect(await screen.findByRole("alert")).toHaveTextContent(/required/i);
		expect(updateLeadMock).not.toHaveBeenCalled();
	});

	it("shows an error toast when the update fails", async () => {
		updateLeadMock.mockRejectedValue(new Error("Insufficient access"));
		render(<EditLeadDialog lead={lead} fieldInfo={null} />);
		const user = await openDialog();

		await user.click(screen.getByRole("button", { name: /save changes/i }));

		await waitFor(() => expect(toastError).toHaveBeenCalledWith("Insufficient access"));
		expect(await screen.findByRole("alert")).toHaveTextContent("Insufficient access");
	});

	it("renders picklist fields as dropdowns when fieldInfo provides values", async () => {
		const fieldInfo: LeadFieldInfoMap = {
			Status: {
				label: "Lead Status",
				updateable: true,
				options: [
					{ value: "Open - Not Contacted", label: "Open - Not Contacted" },
					{ value: "Working - Contacted", label: "Working - Contacted" },
				],
			},
			Rating: { label: "Rating", updateable: true, options: [{ value: "Hot", label: "Hot" }] },
		};
		render(<EditLeadDialog lead={lead} fieldInfo={fieldInfo} />);
		await openDialog();

		// Status/Rating render as comboboxes (dropdowns) rather than text inputs.
		expect(screen.getByRole("combobox", { name: /lead status/i })).toBeInTheDocument();
		expect(screen.getByRole("combobox", { name: /rating/i })).toBeInTheDocument();
	});
});
