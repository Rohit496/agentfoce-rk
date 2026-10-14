import { useState } from "react";
import { useParams, useNavigate } from "react-router";
import { createDataSDK } from "@salesforce/platform-sdk";
import { AlertCircle, ChevronDown, ChevronRight, FileQuestion } from "lucide-react";
import GET_LEAD_DETAIL from "../api/lead/query/getLeadDetail.graphql?raw";
import type {
	GetLeadDetailQuery,
	GetLeadDetailQueryVariables,
} from "../api/graphql-operations-types";
import { Alert, AlertTitle, AlertDescription } from "../components/ui/alert";
import { Button } from "../components/ui/button";
import { Card, CardContent } from "../components/ui/card";
import { fieldValue, formatDateTimeField } from "../features/object-search/utils/fieldUtils";
import { Collapsible, CollapsibleTrigger, CollapsibleContent } from "../components/ui/collapsible";
import { Separator } from "../components/ui/separator";
import { Skeleton } from "../components/ui/skeleton";
import { useAsyncData } from "../hooks/useAsyncData";
import { ObjectBreadcrumb } from "../features/object-search/components/ObjectBreadcrumb";
import { EditLeadDialog } from "./EditLeadDialog";
import { fetchLeadFieldInfo, type LeadFieldInfoMap } from "../api/lead/leadSearchService";

type LeadNode = NonNullable<
	NonNullable<
		NonNullable<NonNullable<GetLeadDetailQuery["uiapi"]["query"]["Lead"]>["edges"]>[number]
	>["node"]
>;

async function fetchLeadDetail(recordId: string): Promise<LeadNode | null | undefined> {
	const data = await createDataSDK();
	const result = await data.graphql!.query<GetLeadDetailQuery, GetLeadDetailQueryVariables>({
		query: GET_LEAD_DETAIL,
		variables: { id: recordId },
		// Mutations don't write the GraphQL cache, so a plain re-query after an
		// update would hit the stale cached record (300s TTL) and the UI wouldn't
		// reflect the change. "no-cache" always fetches fresh from the network so
		// the post-update reload() shows the new values immediately.
		cacheControl: "no-cache",
	});

	if (result.errors?.length) {
		throw new Error(result.errors.map((e) => e.message).join("; "));
	}

	return result.data?.uiapi?.query?.Lead?.edges?.[0]?.node;
}

export default function LeadObjectDetail() {
	const { recordId } = useParams();
	const navigate = useNavigate();

	const {
		data: lead,
		loading,
		error,
		reload,
	} = useAsyncData(() => fetchLeadDetail(recordId!), [recordId]);

	// Prefetch picklist metadata in the background (non-blocking) so the Edit
	// modal opens instantly with dropdowns ready instead of waiting on two
	// objectInfos round-trips when the user clicks Edit.
	const { data: fieldInfo } = useAsyncData(() => fetchLeadFieldInfo(), []);

	return (
		<div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
			<ObjectBreadcrumb
				listPath="/leads"
				listLabel="Leads"
				loading={loading}
				recordName={
					lead ? (fieldValue(lead.Name) ?? "") : error ? "Error" : loading ? undefined : "Not Found"
				}
			/>

			{/* Loading state */}
			{loading && <LeadDetailSkeleton />}

			{/* Error state */}
			{error && <LeadDetailError onBack={() => navigate(-1)} />}

			{/* Not found state */}
			{!loading && !error && !lead && <LeadDetailNotFound onBack={() => navigate(-1)} />}

			{/* Content */}
			{lead && <LeadDetailContent lead={lead} fieldInfo={fieldInfo} onUpdated={reload} />}
		</div>
	);
}

function LeadDetailContent({
	lead,
	fieldInfo,
	onUpdated,
}: {
	lead: LeadNode;
	fieldInfo: LeadFieldInfoMap | null;
	onUpdated: () => void;
}) {
	const dateTimeOptions = { dateStyle: "medium", timeStyle: "short" } as const;
	// Format from the raw ISO `value`, not the localized displayValue (e.g.
	// "21/06/2026, 12:09 pm"), which `new Date(...)` can't parse → "Invalid Date".
	const createdDate = formatDateTimeField(lead.CreatedDate?.value, undefined, dateTimeOptions);
	const lastModifiedDate = formatDateTimeField(
		lead.LastModifiedDate?.value,
		undefined,
		dateTimeOptions,
	);

	return (
		<>
			<div className="flex items-center justify-between mb-4 gap-4">
				<h1 className="text-2xl font-bold">Lead: {fieldValue(lead.Name)}</h1>
				<EditLeadDialog lead={lead} fieldInfo={fieldInfo} onUpdated={onUpdated} />
			</div>

			<Card>
				<CardContent className="space-y-8 pt-6">
					{/* Top section */}
					<div>
						<div className="space-y-4">
							<FieldRow>
								<FieldItem label="Lead Owner">{fieldValue(lead.Owner?.Name)}</FieldItem>
								<FieldItem label="Phone">
									<TelephoneField value={fieldValue(lead.Phone)} />
								</FieldItem>
							</FieldRow>
							<FieldRow>
								<FieldItem label="Salutation">{fieldValue(lead.Salutation)}</FieldItem>
								<FieldItem label="Mobile">
									<TelephoneField value={fieldValue(lead.MobilePhone)} />
								</FieldItem>
							</FieldRow>
							<FieldRow>
								<FieldItem label="Name">{fieldValue(lead.Name)}</FieldItem>
								<FieldItem label="Fax">{fieldValue(lead.Fax)}</FieldItem>
							</FieldRow>
							<FieldRow>
								<FieldItem label="Company">{fieldValue(lead.Company)}</FieldItem>
								<FieldItem label="Email">
									<EmailField value={fieldValue(lead.Email)} />
								</FieldItem>
							</FieldRow>
							<FieldRow>
								<FieldItem label="Title">{fieldValue(lead.Title)}</FieldItem>
								<FieldItem label="Website">{fieldValue(lead.Website)}</FieldItem>
							</FieldRow>
							<FieldRow>
								<FieldItem label="Lead Status">{fieldValue(lead.Status)}</FieldItem>
								<FieldItem label="Rating">{fieldValue(lead.Rating)}</FieldItem>
							</FieldRow>
						</div>
					</div>

					<Separator />

					{/* Additional Information */}
					<Section title="Additional Information">
						<FieldRow>
							<FieldItem label="Lead Source">{fieldValue(lead.LeadSource)}</FieldItem>
							<FieldItem label="Industry">{fieldValue(lead.Industry)}</FieldItem>
						</FieldRow>
						<FieldRow>
							<FieldItem label="Annual Revenue">{fieldValue(lead.AnnualRevenue)}</FieldItem>
							<FieldItem label="No. of Employees">{fieldValue(lead.NumberOfEmployees)}</FieldItem>
						</FieldRow>
						<FieldRow>
							<FieldItem label="Product Interest">{fieldValue(lead.ProductInterest__c)}</FieldItem>
							<FieldItem label="Primary">{fieldValue(lead.Primary__c)}</FieldItem>
						</FieldRow>
						<FieldRow>
							<FieldItem label="SIC Code">{fieldValue(lead.SICCode__c)}</FieldItem>
							<FieldItem label="Number of Locations">
								{fieldValue(lead.NumberofLocations__c)}
							</FieldItem>
						</FieldRow>
						<FieldRow>
							<FieldItem label="Current Generator(s)">
								{fieldValue(lead.CurrentGenerators__c)}
							</FieldItem>
						</FieldRow>
						<FieldItem label="Description">{fieldValue(lead.Description)}</FieldItem>
					</Section>

					<Separator />

					{/* Address Information */}
					<Section title="Address Information">
						<FieldRow>
							<FieldItem label="Country">{fieldValue(lead.Country)}</FieldItem>
							<FieldItem label="State/Province">{fieldValue(lead.State)}</FieldItem>
						</FieldRow>
						<FieldRow>
							<FieldItem label="City">{fieldValue(lead.City)}</FieldItem>
							<FieldItem label="Zip/Postal Code">{fieldValue(lead.PostalCode)}</FieldItem>
						</FieldRow>
						<FieldItem label="Street">{fieldValue(lead.Street)}</FieldItem>
					</Section>

					<Separator />

					{/* System Information */}
					<Section title="System Information">
						<FieldRow>
							<FieldItem label="Created By">
								{[fieldValue(lead.CreatedBy?.Name), createdDate].filter(Boolean).join(" ") || null}
							</FieldItem>
							<FieldItem label="Last Modified By">
								{[fieldValue(lead.LastModifiedBy?.Name), lastModifiedDate]
									.filter(Boolean)
									.join(" ") || null}
							</FieldItem>
						</FieldRow>
					</Section>
				</CardContent>
			</Card>
		</>
	);
}

function TelephoneField({ value }: { value?: string | null }) {
	if (!value) return null;
	return (
		<a href={`tel:${value}`} className="underline">
			{value}
		</a>
	);
}

function EmailField({ value }: { value?: string | null }) {
	if (!value) return null;
	return (
		<a href={`mailto:${value}`} className="underline">
			{value}
		</a>
	);
}

function FieldItem({ label, children }: { label: string; children: React.ReactNode }) {
	return (
		<div>
			<dt className="text-sm text-muted-foreground">{label}</dt>
			<dd className="mt-0.5">{children ?? "—"}</dd>
		</div>
	);
}

function FieldRow({ children }: { children: React.ReactNode }) {
	return <div className="grid grid-cols-2 gap-x-8 gap-y-4">{children}</div>;
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
	const [open, setOpen] = useState(true);
	return (
		<Collapsible open={open} onOpenChange={setOpen}>
			<CollapsibleTrigger className="flex items-center gap-2 cursor-pointer text-lg font-semibold py-2">
				{open ? <ChevronDown className="size-5" /> : <ChevronRight className="size-5" />}
				{title}
			</CollapsibleTrigger>
			<CollapsibleContent>
				<div className="mt-2 space-y-4">{children}</div>
			</CollapsibleContent>
		</Collapsible>
	);
}

function LeadDetailError({ onBack }: { onBack: () => void }) {
	return (
		<>
			<Alert variant="destructive" role="alert">
				<AlertCircle />
				<AlertTitle>
					<h2>Failed to load lead</h2>
				</AlertTitle>
				<AlertDescription>
					Something went wrong while loading this lead. Please try again later.
				</AlertDescription>
			</Alert>
			<div className="mt-4 flex gap-3">
				<Button variant="outline" onClick={onBack}>
					← Back
				</Button>
				<Button variant="outline" onClick={() => window.location.reload()}>
					Retry
				</Button>
			</div>
		</>
	);
}

function LeadDetailNotFound({ onBack }: { onBack: () => void }) {
	return (
		<Card>
			<CardContent className="flex flex-col items-center justify-center py-16 text-center">
				<FileQuestion className="size-12 text-muted-foreground mb-4" />
				<h2 className="text-lg font-semibold mb-1">Lead not found</h2>
				<p className="text-sm text-muted-foreground mb-6">
					The lead you're looking for doesn't exist or may have been deleted.
				</p>
				<Button variant="outline" onClick={onBack}>
					← Go back
				</Button>
			</CardContent>
		</Card>
	);
}

function LeadDetailSkeleton() {
	return (
		<>
			<Skeleton className="h-8 w-56 mb-4" />

			<Card>
				<CardContent className="space-y-8 pt-6">
					{/* Top section: field rows */}
					<div>
						<div className="space-y-4">
							<SkeletonFieldRow />
							<SkeletonFieldRow />
							<SkeletonFieldRow />
							<SkeletonFieldRow />
						</div>
					</div>

					<Separator />

					{/* Additional Information */}
					<SkeletonSection />

					<Separator />

					{/* Address Information */}
					<div className="space-y-4">
						<Skeleton className="h-7 w-48 py-2" />
						<div>
							<Skeleton className="h-4 w-28 mb-1.5" />
							<Skeleton className="h-5 w-44 mb-1" />
							<Skeleton className="h-5 w-36 mb-1" />
							<Skeleton className="h-5 w-28" />
						</div>
					</div>

					<Separator />

					{/* System Information */}
					<div className="space-y-4">
						<Skeleton className="h-7 w-48 py-2" />
						<SkeletonFieldRow />
					</div>
				</CardContent>
			</Card>
		</>
	);
}

function SkeletonField() {
	return (
		<div>
			<Skeleton className="h-4 w-24 mb-1.5" />
			<Skeleton className="h-5 w-40" />
		</div>
	);
}

function SkeletonFieldRow() {
	return (
		<div className="grid grid-cols-2 gap-x-8 gap-y-4">
			<SkeletonField />
			<SkeletonField />
		</div>
	);
}

function SkeletonSection() {
	return (
		<div className="space-y-4">
			<Skeleton className="h-7 w-48 py-2" />
			<SkeletonFieldRow />
			<SkeletonFieldRow />
		</div>
	);
}
