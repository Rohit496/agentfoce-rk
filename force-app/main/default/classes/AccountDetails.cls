/**
 * Returns the details of a single Account (no related records) for the HXL
 * "account details" MCP widget.
 */
global without sharing class AccountDetails {
    global class Result {
        @InvocableVariable(
            label='Found'
            description='True when a matching account was found'
        )
        global Boolean found;

        @InvocableVariable(
            label='Not Found'
            description='True when no matching account was found (drives the empty state)'
        )
        global Boolean notFound;

        @InvocableVariable(
            label='Search Term'
            description='The account name that was searched for'
        )
        global String searchTerm;

        @InvocableVariable(label='Account Id' description='Salesforce Id of the account')
        global String accountId;

        @InvocableVariable(label='Name' description='Account name')
        global String name;

        @InvocableVariable(label='Account Number' description='Account number')
        global String accountNumber;

        @InvocableVariable(label='Type' description='Account type')
        global String type;

        @InvocableVariable(label='Industry' description='Industry')
        global String industry;

        @InvocableVariable(label='Rating' description='Account rating')
        global String rating;

        @InvocableVariable(label='Phone' description='Main phone number')
        global String phone;

        @InvocableVariable(label='Website' description='Website URL')
        global String website;

        @InvocableVariable(
            label='Annual Revenue'
            description='Annual revenue, formatted as currency text'
        )
        global String annualRevenue;

        @InvocableVariable(
            label='Employees'
            description='Number of employees, formatted as text'
        )
        global String employees;

        @InvocableVariable(
            label='Billing Address'
            description='Billing city, state and country on one line'
        )
        global String billingAddress;

        @InvocableVariable(label='Owner' description='Account owner name')
        global String owner;

        @InvocableVariable(label='Region' description='Account region')
        global String region;

        @InvocableVariable(label='Active' description='Whether the account is active')
        global String active;

        @InvocableVariable(label='Customer Priority' description='Customer priority')
        global String customerPriority;

        @InvocableVariable(
            label='Priority Color'
            description='Semantic color token for the customer priority badge'
        )
        global String priorityColor;

        @InvocableVariable(label='Description' description='Account description')
        global String description;

        @InvocableVariable(
            label='Has Priority'
            description='True when the account has a customer priority (shows the priority badge)'
        )
        global Boolean hasPriority;

        @InvocableVariable(
            label='Has Description'
            description='True when the account has a description (shows the description section)'
        )
        global Boolean hasDescription;
    }

    /**
     * @param accountName Single-element list containing the account name to look up
     *        (exact match first, then a partial match).
     * @return Single-element list with the account details (found = false when no match).
     */
    @InvocableMethod(
        label='Get Account Details'
        description='Return only the details of one account (no related records) given its name, for example "show me the details of account Acme"'
    )
    global static List<Result> getDetails(List<String> accountName) {
        Result result = new Result();
        Boolean hasInput =
            accountName != null &&
            !accountName.isEmpty() &&
            String.isNotBlank(accountName[0]);
        result.searchTerm = hasInput ? accountName[0].trim() : '';

        Account acc = hasInput ? findAccount(result.searchTerm) : null;
        result.found = acc != null;
        result.notFound = !result.found;
        result.hasPriority = acc != null && String.isNotBlank(acc.CustomerPriority__c);
        result.hasDescription = acc != null && String.isNotBlank(acc.Description);

        if (acc != null) {
            result.accountId = acc.Id;
            result.name = acc.Name;
            result.accountNumber = valueOrDash(acc.AccountNumber);
            result.type = valueOrDash(acc.Type);
            result.industry = valueOrDash(acc.Industry);
            result.rating = valueOrDash(acc.Rating);
            result.phone = valueOrDash(acc.Phone);
            result.website = valueOrDash(acc.Website);
            result.annualRevenue = formatCurrency(acc.AnnualRevenue);
            result.employees = acc.NumberOfEmployees == null
                ? '—'
                : String.valueOf(acc.NumberOfEmployees);
            result.billingAddress = formatAddress(
                acc.BillingCity,
                acc.BillingState,
                acc.BillingCountry
            );
            result.owner = acc.Owner?.Name;
            result.region = valueOrDash(acc.Region__c);
            result.active = valueOrDash(acc.Active__c);
            result.customerPriority = valueOrDash(acc.CustomerPriority__c);
            result.priorityColor = priorityColor(acc.CustomerPriority__c);
            result.description = String.isBlank(acc.Description)
                ? ''
                : acc.Description;
        }
        return new List<Result>{ result };
    }

    private static Account findAccount(String name) {
        List<Account> accounts = queryAccounts(name);
        if (accounts.isEmpty()) {
            accounts = queryAccounts('%' + name + '%');
        }
        return accounts.isEmpty() ? null : accounts[0];
    }

    private static List<Account> queryAccounts(String namePattern) {
        return [
            SELECT
                Id,
                Name,
                AccountNumber,
                Type,
                Industry,
                Rating,
                Phone,
                Website,
                AnnualRevenue,
                NumberOfEmployees,
                BillingCity,
                BillingState,
                BillingCountry,
                Owner.Name,
                Region__c,
                Active__c,
                CustomerPriority__c,
                Description
            FROM Account
            WHERE Name LIKE :namePattern
            WITH USER_MODE
            ORDER BY Name ASC
            LIMIT 1
        ];
    }

    public static String valueOrDash(String value) {
        return String.isBlank(value) ? '—' : value;
    }

    public static String formatCurrency(Decimal value) {
        return value == null ? '—' : '$' + value.setScale(2).format();
    }

    public static String formatAddress(
        String city,
        String state,
        String country
    ) {
        List<String> parts = new List<String>();
        for (String part : new List<String>{ city, state, country }) {
            if (String.isNotBlank(part)) {
                parts.add(part);
            }
        }
        return parts.isEmpty() ? '—' : String.join(parts, ', ');
    }

    public static String priorityColor(String priority) {
        if (priority == 'High') {
            return 'error';
        }
        if (priority == 'Medium') {
            return 'warning';
        }
        if (priority == 'Low') {
            return 'success';
        }
        return 'default';
    }
}