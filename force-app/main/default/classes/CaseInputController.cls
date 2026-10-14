/**
 * CaseInputController
 *
 * Agentforce action + Custom Lightning Type (CLT) data shape for collecting
 * "Case Information" from the user through a rich LWC form (see the
 * `caseInputForm` LWC and the `caseData` Lightning Type bundle).
 *
 * The inner `CaseData` class is bound to the `caseData` Lightning Type via
 *   lightningTypes/caseData/schema.json ->
 *   "@apexClassType/c__CaseInputController$CaseData"
 * so the LWC editor emits an object whose field names exactly match the
 * @InvocableVariable fields below. Keep them in sync — a mismatch silently
 * breaks the CLT binding.
 *
 * `createCase` consumes the same shape directly (no envelope wrapper) and
 * inserts a Case record.
 */
public with sharing class CaseInputController {
    /**
     * Data shape rendered/collected by the caseInputForm CLT editor.
     * Field names MUST match the object emitted by the LWC `value` getter.
     */
    public class CaseData {
        // Named caseSubject/caseDescription (not subject/description) because
        // 'description' is a reserved token in the planner's schema language
        // and breaks user-input validation for the c__caseData type.
        @InvocableVariable(label='Subject')
        public String caseSubject;

        @InvocableVariable(label='Description')
        public String caseDescription;

        @InvocableVariable(label='Status' required=true)
        public String status;

        @InvocableVariable(label='Priority')
        public String priority;

        @InvocableVariable(label='Contact Id')
        public String contactId;

        @InvocableVariable(label='Contact Name')
        public String contactName;

        @InvocableVariable(label='Account Id')
        public String accountId;

        @InvocableVariable(label='Account Name')
        public String accountName;

        @InvocableVariable(label='Type')
        public String type;

        @InvocableVariable(label='Case Origin' required=true)
        public String caseOrigin;

        @InvocableVariable(label='Case Reason')
        public String caseReason;
    }

    /**
     * Invocable request wrapper. Exposes a SINGLE object-typed field `casedata`
     * so Agentforce binds it to the `c__caseData` Custom Lightning Type (and
     * renders the caseInputForm editor) instead of flattening CaseData's fields
     * into individual text inputs. Mirrors OpportunityCreateController's oppdata.
     */
    public class CreateCaseRequest {
        @InvocableVariable(label='Case Data' required=true)
        public CaseData casedata;
    }

    /**
     * Invocable response wrapper. Exposes a SINGLE object-typed field
     * `caseresult` bound to the `c__caseResult` Custom Lightning Type so the
     * caseResultRenderer output component renders the confirmation card.
     */
    public class CreateCaseResponse {
        @InvocableVariable(label='Case Result')
        public CaseResult caseresult;
    }

    /**
     * Response returned to the agent after the Case is created.
     */
    public class CaseResult {
        @InvocableVariable(label='Case Id')
        public String caseId;

        @InvocableVariable(label='Case Number')
        public String caseNumber;

        @InvocableVariable(label='Subject')
        public String subject;

        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Priority')
        public String priority;

        @InvocableVariable(label='Description')
        public String description;

        @InvocableVariable(label='Created Date')
        public String createdDate;

        @InvocableVariable(label='Estimated Response')
        public String estimatedResponse;

        @InvocableVariable(label='Prompt')
        public String prompt;
    }

    /**
     * Creates a Case from the collected Case Information.
     *
     * @param requests one CaseData per invocation (Agentforce passes a single
     *                 collected form value)
     * @return one CaseResult per request
     */
    @InvocableMethod(
        label='Create Case from Case Information'
        description='Creates a Case record from the Case Information collected via the caseInputForm custom Lightning Type.'
    )
    public static List<CreateCaseResponse> createCase(
        List<CreateCaseRequest> requests
    ) {
        List<Case> toInsert = new List<Case>();

        for (CreateCaseRequest req : requests) {
            CaseData data = req.casedata;
            Case c = new Case();
            c.Status = String.isBlank(data.status) ? 'New' : data.status;
            c.Priority = String.isBlank(data.priority)
                ? 'Medium'
                : data.priority;
            c.Origin = data.caseOrigin;

            if (String.isNotBlank(data.caseSubject)) {
                c.Subject = data.caseSubject;
            }
            if (String.isNotBlank(data.caseDescription)) {
                c.Description = data.caseDescription;
            }
            if (String.isNotBlank(data.type)) {
                c.Type = data.type;
            }
            if (String.isNotBlank(data.caseReason)) {
                c.Reason = data.caseReason;
            }
            if (String.isNotBlank(data.contactId)) {
                c.ContactId = data.contactId;
            }
            if (String.isNotBlank(data.accountId)) {
                c.AccountId = data.accountId;
            }

            toInsert.add(c);
        }

        insert toInsert;

        List<Case> inserted = [
            SELECT
                Id,
                CaseNumber,
                Subject,
                Status,
                Priority,
                Description,
                CreatedDate
            FROM Case
            WHERE Id IN :toInsert
        ];

        List<CreateCaseResponse> responses = new List<CreateCaseResponse>();
        for (Case c : inserted) {
            CaseResult r = new CaseResult();
            r.caseId = c.Id;
            r.caseNumber = c.CaseNumber;
            r.subject = c.Subject;
            r.status = c.Status;
            r.priority = c.Priority;
            r.description = c.Description;
            r.createdDate = c.CreatedDate == null
                ? null
                : c.CreatedDate.format('MMMM d, yyyy');
            r.estimatedResponse = estimatedResponseFor(c.Priority);
            r.prompt = 'Case ' + c.CaseNumber + ' was created successfully.';

            CreateCaseResponse resp = new CreateCaseResponse();
            resp.caseresult = r;
            responses.add(resp);
        }
        return responses;
    }

    /**
     * Maps a Case Priority to a human-readable estimated response SLA.
     */
    private static String estimatedResponseFor(String priority) {
        if (priority == 'High') {
            return 'Within 24 hours';
        } else if (priority == 'Low') {
            return 'Within 72 hours';
        }
        return 'Within 48 hours';
    }
}