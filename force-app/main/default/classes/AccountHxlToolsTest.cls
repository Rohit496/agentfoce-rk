@IsTest
private class AccountHxlToolsTest {
    @TestSetup
    static void setup() {
        // The tools query WITH USER_MODE, so the running user needs FLS on the custom fields.
        Id psId = [SELECT Id FROM PermissionSet WHERE Name = 'HXL_Account_Access'].Id;
        if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :psId] == 0) {
            System.runAs(new User(Id = UserInfo.getUserId())) {
                insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = psId);
            }
        }

        Account acme = new Account(
            Name = 'Acme HXL Test',
            Industry = 'Technology',
            Type = 'Customer - Direct',
            Phone = '555-0100',
            AnnualRevenue = 1000000,
            BillingCity = 'San Francisco',
            BillingCountry = 'United States'
        );
        Account empty = new Account(Name = 'Empty HXL Test', Type = 'Prospect');
        insert new List<Account>{ acme, empty };

        insert new Contact(
            AccountId = acme.Id,
            FirstName = 'Ada',
            LastName = 'Lovelace',
            Email = 'ada@example.com'
        );
        insert new Case(
            AccountId = acme.Id,
            Subject = 'Login issue',
            Status = 'New'
        );
        insert new Opportunity(
            AccountId = acme.Id,
            Name = 'Acme Renewal',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 5000
        );
    }

    @IsTest
    static void detailsReturnsExactMatch() {
        AccountDetails.Result result = AccountDetails.getDetails(
            new List<String>{ 'Acme HXL Test' }
        )[0];

        Assert.isTrue(result.found, 'Expected true: result.found');
        Assert.isFalse(result.notFound, 'Expected false: result.notFound');
        Assert.areEqual('Acme HXL Test', result.name, 'Expected result.name to equal \'Acme HXL Test\'');
        Assert.areEqual('Technology', result.industry, 'Expected result.industry to equal \'Technology\'');
        Assert.areEqual('San Francisco, United States', result.billingAddress, 'Expected result.billingAddress to equal \'San Francisco, United States\'');
        Assert.isFalse(result.hasPriority, 'Expected false: result.hasPriority');
        Assert.isFalse(result.hasDescription, 'Expected false: result.hasDescription');
    }

    @IsTest
    static void detailsFallsBackToPartialMatch() {
        AccountDetails.Result result = AccountDetails.getDetails(
            new List<String>{ 'Acme HXL' }
        )[0];

        Assert.isTrue(result.found, 'Expected true: result.found');
        Assert.areEqual('Acme HXL Test', result.name, 'Expected result.name to equal \'Acme HXL Test\'');
    }

    @IsTest
    static void detailsReportsNotFound() {
        AccountDetails.Result result = AccountDetails.getDetails(
            new List<String>{ 'Does Not Exist' }
        )[0];

        Assert.isFalse(result.found, 'Expected false: result.found');
        Assert.isTrue(result.notFound, 'Expected true: result.notFound');
        Assert.areEqual('Does Not Exist', result.searchTerm, 'Expected result.searchTerm to equal \'Does Not Exist\'');
    }

    @IsTest
    static void detailsHandlesBlankInput() {
        AccountDetails.Result result = AccountDetails.getDetails(
            new List<String>{ '' }
        )[0];

        Assert.isTrue(result.notFound, 'Expected true: result.notFound');
    }

    @IsTest
    static void relatedReturnsChildRecords() {
        AccountWithRelatedRecords.Result result = AccountWithRelatedRecords.getAccounts(
            new List<String>{ 'Acme HXL' }
        )[0];

        Assert.areEqual(1, result.accountCount, 'Expected result.accountCount to equal 1');
        Assert.isFalse(result.noAccounts, 'Expected false: result.noAccounts');
        AccountWithRelatedRecords.AccountRow row = result.accounts[0];
        Assert.areEqual(1, row.contacts.size(), 'Expected row.contacts.size() to equal 1');
        Assert.areEqual(1, row.cases.size(), 'Expected row.cases.size() to equal 1');
        Assert.areEqual(1, row.opportunities.size(), 'Expected row.opportunities.size() to equal 1');
        Assert.areEqual('Contacts (1)', row.contactsTitle, 'Expected row.contactsTitle to equal \'Contacts (1)\'');
        Assert.areEqual('warning', row.cases[0].statusColor, 'Expected row.cases[0].statusColor to equal \'warning\'');
        Assert.areEqual('info', row.opportunities[0].stageColor, 'Expected row.opportunities[0].stageColor to equal \'info\'');
        Assert.isFalse(row.noContacts, 'Expected false: row.noContacts');
    }

    @IsTest
    static void relatedWithBlankNameReturnsAllAccounts() {
        AccountWithRelatedRecords.Result result = AccountWithRelatedRecords.getAccounts(
            new List<String>{ '' }
        )[0];

        Assert.areEqual(2, result.accountCount, 'Expected result.accountCount to equal 2');
        Assert.areEqual('2 accounts found', result.summaryLine, 'Expected result.summaryLine to equal \'2 accounts found\'');
    }

    @IsTest
    static void relatedFlagsEmptyChildLists() {
        AccountWithRelatedRecords.Result result = AccountWithRelatedRecords.getAccounts(
            new List<String>{ 'Empty HXL' }
        )[0];

        AccountWithRelatedRecords.AccountRow row = result.accounts[0];
        Assert.isTrue(row.noContacts, 'Expected true: row.noContacts');
        Assert.isTrue(row.noCases, 'Expected true: row.noCases');
        Assert.isTrue(row.noOpportunities, 'Expected true: row.noOpportunities');
    }

    @IsTest
    static void relatedReportsNoAccounts() {
        AccountWithRelatedRecords.Result result = AccountWithRelatedRecords.getAccounts(
            new List<String>{ 'Does Not Exist' }
        )[0];

        Assert.isTrue(result.noAccounts, 'Expected true: result.noAccounts');
        Assert.areEqual(0, result.accountCount, 'Expected result.accountCount to equal 0');
    }
}