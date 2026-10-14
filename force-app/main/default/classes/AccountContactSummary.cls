@RestResource(urlMapping='/AccountContactSummary/*')
global with sharing class AccountContactSummary {
    @HttpGet
    global static Map<String, Decimal> getAverageContactCountByAccount() {
        RestRequest request = RestContext.request;
        Map<String, Decimal> accountContactCount = new Map<String, Decimal>();

        // Grab the minimum annual revenue threshold from the end of the URL
        Decimal minAnnualRevenue = Decimal.valueOf(
            request.requestURI.substring(request.requestURI.lastIndexOf('/') + 1)
        );

        List<Account> accounts = [
            SELECT Id, Name, (SELECT Id FROM Contacts)
            FROM Account
            WHERE AnnualRevenue >= :minAnnualRevenue
        ];

        for (Account acc : accounts) {
            Decimal contactCount = acc.Contacts.size();
            accountContactCount.put(acc.Name, contactCount);
        }

        return accountContactCount;
    }
}