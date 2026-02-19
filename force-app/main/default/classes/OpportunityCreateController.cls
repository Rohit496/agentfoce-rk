public with sharing class OpportunityCreateController {
    @InvocableMethod(
        label='Create Opportunity'
        description='Creates a new Opportunity record with the name, account name, amount, and close date provided by the user.'
    )
    public static List<CreateOpportunityResponse> createOpportunity(
        List<CreateOpportunityRequest> requests
    ) {
        List<CreateOpportunityResponse> responses = new List<CreateOpportunityResponse>();
        CreateOpportunityResponse response = new CreateOpportunityResponse();

        if (requests == null || requests.isEmpty()) {
            response.message = 'No request data provided.';
            responses.add(response);
            return responses;
        }

        OpportunityData data = requests[0].oppdata;

        try {
            Id accountId = null;
            if (String.isNotBlank(data.accountName)) {
                List<Account> accounts = [
                    SELECT Id
                    FROM Account
                    WHERE Name = :data.accountName
                    LIMIT 1
                ];
                if (!accounts.isEmpty()) {
                    accountId = accounts[0].Id;
                } else {
                    // Create the Account if it doesn't exist
                    Account newAccount = new Account(Name = data.accountName);
                    insert newAccount;
                    accountId = newAccount.Id;
                }
            }

            Opportunity opp = new Opportunity(
                Name = data.opportunityName,
                AccountId = accountId,
                Amount = data.amount,
                CloseDate = data.closeDate,
                StageName = 'Prospecting'
            );
            insert opp;

            response.message =
                'Opportunity "' +
                data.opportunityName +
                '" created successfully.';
        } catch (Exception e) {
            response.message =
                'Failed to create opportunity: ' + e.getMessage();
        }

        responses.add(response);
        return responses;
    }

    public class CreateOpportunityRequest {
        @InvocableVariable(required=true)
        public OpportunityData oppdata;
    }

    public class OpportunityData {
        @InvocableVariable(required=true)
        public String opportunityName;

        @InvocableVariable(required=false)
        public String accountName;

        @InvocableVariable(required=false)
        public Decimal amount;

        @InvocableVariable(required=true)
        public Date closeDate;
    }

    public class CreateOpportunityResponse {
        @InvocableVariable
        public String message;
    }
}
