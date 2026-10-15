/**
 * Tests for the AccountContactSummary REST resource (contact counts per Account above a revenue threshold).
 */
@IsTest
private class AccountContactSummaryTest {
    private static final Decimal HIGH_REVENUE = 500000;
    private static final Decimal LOW_REVENUE = 1000;
    private static final Integer HIGH_ACCOUNT_CONTACTS = 3;

    @TestSetup
    static void setupTestData() {
        List<Account> accounts = TestDataFactory.buildAccounts(2);
        accounts[0].AnnualRevenue = HIGH_REVENUE;
        accounts[1].AnnualRevenue = LOW_REVENUE;
        insert accounts;
        insert TestDataFactory.buildContacts(accounts[0].Id, HIGH_ACCOUNT_CONTACTS);
        insert TestDataFactory.buildContacts(accounts[1].Id, 1);
    }

    private static void setRequestThreshold(Decimal threshold) {
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/AccountContactSummary/' + String.valueOf(threshold);
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response = new RestResponse();
    }

    @IsTest
    static void shouldCountContacts_ForAccountsAboveThreshold() {
        // Given
        setRequestThreshold(100000);

        // When
        Test.startTest();
        Map<String, Decimal> countsByAccount = AccountContactSummary.getAverageContactCountByAccount();
        Test.stopTest();

        // Then
        Assert.areEqual(1, countsByAccount.size(), 'Only the high-revenue Account meets the threshold');
        Assert.areEqual(HIGH_ACCOUNT_CONTACTS, countsByAccount.get('Test Account 0'), 'Its contact count should be returned');
    }

    @IsTest
    static void shouldIncludeAllAccounts_WhenThresholdIsZero() {
        // Given
        setRequestThreshold(0);

        // When
        Test.startTest();
        Map<String, Decimal> countsByAccount = AccountContactSummary.getAverageContactCountByAccount();
        Test.stopTest();

        // Then
        Assert.areEqual(2, countsByAccount.size(), 'Both Accounts have revenue >= 0');
        Assert.areEqual(1, countsByAccount.get('Test Account 1'), 'The low-revenue Account has one contact');
    }

    @IsTest
    static void shouldReturnEmptyMap_WhenNoAccountMeetsThreshold() {
        // Given
        setRequestThreshold(HIGH_REVENUE * 10);

        // When
        Test.startTest();
        Map<String, Decimal> countsByAccount = AccountContactSummary.getAverageContactCountByAccount();
        Test.stopTest();

        // Then
        Assert.isTrue(countsByAccount.isEmpty(), 'No Account reaches a threshold ten times the highest revenue');
    }
}
