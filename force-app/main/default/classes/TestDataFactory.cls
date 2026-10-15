/**
 * Centralised factory for test data.
 *
 * Every @TestSetup delegates record creation here so that a field becoming
 * required breaks one file rather than every test class.
 *
 * Methods come in pairs: `build*` returns unsaved records, `create*` builds and
 * inserts. That split replaces the usual `doInsert` boolean flag, which makes
 * call sites unreadable (`createAccounts(5, true)` says nothing about what true means).
 */
@IsTest
public class TestDataFactory {
    public static final String STAGE_PROSPECTING = 'Prospecting';
    public static final String STAGE_CLOSED_LOST = 'Closed Lost';
    public static final String PROFILE_MINIMUM_ACCESS = 'Minimum Access - Salesforce';

    /** This org enforces a validation rule requiring Account.Type. */
    private static final String ACCOUNT_TYPE = 'Prospect';

    private static final Decimal BASE_AMOUNT = 10000;
    private static final Decimal AMOUNT_INCREMENT = 1000;
    private static final Integer DEFAULT_CLOSE_OFFSET_DAYS = 30;
    private static final Integer ID_BODY_LENGTH = 12;
    private static final String ID_PADDING = '000000000000';

    /** Sequence backing generateFakeId so each generated Id is unique per transaction. */
    private static Integer fakeIdSequence = 1;

    // ─── Accounts ────────────────────────────────────────────────────────

    /**
     * Builds unsaved Accounts with predictable names.
     * @param count Number of Accounts to build
     * @return The built Accounts
     */
    public static List<Account> buildAccounts(Integer count) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(
                new Account(
                    Name = 'Test Account ' + String.valueOf(i),
                    Type = ACCOUNT_TYPE
                )
            );
        }
        return accounts;
    }

    /**
     * Builds and inserts Accounts.
     * @param count Number of Accounts to create
     * @return The inserted Accounts
     */
    public static List<Account> createAccounts(Integer count) {
        List<Account> accounts = buildAccounts(count);
        insert accounts;
        return accounts;
    }

    /**
     * Builds and inserts a single Account.
     * @return The inserted Account
     */
    public static Account createAccount() {
        return createAccounts(1)[0];
    }

    // ─── Opportunities ───────────────────────────────────────────────────

    /**
     * Builds unsaved Opportunities with ascending, deterministic Amounts so tests
     * can compute exact expected sums.
     * @param account Parent Account; may be null for opportunities with no account
     * @param count Number of Opportunities to build
     * @param stageName Stage to apply to every record
     * @return The built Opportunities
     */
    public static List<Opportunity> buildOpportunities(
        Account account,
        Integer count,
        String stageName
    ) {
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < count; i++) {
            opportunities.add(
                new Opportunity(
                    Name = 'Test Opportunity ' + String.valueOf(i),
                    AccountId = account?.Id,
                    StageName = stageName,
                    CloseDate = Date.today().addDays(DEFAULT_CLOSE_OFFSET_DAYS),
                    Amount = BASE_AMOUNT + (i * AMOUNT_INCREMENT)
                )
            );
        }
        return opportunities;
    }

    /**
     * Builds and inserts Opportunities.
     * @param account Parent Account; may be null
     * @param count Number of Opportunities to create
     * @param stageName Stage to apply to every record
     * @return The inserted Opportunities
     */
    public static List<Opportunity> createOpportunities(
        Account account,
        Integer count,
        String stageName
    ) {
        List<Opportunity> opportunities = buildOpportunities(account, count, stageName);
        insert opportunities;
        return opportunities;
    }

    /**
     * Builds and inserts one Opportunity with an exact name, used by search tests.
     * @param name Exact Opportunity name
     * @param stageName Stage to apply
     * @return The inserted Opportunity
     */
    public static Opportunity createNamedOpportunity(String name, String stageName) {
        Opportunity opportunity = new Opportunity(
            Name = name,
            StageName = stageName,
            CloseDate = Date.today().addDays(DEFAULT_CLOSE_OFFSET_DAYS),
            Amount = BASE_AMOUNT
        );
        insert opportunity;
        return opportunity;
    }

    /**
     * Builds an in-memory Opportunity whose read-only IsClosed flag is set.
     *
     * IsClosed is derived by the platform from StageName and cannot be assigned
     * directly, so the record is rehydrated from JSON. This is the standard way
     * to stage a read-only field for a unit test that never touches the database.
     *
     * @param opportunityId Id the record should carry
     * @param stageName Closed stage to report
     * @return An unsaved Opportunity reporting IsClosed = true
     */
    public static Opportunity buildClosedOpportunity(Id opportunityId, String stageName) {
        Map<String, Object> raw = new Map<String, Object>{
            'attributes' => new Map<String, Object>{ 'type' => 'Opportunity' },
            'Id' => opportunityId,
            'StageName' => stageName,
            'IsClosed' => true
        };
        return (Opportunity) JSON.deserialize(JSON.serialize(raw), Opportunity.class);
    }

    // ─── Users ───────────────────────────────────────────────────────────

    /**
     * Builds an unsaved user on the Minimum Access profile, used to prove
     * USER_MODE enforcement.
     * @return The built User
     */
    public static User buildMinimumAccessUser() {
        Profile minimumAccess = [
            SELECT Id
            FROM Profile
            WHERE Name = :PROFILE_MINIMUM_ACCESS
            LIMIT 1
        ];
        String uniqueKey =
            String.valueOf(DateTime.now().getTime()) + String.valueOf(fakeIdSequence++);

        return new User(
            FirstName = 'Least',
            LastName = 'Privilege',
            Alias = 'lpriv',
            Email = 'least.privilege@example.com',
            Username = 'least.privilege.' + uniqueKey + '@example.com.invalid',
            ProfileId = minimumAccess.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
    }

    /**
     * Builds and inserts a Minimum Access user. Call this inside a System.runAs
     * block to avoid MIXED_DML_OPERATION between setup and non-setup objects.
     * @return The inserted User
     */
    public static User createMinimumAccessUser() {
        User user = buildMinimumAccessUser();
        insert user;
        return user;
    }

    // ─── Contacts & Cases ────────────────────────────────────────────────

    /**
     * Builds unsaved Contacts with predictable names under one Account.
     * @param accountId Parent Account Id; may be null
     * @param count Number of Contacts to build
     * @return The built Contacts
     */
    public static List<Contact> buildContacts(Id accountId, Integer count) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            contacts.add(
                new Contact(
                    FirstName = 'Test',
                    LastName = 'Contact ' + String.valueOf(i),
                    Email = 'test.contact' + String.valueOf(i) + '@example.com',
                    AccountId = accountId
                )
            );
        }
        return contacts;
    }

    /**
     * Builds unsaved Cases with predictable subjects.
     * @param accountId Parent Account Id; may be null
     * @param count Number of Cases to build
     * @param status Status to apply to every Case
     * @return The built Cases
     */
    public static List<Case> buildCases(Id accountId, Integer count, String status) {
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < count; i++) {
            cases.add(
                new Case(
                    Subject = 'Test Case ' + String.valueOf(i),
                    Description = 'Description ' + String.valueOf(i),
                    Status = status,
                    Origin = 'Web',
                    AccountId = accountId
                )
            );
        }
        return cases;
    }

    // ─── Helpers ─────────────────────────────────────────────────────────

    /**
     * Produces a syntactically valid Id that matches no real record, so tests can
     * exercise not-found branches without inserting and deleting rows.
     * Describe is requested DEFERRED so child relationships are not eagerly loaded.
     * @param sobjectType The SObject type whose key prefix to use
     * @return A unique, non-existent Id of that type
     */
    public static Id generateFakeId(Schema.SObjectType sobjectType) {
        String prefix = sobjectType
            .getDescribe(SObjectDescribeOptions.DEFERRED)
            .getKeyPrefix();
        String suffix = String.valueOf(fakeIdSequence++);
        return Id.valueOf(
            prefix + ID_PADDING.substring(0, ID_BODY_LENGTH - suffix.length()) + suffix
        );
    }
}