/**
 * Default field values for Accounts created by automation (Agentforce actions, invocables).
 * This org requires Account.Type (custom validation rule), so code that creates Accounts must set it.
 */
public with sharing class AccountDefaults {
    /** Type for Accounts created by automation when the caller doesn't supply one. */
    public static final String ACCOUNT_TYPE = 'Prospect';

    private AccountDefaults() {
    }

    /**
     * Returns the given type, or the default when it is blank.
     * @param accountType Type supplied by the caller; may be blank
     * @return A non-blank Account Type
     * @example
     * String type = AccountDefaults.typeOrDefault(null); // 'Prospect'
     */
    public static String typeOrDefault(String accountType) {
        return String.isBlank(accountType) ? ACCOUNT_TYPE : accountType.trim();
    }
}
