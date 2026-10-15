public with sharing class AccountController {
    /**
     * @description Retrieves all Account records from the database
     * @return List<Account> List of all Account records with Id, Name, Industry, Phone, and AnnualRevenue
     * @throws AuraHandledException if there's an error querying accounts
     */
    @AuraEnabled(cacheable=true)
    public static List<Account> getAllAccounts() {
        try {
            return [
                SELECT
                    Id,
                    Name,
                    Industry,
                    Phone,
                    Type,
                    AnnualRevenue,
                    BillingCity,
                    BillingState,
                    BillingCountry,
                    Rating,
                    Website
                FROM Account
                WITH USER_MODE ORDER BY Name ASC
                LIMIT 200
            ];
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error retrieving accounts: ' + e.getMessage()
            );
        }
    }

    /**
     * @description Retrieves accounts with optional filtering
     * @param searchKey Search term to filter accounts by name
     * @return List<Account> Filtered list of Account records
     * @throws AuraHandledException if there's an error querying accounts
     */
    @AuraEnabled(cacheable=true)
    public static List<Account> searchAccounts(String searchKey) {
        try {
            String searchPattern = '%' + searchKey + '%';
            return [
                SELECT
                    Id,
                    Name,
                    Industry,
                    Phone,
                    Type,
                    AnnualRevenue,
                    BillingCity,
                    BillingState
                FROM Account
                WHERE Name LIKE :searchPattern
                WITH USER_MODE ORDER BY Name ASC
                LIMIT 50
            ];
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error searching accounts: ' + e.getMessage()
            );
        }
    }
}
