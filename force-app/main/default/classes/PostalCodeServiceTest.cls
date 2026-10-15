/**
 * Unit tests for PostalCodeService with HttpCalloutMock. These provide code coverage; the real-callout
 * checks live in PostalCodeServiceIntegrationTest (integration tests don't count toward coverage).
 */
@IsTest
private class PostalCodeServiceTest {
    private static final String BEVERLY_HILLS_JSON =
        '{"country": "United States", "country abbreviation": "US", "post code": "90210", "places": [' +
        '{"place name": "Beverly Hills", "longitude": "-118.4065", "latitude": "34.0901", "state": "California", "state abbreviation": "CA"}]}';

    /** Returns a fixed response and records the request, so tests can check the endpoint. */
    private class PostalCodeMock implements HttpCalloutMock {
        private final Integer statusCode;
        private final String body;
        private final Boolean throwCalloutException;
        public HttpRequest lastRequest;

        PostalCodeMock(Integer statusCode, String body) {
            this(statusCode, body, false);
        }

        PostalCodeMock(Integer statusCode, String body, Boolean throwCalloutException) {
            this.statusCode = statusCode;
            this.body = body;
            this.throwCalloutException = throwCalloutException;
        }

        public HttpResponse respond(HttpRequest request) {
            lastRequest = request;
            if (throwCalloutException) {
                throw new CalloutException('Read timed out');
            }
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setBody(body);
            return response;
        }
    }

    private static String lookupError(String countryCode, String postalCode) {
        try {
            PostalCodeService.lookup(countryCode, postalCode);
        } catch (PostalCodeService.PostalCodeServiceException e) {
            return e.getMessage();
        }
        Assert.fail('Expected PostalCodeServiceException for ' + countryCode + '/' + postalCode);
        return null;
    }

    @IsTest
    static void shouldReturnPlace_AndCallNamedCredential() {
        // Given
        PostalCodeMock mock = new PostalCodeMock(200, BEVERLY_HILLS_JSON);
        Test.setMock(HttpCalloutMock.class, mock);

        // When
        Test.startTest();
        PostalCodeService.PostalCodeResult place = PostalCodeService.lookup(' US ', ' 90210 ');
        Test.stopTest();

        // Then
        Assert.areEqual('callout:PostalCodeApi/us/90210', mock.lastRequest.getEndpoint(), 'Input should be trimmed and the country lower-cased');
        Assert.areEqual('GET', mock.lastRequest.getMethod(), 'The lookup should use GET');
        Assert.areEqual('Beverly Hills', place.placeName, 'Place name should be parsed');
        Assert.areEqual('California', place.state, 'State should be parsed');
        Assert.areEqual('CA', place.stateCode, 'State code should be parsed');
        Assert.areEqual('United States', place.country, 'Country should be parsed');
        Assert.areEqual('90210', place.postalCode, 'Postal code should be parsed');
        Assert.areEqual(34.0901, place.latitude, 'Latitude should be parsed as a number');
        Assert.areEqual(-118.4065, place.longitude, 'Longitude should be parsed as a number');
    }

    @IsTest
    static void shouldThrowUnknownPostalCode_WhenServiceReturns404() {
        Test.setMock(HttpCalloutMock.class, new PostalCodeMock(404, '{}'));
        Assert.areEqual('Unknown postal code: 00000', lookupError('us', '00000'), 'A 404 means the code does not exist');
    }

    @IsTest
    static void shouldThrowHttpStatus_WhenServiceFails() {
        Test.setMock(HttpCalloutMock.class, new PostalCodeMock(500, 'Server error'));
        Assert.areEqual('Postal code service returned HTTP 500', lookupError('us', '90210'), 'Other errors should report the status');
    }

    @IsTest
    static void shouldWrapCalloutException_WhenServiceUnreachable() {
        Test.setMock(HttpCalloutMock.class, new PostalCodeMock(0, null, true));
        Assert.areEqual(
            'Postal code service is unreachable: Read timed out',
            lookupError('us', '90210'),
            'A network failure should be wrapped in the service exception'
        );
    }

    @IsTest
    static void shouldRejectInvalidInput_WithoutCallingService() {
        Assert.areEqual('Country code must be two letters, e.g. "us".', lookupError('usa', '90210'), 'A 3-letter country code is invalid');
        Assert.areEqual('Country code must be two letters, e.g. "us".', lookupError(null, '90210'), 'A missing country code is invalid');
        Assert.areEqual('Postal code must be 2 to 10 letters, digits, spaces or dashes.', lookupError('us', '90210/../x'), 'Path characters are rejected');
        Assert.areEqual('Postal code must be 2 to 10 letters, digits, spaces or dashes.', lookupError('us', ''), 'A blank postal code is invalid');
    }

    @IsTest
    static void shouldThrow_WhenResponseHasNoPlaces() {
        Test.setMock(HttpCalloutMock.class, new PostalCodeMock(200, '{"post code": "12345", "places": []}'));
        Assert.areEqual('Postal code service returned no places.', lookupError('us', '12345'), 'An empty place list is an error');
    }

    @IsTest
    static void shouldFillBillingAddress_FromPostalCode() {
        // Given
        Account account = TestDataFactory.buildAccounts(1)[0];
        account.BillingPostalCode = '90210';
        insert account;
        Test.setMock(HttpCalloutMock.class, new PostalCodeMock(200, BEVERLY_HILLS_JSON));

        // When
        Test.startTest();
        PostalCodeService.enrichBillingAddress(account.Id, 'us');
        Test.stopTest();

        // Then
        Account updated = [SELECT BillingCity, BillingState, BillingCountry, BillingLatitude, BillingLongitude FROM Account WHERE Id = :account.Id];
        Assert.areEqual('Beverly Hills', updated.BillingCity, 'Billing city should come from the place name');
        Assert.areEqual('California', updated.BillingState, 'Billing state should be filled');
        Assert.areEqual('United States', updated.BillingCountry, 'Billing country should be filled');
        Assert.areEqual(34.0901, updated.BillingLatitude, 'Billing latitude should be filled');
        Assert.areEqual(-118.4065, updated.BillingLongitude, 'Billing longitude should be filled');
    }

    @IsTest
    static void shouldCreateAccountWithAddress_CallingOutBeforeInsert() {
        // Given
        Test.setMock(HttpCalloutMock.class, new PostalCodeMock(200, BEVERLY_HILLS_JSON));

        // When
        Test.startTest();
        Account created = PostalCodeService.createAccountWithAddress('Beverly Hills Co', 'Prospect', 'us', ' 90210 ');
        Test.stopTest();

        // Then
        Account saved = [SELECT Name, Type, BillingPostalCode, BillingCity, BillingState FROM Account WHERE Id = :created.Id];
        Assert.areEqual('Beverly Hills Co', saved.Name, 'Name should be saved');
        Assert.areEqual('Prospect', saved.Type, 'Type should be saved');
        Assert.areEqual('90210', saved.BillingPostalCode, 'The trimmed postal code should be saved');
        Assert.areEqual('Beverly Hills', saved.BillingCity, 'Billing city should come from the lookup');
        Assert.areEqual('California', saved.BillingState, 'Billing state should come from the lookup');
    }

    @IsTest
    static void shouldNotCreateAccount_WhenLookupFails() {
        // Given
        Test.setMock(HttpCalloutMock.class, new PostalCodeMock(404, '{}'));

        // When / Then
        Test.startTest();
        try {
            PostalCodeService.createAccountWithAddress('Nowhere Co', 'Prospect', 'us', '00000');
            Assert.fail('Expected PostalCodeServiceException for an unknown postal code');
        } catch (PostalCodeService.PostalCodeServiceException e) {
            Assert.areEqual('Unknown postal code: 00000', e.getMessage(), 'The lookup failure should be reported');
        }
        Test.stopTest();
        Assert.areEqual(0, [SELECT COUNT() FROM Account WHERE Name = 'Nowhere Co'], 'No Account should be created when the lookup fails');
    }

    @IsTest
    static void shouldThrow_WhenAccountHasNoPostalCode() {
        // Given
        Account account = TestDataFactory.createAccount();

        // When / Then
        Test.startTest();
        try {
            PostalCodeService.enrichBillingAddress(account.Id, 'us');
            Assert.fail('Expected PostalCodeServiceException for an Account without a postal code');
        } catch (PostalCodeService.PostalCodeServiceException e) {
            Assert.areEqual('Account has no billing postal code.', e.getMessage(), 'The missing postal code should be reported');
        }
        Test.stopTest();
    }
}
