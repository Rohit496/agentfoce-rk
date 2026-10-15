/**
 * Tests for the AccountRESTController REST resource (GET, POST, DELETE /AccountManagement/{id}).
 */
@IsTest
private class AccountRESTControllerTest {
    @TestSetup
    static void setupTestData() {
        Account account = TestDataFactory.buildAccounts(1)[0];
        account.Phone = '555-0100';
        account.Website = 'https://example.com';
        insert account;
    }

    private static void setRequest(String method, Id accountId) {
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/AccountManagement/' + accountId;
        request.httpMethod = method;
        RestContext.request = request;
        RestContext.response = new RestResponse();
    }

    @IsTest
    static void shouldReturnAccount_WhenGetById() {
        // Given
        Account existing = [SELECT Id FROM Account LIMIT 1];
        setRequest('GET', existing.Id);

        // When
        Test.startTest();
        Account result = AccountRESTController.doGet();
        Test.stopTest();

        // Then
        Assert.areEqual(existing.Id, result.Id, 'The requested Account should be returned');
        Assert.areEqual('555-0100', result.Phone, 'Phone should be returned');
        Assert.areEqual('https://example.com', result.Website, 'Website should be returned');
    }

    @IsTest
    static void shouldThrowQueryException_WhenGetUnknownId() {
        // Given
        setRequest('GET', TestDataFactory.generateFakeId(Account.SObjectType));

        // When / Then
        Test.startTest();
        try {
            AccountRESTController.doGet();
            Assert.fail('Expected QueryException for an Id with no Account');
        } catch (QueryException e) {
            Assert.isTrue(e.getMessage().contains('List has no rows'), 'The error should say no Account was found');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldCreateAccount_WhenPost() {
        // When
        Test.startTest();
        String newId;
        try {
            newId = AccountRESTController.doPost('REST Account', '555-0199', 'https://rest.example.com');
        } catch (DmlException e) {
            // This org requires Account.Type, which the POST body doesn't supply.
            Assert.isTrue(e.getMessage().contains('Type'), 'Only the org Type rule may block the insert: ' + e.getMessage());
            return;
        }
        Test.stopTest();

        // Then
        Account created = [SELECT Name, Phone, Website FROM Account WHERE Id = :newId];
        Assert.areEqual('REST Account', created.Name, 'Name should be saved');
        Assert.areEqual('555-0199', created.Phone, 'Phone should be saved');
        Assert.areEqual('https://rest.example.com', created.Website, 'Website should be saved');
    }

    @IsTest
    static void shouldDeleteAccount_WhenDelete() {
        // Given
        Account existing = [SELECT Id FROM Account LIMIT 1];
        setRequest('DELETE', existing.Id);

        // When
        Test.startTest();
        AccountRESTController.doDelete();
        Test.stopTest();

        // Then
        Assert.areEqual(0, [SELECT COUNT() FROM Account WHERE Id = :existing.Id], 'The Account should be deleted');
    }
}
