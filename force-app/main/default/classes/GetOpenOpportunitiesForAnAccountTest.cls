/**
 * Tests for the GetOpenOpportunitiesForAnAccount prompt-template action.
 */
@IsTest
private class GetOpenOpportunitiesForAnAccountTest {
    @TestSetup
    static void setupTestData() {
        List<Account> accounts = TestDataFactory.createAccounts(2);
        List<Opportunity> opportunities = TestDataFactory.buildOpportunities(accounts[0], 3, TestDataFactory.STAGE_PROSPECTING);
        opportunities.addAll(TestDataFactory.buildOpportunities(accounts[0], 1, TestDataFactory.STAGE_CLOSED_LOST));
        insert opportunities;
    }

    private static List<GetOpenOpportunitiesForAnAccount.Response> run(Account account) {
        GetOpenOpportunitiesForAnAccount.Request request = new GetOpenOpportunitiesForAnAccount.Request();
        request.RelatedEntity = account;
        return GetOpenOpportunitiesForAnAccount.getOpportunitiesPrompt(
            new List<GetOpenOpportunitiesForAnAccount.Request>{ request }
        );
    }

    @IsTest
    static void shouldReturnOnlyOpenOpportunities_AsJson() {
        // Given
        Account withOpportunities = [SELECT Id FROM Account WHERE Name = 'Test Account 0'];

        // When
        Test.startTest();
        List<GetOpenOpportunitiesForAnAccount.Response> responses = run(withOpportunities);
        Test.stopTest();

        // Then
        List<Opportunity> returned = (List<Opportunity>) JSON.deserialize(responses[0].Prompt, List<Opportunity>.class);
        Assert.areEqual(3, returned.size(), 'Only the 3 open Opportunities should be returned, not the closed one');
        for (Opportunity opp : returned) {
            Assert.areEqual(TestDataFactory.STAGE_PROSPECTING, opp.StageName, 'Every returned Opportunity should be open');
        }
    }

    @IsTest
    static void shouldSayNoOpenOpportunities_WhenAccountHasNone() {
        // Given
        Account withoutOpportunities = [SELECT Id FROM Account WHERE Name = 'Test Account 1'];

        // When
        Test.startTest();
        List<GetOpenOpportunitiesForAnAccount.Response> responses = run(withoutOpportunities);
        Test.stopTest();

        // Then
        Assert.areEqual('There are no open opportunities.', responses[0].Prompt, 'The fallback text should be returned');
    }
}
