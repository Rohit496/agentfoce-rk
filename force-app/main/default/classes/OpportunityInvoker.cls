public with sharing class OpportunityInvoker {
    public class OpportunityResult {
        @InvocableVariable
        public Id Id;
        @InvocableVariable
        public String Name;
        @InvocableVariable
        public String StageName;
        @InvocableVariable
        public Date CloseDate;
        @InvocableVariable
        public Decimal Amount;
        @InvocableVariable
        public Id AccountId;
        @InvocableVariable
        public Id OwnerId;
        @InvocableVariable
        public Datetime CreatedDate;
        @InvocableVariable
        public String NextStep;
        @InvocableVariable
        public String Description;
    }

    public class Request {
        @InvocableVariable(required=true)
        public List<String> opportunityNames;
    }

    @InvocableMethod(
        label='Fetch Opportunities By Name'
        description='Accepts a list of requests (each with a list of opportunity names) and returns matching opportunities with selected fields.'
    )
    public static List<List<OpportunityResult>> fetchOpportunitiesByName(
        List<Request> requests
    ) {
        // Collect all names from all requests
        Set<String> names = new Set<String>();
        for (Request req : requests) {
            if (req != null && req.opportunityNames != null) {
                names.addAll(req.opportunityNames);
            }
        }
        // If no names provided, return empty structure matching number of requests
        List<List<OpportunityResult>> results = new List<List<OpportunityResult>>();
        if (names.isEmpty()) {
            for (Integer i = 0; i < requests.size(); i++) {
                results.add(new List<OpportunityResult>());
            }
            return results;
        }

        // Query matching opportunities (case-insensitive search using IN for exact names)
        List<Opportunity> opps = [
            SELECT
                Id,
                Name,
                StageName,
                CloseDate,
                Amount,
                AccountId,
                OwnerId,
                CreatedDate,
                NextStep,
                Description
            FROM Opportunity
            WHERE Name IN :names WITH USER_MODE
        ];

        // Map name -> list of OpportunityResult
        Map<String, List<OpportunityResult>> byName = new Map<String, List<OpportunityResult>>();
        for (Opportunity o : opps) {
            OpportunityResult r = new OpportunityResult();
            r.Id = o.Id;
            r.Name = o.Name;
            r.StageName = o.StageName;
            r.CloseDate = o.CloseDate;
            r.Amount = o.Amount;
            r.AccountId = o.AccountId;
            r.OwnerId = o.OwnerId;
            r.CreatedDate = o.CreatedDate;
            r.NextStep = o.NextStep;
            r.Description = o.Description;
            if (!byName.containsKey(o.Name)) {
                byName.put(o.Name, new List<OpportunityResult>());
            }
            byName.get(o.Name).add(r);
        }

        // Build results per request: for each request, aggregate results for the provided names in order
        for (Request req : requests) {
            List<OpportunityResult> reqResults = new List<OpportunityResult>();
            if (req != null && req.opportunityNames != null) {
                for (String n : req.opportunityNames) {
                    if (byName.containsKey(n)) {
                        reqResults.addAll(byName.get(n));
                    }
                }
            }
            results.add(reqResults);
        }

        return results;
    }
}