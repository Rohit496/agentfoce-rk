/**
 * CaseFormLookupController
 *
 * Lightweight lookup search for the caseInputForm LWC (Agentforce CLT editor).
 * lightning-record-picker is not supported in the Agentforce surface (it
 * depends on the GraphQL UI API), so the form uses this Apex-backed
 * search-as-you-type lookup instead.
 */
public with sharing class CaseFormLookupController {
    /**
     * Searches Account or Contact records by name.
     *
     * @param objectApiName 'Account' or 'Contact' (restricted allowlist)
     * @param searchTerm    user-typed fragment; matched with LIKE %term%
     * @return up to 5 matching records as {id, name} pairs
     */
    @AuraEnabled(cacheable=true)
    public static List<LookupResult> search(
        String objectApiName,
        String searchTerm
    ) {
        List<LookupResult> results = new List<LookupResult>();

        if (String.isBlank(searchTerm) || searchTerm.trim().length() < 2) {
            return results;
        }

        String term = '%' + searchTerm.trim() + '%';

        if (objectApiName == 'Account') {
            for (Account a : [
                SELECT Id, Name
                FROM Account
                WHERE Name LIKE :term
                WITH USER_MODE
                ORDER BY Name
                LIMIT 5
            ]) {
                results.add(new LookupResult(a.Id, a.Name));
            }
        } else if (objectApiName == 'Contact') {
            for (Contact c : [
                SELECT Id, Name
                FROM Contact
                WHERE Name LIKE :term
                WITH USER_MODE
                ORDER BY Name
                LIMIT 5
            ]) {
                results.add(new LookupResult(c.Id, c.Name));
            }
        } else {
            throw new AuraHandledException(
                'Unsupported object: ' + objectApiName
            );
        }

        return results;
    }

    public class LookupResult {
        @AuraEnabled
        public String id;

        @AuraEnabled
        public String name;

        public LookupResult(String id, String name) {
            this.id = id;
            this.name = name;
        }
    }
}