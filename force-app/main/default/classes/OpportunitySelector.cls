/**
 * Selector class for Opportunity queries.
 * Encapsulates every SOQL statement for the Opportunity domain so that Service
 * and Domain layers stay free of query details.
 *
 * Declared `inherited sharing` so the calling context decides enforcement, and
 * `virtual` so tests can stub it via Test.createStub without touching the database.
 */
public inherited sharing virtual class OpportunitySelector {
    // ─── Field Lists ─────────────────────────────────────────────────────

    /**
     * Single source of truth for the fields every Opportunity query returns.
     * Centralised so field additions happen in exactly one place.
     */
    private static final List<String> BASE_FIELDS = new List<String>{
        'Id',
        'Name',
        'StageName',
        'Amount',
        'CloseDate',
        'Probability',
        'AccountId',
        'Account.Name',
        'OwnerId',
        'IsClosed',
        'IsWon',
        'Type',
        'LeadSource',
        'LastModifiedDate'
    };

    /** Upper bound applied to every query so a result set can never run unbounded. */
    private static final Integer DEFAULT_QUERY_LIMIT = 2000;

    /** Pre-built LIMIT clause. Apex will not concatenate an Integer onto a String. */
    private static final String LIMIT_CLAUSE = ' LIMIT ' + String.valueOf(DEFAULT_QUERY_LIMIT);

    /** SOQL LIKE treats these as wildcards; they must be escaped in user input. */
    private static final String LIKE_ESCAPE_PATTERN = '([\\\\%_])';

    /**
     * Builds the shared SELECT ... FROM clause from BASE_FIELDS.
     * @return The common prefix for every Opportunity query
     */
    private static String baseSelect() {
        return 'SELECT ' + String.join(BASE_FIELDS, ', ') + ' FROM Opportunity';
    }

    // ─── Query Methods ───────────────────────────────────────────────────

    /**
     * Selects Opportunity records by their Ids.
     * @param opportunityIds Set of Opportunity Ids to query; null or empty returns an empty list
     * @return Matching Opportunity records, never null
     * @example
     * List<Opportunity> records = new OpportunitySelector().selectByIds(new Set<Id>{ oppId });
     */
    public virtual List<Opportunity> selectByIds(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return new List<Opportunity>();
        }

        String soql =
            baseSelect() +
            ' WHERE Id IN :opportunityIds' +
            ' ORDER BY CloseDate DESC' +
            LIMIT_CLAUSE;

        return Database.queryWithBinds(
            soql,
            new Map<String, Object>{ 'opportunityIds' => opportunityIds },
            AccessLevel.USER_MODE
        );
    }

    /**
     * Selects Opportunity records keyed by Id for efficient lookup.
     * @param opportunityIds Set of Opportunity Ids to query
     * @return Map of Opportunity Id to record, never null
     */
    public virtual Map<Id, Opportunity> selectMapByIds(Set<Id> opportunityIds) {
        return new Map<Id, Opportunity>(selectByIds(opportunityIds));
    }

    /**
     * Selects Opportunities whose Name contains the supplied fragment.
     * The fragment is bound, never concatenated, and LIKE wildcards inside it are
     * escaped so a user-supplied '%' cannot widen the search.
     * @param nameFragment Partial Opportunity name; blank returns an empty list
     * @return Matching Opportunity records ordered by close date descending, never null
     * @example
     * List<Opportunity> records = new OpportunitySelector().selectByNameFragment('Acme');
     */
    public virtual List<Opportunity> selectByNameFragment(String nameFragment) {
        if (String.isBlank(nameFragment)) {
            return new List<Opportunity>();
        }

        String searchTerm = '%' + escapeLikeWildcards(nameFragment) + '%';

        String soql =
            baseSelect() +
            ' WHERE Name LIKE :searchTerm' +
            ' ORDER BY CloseDate DESC' +
            LIMIT_CLAUSE;

        return Database.queryWithBinds(
            soql,
            new Map<String, Object>{ 'searchTerm' => searchTerm },
            AccessLevel.USER_MODE
        );
    }

    /**
     * Selects open Opportunities owned by the supplied users.
     * Filters on OwnerId and IsClosed, both indexed, to keep the query selective.
     * @param ownerIds Set of User Ids; null or empty returns an empty list
     * @return Open Opportunity records for those owners, never null
     */
    public virtual List<Opportunity> selectOpenByOwnerIds(Set<Id> ownerIds) {
        if (ownerIds == null || ownerIds.isEmpty()) {
            return new List<Opportunity>();
        }

        String soql =
            baseSelect() +
            ' WHERE OwnerId IN :ownerIds' +
            ' AND IsClosed = false' +
            ' ORDER BY CloseDate ASC' +
            LIMIT_CLAUSE;

        return Database.queryWithBinds(
            soql,
            new Map<String, Object>{ 'ownerIds' => ownerIds },
            AccessLevel.USER_MODE
        );
    }

    /**
     * Totals pipeline Amount per stage for the supplied owners.
     * Uses an aggregate query so the rollup happens in the database rather than
     * by querying rows and summing them in Apex.
     * @param ownerIds Set of User Ids; null or empty returns an empty map
     * @return Map of StageName to summed Amount, never null
     */
    public virtual Map<String, Decimal> sumAmountByStage(Set<Id> ownerIds) {
        Map<String, Decimal> amountByStage = new Map<String, Decimal>();
        if (ownerIds == null || ownerIds.isEmpty()) {
            return amountByStage;
        }

        List<AggregateResult> rows = [
            SELECT StageName stage, SUM(Amount) total
            FROM Opportunity
            WHERE OwnerId IN :ownerIds AND Amount != NULL
            WITH USER_MODE
            GROUP BY StageName
            LIMIT :DEFAULT_QUERY_LIMIT
        ];

        for (AggregateResult row : rows) {
            amountByStage.put(
                (String) row.get('stage'),
                (Decimal) row.get('total')
            );
        }
        return amountByStage;
    }

    // ─── Private Helpers ─────────────────────────────────────────────────

    /**
     * Escapes backslash, percent and underscore so they match literally in a LIKE clause.
     * Note this is deliberately not String.escapeSingleQuotes — that method is for
     * concatenated SOQL and would corrupt a value passed as a bind variable.
     * @param value Raw user input
     * @return The value with LIKE wildcards escaped
     */
    private static String escapeLikeWildcards(String value) {
        return value.replaceAll(LIKE_ESCAPE_PATTERN, '\\\\$1');
    }
}