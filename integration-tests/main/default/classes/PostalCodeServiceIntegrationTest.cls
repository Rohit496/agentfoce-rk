/**
 * Apex integration tests (Winter '27 Developer Preview) for PostalCodeService.
 *
 * Unlike PostalCodeServiceTest (HttpCalloutMock), these make REAL callouts through the PostalCodeApi
 * named credential, so they catch a broken endpoint, credential or payload contract that a mock hides.
 *
 * Rules of the feature:
 * - Scratch orgs only, with the ApexIntegrationTests feature (config/integration-tests-scratch-def.json).
 * - Data is NOT rolled back: @TearDown runs after each test method and deletes what that method created.
 * - Asynchronous only, one integration test class per org at a time: sf apex run test (no --synchronous).
 * - Doesn't count toward code coverage. A registered Test.setMock() would still win, so none is set here.
 * - The running user needs the Postal_Code_API_Access permission set (named principal access).
 */
@IntegrationTest
private class PostalCodeServiceIntegrationTest {
    private static final String TEST_ACCOUNT_PREFIX = 'IT PostalCode ';

    @IntegrationTest
    static void shouldResolveRealPostalCode() {
        // When: real callout to the postal-code service
        PostalCodeService.PostalCodeResult place = PostalCodeService.lookup('us', '90210');

        // Then: the live payload still matches the contract the service parses
        Assert.areEqual('Beverly Hills', place.placeName, '90210 should resolve to Beverly Hills');
        Assert.areEqual('California', place.state, 'The live response should include the state');
        Assert.areEqual('CA', place.stateCode, 'The live response should include the state abbreviation');
        Assert.areEqual('United States', place.country, 'The live response should include the country');
        Assert.isNotNull(place.latitude, 'The live response should include coordinates');
    }

    @IntegrationTest
    static void shouldReportUnknownPostalCode_FromRealService() {
        // When / Then: the real service answers 404 for a code that doesn't exist
        try {
            PostalCodeService.lookup('us', '00000');
            Assert.fail('Expected PostalCodeServiceException for a postal code the real service does not know');
        } catch (PostalCodeService.PostalCodeServiceException e) {
            Assert.areEqual('Unknown postal code: 00000', e.getMessage(), 'A real 404 should map to the unknown-code error');
        }
    }

    @IntegrationTest
    static void shouldCreateAccountWithRealAddress() {
        // When: real callout first, then the insert (a callout after uncommitted DML is not allowed,
        // and integration tests don't auto-commit). The created Account stays in the org: @TearDown removes it.
        Account created = PostalCodeService.createAccountWithAddress(TEST_ACCOUNT_PREFIX + 'New York', 'Prospect', 'us', '10001');

        // Then
        Account saved = [SELECT BillingCity, BillingState, BillingCountry FROM Account WHERE Id = :created.Id WITH USER_MODE];
        Assert.areEqual('New York City', saved.BillingCity, '10001 should resolve to New York City');
        Assert.areEqual('New York', saved.BillingState, 'The billing state should come from the live response');
        Assert.areEqual('United States', saved.BillingCountry, 'The billing country should come from the live response');
    }

    @TearDown
    static void deleteCreatedAccounts() {
        // Runs after every test method: delete only what the methods above created.
        String prefixPattern = TEST_ACCOUNT_PREFIX + '%';
        delete as user [SELECT Id FROM Account WHERE Name LIKE :prefixPattern WITH USER_MODE];
    }
}
