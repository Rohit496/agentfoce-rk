@isTest
private class OpportunityControllerTest {
    @TestSetup
    static void setupTestData() {
        Account testAccount1 = new Account(Name = 'Acme Corp');
        Account testAccount2 = new Account(Name = 'Global Industries');
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

        System.assertEquals(
            1,
            responses.size(),
            'Should return one response wrapper'
        );
        System.assertEquals(
            2,
            responses[0].opportunityOptions.size(),
            'Should find two opportunities matching name'
        );
        System.assert(
            responses[0]
                .opportunityOptions[0]
                .name.contains('Enterprise'),
            'First result should contain Enterprise'
        );
    }

    @isTest
    static void testGetOpportunities_WithName_NoMatch() {
        OpportunityController.OpportunityRequest request = new OpportunityController.OpportunityRequest();
        request.opportunityName = 'NonExistent Deal';

        List<OpportunityController.OpportunityResponse> responses = OpportunityController.getOpportunities(
            new List<OpportunityController.OpportunityRequest>{ request }
        );

        System.assertEquals(1, responses.size());
        System.assertEquals(
            0,
            responses[0].opportunityOptions.size(),
            'Should return no opportunities for unmatched name'
        );
    }

    @isTest
    static void testGetOpportunities_WithBlankName_ReturnsAll() {
        OpportunityController.OpportunityRequest request = new OpportunityController.OpportunityRequest();
        request.opportunityName = '';

        List<OpportunityController.OpportunityResponse> responses = OpportunityController.getOpportunities(
            new List<OpportunityController.OpportunityRequest>{ request }
        );

        System.assertEquals(1, responses.size());
        System.assertEquals(
            3,
            responses[0].opportunityOptions.size(),
            'Should return all opportunities when name is blank'
        );
    }

    @isTest
    static void testGetOpportunities_WithNullName_ReturnsAll() {
        OpportunityController.OpportunityRequest request = new OpportunityController.OpportunityRequest();
        request.opportunityName = null;

        List<OpportunityController.OpportunityResponse> responses = OpportunityController.getOpportunities(
            new List<OpportunityController.OpportunityRequest>{ request }
        );

        System.assertEquals(1, responses.size());
        System.assertEquals(
            3,
            responses[0].opportunityOptions.size(),
            'Should return all opportunities when name is null'
        );
    }

    @isTest
    static void testGetOpportunities_WithNullRequest_ReturnsAll() {
        List<OpportunityController.OpportunityResponse> responses = OpportunityController.getOpportunities(
            null
        );

        System.assertEquals(1, responses.size());
        System.assertEquals(
            3,
            responses[0].opportunityOptions.size(),
            'Should return all opportunities when request is null'
        );
    }

    @isTest
    static void testGetOpportunities_WithEmptyRequestList_ReturnsAll() {
        List<OpportunityController.OpportunityResponse> responses = OpportunityController.getOpportunities(
            new List<OpportunityController.OpportunityRequest>()
        );

        System.assertEquals(1, responses.size());
        System.assertEquals(
            3,
            responses[0].opportunityOptions.size(),
            'Should return all opportunities when request list is empty'
        );
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
        System.assertNotEquals(null, opp.id, 'Id should be populated');
        System.assertEquals('Small Business Package', opp.name);
        System.assertEquals('Global Industries', opp.accountName);
        System.assertEquals(25000, opp.amount);
        System.assertNotEquals(null, opp.closeDate);
    }

    @isTest
    static void testOpportunities_OrderedByCloseDateDesc() {
        OpportunityController.OpportunityRequest request = new OpportunityController.OpportunityRequest();

        List<OpportunityController.OpportunityResponse> responses = OpportunityController.getOpportunities(
            new List<OpportunityController.OpportunityRequest>{ request }
        );

        List<OpportunityController.OpportunityDetail> opps = responses[0]
            .opportunityOptions;
        System.assertEquals(3, opps.size());

        for (Integer i = 0; i < opps.size() - 1; i++) {
            System.assert(
                opps[i].closeDate <= opps[i + 1].closeDate,
                'Opportunities should be ordered by CloseDate descending'
            );
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

        System.assertEquals(1, responses[0].opportunityOptions.size());
        System.assertEquals(
            null,
            responses[0].opportunityOptions[0].accountName,
            'Account name should be null when no account is associated'
        );
    }
}
