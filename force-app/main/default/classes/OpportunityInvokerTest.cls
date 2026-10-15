/**
 * Tests for the OpportunityInvoker "Fetch Opportunities By Name" invocable.
 */
@IsTest
private class OpportunityInvokerTest {
    @TestSetup
    static void setupTestData() {
        Account account = TestDataFactory.createAccount();
        List<Opportunity> opportunities = new List<Opportunity>{
            TestDataFactory.buildOpportunities(account, 1, TestDataFactory.STAGE_PROSPECTING)[0],
            TestDataFactory.buildOpportunities(account, 1, TestDataFactory.STAGE_PROSPECTING)[0],
            TestDataFactory.buildOpportunities(account, 1, TestDataFactory.STAGE_PROSPECTING)[0]
        };
        opportunities[0].Name = 'Alpha';
        opportunities[1].Name = 'Beta';
        opportunities[2].Name = 'Beta'; // two Opportunities share a name
        opportunities[2].NextStep = 'Send proposal';
        insert opportunities;
    }

    private static OpportunityInvoker.Request request(List<String> names) {
        OpportunityInvoker.Request req = new OpportunityInvoker.Request();
        req.opportunityNames = names;
        return req;
    }

    @IsTest
    static void shouldReturnMatchesPerRequest_InNameOrder() {
        // When
        Test.startTest();
        List<List<OpportunityInvoker.OpportunityResult>> results = OpportunityInvoker.fetchOpportunitiesByName(
            new List<OpportunityInvoker.Request>{ request(new List<String>{ 'Beta', 'Alpha' }), request(new List<String>{ 'Alpha' }) }
        );
        Test.stopTest();

        // Then
        Assert.areEqual(2, results.size(), 'One result list per request');
        Assert.areEqual(3, results[0].size(), 'Both "Beta" Opportunities and "Alpha" should be returned');
        Assert.areEqual('Beta', results[0][0].Name, 'Results follow the order of the requested names');
        Assert.areEqual('Alpha', results[0][2].Name, 'Alpha was requested last, so it comes last');
        Assert.areEqual(1, results[1].size(), 'The second request only asked for Alpha');
        Assert.areEqual(TestDataFactory.STAGE_PROSPECTING, results[1][0].StageName, 'Selected fields should be mapped');
        Assert.isNotNull(results[1][0].AccountId, 'AccountId should be mapped');
    }

    @IsTest
    static void shouldReturnEmptyList_ForUnknownNames() {
        // When
        Test.startTest();
        List<List<OpportunityInvoker.OpportunityResult>> results = OpportunityInvoker.fetchOpportunitiesByName(
            new List<OpportunityInvoker.Request>{ request(new List<String>{ 'Gamma' }) }
        );
        Test.stopTest();

        // Then
        Assert.areEqual(1, results.size(), 'Still one result list for the request');
        Assert.isTrue(results[0].isEmpty(), 'An unknown name matches nothing');
    }

    @IsTest
    static void shouldReturnEmptyListsPerRequest_WhenNoNamesGiven() {
        // When
        Test.startTest();
        List<List<OpportunityInvoker.OpportunityResult>> results = OpportunityInvoker.fetchOpportunitiesByName(
            new List<OpportunityInvoker.Request>{ request(null), request(new List<String>()) }
        );
        Test.stopTest();

        // Then
        Assert.areEqual(2, results.size(), 'The output keeps one list per request');
        Assert.isTrue(results[0].isEmpty() && results[1].isEmpty(), 'No names means no results');
    }

    @IsTest
    static void shouldSkipNullRequest_AmongValidOnes() {
        // When
        Test.startTest();
        List<List<OpportunityInvoker.OpportunityResult>> results = OpportunityInvoker.fetchOpportunitiesByName(
            new List<OpportunityInvoker.Request>{ null, request(new List<String>{ 'Alpha' }) }
        );
        Test.stopTest();

        // Then
        Assert.areEqual(2, results.size(), 'A null request still gets a result slot');
        Assert.isTrue(results[0].isEmpty(), 'The null request yields an empty list');
        Assert.areEqual(1, results[1].size(), 'The valid request is still answered');
    }
}
