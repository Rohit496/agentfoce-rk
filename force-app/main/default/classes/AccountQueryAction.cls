public with sharing class AccountQueryAction {
    @InvocableMethod(
        label='Get Account Names'
        description='Returns the list of account names corresponding to the specified account IDs.'
        category='Account'
    )
    public static List<String> getAccountNames(List<ID> ids) {
        List<Account> accounts = [
            SELECT Name
            FROM Account
            WHERE Id IN :ids
            WITH USER_MODE
        ];
        Map<ID, String> idToName = new Map<ID, String>();
        for (Account account : accounts) {
            idToName.put(account.Id, account.Name);
        }
        // put each name in the output at the same position as the id in the input
        List<String> accountNames = new List<String>();
        for (String id : ids) {
            accountNames.add(idToName.get(id));
        }
        return accountNames;
    }
}