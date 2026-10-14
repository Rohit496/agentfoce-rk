/**
 * Returns accounts together with their related contacts, cases and opportunities
 * for the HXL "account related records" accordion MCP widget.
 */
global without sharing class AccountWithRelatedRecords {
    private static final Integer MAX_ACCOUNTS = 10;
    private static final Integer MAX_CHILDREN = 5;

    global class ContactRow {
        @InvocableVariable(label='Name' description='Contact full name')
        global String name;

        @InvocableVariable(label='Title' description='Contact job title')
        global String title;

        @InvocableVariable(label='Email' description='Contact email')
        global String email;

        @InvocableVariable(label='Phone' description='Contact phone')
        global String phone;
    }

    global class CaseRow {
        @InvocableVariable(label='Case Number' description='Case number')
        global String caseNumber;

        @InvocableVariable(label='Subject' description='Case subject')
        global String subject;

        @InvocableVariable(label='Status' description='Case status')
        global String status;

        @InvocableVariable(label='Priority' description='Case priority')
        global String priority;

        @InvocableVariable(
            label='Status Color'
            description='Semantic color token for the case status badge'
        )
        global String statusColor;
    }

    global class OpportunityRow {
        @InvocableVariable(label='Name' description='Opportunity name')
        global String name;

        @InvocableVariable(label='Stage' description='Opportunity stage')
        global String stage;

        @InvocableVariable(
            label='Amount'
            description='Opportunity amount, formatted as currency text'
        )
        global String amount;

        @InvocableVariable(
            label='Close Date'
            description='Close date, formatted as text'
        )
        global String closeDate;

        @InvocableVariable(
            label='Stage Color'
            description='Semantic color token for the stage badge'
        )
        global String stageColor;
    }

    global class AccountRow {
        @InvocableVariable(label='Name' description='Account name')
        global String name;

        @InvocableVariable(
            label='Subtitle'
            description='Industry and type on one line, shown under the account name'
        )
        global String subtitle;

        @InvocableVariable(label='Phone' description='Main phone number')
        global String phone;

        @InvocableVariable(label='Owner' description='Account owner name')
        global String owner;

        @InvocableVariable(
            label='Billing Address'
            description='Billing city, state and country on one line'
        )
        global String billingAddress;

        @InvocableVariable(
            label='Annual Revenue'
            description='Annual revenue, formatted as currency text'
        )
        global String annualRevenue;

        @InvocableVariable(
            label='Contacts Title'
            description='Section header, e.g. "Contacts (3)"'
        )
        global String contactsTitle;

        @InvocableVariable(
            label='Cases Title'
            description='Section header, e.g. "Cases (2)"'
        )
        global String casesTitle;

        @InvocableVariable(
            label='Opportunities Title'
            description='Section header, e.g. "Opportunities (1)"'
        )
        global String opportunitiesTitle;

        @InvocableVariable(
            label='No Contacts'
            description='True when the account has no contacts'
        )
        global Boolean noContacts;

        @InvocableVariable(
            label='No Cases'
            description='True when the account has no cases'
        )
        global Boolean noCases;

        @InvocableVariable(
            label='No Opportunities'
            description='True when the account has no opportunities'
        )
        global Boolean noOpportunities;

        @InvocableVariable(label='Contacts' description='Most recent contacts')
        global List<ContactRow> contacts;

        @InvocableVariable(label='Cases' description='Most recent cases')
        global List<CaseRow> cases;

        @InvocableVariable(
            label='Opportunities'
            description='Most recent opportunities'
        )
        global List<OpportunityRow> opportunities;
    }

    global class Result {
        @InvocableVariable(
            label='Summary Line'
            description='Pre-formatted summary, e.g. "3 accounts found"'
        )
        global String summaryLine;

        @InvocableVariable(
            label='Account Count'
            description='Number of accounts returned'
        )
        global Integer accountCount;

        @InvocableVariable(
            label='No Accounts'
            description='True when no accounts matched (drives the empty state)'
        )
        global Boolean noAccounts;

        @InvocableVariable(
            label='Accounts'
            description='Accounts with their related contacts, cases and opportunities'
        )
        global List<AccountRow> accounts;
    }

    /**
     * @param accountName Single-element list containing an optional account name filter
     *        (partial match). Blank returns all accounts, up to 10.
     * @return Single-element list with the accounts and their related records.
     */
    @InvocableMethod(
        label='Get Accounts With Related Records'
        description='Return accounts along with their related contacts, cases and opportunities, for example "show me the account Acme and its related records" or "show all accounts with their related records". Leave the account name blank to return all accounts.'
    )
    global static List<Result> getAccounts(List<String> accountName) {
        String filter = accountName != null &&
            !accountName.isEmpty() &&
            String.isNotBlank(accountName[0])
            ? accountName[0].trim()
            : null;
        String namePattern = filter == null ? '%' : '%' + filter + '%';

        List<Account> accounts = [
            SELECT
                Id,
                Name,
                Industry,
                Type,
                Phone,
                AnnualRevenue,
                BillingCity,
                BillingState,
                BillingCountry,
                Owner.Name,
                (
                    SELECT Name, Title, Email, Phone
                    FROM Contacts
                    ORDER BY CreatedDate DESC
                    LIMIT :MAX_CHILDREN
                ),
                (
                    SELECT CaseNumber, Subject, Status, Priority, IsClosed
                    FROM Cases
                    ORDER BY CreatedDate DESC
                    LIMIT :MAX_CHILDREN
                ),
                (
                    SELECT Name, StageName, Amount, CloseDate, IsClosed, IsWon
                    FROM Opportunities
                    ORDER BY CloseDate DESC
                    LIMIT :MAX_CHILDREN
                )
            FROM Account
            WHERE Name LIKE :namePattern
            WITH USER_MODE
            ORDER BY Name ASC
            LIMIT :MAX_ACCOUNTS
        ];

        Result result = new Result();
        result.accounts = new List<AccountRow>();
        for (Account acc : accounts) {
            result.accounts.add(toRow(acc));
        }
        result.accountCount = result.accounts.size();
        result.noAccounts = result.accounts.isEmpty();
        result.summaryLine =
            result.accountCount +
            (result.accountCount == 1 ? ' account found' : ' accounts found') +
            (filter == null ? '' : ' for "' + filter + '"');
        return new List<Result>{ result };
    }

    private static AccountRow toRow(Account acc) {
        AccountRow row = new AccountRow();
        row.name = acc.Name;
        row.subtitle = joinNonBlank(
            new List<String>{ acc.Industry, acc.Type },
            ' • '
        );
        row.phone = AccountDetails.valueOrDash(acc.Phone);
        row.owner = acc.Owner?.Name;
        row.billingAddress = AccountDetails.formatAddress(
            acc.BillingCity,
            acc.BillingState,
            acc.BillingCountry
        );
        row.annualRevenue = AccountDetails.formatCurrency(acc.AnnualRevenue);

        row.contacts = new List<ContactRow>();
        for (Contact c : acc.Contacts) {
            ContactRow cr = new ContactRow();
            cr.name = c.Name;
            cr.title = AccountDetails.valueOrDash(c.Title);
            cr.email = AccountDetails.valueOrDash(c.Email);
            cr.phone = AccountDetails.valueOrDash(c.Phone);
            row.contacts.add(cr);
        }

        row.cases = new List<CaseRow>();
        for (Case cs : acc.Cases) {
            CaseRow cr = new CaseRow();
            cr.caseNumber = cs.CaseNumber;
            cr.subject = AccountDetails.valueOrDash(cs.Subject);
            cr.status = AccountDetails.valueOrDash(cs.Status);
            cr.priority = AccountDetails.valueOrDash(cs.Priority);
            cr.statusColor = cs.IsClosed ? 'success' : 'warning';
            row.cases.add(cr);
        }

        row.opportunities = new List<OpportunityRow>();
        for (Opportunity opp : acc.Opportunities) {
            OpportunityRow orow = new OpportunityRow();
            orow.name = opp.Name;
            orow.stage = AccountDetails.valueOrDash(opp.StageName);
            orow.amount = AccountDetails.formatCurrency(opp.Amount);
            orow.closeDate = opp.CloseDate == null
                ? '—'
                : opp.CloseDate.format();
            orow.stageColor = !opp.IsClosed
                ? 'info'
                : (opp.IsWon ? 'success' : 'error');
            row.opportunities.add(orow);
        }

        row.contactsTitle = 'Contacts (' + row.contacts.size() + ')';
        row.casesTitle = 'Cases (' + row.cases.size() + ')';
        row.opportunitiesTitle =
            'Opportunities (' + row.opportunities.size() + ')';
        row.noContacts = row.contacts.isEmpty();
        row.noCases = row.cases.isEmpty();
        row.noOpportunities = row.opportunities.isEmpty();
        return row;
    }

    private static String joinNonBlank(List<String> values, String separator) {
        List<String> parts = new List<String>();
        for (String value : values) {
            if (String.isNotBlank(value)) {
                parts.add(value);
            }
        }
        return parts.isEmpty() ? '—' : String.join(parts, separator);
    }
}