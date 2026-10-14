@RestResource(urlMapping='/accounts')
global with sharing class AccountApi {

    global class CreateAccountRequest {
        public String name;
        public String phone;
        public String website;
        public String type;
    }

    global class CreateAccountResponse {
        public Boolean success;
        public String id;
        public String message;
    }

    @HttpPost
    global static CreateAccountResponse createAccount() {

        String body = RestContext.request.requestBody.toString();

        CreateAccountRequest req =
            (CreateAccountRequest) JSON.deserialize(
                body,
                CreateAccountRequest.class
            );

        CreateAccountResponse res = new CreateAccountResponse();

        if (req == null || String.isBlank(req.name)) {

            RestContext.response.statusCode = 400;

            res.success = false;
            res.message = 'Account name is required';

            return res;
        }

        Account acc = new Account(
            Name = req.name,
            Phone = req.phone,
            Website = req.website,
            Type = req.type
        );

        insert acc;

        RestContext.response.statusCode = 201;

        res.success = true;
        res.id = acc.Id;
        res.message = 'Account created successfully';

        return res;
    }
}