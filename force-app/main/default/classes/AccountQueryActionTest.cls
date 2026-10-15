/**
 * Tests for the AccountQueryAction invocable: names returned in input order, unknown Ids as null.
 */
@IsTest
private class AccountQueryActionTest {
    @TestSetup
    static void setupTestData() {
        TestDataFactory.createAccounts(2);
    }

    @IsTest
    static void shouldReturnNamesInInputOrder_WhenIdsExist() {
        // Given: Ids in reverse name order
        List<Account> accounts = [SELECT Id, Name FROM Account ORDER BY Name DESC];
        List<Id> ids = new List<Id>{ accounts[0].Id, accounts[1].Id };

        // When
        Test.startTest();
        List<String> names = AccountQueryAction.getAccountNames(ids);
        Test.stopTest();

        // Then
        Assert.areEqual(2, names.size(), 'One name per input Id');
        Assert.areEqual(accounts[0].Name, names[0], 'The first name should match the first Id');
        Assert.areEqual(accounts[1].Name, names[1], 'The second name should match the second Id');
    }

    @IsTest
    static void shouldReturnNull_ForUnknownId() {
        // Given
        Account existing = [SELECT Id, Name FROM Account ORDER BY Name LIMIT 1];
        Id unknownId = TestDataFactory.generateFakeId(Account.SObjectType);

        // When
        Test.startTest();
        List<String> names = AccountQueryAction.getAccountNames(new List<Id>{ unknownId, existing.Id });
        Test.stopTest();

        // Then
        Assert.areEqual(2, names.size(), 'The output keeps one slot per input Id');
        Assert.isNull(names[0], 'An Id with no matching Account should map to null');
        Assert.areEqual(existing.Name, names[1], 'The existing Account name should keep its position');
    }

    @IsTest
    static void shouldReturnEmptyList_WhenNoIdsGiven() {
        // When
        Test.startTest();
        List<String> names = AccountQueryAction.getAccountNames(new List<Id>());
        Test.stopTest();

        // Then
        Assert.isTrue(names.isEmpty(), 'No Ids in means no names out');
    }
}
