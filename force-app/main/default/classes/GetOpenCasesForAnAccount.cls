public with sharing class GetOpenCasesForAnAccount {
    
        @InvocableMethod(label='Open Cases'
            description='Get Open Cases for an Account')
        public static List<Response> getOpenCases(List<Request> requests) {
            Account a = requests[0].RelatedEntity;
            ID searchAcctId = a.Id;

            List<Case> cases =
                [SELECT Id, CaseNumber, CreatedDate, Subject, Description, Priority, Status
                 FROM Case
                 WHERE AccountId = :searchAcctId AND IsClosed = FALSE
                 WITH USER_MODE];

            string responseData = null;

            if(cases.isEmpty()) {
                responseData = 'There are no open cases.';
            } else {
                responseData = JSON.serialize(cases);
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