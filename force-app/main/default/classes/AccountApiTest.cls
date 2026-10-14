@isTest
private class AccountApiTest {

    /**
     * Builds a RestContext with a POST request whose body is the JSON
     * serialization of the supplied payload, then returns the response.
     */
    private static AccountApi.CreateAccountResponse invokeCreateAccount(String body) {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/accounts';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        return AccountApi.createAccount();
    }

    @isTest
    static void testCreateAccount_Success() {
        String body = JSON.serialize(new Map<String, Object>{
            'name' => 'Acme Corp',
            'phone' => '1234567890',
            'website' => 'https://acme.example.com',
            'type' => 'Prospect'
        });

        Test.startTest();
        AccountApi.CreateAccountResponse res = invokeCreateAccount(body);
        Test.stopTest();

        System.assertEquals(true, res.success, 'Response should indicate success');
        System.assertNotEquals(null, res.id, 'Created account Id should be returned');
        System.assertEquals('Account created successfully', res.message);
        System.assertEquals(201, RestContext.response.statusCode, 'Should return HTTP 201');

        Account acc = [SELECT Name, Phone, Website, Type FROM Account WHERE Id = :res.id];
        System.assertEquals('Acme Corp', acc.Name);
        System.assertEquals('1234567890', acc.Phone);
        System.assertEquals('https://acme.example.com', acc.Website);
        System.assertEquals('Prospect', acc.Type);
    }

    @isTest
    static void testCreateAccount_NameOnly() {
        String body = JSON.serialize(new Map<String, Object>{
            'name' => 'Name Only Inc',
            'type' => 'Prospect'
        });

        Test.startTest();
        AccountApi.CreateAccountResponse res = invokeCreateAccount(body);
        Test.stopTest();

        System.assertEquals(true, res.success);
        System.assertEquals(201, RestContext.response.statusCode);

        Account acc = [SELECT Name, Phone, Website FROM Account WHERE Id = :res.id];
        System.assertEquals('Name Only Inc', acc.Name);
        System.assertEquals(null, acc.Phone, 'Phone should be null when omitted');
        System.assertEquals(null, acc.Website, 'Website should be null when omitted');
    }

    @isTest
    static void testCreateAccount_MissingName() {
        String body = JSON.serialize(new Map<String, Object>{ 'phone' => '5551234567' });

        Test.startTest();
        AccountApi.CreateAccountResponse res = invokeCreateAccount(body);
        Test.stopTest();

        System.assertEquals(false, res.success, 'Response should indicate failure');
        System.assertEquals(null, res.id, 'No account Id should be returned');
        System.assertEquals('Account name is required', res.message);
        System.assertEquals(400, RestContext.response.statusCode, 'Should return HTTP 400');

        System.assertEquals(0, [SELECT COUNT() FROM Account], 'No account should be inserted');
    }

    @isTest
    static void testCreateAccount_BlankName() {
        String body = JSON.serialize(new Map<String, Object>{
            'name' => '   ',
            'phone' => '5551234567'
        });

        Test.startTest();
        AccountApi.CreateAccountResponse res = invokeCreateAccount(body);
        Test.stopTest();

        System.assertEquals(false, res.success);
        System.assertEquals('Account name is required', res.message);
        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(0, [SELECT COUNT() FROM Account]);
    }

    @isTest
    static void testCreateAccount_EmptyBody() {
        Test.startTest();
        AccountApi.CreateAccountResponse res = invokeCreateAccount('{}');
        Test.stopTest();

        System.assertEquals(false, res.success, 'Empty payload has no name, should fail');
        System.assertEquals('Account name is required', res.message);
        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(0, [SELECT COUNT() FROM Account]);
    }
}