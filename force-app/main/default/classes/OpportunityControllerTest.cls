@isTest
private class OpportunityControllerTest {
    @TestSetup
    static void setupTestData() {
        // The org requires Account.Type (custom validation rule), so test Accounts must set it.
        Account testAccount1 = new Account(Name = 'Acme Corp', Type = 'Customer - Direct');
        Account testAccount2 = new Account(Name = 'Global Industries', Type = 'Customer - Direct');
        insert new List<Account>{ testAccount1, testAccount2 };

        List<Opportunity> opportunities = new List<Opportunity>{
            new Opportunity(
                Name = 'Enterprise Deal',
                AccountId = testAccount1.Id,
                Amount = 100000,
                CloseDate = Date.today().addDays(30),
                StageName = 'Prospecting'
            ),
            new Opportunity(
                Name = 'Small Business Package',
                AccountId = testAccount2.Id,
                Amount = 25000,
                CloseDate = Date.today().addDays(60),
                StageName = 'Qualification'
            ),
            new Opportunity(
                Name = 'Enterprise Renewal',
                AccountId = testAccount1.Id,
                Amount = 150000,
                CloseDate = Date.today().addDays(15),
                StageName = 'Negotiation'
            )
        };
        insert opportunities;
    }

    @isTest
    static void testGetOpportunities_WithName_MatchesName() {
        OpportunityController.OpportunityRequest request = new OpportunityController.OpportunityRequest();
        request.opportunityName = 'Enterprise';

        List<OpportunityController.OpportunityResponse> responses = OpportunityController.getOpportunities(
            new List<OpportunityController.OpportunityRequest>{ request }
        );

        Assert.areEqual(1, responses.size(), 'Should return one response wrapper');
        Assert.areEqual(2, responses[0].opportunityOptions.size(), 'Should find two opportunities matching name');
        Assert.isTrue(responses[0]
                .opportunityOptions[0]
                .name.contains('Enterprise'), 'First result should contain Enterprise');
    }

    @isTest
    static void testGetOpportunities_WithName_NoMatch() {
        OpportunityController.OpportunityRequest request = new OpportunityController.OpportunityRequest();
        request.opportunityName = 'NonExistent Deal';

        List<OpportunityController.OpportunityResponse> responses = OpportunityController.getOpportunities(
            new List<OpportunityController.OpportunityRequest>{ request }
        );

        Assert.areEqual(1, responses.size(), 'Expected responses.size() to equal 1');
        Assert.areEqual(0, responses[0].opportunityOptions.size(), 'Should return no opportunities for unmatched name');
    }

    @isTest
    static void testGetOpportunities_WithBlankName_ReturnsAll() {
        OpportunityController.OpportunityRequest request = new OpportunityController.OpportunityRequest();
        request.opportunityName = '';

        List<OpportunityController.OpportunityResponse> responses = OpportunityController.getOpportunities(
            new List<OpportunityController.OpportunityRequest>{ request }
        );

        Assert.areEqual(1, responses.size(), 'Expected responses.size() to equal 1');
        Assert.areEqual(3, responses[0].opportunityOptions.size(), 'Should return all opportunities when name is blank');
    }

    @isTest
    static void testGetOpportunities_WithNullName_ReturnsAll() {
        OpportunityController.OpportunityRequest request = new OpportunityController.OpportunityRequest();
        request.opportunityName = null;

        List<OpportunityController.OpportunityResponse> responses = OpportunityController.getOpportunities(
            new List<OpportunityController.OpportunityRequest>{ request }
        );

        Assert.areEqual(1, responses.size(), 'Expected responses.size() to equal 1');
        Assert.areEqual(3, responses[0].opportunityOptions.size(), 'Should return all opportunities when name is null');
    }

    @isTest
    static void testGetOpportunities_WithNullRequest_ReturnsAll() {
        List<OpportunityController.OpportunityResponse> responses = OpportunityController.getOpportunities(
            null
        );

        Assert.areEqual(1, responses.size(), 'Expected responses.size() to equal 1');
        Assert.areEqual(3, responses[0].opportunityOptions.size(), 'Should return all opportunities when request is null');
    }

    @isTest
    static void testGetOpportunities_WithEmptyRequestList_ReturnsAll() {
        List<OpportunityController.OpportunityResponse> responses = OpportunityController.getOpportunities(
            new List<OpportunityController.OpportunityRequest>()
        );

        Assert.areEqual(1, responses.size(), 'Expected responses.size() to equal 1');
        Assert.areEqual(3, responses[0].opportunityOptions.size(), 'Should return all opportunities when request list is empty');
    }

    @isTest
    static void testOpportunityFieldMapping() {
        OpportunityController.OpportunityRequest request = new OpportunityController.OpportunityRequest();
        request.opportunityName = 'Small Business';

        List<OpportunityController.OpportunityResponse> responses = OpportunityController.getOpportunities(
            new List<OpportunityController.OpportunityRequest>{ request }
        );

        OpportunityController.OpportunityDetail opp = responses[0]
            .opportunityOptions[0];
        Assert.isNotNull(opp.id, 'Id should be populated');
        Assert.areEqual('Small Business Package', opp.name, 'Expected opp.name to equal \'Small Business Package\'');
        Assert.areEqual('Global Industries', opp.accountName, 'Expected opp.accountName to equal \'Global Industries\'');
        Assert.areEqual(25000, opp.amount, 'Expected opp.amount to equal 25000');
        Assert.isNotNull(opp.closeDate, 'Expected a value (not null): opp.closeDate');
    }

    @isTest
    static void testOpportunities_OrderedByCloseDateDesc() {
        OpportunityController.OpportunityRequest request = new OpportunityController.OpportunityRequest();

        List<OpportunityController.OpportunityResponse> responses = OpportunityController.getOpportunities(
            new List<OpportunityController.OpportunityRequest>{ request }
        );

        List<OpportunityController.OpportunityDetail> opps = responses[0]
            .opportunityOptions;
        Assert.areEqual(3, opps.size(), 'Expected opps.size() to equal 3');

        for (Integer i = 0; i < opps.size() - 1; i++) {
            Assert.isTrue(opps[i].closeDate >= opps[i + 1].closeDate, 'Opportunities should be ordered by CloseDate descending');
        }
    }

    @isTest
    static void testOpportunity_WithNullAccountName() {
        Opportunity oppWithoutAccount = new Opportunity(
            Name = 'No Account Deal',
            Amount = 50000,
            CloseDate = Date.today().addDays(45),
            StageName = 'Prospecting'
        );
        insert oppWithoutAccount;

        OpportunityController.OpportunityRequest request = new OpportunityController.OpportunityRequest();
        request.opportunityName = 'No Account';

        List<OpportunityController.OpportunityResponse> responses = OpportunityController.getOpportunities(
            new List<OpportunityController.OpportunityRequest>{ request }
        );

        Assert.areEqual(1, responses[0].opportunityOptions.size(), 'Expected responses[0].opportunityOptions.size() to equal 1');
        Assert.isNull(responses[0].opportunityOptions[0].accountName, 'Account name should be null when no account is associated');
    }
}