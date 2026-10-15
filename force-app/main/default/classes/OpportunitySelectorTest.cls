/**
 * Tests for OpportunitySelector.
 *
 * Covers null and empty guards, field population, sort order, bulk volume,
 * LIKE wildcard escaping, and USER_MODE enforcement under System.runAs.
 */
@IsTest
private class OpportunitySelectorTest {
    private static final Integer BULK_RECORD_COUNT = 251;
    private static final String WILDCARD_NAME = 'Acme 50% Discount';
    private static final String DECOY_NAME = 'Acme 5000 Deal';

    @TestSetup
    static void setupTestData() {
        Account account = TestDataFactory.createAccount();
        TestDataFactory.createOpportunities(
            account,
            BULK_RECORD_COUNT,
            TestDataFactory.STAGE_PROSPECTING
        );
    }

    // ─── Guard Clauses ───────────────────────────────────────────────────

    @IsTest
    static void shouldReturnEmptyList_WhenIdsAreNull() {
        // When
        Test.startTest();
        List<Opportunity> results = new OpportunitySelector().selectByIds(null);
        Test.stopTest();

        // Then
        Assert.areEqual(0, results.size(), 'Null input should yield an empty list');
    }

    @IsTest
    static void shouldReturnEmptyList_WhenIdsAreEmpty() {
        // When
        Test.startTest();
        List<Opportunity> results = new OpportunitySelector().selectByIds(new Set<Id>());
        Test.stopTest();

        // Then
        Assert.areEqual(0, results.size(), 'Empty input should yield an empty list');
    }

    @IsTest
    static void shouldReturnEmptyMap_WhenIdsAreEmpty() {
        // When
        Test.startTest();
        Map<Id, Opportunity> results = new OpportunitySelector()
            .selectMapByIds(new Set<Id>());
        Test.stopTest();

        // Then
        Assert.areEqual(0, results.size(), 'Empty input should yield an empty map');
    }

    @IsTest
    static void shouldReturnEmptyList_WhenNameFragmentIsBlank() {
        // When
        Test.startTest();
        List<Opportunity> results = new OpportunitySelector().selectByNameFragment('   ');
        Test.stopTest();

        // Then
        Assert.areEqual(0, results.size(), 'Blank fragment should yield an empty list');
    }

    @IsTest
    static void shouldReturnEmptyMap_WhenOwnerIdsAreNull() {
        // When
        Test.startTest();
        Map<String, Decimal> totals = new OpportunitySelector().sumAmountByStage(null);
        Test.stopTest();

        // Then
        Assert.areEqual(0, totals.size(), 'Null owners should yield an empty map');
    }

    @IsTest
    static void shouldReturnEmptyList_WhenOwnerIdsAreEmpty() {
        // When
        Test.startTest();
        List<Opportunity> results = new OpportunitySelector()
            .selectOpenByOwnerIds(new Set<Id>());
        Test.stopTest();

        // Then
        Assert.areEqual(0, results.size(), 'Empty owners should yield an empty list');
    }

    // ─── Query Behaviour ─────────────────────────────────────────────────

    @IsTest
    static void shouldPopulateFields_WhenIdsProvided() {
        // Given
        Opportunity seeded = [SELECT Id FROM Opportunity LIMIT 1];

        // When
        Test.startTest();
        List<Opportunity> results = new OpportunitySelector()
            .selectByIds(new Set<Id>{ seeded.Id });
        Test.stopTest();

        // Then
        Assert.areEqual(1, results.size(), 'Exactly one record should return');
        Opportunity actual = results[0];
        Assert.areEqual(seeded.Id, actual.Id, 'Returned record should match the requested Id');
        Assert.isNotNull(actual.StageName, 'StageName should be populated');
        Assert.isNotNull(actual.Amount, 'Amount should be populated');
        Assert.isNotNull(actual.Account.Name, 'Parent Account Name should be populated');
    }

    @IsTest
    static void shouldReturnAllRecords_WhenBulkVolume() {
        // Given
        Map<Id, Opportunity> seeded = new Map<Id, Opportunity>(
            [SELECT Id FROM Opportunity]
        );

        // When
        Test.startTest();
        List<Opportunity> results = new OpportunitySelector().selectByIds(seeded.keySet());
        Test.stopTest();

        // Then
        Assert.areEqual(BULK_RECORD_COUNT, results.size(), 'Selector should return every requested record past the 200-row boundary');
    }

    @IsTest
    static void shouldReturnOnlyOpenRecords_WhenOwnerIdsProvided() {
        // Given — close one record so the IsClosed filter has something to exclude
        Opportunity toClose = [SELECT Id FROM Opportunity LIMIT 1];
        toClose.StageName = TestDataFactory.STAGE_CLOSED_LOST;
        update toClose;

        // When
        Test.startTest();
        List<Opportunity> results = new OpportunitySelector()
            .selectOpenByOwnerIds(new Set<Id>{ UserInfo.getUserId() });
        Test.stopTest();

        // Then
        Assert.areEqual(BULK_RECORD_COUNT - 1, results.size(), 'The closed record should be excluded');
        for (Opportunity result : results) {
            Assert.isFalse(result.IsClosed, 'Every returned record should be open');
        }
    }

    @IsTest
    static void shouldOrderByCloseDateAscending_WhenSelectingOpenRecords() {
        // Given — a record that closes sooner than everything in setup
        Opportunity soonest = [SELECT Id, CloseDate FROM Opportunity LIMIT 1];
        soonest.CloseDate = Date.today();
        update soonest;

        // When
        Test.startTest();
        List<Opportunity> results = new OpportunitySelector()
            .selectOpenByOwnerIds(new Set<Id>{ UserInfo.getUserId() });
        Test.stopTest();

        // Then
        Assert.areEqual(soonest.Id, results[0].Id, 'Earliest close date should sort first');
    }

    // ─── SOQL Injection / Wildcard Safety ────────────────────────────────

    @IsTest
    static void shouldMatchLiterally_WhenNameFragmentContainsWildcard() {
        // Given — one record whose name contains a literal '%', plus a decoy
        // that shares the digits but not the '%'
        TestDataFactory.createNamedOpportunity(
            WILDCARD_NAME,
            TestDataFactory.STAGE_PROSPECTING
        );
        TestDataFactory.createNamedOpportunity(
            DECOY_NAME,
            TestDataFactory.STAGE_PROSPECTING
        );

        // When — '%' in user input must be escaped, not treated as a wildcard
        Test.startTest();
        List<Opportunity> results = new OpportunitySelector().selectByNameFragment('50%');
        Test.stopTest();

        // Then
        Assert.areEqual(1, results.size(), 'Only the record containing a literal "50%" should match');
        Assert.areEqual(WILDCARD_NAME, results[0].Name, 'The decoy containing "5000" must not match');
    }

    @IsTest
    static void shouldReturnMatchingRecords_WhenNameFragmentProvided() {
        // Given
        TestDataFactory.createNamedOpportunity(
            WILDCARD_NAME,
            TestDataFactory.STAGE_PROSPECTING
        );

        // When
        Test.startTest();
        List<Opportunity> results = new OpportunitySelector().selectByNameFragment('Acme');
        Test.stopTest();

        // Then
        Assert.areEqual(1, results.size(), 'The Acme record should match');
        Assert.areEqual(WILDCARD_NAME, results[0].Name, 'Matched name should be the Acme record');
    }

    // ─── Aggregates ──────────────────────────────────────────────────────

    @IsTest
    static void shouldSumAmountsByStage_WhenOwnerIdsProvided() {
        // Given — derive the expected total from the seeded rows themselves
        Decimal expectedTotal = 0;
        for (Opportunity seeded : [SELECT Amount FROM Opportunity WHERE Amount != NULL]) {
            expectedTotal += seeded.Amount;
        }

        // When
        Test.startTest();
        Map<String, Decimal> totals = new OpportunitySelector()
            .sumAmountByStage(new Set<Id>{ UserInfo.getUserId() });
        Test.stopTest();

        // Then
        Assert.areEqual(1, totals.size(), 'All setup records share a single stage');
        Assert.areEqual(expectedTotal, totals.get(TestDataFactory.STAGE_PROSPECTING), 'Aggregate total should equal the sum of the seeded amounts');
    }

    // ─── Security ────────────────────────────────────────────────────────

    @IsTest
    static void shouldEnforceUserMode_WhenRunningAsRestrictedUser() {
        // Given — a user with no Opportunity access, created in an isolated
        // context to avoid MIXED_DML_OPERATION
        Map<Id, Opportunity> seeded = new Map<Id, Opportunity>(
            [SELECT Id FROM Opportunity]
        );
        User restrictedUser;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            restrictedUser = TestDataFactory.createMinimumAccessUser();
        }

        // When / Then — USER_MODE must refuse the query for that user
        Test.startTest();
        System.runAs(restrictedUser) {
            try {
                new OpportunitySelector().selectByIds(seeded.keySet());
                Assert.fail('USER_MODE should block a user without Opportunity access');
            } catch (QueryException e) {
                Assert.isTrue(String.isNotBlank(e.getMessage()), 'A QueryException should explain the access failure');
            }
        }
        Test.stopTest();
    }
}