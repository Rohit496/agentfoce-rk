import { useState } from "react";
import { Loader2, Pencil } from "lucide-react";
import {
	updateLead,
	type LeadUpdateFields,
	type UpdatedLeadRecord,
	type LeadFieldInfoMap,
} from "../api/lead/leadSearchService";
import { fieldValue } from "../features/object-search/utils/fieldUtils";
import { Button } from "../components/ui/button";
import {
	Dialog,
	DialogContent,
	DialogDescription,
	DialogFooter,
	DialogHeader,
	DialogTitle,
	DialogTrigger,
} from "../components/ui/dialog";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from "../components/ui/select";
import { toast } from "../components/ui/sonner";

/** Shape of the field nodes returned by the Lead detail query. */
type FieldNode = { value?: unknown; displayValue?: string | null } | null | undefined;

/** A Lead record (the detail-query node) — accessed by field API name. */
export type EditableLead = { Id: string } & Record<string, unknown>;

interface EditLeadDialogProps {
	lead: EditableLead;
	/**
	 * Picklist metadata, prefetched by the parent so the modal opens instantly
	 * with dropdowns ready. When null (not loaded yet), picklist fields render as
	 * text inputs and upgrade to dropdowns as soon as it arrives.
	 */
	fieldInfo?: LeadFieldInfoMap | null;
	/** Called after a successful update so the caller can refresh its data. */
	onUpdated?: (record: UpdatedLeadRecord) => void;
}

type FieldKind = "text" | "number" | "textarea" | "picklist" | "email" | "url";

interface FieldConfig {
	name: string;
	label: string;
	kind: FieldKind;
	required?: boolean;
	fullWidth?: boolean;
}

interface Section {
	title?: string;
	fields: FieldConfig[];
}

// Mirrors the standard Salesforce Lead edit layout. Field `name`s match both the
// detail-query field nodes and the LeadUpdateRepresentation input keys.
const SECTIONS: Section[] = [
	{
		fields: [
			{ name: "Salutation", label: "Salutation", kind: "picklist" },
			{ name: "FirstName", label: "First Name", kind: "text" },
			{ name: "LastName", label: "Last Name", kind: "text", required: true },
			{ name: "Company", label: "Company", kind: "text", required: true },
			{ name: "Title", label: "Title", kind: "text" },
			{ name: "Phone", label: "Phone", kind: "text" },
			{ name: "MobilePhone", label: "Mobile", kind: "text" },
			{ name: "Fax", label: "Fax", kind: "text" },
			{ name: "Email", label: "Email", kind: "email" },
			{ name: "Website", label: "Website", kind: "url" },
			{ name: "LeadSource", label: "Lead Source", kind: "picklist" },
			{ name: "Industry", label: "Industry", kind: "picklist" },
			{ name: "Status", label: "Lead Status", kind: "picklist", required: true },
			{ name: "Rating", label: "Rating", kind: "picklist" },
			{ name: "AnnualRevenue", label: "Annual Revenue", kind: "number" },
			{ name: "NumberOfEmployees", label: "No. of Employees", kind: "number" },
			{ name: "ProductInterest__c", label: "Product Interest", kind: "picklist" },
			{ name: "Primary__c", label: "Primary", kind: "picklist" },
			{ name: "SICCode__c", label: "SIC Code", kind: "text" },
			{ name: "NumberofLocations__c", label: "Number of Locations", kind: "number" },
			{ name: "CurrentGenerators__c", label: "Current Generator(s)", kind: "text" },
		],
	},
	{
		title: "Address",
		fields: [
			{ name: "Country", label: "Country", kind: "picklist" },
			{ name: "State", label: "State/Province", kind: "picklist" },
			{ name: "City", label: "City", kind: "text" },
			{ name: "PostalCode", label: "Zip/Postal Code", kind: "text" },
			{ name: "Street", label: "Street", kind: "textarea", fullWidth: true },
		],
	},
	{
		fields: [{ name: "Description", label: "Description", kind: "textarea", fullWidth: true }],
	},
];

const ALL_FIELDS: FieldConfig[] = SECTIONS.flatMap((s) => s.fields);
const NUMERIC_KINDS = new Set<FieldKind>(["number"]);
// Radix Select forbids an empty-string item value; use a sentinel for "none".
const NONE = "__none__";

type FormState = Record<string, string>;

function getField(lead: EditableLead, name: string): FieldNode {
	return lead[name] as FieldNode;
}

function initialForm(lead: EditableLead): FormState {
	const form: FormState = {};
	for (const cfg of ALL_FIELDS) {
		const node = getField(lead, cfg.name);
		if (cfg.kind === "number") {
			// Use the raw numeric value, not the formatted displayValue ("$1,200").
			const raw = node?.value;
			form[cfg.name] = raw == null ? "" : String(raw);
		} else if (cfg.kind === "picklist") {
			// Use the raw API value so it matches a picklist option's value.
			const raw = node?.value;
			form[cfg.name] = raw == null ? "" : String(raw);
		} else {
			form[cfg.name] = fieldValue(node) ?? "";
		}
	}
	return form;
}

function buildPayload(form: FormState): LeadUpdateFields {
	const payload: Record<string, string | number | undefined> = {};
	for (const cfg of ALL_FIELDS) {
		const value = (form[cfg.name] ?? "").trim();
		if (value === "") {
			payload[cfg.name] = undefined;
			continue;
		}
		if (NUMERIC_KINDS.has(cfg.kind)) {
			const parsed = Number(value);
			payload[cfg.name] = Number.isFinite(parsed) ? parsed : undefined;
		} else {
			payload[cfg.name] = value;
		}
	}
	return payload as LeadUpdateFields;
}

function readOnlyOwnerName(lead: EditableLead): string | null {
	const owner = lead.Owner as { Name?: FieldNode } | null | undefined;
	return fieldValue(owner?.Name);
}

function readOnlyUserDate(lead: EditableLead, userKey: string, dateKey: string): string | null {
	const user = lead[userKey] as { Name?: FieldNode } | null | undefined;
	const name = fieldValue(user?.Name);
	const date = fieldValue(getField(lead, dateKey));
	const parts = [name, date].filter(Boolean);
	return parts.length ? parts.join(", ") : null;
}

export function EditLeadDialog({ lead, fieldInfo, onUpdated }: EditLeadDialogProps) {
	const [open, setOpen] = useState(false);
	const [form, setForm] = useState<FormState>(() => initialForm(lead));
	const [saving, setSaving] = useState(false);
	const [error, setError] = useState<string | null>(null);

	function handleOpenChange(next: boolean) {
		if (next) {
			setForm(initialForm(lead));
			setError(null);
		}
		setOpen(next);
	}

	function update(name: string, value: string) {
		setForm((prev) => ({ ...prev, [name]: value }));
	}

	async function handleSubmit(e: React.FormEvent) {
		e.preventDefault();
		const missing = ALL_FIELDS.filter((f) => f.required && (form[f.name] ?? "").trim() === "");
		if (missing.length) {
			setError(`${missing.map((f) => f.label).join(", ")} ${missing.length > 1 ? "are" : "is"} required.`);
			return;
		}

		setSaving(true);
		setError(null);
		try {
			const record = await updateLead(lead.Id, buildPayload(form));
			toast.success("Lead updated");
			setOpen(false);
			onUpdated?.(record);
		} catch (err) {
			const message = err instanceof Error ? err.message : "Failed to update lead";
			setError(message);
			toast.error(message);
		} finally {
			setSaving(false);
		}
	}

	const ownerName = readOnlyOwnerName(lead);
	const createdBy = readOnlyUserDate(lead, "CreatedBy", "CreatedDate");
	const lastModifiedBy = readOnlyUserDate(lead, "LastModifiedBy", "LastModifiedDate");

	return (
		<Dialog open={open} onOpenChange={handleOpenChange}>
			<DialogTrigger asChild>
				<Button variant="outline" size="sm">
					<Pencil className="size-4" />
					Edit
				</Button>
			</DialogTrigger>
			<DialogContent className="sm:max-w-3xl max-h-[90vh] overflow-y-auto">
				<form onSubmit={handleSubmit}>
					<DialogHeader>
						<DialogTitle>Edit Lead</DialogTitle>
						<DialogDescription>
							<span className="text-destructive">*</span> = Required Information
						</DialogDescription>
					</DialogHeader>

					<div className="space-y-6 py-4">
						{ownerName && <ReadOnlyField label="Lead Owner" value={ownerName} />}

						{SECTIONS.map((section, i) => (
							<div key={section.title ?? i} className="space-y-4">
								{section.title && (
									<h3 className="text-sm font-semibold border-b pb-1">{section.title}</h3>
								)}
								<div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
									{section.fields.map((cfg) => (
										<FormField
											key={cfg.name}
											config={cfg}
											value={form[cfg.name] ?? ""}
											options={fieldInfo?.[cfg.name]?.options ?? []}
											onChange={update}
										/>
									))}
								</div>
							</div>
						))}

						<div className="grid grid-cols-1 sm:grid-cols-2 gap-4 border-t pt-4">
							{createdBy && <ReadOnlyField label="Created By" value={createdBy} />}
							{lastModifiedBy && <ReadOnlyField label="Last Modified By" value={lastModifiedBy} />}
						</div>
					</div>

					{error && (
						<p role="alert" className="text-sm text-destructive mb-2">
							{error}
						</p>
					)}

					<DialogFooter>
						<Button type="button" variant="outline" onClick={() => setOpen(false)} disabled={saving}>
							Cancel
						</Button>
						<Button type="submit" disabled={saving}>
							{saving && <Loader2 className="size-4 animate-spin" />}
							{saving ? "Saving…" : "Save changes"}
						</Button>
					</DialogFooter>
				</form>
			</DialogContent>
		</Dialog>
	);
}

function FormField({
	config,
	value,
	options,
	onChange,
}: {
	config: FieldConfig;
	value: string;
	options: { value: string; label: string }[];
	onChange: (name: string, value: string) => void;
}) {
	const { name, label, kind, required, fullWidth } = config;
	const labelEl = (
		<Label htmlFor={name}>
			{label}
			{required && <span className="text-destructive"> *</span>}
		</Label>
	);

	// Picklist fields render as a dropdown when the org returned valid values,
	// otherwise they gracefully fall back to a free-text input.
	if (kind === "picklist" && options.length > 0) {
		return (
			<div className={fullWidth ? "sm:col-span-2 flex flex-col gap-1.5" : "flex flex-col gap-1.5"}>
				{labelEl}
				<Select
					value={value === "" ? NONE : value}
					onValueChange={(v) => onChange(name, v === NONE ? "" : v)}
				>
					<SelectTrigger id={name} className="w-full" aria-label={label}>
						<SelectValue placeholder="--None--" />
					</SelectTrigger>
					<SelectContent>
						{!required && <SelectItem value={NONE}>--None--</SelectItem>}
						{options.map((opt) => (
							<SelectItem key={opt.value} value={opt.value}>
								{opt.label}
							</SelectItem>
						))}
					</SelectContent>
				</Select>
			</div>
		);
	}

	if (kind === "textarea") {
		return (
			<div className={fullWidth ? "sm:col-span-2 flex flex-col gap-1.5" : "flex flex-col gap-1.5"}>
				{labelEl}
				<textarea
					id={name}
					name={name}
					className="border-input focus-visible:border-ring focus-visible:ring-ring/50 min-h-20 w-full rounded-lg border bg-transparent px-2.5 py-1.5 text-sm outline-none focus-visible:ring-3"
					value={value}
					onChange={(e) => onChange(name, e.target.value)}
				/>
			</div>
		);
	}

	const inputType = kind === "number" ? "number" : kind === "email" ? "email" : kind === "url" ? "url" : "text";
	return (
		<div className={fullWidth ? "sm:col-span-2 flex flex-col gap-1.5" : "flex flex-col gap-1.5"}>
			{labelEl}
			<Input
				id={name}
				name={name}
				type={inputType}
				value={value}
				onChange={(e) => onChange(name, e.target.value)}
			/>
		</div>
	);
}

function ReadOnlyField({ label, value }: { label: string; value: string }) {
	return (
		<div className="flex flex-col gap-1">
			<span className="text-sm text-muted-foreground">{label}</span>
			<span className="text-sm">{value}</span>
		</div>
	);
}
