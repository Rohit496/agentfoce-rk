/**
 * Service class for Opportunity business logic.
 *
 * Owns orchestration only: it delegates every query to OpportunitySelector and
 * performs no inline SOQL. All public entry points are bulk-first and report
 * per-record outcomes rather than failing the whole transaction on one bad row.
 */
public with sharing class OpportunityService {
    // ─── Constants ───────────────────────────────────────────────────────

    /** Stage applied by closeWon. Extract to Custom Metadata if it varies per org. */
    private static final String STAGE_CLOSED_WON = 'Closed Won';

    private static final String ERROR_EMPTY_INPUT = 'At least one Opportunity Id is required.';
    private static final String ERROR_NULL_SELECTOR = 'An OpportunitySelector instance is required.';
    private static final String ERROR_BATCH_TOO_LARGE = 'Too many Opportunity Ids in one call. Maximum is ';
    private static final String ERROR_NOT_ACCESSIBLE = 'Opportunity not found or not accessible to the running user.';
    private static final String ERROR_UPDATE_FAILED = 'Unable to close Opportunities as Closed Won.';

    /** Keeps a single call comfortably inside the 10,000-row DML limit. */
    private static final Integer MAX_RECORDS_PER_CALL = 5000;

    // ─── State ───────────────────────────────────────────────────────────

    private final OpportunitySelector selector;

    // ─── Constructors ────────────────────────────────────────────────────

    /**
     * Default constructor wiring the production selector.
     */
    public OpportunityService() {
        this(new OpportunitySelector());
    }

    /**
     * Dependency-injection constructor. Tests pass a stubbed selector so the
     * business logic can be exercised without database setup.
     * @param selector The selector this service queries through
     * @throws OpportunityServiceException if selector is null
     */
    public OpportunityService(OpportunitySelector selector) {
        if (selector == null) {
            throw new OpportunityServiceException(ERROR_NULL_SELECTOR);
        }
        this.selector = selector;
    }

    // ─── Public API ──────────────────────────────────────────────────────

    /**
     * Moves the supplied Opportunities to Closed Won.
     *
     * Already-closed records are skipped rather than updated, so the method is
     * safe to re-run, and only genuinely changed records consume DML rows.
     * Partial success is used: one failing record does not roll back the rest.
     *
     * @param opportunityIds Opportunity Ids to close
     * @return CloseResult describing closed, skipped and failed records
     * @throws OpportunityServiceException if the input is empty or exceeds MAX_RECORDS_PER_CALL,
     *         or if the update fails for a reason unrelated to an individual row
     * @example
     * CloseResult result = new OpportunityService().closeWon(new Set<Id>{ oppId });
     * System.assertEquals(1, result.closedIds.size(), 'Expected the opportunity to close');
     */
    public CloseResult closeWon(Set<Id> opportunityIds) {
        validateBatch(opportunityIds);

        // One query for the whole set, outside any loop.
        Map<Id, Opportunity> opportunitiesById = selector.selectMapByIds(opportunityIds);

        CloseResult result = new CloseResult();
        List<Opportunity> pendingUpdates = triageForClosure(
            opportunityIds,
            opportunitiesById,
            result
        );

        if (!pendingUpdates.isEmpty()) {
            applyUpdates(pendingUpdates, result);
        }
        return result;
    }

    // ─── Convenience Overloads ───────────────────────────────────────────

    /**
     * Single-record convenience overload that delegates to the bulk method.
     * @param opportunityId The Opportunity to close
     * @return CloseResult for that single record
     * @throws OpportunityServiceException if opportunityId is null
     */
    public CloseResult closeWon(Id opportunityId) {
        if (opportunityId == null) {
            throw new OpportunityServiceException(ERROR_EMPTY_INPUT);
        }
        return closeWon(new Set<Id>{ opportunityId });
    }

    // ─── Private Helpers ─────────────────────────────────────────────────

    /**
     * Rejects input that cannot be processed safely.
     * @param opportunityIds The caller-supplied Ids
     * @throws OpportunityServiceException if the set is empty or oversized
     */
    private void validateBatch(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            throw new OpportunityServiceException(ERROR_EMPTY_INPUT);
        }
        if (opportunityIds.size() > MAX_RECORDS_PER_CALL) {
            throw new OpportunityServiceException(
                ERROR_BATCH_TOO_LARGE + String.valueOf(MAX_RECORDS_PER_CALL) + '.'
            );
        }
    }

    /**
     * Sorts each requested Id into closeable, skippable, or failed, and returns
     * only the records that actually need a DML row.
     * @param opportunityIds The requested Ids
     * @param opportunitiesById Records the selector was able to read
     * @param result Accumulator mutated with skipped and failed records
     * @return Records to update
     */
    private List<Opportunity> triageForClosure(
        Set<Id> opportunityIds,
        Map<Id, Opportunity> opportunitiesById,
        CloseResult result
    ) {
        List<Opportunity> pendingUpdates = new List<Opportunity>();

        for (Id opportunityId : opportunityIds) {
            Opportunity opportunity = opportunitiesById.get(opportunityId);

            if (opportunity == null) {
                // Absent means deleted or filtered out by USER_MODE sharing/FLS.
                result.failures.add(new CloseFailure(opportunityId, ERROR_NOT_ACCESSIBLE));
            } else if (opportunity.IsClosed == true) {
                // Compared against true: IsClosed is null when a caller supplies a
                // record whose IsClosed field was never queried.
                result.skippedIds.add(opportunityId);
            } else {
                pendingUpdates.add(
                    new Opportunity(Id = opportunityId, StageName = STAGE_CLOSED_WON)
                );
            }
        }
        return pendingUpdates;
    }

    /**
     * Performs the partial-success update and records each row's outcome.
     * @param pendingUpdates Records to update; must be non-empty
     * @param result Accumulator mutated with per-record outcomes
     * @throws OpportunityServiceException if the DML call itself fails
     */
    private void applyUpdates(List<Opportunity> pendingUpdates, CloseResult result) {
        List<Database.SaveResult> saveResults;
        try {
            saveResults = Database.update(
                pendingUpdates,
                false, // partial success: keep the good rows
                AccessLevel.USER_MODE // CRUD/FLS enforced for the running user
            );
        } catch (DmlException e) {
            // Preserve the cause chain rather than flattening it into a string.
            throw new OpportunityServiceException(ERROR_UPDATE_FAILED, e);
        }

        for (Integer i = 0; i < saveResults.size(); i++) {
            Database.SaveResult saveResult = saveResults[i];
            Id recordId = pendingUpdates[i].Id;

            if (saveResult.isSuccess()) {
                result.closedIds.add(recordId);
                continue;
            }

            List<String> messages = new List<String>();
            for (Database.Error error : saveResult.getErrors()) {
                messages.add(error.getMessage());
            }
            result.failures.add(
                new CloseFailure(recordId, String.join(messages, ' | '))
            );
        }
    }

    // ─── Result Types ────────────────────────────────────────────────────

    /**
     * Outcome of a closeWon call. Collections are always initialised so callers
     * never need a null check before iterating.
     */
    public class CloseResult {
        /** Ids successfully moved to Closed Won. */
        public List<Id> closedIds = new List<Id>();

        /** Ids left untouched because the Opportunity was already closed. */
        public List<Id> skippedIds = new List<Id>();

        /** Per-record failures; empty when everything succeeded. */
        public List<CloseFailure> failures = new List<CloseFailure>();

        /**
         * Reports whether every requested record was handled without error.
         * @return true when no record failed
         */
        public Boolean isCompleteSuccess() {
            return failures.isEmpty();
        }
    }

    /**
     * A single record's failure reason. The message is safe to surface to users:
     * it carries no stack trace and no record data beyond the Id.
     */
    public class CloseFailure {
        /** The Opportunity that could not be closed. */
        public Id recordId;

        /** Why it could not be closed. */
        public String message;

        /**
         * Captures one record's failure reason.
         * @param recordId The Opportunity Id that failed
         * @param message The user-safe reason for the failure
         */
        public CloseFailure(Id recordId, String message) {
            this.recordId = recordId;
            this.message = message;
        }
    }

    // ─── Exception ───────────────────────────────────────────────────────

    /**
     * Signals an OpportunityService failure that the caller is expected to handle
     * distinctly from system exceptions.
     */
    public class OpportunityServiceException extends Exception {
    }
}