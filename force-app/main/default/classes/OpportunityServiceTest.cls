/**
 * Tests for OpportunityService.
 *
 * Splits into two groups: stub-backed tests that exercise the orchestration logic
 * with zero DML, and integration tests that prove the real DML path behaves.
 */
@IsTest
private class OpportunityServiceTest {
    private static final Integer BULK_RECORD_COUNT = 251;
    private static final Integer OVER_BATCH_LIMIT = 5001;
    private static final String STAGE_CLOSED_WON = 'Closed Won';

    @TestSetup
    static void setupTestData() {
        Account account = TestDataFactory.createAccount();
        TestDataFactory.createOpportunities(
            account,
            BULK_RECORD_COUNT,
            TestDataFactory.STAGE_PROSPECTING
        );
    }

    // ─── Constructor ─────────────────────────────────────────────────────

    @IsTest
    static void shouldThrowException_WhenSelectorIsNull() {
        // When / Then
        Test.startTest();
        try {
            new OpportunityService(null);
            Assert.fail('Expected OpportunityServiceException for a null selector');
        } catch (OpportunityService.OpportunityServiceException e) {
            Assert.isTrue(
                e.getMessage().contains('OpportunitySelector'),
                'Message should name the missing dependency, got: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    // ─── Input Validation ────────────────────────────────────────────────

    @IsTest
    static void shouldThrowException_WhenIdSetIsNull() {
        // Given
        OpportunityService service = new OpportunityService();

        // When / Then
        Test.startTest();
        try {
            service.closeWon((Set<Id>) null);
            Assert.fail('Expected OpportunityServiceException for null input');
        } catch (OpportunityService.OpportunityServiceException e) {
            Assert.isTrue(
                e.getMessage().contains('required'),
                'Message should state an Id is required, got: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowException_WhenIdSetIsEmpty() {
        // Given
        OpportunityService service = new OpportunityService();

        // When / Then
        Test.startTest();
        try {
            service.closeWon(new Set<Id>());
            Assert.fail('Expected OpportunityServiceException for empty input');
        } catch (OpportunityService.OpportunityServiceException e) {
            Assert.isTrue(
                e.getMessage().contains('required'),
                'Message should state an Id is required, got: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowException_WhenSingleIdIsNull() {
        // Given
        OpportunityService service = new OpportunityService();

        // When / Then
        Test.startTest();
        try {
            service.closeWon((Id) null);
            Assert.fail('Expected OpportunityServiceException for a null Id');
        } catch (OpportunityService.OpportunityServiceException e) {
            Assert.isTrue(
                e.getMessage().contains('required'),
                'Message should state an Id is required, got: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowException_WhenBatchExceedsMaximum() {
        // Given — fake Ids only, so this costs no DML
        Set<Id> oversizedBatch = new Set<Id>();
        for (Integer i = 0; i < OVER_BATCH_LIMIT; i++) {
            oversizedBatch.add(TestDataFactory.generateFakeId(Opportunity.SObjectType));
        }
        OpportunityService service = new OpportunityService();

        // When / Then
        Test.startTest();
        try {
            service.closeWon(oversizedBatch);
            Assert.fail('Expected OpportunityServiceException for an oversized batch');
        } catch (OpportunityService.OpportunityServiceException e) {
            Assert.isTrue(
                e.getMessage().contains('Maximum is'),
                'Message should state the maximum, got: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    // ─── Behaviour (stub-backed, no DML) ─────────────────────────────────

    @IsTest
    static void shouldSkipOpportunity_WhenAlreadyClosed() {
        // Given — a closed Opportunity returned by a stubbed selector
        Id closedId = TestDataFactory.generateFakeId(Opportunity.SObjectType);
        Opportunity closed = TestDataFactory.buildClosedOpportunity(
            closedId,
            TestDataFactory.STAGE_CLOSED_LOST
        );
        OpportunityService service = new OpportunityService(
            stubSelectorReturning(new Map<Id, Opportunity>{ closedId => closed })
        );

        // When
        Test.startTest();
        OpportunityService.CloseResult result = service.closeWon(new Set<Id>{ closedId });
        Test.stopTest();

        // Then
        Assert.areEqual(1, result.skippedIds.size(), 'Closed record should be skipped');
        Assert.areEqual(closedId, result.skippedIds[0], 'Skipped Id should match input');
        Assert.areEqual(0, result.closedIds.size(), 'Nothing should have been closed');
        Assert.isTrue(result.isCompleteSuccess(), 'A skip is not a failure');
    }

    @IsTest
    static void shouldReportFailure_WhenRecordIsNotAccessible() {
        // Given — the selector returns nothing for the requested Id
        Id missingId = TestDataFactory.generateFakeId(Opportunity.SObjectType);
        OpportunityService service = new OpportunityService(
            stubSelectorReturning(new Map<Id, Opportunity>())
        );

        // When
        Test.startTest();
        OpportunityService.CloseResult result = service.closeWon(new Set<Id>{ missingId });
        Test.stopTest();

        // Then
        Assert.areEqual(1, result.failures.size(), 'Inaccessible record should be reported');
        Assert.areEqual(missingId, result.failures[0].recordId, 'Failure should carry the Id');
        Assert.isFalse(result.isCompleteSuccess(), 'Result should not report complete success');
        Assert.areEqual(0, result.closedIds.size(), 'Nothing should have been closed');
    }

    @IsTest
    static void shouldReportFailure_WhenUpdateRejectsTheRecord() {
        // Given — the selector reports an open Opportunity that does not exist in
        // the database, so the DML row is rejected while the call itself succeeds.
        // IsClosed is deliberately left unset to prove the null-safe stage check.
        Id ghostId = TestDataFactory.generateFakeId(Opportunity.SObjectType);
        Opportunity ghost = new Opportunity(
            Id = ghostId,
            StageName = TestDataFactory.STAGE_PROSPECTING
        );
        OpportunityService service = new OpportunityService(
            stubSelectorReturning(new Map<Id, Opportunity>{ ghostId => ghost })
        );

        // When
        Test.startTest();
        OpportunityService.CloseResult result = service.closeWon(new Set<Id>{ ghostId });
        Test.stopTest();

        // Then — partial success: the bad row is reported, nothing is thrown
        Assert.areEqual(1, result.failures.size(), 'The rejected row should be reported');
        Assert.areEqual(ghostId, result.failures[0].recordId, 'Failure should carry the Id');
        Assert.isTrue(
            String.isNotBlank(result.failures[0].message),
            'Failure should carry a reason from the SaveResult'
        );
        Assert.isFalse(result.isCompleteSuccess(), 'Result should not report complete success');
        Assert.areEqual(0, result.closedIds.size(), 'Nothing should have been closed');
    }

    // ─── Behaviour (real DML) ────────────────────────────────────────────

    @IsTest
    static void shouldCloseOpportunity_WhenOpen() {
        // Given
        Opportunity target = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityService service = new OpportunityService();

        // When
        Test.startTest();
        OpportunityService.CloseResult result = service.closeWon(new Set<Id>{ target.Id });
        Test.stopTest();

        // Then
        Assert.areEqual(1, result.closedIds.size(), 'One record should be closed');
        Assert.isTrue(result.isCompleteSuccess(), 'No failures expected');
        Opportunity reloaded = [SELECT StageName, IsWon FROM Opportunity WHERE Id = :target.Id];
        Assert.areEqual(STAGE_CLOSED_WON, reloaded.StageName, 'Stage should be Closed Won');
        Assert.isTrue(reloaded.IsWon, 'Opportunity should be flagged as won');
    }

    @IsTest
    static void shouldCloseOpportunity_WhenUsingSingleIdOverload() {
        // Given
        Opportunity target = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityService service = new OpportunityService();

        // When
        Test.startTest();
        OpportunityService.CloseResult result = service.closeWon(target.Id);
        Test.stopTest();

        // Then
        Assert.areEqual(1, result.closedIds.size(), 'Overload should close one record');
        Assert.areEqual(target.Id, result.closedIds[0], 'Closed Id should match input');
    }

    @IsTest
    static void shouldCloseAllOpportunities_WhenBulkVolume() {
        // Given — 251 records, past the 200-record batch boundary
        Map<Id, Opportunity> opportunitiesById = new Map<Id, Opportunity>(
            [SELECT Id FROM Opportunity]
        );
        Assert.areEqual(
            BULK_RECORD_COUNT,
            opportunitiesById.size(),
            'Setup should have created the full bulk volume'
        );
        OpportunityService service = new OpportunityService();

        // When
        Test.startTest();
        OpportunityService.CloseResult result = service.closeWon(opportunitiesById.keySet());
        Test.stopTest();

        // Then
        Assert.areEqual(
            BULK_RECORD_COUNT,
            result.closedIds.size(),
            'Every record should be closed'
        );
        Assert.isTrue(result.isCompleteSuccess(), 'Bulk run should report no failures');
        Assert.areEqual(
            BULK_RECORD_COUNT,
            [SELECT COUNT() FROM Opportunity WHERE StageName = :STAGE_CLOSED_WON],
            'All records should persist as Closed Won'
        );
    }

    @IsTest
    static void shouldSkipUnchangedRecords_WhenRunTwice() {
        // Given — a first run that closes everything
        Map<Id, Opportunity> opportunitiesById = new Map<Id, Opportunity>(
            [SELECT Id FROM Opportunity]
        );
        OpportunityService service = new OpportunityService();
        service.closeWon(opportunitiesById.keySet());

        // When — the same call is replayed
        Test.startTest();
        OpportunityService.CloseResult result = service.closeWon(opportunitiesById.keySet());
        Test.stopTest();

        // Then — idempotent: no further DML, everything skipped
        Assert.areEqual(
            BULK_RECORD_COUNT,
            result.skippedIds.size(),
            'Second run should skip every already-closed record'
        );
        Assert.areEqual(0, result.closedIds.size(), 'Second run should close nothing');
    }

    // ─── Helpers ─────────────────────────────────────────────────────────

    /**
     * Builds a stubbed OpportunitySelector whose selectMapByIds returns a fixed map.
     * @param toReturn The map the stub should hand back
     * @return A stubbed selector instance
     */
    private static OpportunitySelector stubSelectorReturning(Map<Id, Opportunity> toReturn) {
        return (OpportunitySelector) Test.createStub(
            OpportunitySelector.class,
            new SelectorStub(toReturn)
        );
    }

    /**
     * Minimal StubProvider standing in for OpportunitySelector so service logic can
     * be tested without querying.
     */
    private class SelectorStub implements System.StubProvider {
        private final Map<Id, Opportunity> toReturn;

        /**
         * Captures the canned response this stub will return.
         * @param toReturn The map selectMapByIds should hand back
         */
        private SelectorStub(Map<Id, Opportunity> toReturn) {
            this.toReturn = toReturn;
        }

        /**
         * Routes a stubbed call to the canned response.
         * @param stubbedObject The stub instance
         * @param stubbedMethodName Name of the invoked method
         * @param returnType Declared return type
         * @param listOfParamTypes Declared parameter types
         * @param listOfParamNames Declared parameter names
         * @param listOfArgs Arguments the caller passed
         * @return The canned response, or null for unstubbed methods
         */
        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs
        ) {
            if (stubbedMethodName == 'selectMapByIds') {
                return toReturn;
            }
            if (stubbedMethodName == 'selectByIds') {
                return toReturn.values();
            }
            return null;
        }
    }
}