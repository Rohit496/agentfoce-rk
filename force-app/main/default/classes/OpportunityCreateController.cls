/**
 * Controller class for creating Opportunities in Salesforce.
 * This class provides an invocable method that can be used in flows or other automation tools
 * to create new Opportunity records based on provided data.
 */
public with sharing class OpportunityCreateController {
    /**
     * Invocable method to create a new Opportunity record.
     * This method processes a list of requests and creates opportunities accordingly.
     * It handles account lookup or creation if an account name is provided.
     * @param requests List of CreateOpportunityRequest containing opportunity data
     * @return List of CreateOpportunityResponse with success or error messages
     */
    @InvocableMethod(
        label='Create Opportunity'
        description='Creates a new Opportunity record with the name, account name, amount, and close date provided by the user in form Data.'
    )
    public static List<CreateOpportunityResponse> createOpportunity(
        List<CreateOpportunityRequest> requests
    ) {
        List<CreateOpportunityResponse> responses = new List<CreateOpportunityResponse>();
        CreateOpportunityResponse response = new CreateOpportunityResponse();

        // Validate input requests
        if (requests == null || requests.isEmpty()) {
            response.message = 'No request data provided.';
            responses.add(response);
            return responses;
        }

        OpportunityData data = requests[0].oppdata;
        System.debug('Received Opportunity Data: ' + data);

        try {
            Id accountId = null;
            // Check if account name is provided and find or create the account
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

            // Create the new Opportunity record
            Opportunity opp = new Opportunity(
                Name = data.opportunityName,
                AccountId = accountId,
                Amount = data.amount,
                CloseDate = data.closeDate,
                StageName = 'Prospecting'
            );
            System.debug('Creating Opportunity: ' + opp);
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

    /**
     * Wrapper class for the invocable method request.
     * Contains the opportunity data to be used for creation.
     */
    public class CreateOpportunityRequest {
        @InvocableVariable(required=true)
        public OpportunityData oppdata;
    }

    /**
     * Data structure containing the details for creating an Opportunity.
     * Includes opportunity name, account name, amount, and close date.
     */
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

    /**
     * Response wrapper class for the invocable method.
     * Contains a message indicating the result of the operation.
     */
    public class CreateOpportunityResponse {
        @InvocableVariable
        public String message;
    }
}