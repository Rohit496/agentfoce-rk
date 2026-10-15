/**
 * Tests for the OpportunityCreateController "Create Opportunity" Agentforce action.
 */
@IsTest
private class OpportunityCreateControllerTest {
    private static final Date CLOSE_DATE = Date.today().addDays(30);

    @TestSetup
    static void setupTestData() {
        TestDataFactory.createAccounts(1); // 'Test Account 0'
    }

    private static List<OpportunityCreateController.CreateOpportunityResponse> create(
        String opportunityName,
        String accountName,
        Decimal amount,
        Date closeDate
    ) {
        OpportunityCreateController.OpportunityData data = new OpportunityCreateController.OpportunityData();
        data.opportunityName = opportunityName;
        data.accountName = accountName;
        data.amount = amount;
        data.closeDate = closeDate;
        OpportunityCreateController.CreateOpportunityRequest request = new OpportunityCreateController.CreateOpportunityRequest();
        request.oppdata = data;
        return OpportunityCreateController.createOpportunity(
            new List<OpportunityCreateController.CreateOpportunityRequest>{ request }
        );
    }

    @IsTest
    static void shouldLinkToExistingAccount_WhenAccountNameExists() {
        // When
        Test.startTest();
        List<OpportunityCreateController.CreateOpportunityResponse> responses = create('Big Deal', 'Test Account 0', 50000, CLOSE_DATE);
        Test.stopTest();

        // Then
        Assert.areEqual('Opportunity "Big Deal" created successfully.', responses[0].message, 'Success message should name the Opportunity');
        Opportunity created = [SELECT Account.Name, Amount, CloseDate, StageName FROM Opportunity WHERE Name = 'Big Deal'];
        Assert.areEqual('Test Account 0', created.Account.Name, 'The existing Account should be linked');
        Assert.areEqual(50000, created.Amount, 'Amount should be saved');
        Assert.areEqual(CLOSE_DATE, created.CloseDate, 'Close date should be saved');
        Assert.areEqual('Prospecting', created.StageName, 'New Opportunities start in Prospecting');
        Assert.areEqual(1, [SELECT COUNT() FROM Account], 'No new Account should be created');
    }

    @IsTest
    static void shouldCreateOpportunityWithoutAccount_WhenNoAccountName() {
        // When
        Test.startTest();
        List<OpportunityCreateController.CreateOpportunityResponse> responses = create('Solo Deal', null, null, CLOSE_DATE);
        Test.stopTest();

        // Then
        Assert.areEqual('Opportunity "Solo Deal" created successfully.', responses[0].message, 'The Opportunity should be created');
        Opportunity created = [SELECT AccountId FROM Opportunity WHERE Name = 'Solo Deal'];
        Assert.isNull(created.AccountId, 'No Account should be linked when none was given');
    }

    @IsTest
    static void shouldCreateAccountWithDefaultType_WhenAccountNameIsNew() {
        // When
        Test.startTest();
        List<OpportunityCreateController.CreateOpportunityResponse> responses = create('New Logo Deal', 'Brand New Co', 1000, CLOSE_DATE);
        Test.stopTest();

        // Then
        Assert.areEqual('Opportunity "New Logo Deal" created successfully.', responses[0].message, 'Success should be reported');
        Account newAccount = [SELECT Id, Type FROM Account WHERE Name = 'Brand New Co'];
        Assert.areEqual(AccountDefaults.ACCOUNT_TYPE, newAccount.Type, 'The new Account needs a Type for the org validation rule');
        Opportunity created = [SELECT AccountId FROM Opportunity WHERE Name = 'New Logo Deal'];
        Assert.areEqual(newAccount.Id, created.AccountId, 'The Opportunity should be linked to the new Account');
    }

    @IsTest
    static void shouldReportFailure_WhenCloseDateMissing() {
        // When: CloseDate is required on Opportunity
        Test.startTest();
        List<OpportunityCreateController.CreateOpportunityResponse> responses = create('No Date Deal', null, 100, null);
        Test.stopTest();

        // Then
        Assert.isTrue(responses[0].message.startsWith('Failed to create opportunity: '), 'A missing close date should be reported');
        Assert.areEqual(0, [SELECT COUNT() FROM Opportunity], 'No Opportunity should be created');
    }

    @IsTest
    static void shouldReportNoData_WhenRequestsEmpty() {
        // When
        Test.startTest();
        List<OpportunityCreateController.CreateOpportunityResponse> emptyResponses = OpportunityCreateController.createOpportunity(
            new List<OpportunityCreateController.CreateOpportunityRequest>()
        );
        List<OpportunityCreateController.CreateOpportunityResponse> nullResponses = OpportunityCreateController.createOpportunity(null);
        Test.stopTest();

        // Then
        Assert.areEqual('No request data provided.', emptyResponses[0].message, 'An empty request list should be reported');
        Assert.areEqual('No request data provided.', nullResponses[0].message, 'A null request list should be reported');
    }
}
