/**
 * Looks up places by postal code through the PostalCodeApi named credential (Zippopotam.us, no authentication)
 * and can copy the result onto an Account's billing address.
 *
 * The endpoint lives in the named credential, never in code. Record access uses user mode.
 */
public with sharing class PostalCodeService {
    private static final String NAMED_CREDENTIAL = 'callout:PostalCodeApi';
    private static final Integer TIMEOUT_MS = 10000;
    private static final Pattern COUNTRY_CODE = Pattern.compile('^[A-Za-z]{2}$');
    private static final Pattern POSTAL_CODE = Pattern.compile('^[A-Za-z0-9 -]{2,10}$');

    /** Thrown for invalid input, unknown postal codes and failed callouts. */
    public class PostalCodeServiceException extends Exception {
    }

    /** One place returned for a postal code. */
    public class PostalCodeResult {
        @AuraEnabled
        public String postalCode;
        @AuraEnabled
        public String country;
        @AuraEnabled
        public String placeName;
        @AuraEnabled
        public String state;
        @AuraEnabled
        public String stateCode;
        @AuraEnabled
        public Decimal latitude;
        @AuraEnabled
        public Decimal longitude;
    }

    /**
     * Returns the first place for a postal code.
     * @param countryCode ISO 3166-1 alpha-2 country code, e.g. 'us'
     * @param postalCode Postal code, e.g. '90210'
     * @return The place for that postal code
     * @throws PostalCodeServiceException when the input is invalid, the code is unknown (404) or the callout fails
     * @example
     * PostalCodeService.PostalCodeResult place = PostalCodeService.lookup('us', '90210'); // Beverly Hills, CA
     */
    public static PostalCodeResult lookup(String countryCode, String postalCode) {
        if (String.isBlank(countryCode) || !COUNTRY_CODE.matcher(countryCode.trim()).matches()) {
            throw new PostalCodeServiceException('Country code must be two letters, e.g. "us".');
        }
        if (String.isBlank(postalCode) || !POSTAL_CODE.matcher(postalCode.trim()).matches()) {
            throw new PostalCodeServiceException('Postal code must be 2 to 10 letters, digits, spaces or dashes.');
        }

        HttpRequest request = new HttpRequest();
        request.setEndpoint(
            NAMED_CREDENTIAL + '/' +
            EncodingUtil.urlEncode(countryCode.trim().toLowerCase(), 'UTF-8') + '/' +
            EncodingUtil.urlEncode(postalCode.trim(), 'UTF-8')
        );
        request.setMethod('GET');
        request.setTimeout(TIMEOUT_MS);

        HttpResponse response;
        try {
            response = new Http().send(request);
        } catch (CalloutException e) {
            throw new PostalCodeServiceException('Postal code service is unreachable: ' + e.getMessage(), e);
        }
        if (response.getStatusCode() == 404) {
            throw new PostalCodeServiceException('Unknown postal code: ' + postalCode.trim());
        }
        if (response.getStatusCode() != 200) {
            throw new PostalCodeServiceException('Postal code service returned HTTP ' + response.getStatusCode());
        }
        return parse(response.getBody());
    }

    /**
     * Fills an Account's billing city, state, country and coordinates from its billing postal code.
     * @param accountId Account whose BillingPostalCode is set
     * @param countryCode Country code for the lookup, e.g. 'us'
     * @return The updated Account
     * @throws PostalCodeServiceException when the Account has no billing postal code or the lookup fails
     */
    public static Account enrichBillingAddress(Id accountId, String countryCode) {
        Account account = [
            SELECT Id, BillingPostalCode
            FROM Account
            WHERE Id = :accountId
            WITH USER_MODE
            LIMIT 1
        ];
        if (String.isBlank(account.BillingPostalCode)) {
            throw new PostalCodeServiceException('Account has no billing postal code.');
        }
        PostalCodeResult place = lookup(countryCode, account.BillingPostalCode);
        account.BillingCity = place.placeName;
        account.BillingState = place.state;
        account.BillingCountry = place.country;
        account.BillingLatitude = place.latitude;
        account.BillingLongitude = place.longitude;
        update as user account;
        return account;
    }

    /**
     * Creates an Account whose billing address is filled from a postal code.
     * The callout happens before the insert, so it also works in a transaction that must not call out after DML.
     * @param accountName Name of the new Account
     * @param accountType Account Type (required by this org's validation rule)
     * @param countryCode Country code for the lookup, e.g. 'us'
     * @param postalCode Postal code, e.g. '10001'
     * @return The inserted Account
     * @throws PostalCodeServiceException when the lookup fails
     * @example
     * Account nyc = PostalCodeService.createAccountWithAddress('Acme NYC', 'Prospect', 'us', '10001');
     */
    public static Account createAccountWithAddress(String accountName, String accountType, String countryCode, String postalCode) {
        PostalCodeResult place = lookup(countryCode, postalCode);
        Account account = new Account(
            Name = accountName,
            Type = accountType,
            BillingPostalCode = postalCode.trim(),
            BillingCity = place.placeName,
            BillingState = place.state,
            BillingCountry = place.country,
            BillingLatitude = place.latitude,
            BillingLongitude = place.longitude
        );
        insert as user account;
        return account;
    }

    @TestVisible
    private static PostalCodeResult parse(String body) {
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(body);
        List<Object> places = (List<Object>) root.get('places');
        if (places == null || places.isEmpty()) {
            throw new PostalCodeServiceException('Postal code service returned no places.');
        }
        Map<String, Object> first = (Map<String, Object>) places[0];
        PostalCodeResult result = new PostalCodeResult();
        result.postalCode = (String) root.get('post code');
        result.country = (String) root.get('country');
        result.placeName = (String) first.get('place name');
        result.state = (String) first.get('state');
        result.stateCode = (String) first.get('state abbreviation');
        result.latitude = toDecimal(first.get('latitude'));
        result.longitude = toDecimal(first.get('longitude'));
        return result;
    }

    private static Decimal toDecimal(Object value) {
        return value == null ? null : Decimal.valueOf(String.valueOf(value));
    }
}
