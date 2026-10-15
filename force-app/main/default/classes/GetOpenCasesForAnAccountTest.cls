/**
 * Tests for the GetOpenCasesForAnAccount prompt-template action.
 */
@IsTest
private class GetOpenCasesForAnAccountTest {
    @TestSetup
    static void setupTestData() {
        List<Account> accounts = TestDataFactory.createAccounts(2);
        List<Case> cases = TestDataFactory.buildCases(accounts[0].Id, 2, 'New');
        cases.addAll(TestDataFactory.buildCases(accounts[0].Id, 1, 'Closed'));
        insert cases;
    }

    private static List<GetOpenCasesForAnAccount.Response> run(Account account) {
        GetOpenCasesForAnAccount.Request request = new GetOpenCasesForAnAccount.Request();
        request.RelatedEntity = account;
        return GetOpenCasesForAnAccount.getOpenCases(new List<GetOpenCasesForAnAccount.Request>{ request });
    }

    @IsTest
    static void shouldReturnOnlyOpenCases_AsJson() {
        // Given
        Account withCases = [SELECT Id FROM Account WHERE Name = 'Test Account 0'];

        // When
        Test.startTest();
        List<GetOpenCasesForAnAccount.Response> responses = run(withCases);
        Test.stopTest();

        // Then
        Assert.areEqual(1, responses.size(), 'One response per call');
        List<Case> returned = (List<Case>) JSON.deserialize(responses[0].Prompt, List<Case>.class);
        Assert.areEqual(2, returned.size(), 'Only the 2 open Cases should be returned, not the closed one');
        for (Case c : returned) {
            Assert.areEqual('New', c.Status, 'Every returned Case should be open');
        }
    }

    @IsTest
    static void shouldSayNoOpenCases_WhenAccountHasNone() {
        // Given
        Account withoutCases = [SELECT Id FROM Account WHERE Name = 'Test Account 1'];

        // When
        Test.startTest();
        List<GetOpenCasesForAnAccount.Response> responses = run(withoutCases);
        Test.stopTest();

        // Then
        Assert.areEqual('There are no open cases.', responses[0].Prompt, 'An Account without open Cases gets the fallback text');
    }
}
