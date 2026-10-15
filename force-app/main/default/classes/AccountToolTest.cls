/**
 * Tests for the AccountTool "Create Account" invocable.
 */
@IsTest
private class AccountToolTest {
    private static AccountTool.Input input(String name, String accountType) {
        AccountTool.Input inp = new AccountTool.Input();
        inp.accountName = name;
        inp.accountType = accountType;
        return inp;
    }

    @IsTest
    static void shouldCreateAccount_WithDefaultType_WhenTypeNotGiven() {
        // When
        Test.startTest();
        List<AccountTool.Output> results = AccountTool.createAccount(
            new List<AccountTool.Input>{ input('Agent Created Account', null) }
        );
        Test.stopTest();

        // Then
        Assert.areEqual(1, results.size(), 'One input should produce one result');
        Assert.areEqual('Created: Agent Created Account', results[0].message, 'Success message should name the Account');
        Account created = [SELECT Type FROM Account WHERE Name = 'Agent Created Account'];
        Assert.areEqual(AccountDefaults.ACCOUNT_TYPE, created.Type, 'Type should default so the org validation rule passes');
    }

    @IsTest
    static void shouldCreateAccount_WithGivenType() {
        // When
        Test.startTest();
        AccountTool.createAccount(new List<AccountTool.Input>{ input('Direct Customer Co', 'Customer - Direct') });
        Test.stopTest();

        // Then
        Account created = [SELECT Type FROM Account WHERE Name = 'Direct Customer Co'];
        Assert.areEqual('Customer - Direct', created.Type, 'A supplied Type should be used');
    }

    @IsTest
    static void shouldCreateAllAccounts_WhenBulk() {
        // Given
        List<AccountTool.Input> inputs = new List<AccountTool.Input>();
        for (Integer i = 0; i < 201; i++) {
            inputs.add(input('Bulk Agent Account ' + i, null));
        }

        // When
        Test.startTest();
        List<AccountTool.Output> results = AccountTool.createAccount(inputs);
        Test.stopTest();

        // Then
        Assert.areEqual(201, results.size(), 'Every input should get a result');
        Assert.areEqual(201, [SELECT COUNT() FROM Account WHERE Name LIKE 'Bulk Agent Account %'], 'All 201 Accounts should be inserted in one DML');
    }

    @IsTest
    static void shouldReportError_WhenAccountNameMissing() {
        // When: Name is required on Account
        Test.startTest();
        List<AccountTool.Output> results = AccountTool.createAccount(
            new List<AccountTool.Input>{ input(null, null) }
        );
        Test.stopTest();

        // Then
        Assert.areEqual(1, results.size(), 'The failure should be returned as one result');
        Assert.isTrue(results[0].message.startsWith('Error creating account: '), 'A missing name should be reported as an error');
        Assert.areEqual(0, [SELECT COUNT() FROM Account], 'No Account should be created');
    }

    @IsTest
    static void shouldReturnNoResults_WhenNoInputs() {
        // When
        Test.startTest();
        List<AccountTool.Output> results = AccountTool.createAccount(new List<AccountTool.Input>());
        Test.stopTest();

        // Then
        Assert.isTrue(results.isEmpty(), 'No inputs should produce no results');
    }
}
