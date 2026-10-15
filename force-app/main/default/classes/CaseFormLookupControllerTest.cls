/**
 * Tests for CaseFormLookupController, the search-as-you-type lookup used by the caseInputForm LWC.
 */
@IsTest
private class CaseFormLookupControllerTest {
    @TestSetup
    static void setupTestData() {
        List<Account> accounts = TestDataFactory.createAccounts(7);
        insert TestDataFactory.buildContacts(accounts[0].Id, 2);
    }

    @IsTest
    static void shouldReturnAtMostFiveAccounts_SortedByName() {
        // When: 7 Accounts match "Test Account"
        Test.startTest();
        List<CaseFormLookupController.LookupResult> results = CaseFormLookupController.search('Account', 'Test Account');
        Test.stopTest();

        // Then
        Assert.areEqual(5, results.size(), 'Results should be capped at 5');
        Assert.areEqual('Test Account 0', results[0].name, 'Results should be sorted by Name');
        Assert.isNotNull(results[0].id, 'Each result should carry the record Id');
    }

    @IsTest
    static void shouldReturnMatchingContacts() {
        // When
        Test.startTest();
        List<CaseFormLookupController.LookupResult> results = CaseFormLookupController.search('Contact', 'Contact 1');
        Test.stopTest();

        // Then
        Assert.areEqual(1, results.size(), 'Only one Contact name contains "Contact 1"');
        Assert.areEqual('Test Contact 1', results[0].name, 'The matching Contact should be returned');
    }

    @IsTest
    static void shouldReturnNothing_WhenSearchTermTooShort() {
        // When
        Test.startTest();
        List<CaseFormLookupController.LookupResult> shortTerm = CaseFormLookupController.search('Account', ' T ');
        List<CaseFormLookupController.LookupResult> blankTerm = CaseFormLookupController.search('Account', '');
        Test.stopTest();

        // Then
        Assert.isTrue(shortTerm.isEmpty(), 'A one-character term (after trimming) should not search');
        Assert.isTrue(blankTerm.isEmpty(), 'A blank term should not search');
    }

    @IsTest
    static void shouldThrow_WhenObjectNotAllowed() {
        // When / Then
        Test.startTest();
        try {
            CaseFormLookupController.search('User', 'Admin');
            Assert.fail('Expected AuraHandledException for an object outside the allowlist');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'The UI should get an error message');
        }
        Test.stopTest();
    }
}
