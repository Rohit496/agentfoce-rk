public with sharing class GetOpenOpportunitiesForAnAccount {

        @InvocableMethod(label='Open Opportunities'
            description='Get Open Opportunities for an Account')
        public static List<Response> getOpportunitiesPrompt(List<Request> requests) {
            Account a = requests[0].RelatedEntity;
            ID searchAcctId = a.Id;

            List<Opportunity> opptys =
                [SELECT Id, Name, Amount, StageName, CloseDate
                 FROM Opportunity
                 WHERE AccountId = :searchAcctId AND IsClosed = FALSE
                 WITH USER_MODE];

            string responseData = null;
    
            if(opptys.isEmpty()) {
                responseData = 'There are no open opportunities.';
            } else {
                responseData = JSON.serialize(opptys);
            }
           
            List<Response> responses = new List<Response>();
            Response res = new Response();
            res.Prompt = responseData;
            responses.add(res);
            return responses;
        }
        
        public class Request {
            @InvocableVariable(required=true)
            public Account RelatedEntity;
        }
            
        public class Response {
            @InvocableVariable
            public String Prompt;
        }
}