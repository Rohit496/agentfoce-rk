/**
 * Tests for AccountController: listing, name search, and USER_MODE enforcement.
 */
@IsTest
private class AccountControllerTest {
    private static final Integer ACCOUNT_COUNT = 3;

    @TestSetup
    static void setupTestData() {
        TestDataFactory.createAccounts(ACCOUNT_COUNT);
    }

    @IsTest
    static void shouldReturnAllAccountsSortedByName_WhenGetAllAccounts() {
        // When
        Test.startTest();
        List<Account> accounts = AccountController.getAllAccounts();
        Test.stopTest();

        // Then
        Assert.areEqual(ACCOUNT_COUNT, accounts.size(), 'All test Accounts should be returned');
        Assert.areEqual('Test Account 0', accounts[0].Name, 'Accounts should be sorted by Name ascending');
        Assert.areEqual('Test Account 2', accounts[ACCOUNT_COUNT - 1].Name, 'The last Account should sort last');
    }

    @IsTest
    static void shouldReturnMatchingAccount_WhenSearchKeyMatchesName() {
        // When
        Test.startTest();
        List<Account> accounts = AccountController.searchAccounts('Account 1');
        Test.stopTest();

        // Then
        Assert.areEqual(1, accounts.size(), 'Only one Account name contains "Account 1"');
        Assert.areEqual('Test Account 1', accounts[0].Name, 'The matching Account should be returned');
    }

    @IsTest
    static void shouldReturnNoAccounts_WhenSearchKeyMatchesNothing() {
        // When
        Test.startTest();
        List<Account> accounts = AccountController.searchAccounts('no-such-account');
        Test.stopTest();

        // Then
        Assert.isTrue(accounts.isEmpty(), 'No Account should match an unknown search key');
    }

    @IsTest
    static void shouldThrowAuraHandledException_WhenUserCannotReadAccounts() {
        // Given: a user without Account access (USER_MODE enforces CRUD/FLS)
        User restrictedUser = TestDataFactory.createMinimumAccessUser();

        // When / Then
        System.runAs(restrictedUser) {
            Test.startTest();
            try {
                AccountController.getAllAccounts();
                Assert.fail('Expected AuraHandledException for a user without Account access');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage(), 'The exception should carry a message for the UI');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void shouldThrowAuraHandledException_WhenUserCannotSearchAccounts() {
        // Given
        User restrictedUser = TestDataFactory.createMinimumAccessUser();

        // When / Then
        System.runAs(restrictedUser) {
            Test.startTest();
            try {
                AccountController.searchAccounts('Account');
                Assert.fail('Expected AuraHandledException for a user without Account access');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage(), 'The exception should carry a message for the UI');
            }
            Test.stopTest();
        }
    }
}
