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

        Assert.isTrue(res.success, 'Response should indicate success');
        Assert.isNotNull(res.id, 'Created account Id should be returned');
        Assert.areEqual('Account created successfully', res.message, 'Expected res.message to equal \'Account created successfully\'');
        Assert.areEqual(201, RestContext.response.statusCode, 'Should return HTTP 201');

        Account acc = [SELECT Name, Phone, Website, Type FROM Account WHERE Id = :res.id];
        Assert.areEqual('Acme Corp', acc.Name, 'Expected acc.Name to equal \'Acme Corp\'');
        Assert.areEqual('1234567890', acc.Phone, 'Expected acc.Phone to equal \'1234567890\'');
        Assert.areEqual('https://acme.example.com', acc.Website, 'Expected acc.Website to equal \'https://acme.example.com\'');
        Assert.areEqual('Prospect', acc.Type, 'Expected acc.Type to equal \'Prospect\'');
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

        Assert.isTrue(res.success, 'Expected true: res.success');
        Assert.areEqual(201, RestContext.response.statusCode, 'Expected RestContext.response.statusCode to equal 201');

        Account acc = [SELECT Name, Phone, Website FROM Account WHERE Id = :res.id];
        Assert.areEqual('Name Only Inc', acc.Name, 'Expected acc.Name to equal \'Name Only Inc\'');
        Assert.isNull(acc.Phone, 'Phone should be null when omitted');
        Assert.isNull(acc.Website, 'Website should be null when omitted');
    }

    @isTest
    static void testCreateAccount_MissingName() {
        String body = JSON.serialize(new Map<String, Object>{ 'phone' => '5551234567' });

        Test.startTest();
        AccountApi.CreateAccountResponse res = invokeCreateAccount(body);
        Test.stopTest();

        Assert.isFalse(res.success, 'Response should indicate failure');
        Assert.isNull(res.id, 'No account Id should be returned');
        Assert.areEqual('Account name is required', res.message, 'Expected res.message to equal \'Account name is required\'');
        Assert.areEqual(400, RestContext.response.statusCode, 'Should return HTTP 400');

        Assert.areEqual(0, [SELECT COUNT() FROM Account], 'No account should be inserted');
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

        Assert.isFalse(res.success, 'Expected false: res.success');
        Assert.areEqual('Account name is required', res.message, 'Expected res.message to equal \'Account name is required\'');
        Assert.areEqual(400, RestContext.response.statusCode, 'Expected RestContext.response.statusCode to equal 400');
        Assert.areEqual(0, [SELECT COUNT() FROM Account], 'Expected [SELECT COUNT() FROM Account] to equal 0');
    }

    @isTest
    static void testCreateAccount_EmptyBody() {
        Test.startTest();
        AccountApi.CreateAccountResponse res = invokeCreateAccount('{}');
        Test.stopTest();

        Assert.isFalse(res.success, 'Empty payload has no name, should fail');
        Assert.areEqual('Account name is required', res.message, 'Expected res.message to equal \'Account name is required\'');
        Assert.areEqual(400, RestContext.response.statusCode, 'Expected RestContext.response.statusCode to equal 400');
        Assert.areEqual(0, [SELECT COUNT() FROM Account], 'Expected [SELECT COUNT() FROM Account] to equal 0');
    }
}